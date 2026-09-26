# dmark - Directory Marks
# Version 0.1.0

$script:DMarkVersion = "0.3.1"
$script:DMarkUpdateUrl = "https://raw.githubusercontent.com/FrEaKAlL/dmark/main/src/dmark.ps1"
$script:DMarkHome = Join-Path $HOME ".dmark"
$script:DMarkFile = Join-Path $script:DMarkHome "marks.json"

function Initialize-DMark {
    if (-not (Test-Path $script:DMarkHome)) {
        New-Item -ItemType Directory -Path $script:DMarkHome -Force | Out-Null
    }

    if (-not (Test-Path $script:DMarkFile)) {
        "{}" | Set-Content -Path $script:DMarkFile -Encoding UTF8
    }
}

function Get-DMarkData {
    Initialize-DMark

    try {
        $content = Get-Content $script:DMarkFile -Raw

        if ([string]::IsNullOrWhiteSpace($content)) {
            return @{}
        }

        $json = $content | ConvertFrom-Json

        $marks = @{}

        if ($null -ne $json) {
            $json.PSObject.Properties | ForEach-Object {
                $marks[$_.Name] = $_.Value
            }
        }

        return $marks
    }
    catch {
        Write-Host "Error leyendo la configuración de dmark." -ForegroundColor Red
        return @{}
    }
}

function Save-DMarkData {
    param(
        [hashtable]$Marks
    )

    Initialize-DMark

    $Marks |
        ConvertTo-Json |
        Set-Content -Path $script:DMarkFile -Encoding UTF8
}

function Show-DMarkList {
    $marks = Get-DMarkData

    if ($marks.Count -eq 0) {
        Write-Host ""
        Write-Host "No tienes directorios registrados."
        Write-Host ""
        Write-Host "Agrega uno con:"
        Write-Host "  dm add <nombre>"
        Write-Host ""
        return
    }

    Write-Host ""
    Write-Host "dmark - Directorios registrados"
    Write-Host ""

    $marks.GetEnumerator() |
        Sort-Object Name |
        ForEach-Object {
            Write-Host ("  {0,-20} {1}" -f $_.Name, $_.Value)
        }

    Write-Host ""
}

function Add-DMark {
    param(
        [string]$Name,
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        Write-Host "Debes indicar un nombre." -ForegroundColor Yellow
        Write-Host "Ejemplo: dm add logs"
        return
    }

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = (Get-Location).Path
    }

    try {
        $Path = (Resolve-Path $Path -ErrorAction Stop).Path
    }
    catch {
        Write-Host "La ruta no existe:" -ForegroundColor Red
        Write-Host "  $Path"
        return
    }

    $marks = Get-DMarkData

    if ($marks.ContainsKey($Name)) {
        Write-Host "Ya existe un marcador llamado '$Name'." -ForegroundColor Yellow
        Write-Host "Ruta actual:"
        Write-Host "  $($marks[$Name])"
        return
    }

    $marks[$Name] = $Path

    Save-DMarkData $marks

    Write-Host ""
    Write-Host "Marcador agregado:" -ForegroundColor Green
    Write-Host "  $Name -> $Path"
    Write-Host ""
}

function Remove-DMark {
    param(
        [string]$Name
    )

    $marks = Get-DMarkData

    if (-not $marks.ContainsKey($Name)) {
        Write-Host "No existe el marcador '$Name'." -ForegroundColor Yellow
        return
    }

    $marks.Remove($Name)

    Save-DMarkData $marks

    Write-Host "Marcador '$Name' eliminado." -ForegroundColor Green
}

