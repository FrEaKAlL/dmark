# ============================================================
# dmark - Directory Marks
# Installer
# Version 0.3.2
# ============================================================

$ErrorActionPreference = "Stop"

$DMarkVersion = "0.3.2"

$DMarkHome = Join-Path $HOME ".dmark"
$DMarkBin = Join-Path $DMarkHome "bin"
$DMarkInstalledScript = Join-Path $DMarkBin "dmark.ps1"

$SourceScript = Join-Path $PSScriptRoot "src\dmark.ps1"

$ProfileStart = "# >>> dmark >>>"
$ProfileEnd   = "# <<< dmark <<<"

Write-Host ""
Write-Host "====================================="
Write-Host " dmark - Directory Marks"
Write-Host " Installer v$DMarkVersion"
Write-Host "====================================="
Write-Host ""

# ------------------------------------------------------------
# Funcion para configurar un Profile
# ------------------------------------------------------------

function Install-DMarkProfile {

    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfilePath,

        [Parameter(Mandatory = $true)]
        [string]$ProfileName
    )

    Write-Host ""
    Write-Host "      $ProfileName"
    Write-Host "      $ProfilePath"

    $ProfileDirectory = Split-Path $ProfilePath -Parent

    if (-not (Test-Path $ProfileDirectory)) {
        New-Item `
            -ItemType Directory `
            -Path $ProfileDirectory `
            -Force | Out-Null
    }

    if (-not (Test-Path $ProfilePath)) {
        New-Item `
            -ItemType File `
            -Path $ProfilePath `
            -Force | Out-Null
    }

    $ProfileContent = Get-Content $ProfilePath -Raw

    if ($null -eq $ProfileContent) {
        $ProfileContent = ""
    }

    $EscapedStart = [regex]::Escape($ProfileStart)
    $EscapedEnd   = [regex]::Escape($ProfileEnd)

    $ExistingBlockPattern =
        "(?ms)$EscapedStart.*?$EscapedEnd\s*"

    # Eliminar bloque anterior de dmark
    $ProfileContent = [regex]::Replace(
        $ProfileContent,
        $ExistingBlockPattern,
        ""
    )

    $DMarkProfileBlock = @"

$ProfileStart
# Carga dmark - Directory Marks

`$DMarkScript = Join-Path `$HOME ".dmark\bin\dmark.ps1"

if (Test-Path `$DMarkScript) {
    . `$DMarkScript
}

$ProfileEnd

"@

    $NewProfileContent = $ProfileContent.TrimEnd()

    if (-not [string]::IsNullOrWhiteSpace($NewProfileContent)) {
        $NewProfileContent += "`r`n"
    }

    $NewProfileContent += $DMarkProfileBlock

    Set-Content `
        -Path $ProfilePath `
        -Value $NewProfileContent `
        -Encoding UTF8

    Write-Host "      OK" -ForegroundColor Green
}


# ------------------------------------------------------------
# 1. Validar archivo fuente
# ------------------------------------------------------------

Write-Host "[1/5] Validando archivos..."

if (-not (Test-Path $SourceScript)) {
    Write-Host ""
    Write-Host "ERROR: No se encontro:" -ForegroundColor Red
    Write-Host "  $SourceScript"
    Write-Host ""
    exit 1
}

Write-Host "      OK" -ForegroundColor Green


# ------------------------------------------------------------
# 2. Crear estructura ~/.dmark
# ------------------------------------------------------------

Write-Host "[2/5] Preparando directorio de instalacion..."

if (-not (Test-Path $DMarkHome)) {
    New-Item `
        -ItemType Directory `
        -Path $DMarkHome `
        -Force | Out-Null
}

if (-not (Test-Path $DMarkBin)) {
    New-Item `
        -ItemType Directory `
        -Path $DMarkBin `
        -Force | Out-Null
}

Write-Host "      $DMarkBin"
Write-Host "      OK" -ForegroundColor Green


# ------------------------------------------------------------
# 3. Instalar dmark.ps1
# ------------------------------------------------------------

Write-Host "[3/5] Instalando dmark..."

Copy-Item `
    -Path $SourceScript `
    -Destination $DMarkInstalledScript `
    -Force

Write-Host "      $DMarkInstalledScript"
Write-Host "      OK" -ForegroundColor Green



# ------------------------------------------------------------
# 4. Configurar Profiles
# ------------------------------------------------------------

Write-Host "[4/5] Configurando PowerShell Profiles..."

$Profiles = @()

# Windows PowerShell 5.1
$WindowsPowerShellProfile = Join-Path `
    ([Environment]::GetFolderPath("MyDocuments")) `
    "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"

$Profiles += @{
    Name = "Windows PowerShell 5.1"
    Path = $WindowsPowerShellProfile
}


# PowerShell 7+
$PowerShellProfile = Join-Path `
    ([Environment]::GetFolderPath("MyDocuments")) `
    "PowerShell\Microsoft.PowerShell_profile.ps1"

$Profiles += @{
    Name = "PowerShell 7+"
    Path = $PowerShellProfile
}


# Evitar procesar dos veces la misma ruta
$ProcessedProfiles = @{}

foreach ($ProfileInfo in $Profiles) {

    $ProfilePath = $ProfileInfo.Path

    if ($ProcessedProfiles.ContainsKey($ProfilePath)) {
        continue
    }

    Install-DMarkProfile `
        -ProfilePath $ProfilePath `
        -ProfileName $ProfileInfo.Name

    $ProcessedProfiles[$ProfilePath] = $true
}


# ------------------------------------------------------------
# 5. Cargar dmark en esta ejecucion
# ------------------------------------------------------------

Write-Host ""
Write-Host "[5/5] Validando instalacion..."

if (-not (Test-Path $DMarkInstalledScript)) {
    Write-Host "      ERROR" -ForegroundColor Red
    Write-Host "No se encontro:"
    Write-Host "  $DMarkInstalledScript"
    exit 1
}

Write-Host "      OK" -ForegroundColor Green


# ------------------------------------------------------------
# Resultado
# ------------------------------------------------------------

Write-Host ""
Write-Host "====================================="
Write-Host " dmark instalado correctamente"
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

Write-Host "Instalacion:"
Write-Host "  $DMarkInstalledScript"
Write-Host ""

Write-Host "Profiles configurados:"
Write-Host ""

foreach ($ProfileInfo in $Profiles) {
    Write-Host "  $($ProfileInfo.Name)"
    Write-Host "    $($ProfileInfo.Path)"
}

Write-Host ""
Write-Host "Configuracion:"
Write-Host "  $DMarkHome\marks.json"
Write-Host ""

Write-Host "dmark estara disponible en nuevas sesiones de:"
Write-Host ""
Write-Host "  - Windows PowerShell 5.1"
Write-Host "  - PowerShell 7+"
Write-Host ""

Write-Host "Comandos:"
Write-Host ""
Write-Host "  dm"
Write-Host "  dm add <nombre>"
Write-Host "  dm <nombre>"
Write-Host "  dm rm <nombre>"
Write-Host "  dm rename <actual> <nuevo>"
Write-Host "  dm path <nombre>"
Write-Host "  dm open <nombre>"
Write-Host "  dm update"
Write-Host "  dm --help"
Write-Host ""

Write-Host "Abre una nueva terminal para comenzar."
Write-Host ""
