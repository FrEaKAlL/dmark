# ============================================================
# dmark - Directory Marks
# Uninstaller
# Version 0.3.2
# ============================================================

param(
    [switch]$Purge
)

$ErrorActionPreference = "Stop"

$DMarkHome = Join-Path $HOME ".dmark"
$DMarkBin  = Join-Path $DMarkHome "bin"
$DMarkFile = Join-Path $DMarkHome "marks.json"

$ProfileStart = "# >>> dmark >>>"
$ProfileEnd   = "# <<< dmark <<<"


function Remove-DMarkFromProfile {

    param(
        [string]$ProfilePath,
        [string]$ProfileName
    )

    Write-Host ""
    Write-Host "      $ProfileName"

    if (-not (Test-Path $ProfilePath)) {
        Write-Host "      Profile no encontrado."
        return
    }

    $ProfileContent = Get-Content $ProfilePath -Raw

    if ($null -eq $ProfileContent) {
        return
    }

    $EscapedStart = [regex]::Escape($ProfileStart)
    $EscapedEnd   = [regex]::Escape($ProfileEnd)

    $Pattern = "(?ms)$EscapedStart.*?$EscapedEnd\s*"

    if ($ProfileContent -match $Pattern) {

        $ProfileContent = [regex]::Replace(
            $ProfileContent,
            $Pattern,
            ""
        )

        Set-Content `
            -Path $ProfilePath `
            -Value $ProfileContent.TrimEnd() `
            -Encoding UTF8

        Write-Host "      Configuracion eliminada." -ForegroundColor Green
    }
    else {
        Write-Host "      Sin configuracion de dmark."
    }
}


Write-Host ""
Write-Host "====================================="
Write-Host " dmark - Directory Marks"
Write-Host " Uninstaller"
Write-Host "====================================="
Write-Host ""

try {

    # --------------------------------------------------------
    # Profiles
    # --------------------------------------------------------

    Write-Host "[1/3] Limpiando PowerShell Profiles..."

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

        Remove-DMarkFromProfile `
            -ProfilePath $ProfileInfo.Path `
            -ProfileName $ProfileInfo.Name

        $ProcessedProfiles[$ProfileInfo.Path] = $true
    }


    # --------------------------------------------------------
    # Programa
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "[2/3] Eliminando dmark..."

    if (Test-Path $DMarkBin) {

        Remove-Item `
            -Path $DMarkBin `
            -Recurse `
            -Force

        Write-Host "      Eliminado." -ForegroundColor Green
    }
    else {
        Write-Host "      dmark no parece estar instalado."
    }


    # --------------------------------------------------------
    # Datos
    # --------------------------------------------------------

    Write-Host "[3/3] Revisando marcadores..."

    if ($Purge) {

        if (Test-Path $DMarkFile) {
            Remove-Item $DMarkFile -Force
        }

        if (Test-Path $DMarkHome) {

            $RemainingItems = Get-ChildItem $DMarkHome -Force

            if ($RemainingItems.Count -eq 0) {
                Remove-Item $DMarkHome -Force
            }
        }

        Write-Host "      Limpieza completa realizada." -ForegroundColor Green
    }
    else {

        if (Test-Path $DMarkFile) {
            Write-Host "      Marcadores conservados:" -ForegroundColor Green
            Write-Host "      $DMarkFile"
        }
        else {
            Write-Host "      No existen marcadores guardados."
        }
    }


    Write-Host ""
    Write-Host "====================================="
    Write-Host " dmark desinstalado correctamente"
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host ""

    if (-not $Purge -and (Test-Path $DMarkFile)) {
        Write-Host "Tus marcadores fueron conservados."
        Write-Host "  $DMarkFile"
        Write-Host ""
    }

    Write-Host "Cierra las terminales abiertas para completar la desinstalacion."
    Write-Host ""
}
catch {

    Write-Host ""
    Write-Host "No se pudo completar la desinstalacion." -ForegroundColor Red
    Write-Host ""
    Write-Host "Detalle:"
    Write-Host "  $($_.Exception.Message)"
    Write-Host ""

    exit 1
}