function Rename-DMark {
    param(
        [string]$OldName,
        [string]$NewName
    )

    if ([string]::IsNullOrWhiteSpace($OldName) -or
        [string]::IsNullOrWhiteSpace($NewName)) {

        Write-Host "Uso:"
        Write-Host "  dm rename <actual> <nuevo>"
        return
    }

    $marks = Get-DMarkData

    if (-not $marks.ContainsKey($OldName)) {
        Write-Host "No existe '$OldName'." -ForegroundColor Yellow
        return
    }

    if ($marks.ContainsKey($NewName)) {
        Write-Host "Ya existe '$NewName'." -ForegroundColor Yellow
        return
    }

    $path = $marks[$OldName]

    $marks.Remove($OldName)
    $marks[$NewName] = $path

    Save-DMarkData $marks

    Write-Host "$OldName -> $NewName" -ForegroundColor Green
}

function Show-DMarkHelp {

    Write-Host @"

dmark - Directory Marks
Version $script:DMarkVersion

Uso:

  dm
      Lista todos los directorios registrados.

  dm <nombre>
      Navega al directorio.

  dm add <nombre>
      Registra el directorio actual.

  dm add <nombre> <ruta>
      Registra una ruta específica.

  dm update
      Busca e instala una nueva version de dmark.

  dm rm <nombre>
      Elimina un marcador.

  dm rename <actual> <nuevo>
      Renombra un marcador.

  dm path <nombre>
      Muestra la ruta registrada.

  dm open <nombre>
      Abre el directorio en Explorer.

  dm --help
      Muestra esta ayuda.

  dm --version
      Muestra la versión.

Ejemplos:

  dm add logs
  dm add personal C:\ProyectosPersonales

  dm logs
  dm personal

"@
}

