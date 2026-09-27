# dmark - Directory Marks
# Version 0.1.0

$script:DMarkVersion = "0.5.0"
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

  dm doctor
      Diagnostica la instalacion y configuracion.

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

function Test-DMarkProfile {

    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfilePath
    )

    if (-not (Test-Path $ProfilePath)) {
        return $false
    }

    try {

        $Content = Get-Content `
            -Path $ProfilePath `
            -Raw `
            -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($Content)) {
            return $false
        }

        return (
            $Content -match '# >>> dmark >>>' -and
            $Content -match '\.dmark[\\/]bin[\\/]dmark\.ps1' -and
            $Content -match '# <<< dmark <<<'
        )

    }
    catch {
        return $false
    }
}

function Show-DMarkDoctor {

    Initialize-DMark

    $OkCount = 0
    $WarnCount = 0
    $ErrorCount = 0

    function Write-DoctorResult {

        param(
            [Parameter(Mandatory = $true)]
            [ValidateSet("OK", "WARN", "ERROR")]
            [string]$Status,

            [Parameter(Mandatory = $true)]
            [string]$Name,

            [string]$Value = ""
        )

        switch ($Status) {

            "OK" {
                Write-Host "[OK]   " -ForegroundColor Green -NoNewline
                $script:DoctorOkCount++
            }

            "WARN" {
                Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline
                $script:DoctorWarnCount++
            }

            "ERROR" {
                Write-Host "[ERROR]" -ForegroundColor Red -NoNewline
                Write-Host " " -NoNewline
                $script:DoctorErrorCount++
            }
        }

        Write-Host $Name -NoNewline

        if (-not [string]::IsNullOrWhiteSpace($Value)) {
            Write-Host "  $Value"
        }
        else {
            Write-Host ""
        }
    }


    $script:DoctorOkCount = 0
    $script:DoctorWarnCount = 0
    $script:DoctorErrorCount = 0


    Write-Host ""
    Write-Host "dmark doctor"
    Write-Host "------------"
    Write-Host ""


    # --------------------------------------------------------
    # Version
    # --------------------------------------------------------

    Write-DoctorResult `
        -Status "OK" `
        -Name "Version" `
        -Value $script:DMarkVersion


    # --------------------------------------------------------
    # PowerShell
    # --------------------------------------------------------

    $PowerShellVersion = $PSVersionTable.PSVersion.ToString()

    Write-DoctorResult `
        -Status "OK" `
        -Name "PowerShell" `
        -Value $PowerShellVersion


    # --------------------------------------------------------
    # Archivo instalado
    # --------------------------------------------------------

    $InstalledScript = Join-Path `
        $HOME `
        ".dmark\bin\dmark.ps1"

    if (Test-Path $InstalledScript) {

        Write-DoctorResult `
            -Status "OK" `
            -Name "Installation" `
            -Value $InstalledScript

    }
    else {

        Write-DoctorResult `
            -Status "ERROR" `
            -Name "Installation" `
            -Value "dmark.ps1 not found"
    }


    # --------------------------------------------------------
    # marks.json
    # --------------------------------------------------------

    if (Test-Path $script:DMarkFile) {

        try {

            $RawMarks = Get-Content `
                -Path $script:DMarkFile `
                -Raw `
                -ErrorAction Stop

            if ([string]::IsNullOrWhiteSpace($RawMarks)) {
                throw "Empty file"
            }

            $null = $RawMarks | ConvertFrom-Json

            Write-DoctorResult `
                -Status "OK" `
                -Name "marks.json" `
                -Value "Valid"

        }
        catch {

            Write-DoctorResult `
                -Status "ERROR" `
                -Name "marks.json" `
                -Value "Invalid JSON"
        }

    }
    else {

        Write-DoctorResult `
            -Status "WARN" `
            -Name "marks.json" `
            -Value "Not created yet"
    }


    # --------------------------------------------------------
    # Cantidad de marcadores
    # --------------------------------------------------------

    try {

        $Marks = Get-DMarkData

        Write-DoctorResult `
            -Status "OK" `
            -Name "Marks" `
            -Value $Marks.Count

    }
    catch {

        Write-DoctorResult `
            -Status "ERROR" `
            -Name "Marks" `
            -Value "Unable to read"
    }


    # --------------------------------------------------------
    # Profiles
    # --------------------------------------------------------

    try {

        $Documents = [Environment]::GetFolderPath("MyDocuments")

        $PS5Profile = Join-Path `
            $Documents `
            "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"

        $PS7Profile = Join-Path `
            $Documents `
            "PowerShell\Microsoft.PowerShell_profile.ps1"


        if (Test-DMarkProfile $PS5Profile) {

            Write-DoctorResult `
                -Status "OK" `
                -Name "PS 5.1 profile" `
                -Value "Configured"

        }
        else {

            Write-DoctorResult `
                -Status "WARN" `
                -Name "PS 5.1 profile" `
                -Value "Not configured"
        }


        if (Test-DMarkProfile $PS7Profile) {

            Write-DoctorResult `
                -Status "OK" `
                -Name "PS 7+ profile" `
                -Value "Configured"

        }
        else {

            Write-DoctorResult `
                -Status "WARN" `
                -Name "PS 7+ profile" `
                -Value "Not configured"
        }

    }
    catch {

        Write-DoctorResult `
            -Status "WARN" `
            -Name "PowerShell profiles" `
            -Value "Unable to validate"
    }


    # --------------------------------------------------------
    # Resumen
    # --------------------------------------------------------

    Write-Host ""
    Write-Host "Summary"
    Write-Host "-------"

    Write-Host "OK     : $script:DoctorOkCount" `
        -ForegroundColor Green

    Write-Host "Warnings: $script:DoctorWarnCount" `
        -ForegroundColor Yellow

    Write-Host "Errors  : $script:DoctorErrorCount" `
        -ForegroundColor Red

    Write-Host ""

    if (
        $script:DoctorWarnCount -eq 0 -and
        $script:DoctorErrorCount -eq 0
    ) {

        Write-Host "No problems found." `
            -ForegroundColor Green

    }
    elseif ($script:DoctorErrorCount -gt 0) {

        Write-Host `
            "dmark found one or more problems that require attention." `
            -ForegroundColor Red

    }
    else {

        Write-Host `
            "dmark is working, but some configuration warnings were found." `
            -ForegroundColor Yellow
    }

    Write-Host ""
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

        "doctor" {
            Show-DMarkDoctor
            return
        }

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

