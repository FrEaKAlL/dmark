# ============================================================
# dmark - Directory Marks
# Installer
# Version 0.2.0
# ============================================================

$ErrorActionPreference = "Stop"

$DMarkVersion = "0.2.0"

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
# 1. Validar archivo fuente
# ------------------------------------------------------------

Write-Host "[1/5] Validando archivos..."

if (-not (Test-Path $SourceScript)) {
    Write-Host ""
    Write-Host "ERROR: No se encontro:" -ForegroundColor Red
    Write-Host "  $SourceScript"
    Write-Host ""
    Write-Host "Ejecuta install.ps1 desde el repositorio de dmark."
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
# 4. Configurar PowerShell Profile
# ------------------------------------------------------------

Write-Host "[4/5] Configurando PowerShell..."

$ProfilePath = $PROFILE

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

# Eliminar configuracion anterior de dmark
$ProfileContent =
    [regex]::Replace(
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

$ProfileContent =
    $ProfileContent.TrimEnd() +
    "`r`n" +
    $DMarkProfileBlock

Set-Content `
    -Path $ProfilePath `
    -Value $ProfileContent `
    -Encoding UTF8

Write-Host "      Profile:"
Write-Host "      $ProfilePath"
Write-Host "      OK" -ForegroundColor Green


# ------------------------------------------------------------
# 5. Cargar dmark en la sesion actual
# ------------------------------------------------------------

Write-Host "[5/5] Cargando dmark..."

. $DMarkInstalledScript

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

Write-Host "Configuracion:"
Write-Host "  $DMarkHome\marks.json"
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
Write-Host "  dm --help"
Write-Host ""

Write-Host "Puedes comenzar a utilizar dmark ahora."
Write-Host ""