function Update-DMark {

    Write-Host ""
    Write-Host "dmark - Update"
    Write-Host ""

    $CurrentVersion = $script:DMarkVersion
    $TempFile = Join-Path $env:TEMP "dmark-update.ps1"

    Write-Host "Version instalada : $CurrentVersion"
    Write-Host "Buscando actualizaciones..."

    try {

        # ----------------------------------------------------
        # Descargar nueva version
        # ----------------------------------------------------

        Invoke-WebRequest `
            -Uri $script:DMarkUpdateUrl `
            -OutFile $TempFile `
            -UseBasicParsing `
            -ErrorAction Stop

        if (-not (Test-Path $TempFile)) {
            throw "No se pudo descargar el archivo de actualizacion."
        }

        # ----------------------------------------------------
        # Leer version remota
        # ----------------------------------------------------

        $RemoteContent = Get-Content $TempFile -Raw

        $VersionMatch = [regex]::Match(
            $RemoteContent,
            '\$script:DMarkVersion\s*=\s*"([^"]+)"'
        )

        if (-not $VersionMatch.Success) {
            throw "No se pudo determinar la version remota."
        }

        $RemoteVersion = $VersionMatch.Groups[1].Value

        Write-Host "Version disponible : $RemoteVersion"
        Write-Host ""

        # ----------------------------------------------------
        # Comparar versiones
        # ----------------------------------------------------

        try {
            $CurrentVersionObject = [version]$CurrentVersion
            $RemoteVersionObject = [version]$RemoteVersion
        }
        catch {
            throw "Formato de version invalido."
        }

        if ($RemoteVersionObject -eq $CurrentVersionObject) {

            Write-Host "dmark ya esta actualizado." -ForegroundColor Green
            Write-Host ""

            Remove-Item $TempFile -Force -ErrorAction SilentlyContinue
            return
        }

        if ($RemoteVersionObject -lt $CurrentVersionObject) {

            Write-Host "La version instalada es mas reciente que la publicada." `
                -ForegroundColor Yellow

            Write-Host ""
            Write-Host "Instalada : $CurrentVersion"
            Write-Host "Remota    : $RemoteVersion"
            Write-Host ""

            Remove-Item $TempFile -Force -ErrorAction SilentlyContinue
            return
        }

        # ----------------------------------------------------
        # Validaciones de seguridad
        # ----------------------------------------------------

        if ($RemoteContent -notmatch "function dmark") {
            throw "El archivo descargado no parece ser una version valida de dmark."
        }

        if ($RemoteContent -notmatch "Set-Alias dm dmark") {
            throw "El archivo descargado no contiene el alias dm."
        }

        # ----------------------------------------------------
        # Determinar instalacion
        # ----------------------------------------------------

        $InstalledFile = Join-Path $HOME ".dmark\bin\dmark.ps1"

        if (-not (Test-Path $InstalledFile)) {
            throw "No se encontro la instalacion de dmark en $InstalledFile"
        }

        # ----------------------------------------------------
        # Backup
        # ----------------------------------------------------

        $BackupFile = "$InstalledFile.bak"

        Copy-Item `
            -Path $InstalledFile `
            -Destination $BackupFile `
            -Force

        # ----------------------------------------------------
        # Instalar nueva version
        # ----------------------------------------------------

        Write-Host "Actualizando..."

        try {

            Copy-Item `
                -Path $TempFile `
                -Destination $InstalledFile `
                -Force

        }
        catch {

            Write-Host "Error instalando la actualizacion." -ForegroundColor Red
            Write-Host "Restaurando version anterior..."

            Copy-Item `
                -Path $BackupFile `
                -Destination $InstalledFile `
                -Force

            throw
        }

        # ----------------------------------------------------
        # Limpiar archivos
        # ----------------------------------------------------

        Remove-Item $TempFile -Force -ErrorAction SilentlyContinue
        Remove-Item $BackupFile -Force -ErrorAction SilentlyContinue

        # ----------------------------------------------------
        # Recargar
        # ----------------------------------------------------

        . $InstalledFile

        Write-Host ""
        Write-Host "dmark actualizado correctamente." -ForegroundColor Green
        Write-Host ""
        Write-Host "  $CurrentVersion -> $RemoteVersion"
        Write-Host ""
    }
    catch {

        Write-Host ""
        Write-Host "No se pudo actualizar dmark." -ForegroundColor Red
        Write-Host ""
        Write-Host "Detalle:"
        Write-Host "  $($_.Exception.Message)"
        Write-Host ""

        if (Test-Path $TempFile) {
            Remove-Item $TempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function dmark {

    param(
        [Parameter(Position = 0)]
        [string]$Command,

        [Parameter(Position = 1)]
        [string]$Argument1,

        [Parameter(Position = 2)]
        [string]$Argument2
    )

    Initialize-DMark

    if ([string]::IsNullOrWhiteSpace($Command)) {
        Show-DMarkList
        return
    }

    switch ($Command.ToLower()) {

        "add" {
            Add-DMark $Argument1 $Argument2
            return
        }

        "update" {
            Update-DMark
        }

        "rm" {
            Remove-DMark $Argument1
            return
        }

        "remove" {
            Remove-DMark $Argument1
            return
        }

        "rename" {
            Rename-DMark $Argument1 $Argument2
            return
        }

        "path" {

            $marks = Get-DMarkData

            if ($marks.ContainsKey($Argument1)) {
                Write-Host $marks[$Argument1]
            }
            else {
                Write-Host "No existe '$Argument1'." -ForegroundColor Yellow
            }

            return
        }

        "open" {

            $marks = Get-DMarkData

            if ($marks.ContainsKey($Argument1)) {
                Start-Process explorer.exe $marks[$Argument1]
            }
            else {
                Write-Host "No existe '$Argument1'." -ForegroundColor Yellow
            }

            return
        }

        "--help" {
            Show-DMarkHelp
            return
        }

        "-h" {
            Show-DMarkHelp
            return
        }

        "--version" {
            Write-Host "dmark $script:DMarkVersion"
            return
        }

        default {

            $marks = Get-DMarkData

            if (-not $marks.ContainsKey($Command)) {
                Write-Host "No existe el marcador '$Command'." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Ejecuta 'dm' para ver los disponibles."
                return
            }

            $destination = $marks[$Command]

            if (-not (Test-Path $destination)) {
                Write-Host "La ruta registrada ya no existe:" -ForegroundColor Red
                Write-Host "  $destination"
                return
            }

            Set-Location $destination
        }
    }
}

Set-Alias dm dmark