# ============================================================
# dmark - Autocompletado
# ============================================================

$script:DMarkCommands = @(
    "add",
    "rm",
    "remove",
    "rename",
    "path",
    "open",
    "update",
    "doctor",
    "--help",
    "--version"
)

function Get-DMarkCompletion {

    param(
        [string]$WordToComplete,
        $CommandAst
    )

    try {

        # Obtener los elementos escritos en el comando
        $Elements = @($CommandAst.CommandElements)

        # Quitamos "dm" / "dmark"
        $Arguments = @()

        if ($Elements.Count -gt 1) {
            $Arguments = @(
                $Elements |
                    Select-Object -Skip 1 |
                    ForEach-Object {
                        $_.Extent.Text.Trim("'`"")
                    }
            )
        }

        # ----------------------------------------------------
        # Primer argumento
        #
        # dm <TAB>
        # dm ya<TAB>
        #
        # Comandos + marcadores
        # ----------------------------------------------------

        if ($Arguments.Count -le 1) {

            $Results = @()

            $Results += $script:DMarkCommands

            $Marks = Get-DMarkData

            if ($Marks.Count -gt 0) {
                $Results += $Marks.Keys
            }

            $Results |
                Sort-Object -Unique |
                Where-Object {
                    $_ -like "$WordToComplete*"
                } |
                ForEach-Object {

                    [System.Management.Automation.CompletionResult]::new(
                        $_,
                        $_,
                        "ParameterValue",
                        $_
                    )
                }

            return
        }

        # ----------------------------------------------------
        # Segundo argumento
        #
        # Los siguientes comandos trabajan con
        # marcadores existentes.
        # ----------------------------------------------------

        $SubCommand = $Arguments[0].ToLower()

        if ($SubCommand -in @(
            "rm",
            "remove",
            "rename",
            "path",
            "open"
        )) {

            $Marks = Get-DMarkData

            $Marks.Keys |
                Sort-Object |
                Where-Object {
                    $_ -like "$WordToComplete*"
                } |
                ForEach-Object {

                    [System.Management.Automation.CompletionResult]::new(
                        $_,
                        $_,
                        "ParameterValue",
                        $Marks[$_]
                    )
                }

            return
        }

    }
    catch {
        # El autocompletado nunca debe impedir
        # el funcionamiento normal de PowerShell.
        return
    }
}


function Register-DMarkCompletion {

    $Completer = {

        param(
            $CommandName,
            $ParameterName,
            $WordToComplete,
            $CommandAst,
            $FakeBoundParameters
        )

        Get-DMarkCompletion `
            -WordToComplete $WordToComplete `
            -CommandAst $CommandAst
    }

    Register-ArgumentCompleter `
        -CommandName dmark `
        -ParameterName Command `
        -ScriptBlock $Completer

    Register-ArgumentCompleter `
        -CommandName dm `
        -ParameterName Command `
        -ScriptBlock $Completer
}


Register-DMarkCompletion
