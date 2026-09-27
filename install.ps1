# ============================================================
# dmark - Directory Marks
# Installer
# Version 0.5.0
# ============================================================

$ErrorActionPreference = "Stop"

$DMarkVersion = "0.5.0"

$DMarkHome = Join-Path $HOME ".dmark"
$DMarkBin = Join-Path $DMarkHome "bin"
$DMarkInstalledScript = Join-Path $DMarkBin "dmark.ps1"

$DMarkDownloadUrl =
    "https://raw.githubusercontent.com/FrEaKAlL/dmark/main/src/dmark.ps1"

$ProfileStart = "# >>> dmark >>>"
$ProfileEnd   = "# <<< dmark <<<"

Write-Host ""
Write-Host "====================================="
Write-Host " dmark - Directory Marks"
Write-Host " Installer v$DMarkVersion"
Write-Host "====================================="
Write-Host ""


# ============================================================
# FUNCIONES
# ============================================================

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

    # Eliminar una configuracion anterior
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


# ============================================================
# 1. PREPARAR INSTALACION
# ============================================================

Write-Host "[1/5] Preparando instalacion..."

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


# ============================================================
# 2. OBTENER DMARK
# ============================================================

Write-Host "[2/5] Obteniendo dmark..."

$LocalSource = $null

# Cuando install.ps1 se ejecuta desde un repositorio clonado,
# $PSScriptRoot contiene la ubicacion del script.
if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {

    $PossibleSource = Join-Path $PSScriptRoot "src\dmark.ps1"

    if (Test-Path $PossibleSource) {
        $LocalSource = $PossibleSource
    }
}


if ($null -ne $LocalSource) {

    Write-Host "      Instalacion local"
    Write-Host "      $LocalSource"

    Copy-Item `
        -Path $LocalSource `
        -Destination $DMarkInstalledScript `
        -Force

}
else {

    Write-Host "      Instalacion remota"
    Write-Host "      Descargando desde GitHub..."

    $TempFile = Join-Path $env:TEMP "dmark-install.ps1"

    try {

        Invoke-WebRequest `
            -Uri $DMarkDownloadUrl `
            -OutFile $TempFile `
            -UseBasicParsing `
            -ErrorAction Stop

        if (-not (Test-Path $TempFile)) {
            throw "No se pudo descargar dmark."
        }

        $DownloadedContent = Get-Content $TempFile -Raw

        # Validaciones basicas antes de instalar
        if ($DownloadedContent -notmatch '\$script:DMarkVersion') {
            throw "El archivo descargado no contiene una version valida."
        }

        if ($DownloadedContent -notmatch 'function dmark') {
            throw "El archivo descargado no parece ser dmark."
        }

        if ($DownloadedContent -notmatch 'Set-Alias dm dmark') {
            throw "El archivo descargado no contiene el alias dm."
        }

        Copy-Item `
            -Path $TempFile `
            -Destination $DMarkInstalledScript `
            -Force

    }
    finally {

        if (Test-Path $TempFile) {
            Remove-Item $TempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "      OK" -ForegroundColor Green


# ============================================================
# 3. VALIDAR ARCHIVO INSTALADO
# ============================================================

Write-Host "[3/5] Validando dmark..."

if (-not (Test-Path $DMarkInstalledScript)) {
    throw "No se encontro dmark despues de la instalacion."
}

$InstalledContent = Get-Content $DMarkInstalledScript -Raw

$VersionMatch = [regex]::Match(
    $InstalledContent,
    '\$script:DMarkVersion\s*=\s*"([^"]+)"'
)

if (-not $VersionMatch.Success) {
    throw "No se pudo determinar la version instalada."
}

$InstalledVersion = $VersionMatch.Groups[1].Value

Write-Host "      Version $InstalledVersion"
Write-Host "      OK" -ForegroundColor Green


# ============================================================
# 4. CONFIGURAR POWERSHELL
# ============================================================

Write-Host "[4/5] Configurando PowerShell Profiles..."

$Documents = [Environment]::GetFolderPath("MyDocuments")

$Profiles = @(
    @{
        Name = "Windows PowerShell 5.1"
        Path = Join-Path $Documents `
            "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    },
    @{
        Name = "PowerShell 7+"
        Path = Join-Path $Documents `
            "PowerShell\Microsoft.PowerShell_profile.ps1"
    }
)

$ProcessedProfiles = @{}

foreach ($ProfileInfo in $Profiles) {

    if ($ProcessedProfiles.ContainsKey($ProfileInfo.Path)) {
        continue
    }

    Install-DMarkProfile `
        -ProfilePath $ProfileInfo.Path `
        -ProfileName $ProfileInfo.Name

    $ProcessedProfiles[$ProfileInfo.Path] = $true
}


# ============================================================
# 5. FINALIZAR
# ============================================================

Write-Host ""
Write-Host "[5/5] Cargando dmark..."

try {

    . $DMarkInstalledScript

    Write-Host "      Version $InstalledVersion"
    Write-Host "      OK" -ForegroundColor Green

}
catch {

    Write-Host "      No se pudo cargar dmark en la sesion actual." `
        -ForegroundColor Yellow

    Write-Host "      Abre una nueva terminal para utilizar dm."
}

Write-Host ""
Write-Host "====================================="
Write-Host " dmark instalado correctamente"
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

Write-Host "Version:"
Write-Host "  $InstalledVersion"
Write-Host ""

Write-Host "Instalacion:"
Write-Host "  $DMarkInstalledScript"
Write-Host ""

Write-Host "Marcadores:"
Write-Host "  $DMarkHome\marks.json"
Write-Host ""

Write-Host "Compatible con:"
Write-Host "  - Windows PowerShell 5.1"
Write-Host "  - PowerShell 7+"
Write-Host ""

Write-Host "Abre una nueva terminal y ejecuta:"
Write-Host ""
Write-Host "  dm"
Write-Host "  dm --help"
Write-Host ""
