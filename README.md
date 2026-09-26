# dmark

**Directory Marks for PowerShell**

`dmark` es una herramienta ligera para PowerShell que permite guardar directorios frecuentes con un nombre corto y navegar hacia ellos rápidamente desde cualquier ubicación de la terminal.

En lugar de escribir:

```powershell
cd C:\ProyectosPersonales\Aplicaciones\MiProyecto
```

puedes registrar la ruta una sola vez:

```powershell
dm add miproyecto C:\ProyectosPersonales\Aplicaciones\MiProyecto
```

y posteriormente navegar hacia ella simplemente con:

```powershell
dm miproyecto
```

## Características

* Navegación rápida entre directorios.
* Marcadores persistentes.
* Alias corto `dm`.
* Registro del directorio actual.
* Registro manual de cualquier ruta.
* Listado de marcadores.
* Eliminación y renombrado de marcadores.
* Apertura de directorios en Windows Explorer.
* Instalación automática en el perfil de PowerShell.
* Sin dependencias externas.
* No requiere Node.js, Python ni aplicaciones adicionales.
* Los marcadores se mantienen separados de los archivos de la aplicación.

## Requisitos

Actualmente `dmark` está diseñado para:

* Windows
* PowerShell
* Windows PowerShell o terminales que utilicen PowerShell como shell

También puede utilizarse desde terminales como Warp siempre que la sesión activa sea PowerShell.

## Instalación

Clona el repositorio:

```powershell
git clone https://github.com/FrEaKAlL/dmark.git
```

Entra al directorio:

```powershell
cd dmark
```

Ejecuta el instalador:

```powershell
.\install.ps1
```

El instalador copiará `dmark` a:

```text
~\.dmark\bin\dmark.ps1
```

y agregará automáticamente la carga de `dmark` al perfil de PowerShell.

Después de la instalación puedes utilizar inmediatamente:

```powershell
dm
```

También puedes cerrar la terminal, abrir una nueva sesión de PowerShell y ejecutar:

```powershell
dm --version
```

## Uso rápido

### Registrar el directorio actual

Ubícate en la carpeta que quieres guardar:

```powershell
cd C:\ProyectosPersonales
```

y ejecuta:

```powershell
dm add personales
```

A partir de ese momento puedes regresar desde cualquier ubicación con:

```powershell
dm personales
```

### Registrar una ruta directamente

No es necesario estar dentro del directorio:

```powershell
dm add logs D:\Logs
```

Después:

```powershell
dm logs
```

te llevará directamente a:

```text
D:\Logs
```

## Comandos

### Listar marcadores

```powershell
dm
```

Ejemplo:

```text
dmark - Directorios registrados

  logs                 D:\Logs
  personales           C:\ProyectosPersonales
```

### Agregar el directorio actual

```powershell
dm add <nombre>
```

Ejemplo:

```powershell
dm add logs
```

### Agregar una ruta específica

```powershell
dm add <nombre> <ruta>
```

Ejemplo:

```powershell
dm add personal C:\ProyectosPersonales
```

### Navegar a un directorio

```powershell
dm <nombre>
```

Ejemplo:

```powershell
dm logs
```

### Mostrar la ruta

```powershell
dm path <nombre>
```

Ejemplo:

```powershell
dm path logs
```

### Abrir en Windows Explorer

```powershell
dm open <nombre>
```

Ejemplo:

```powershell
dm open logs
```

### Renombrar un marcador

```powershell
dm rename <actual> <nuevo>
```

Ejemplo:

```powershell
dm rename personal proyectos
```

### Eliminar un marcador

Puedes utilizar:

```powershell
dm rm <nombre>
```

o:

```powershell
dm remove <nombre>
```

Ejemplo:

```powershell
dm rm logs
```

### Mostrar ayuda

```powershell
dm --help
```

También:

```powershell
dm -h
```

### Mostrar versión

```powershell
dm --version
```

## `dmark` y `dm`

El nombre principal de la herramienta es:

```powershell
dmark
```

Para facilitar su uso diario se proporciona el alias:

```powershell
dm
```

Por lo tanto:

```powershell
dmark logs
```


y:

```powershell
dm logs
```

son equivalentes.

## Almacenamiento de marcadores

Los directorios registrados se almacenan en:

```text
~\.dmark\marks.json
```

Por ejemplo:

```json
{
  "personales": "C:\\ProyectosPersonales",
  "logs": "D:\\Logs"
}
```

Este archivo es independiente de los archivos de instalación de `dmark`.

La estructura local es:

```text
~\.dmark\
├── bin\
│   └── dmark.ps1
│
└── marks.json
```

Esto permite actualizar o reinstalar `dmark` sin eliminar los directorios registrados.

## Estructura del proyecto

```text
dmark\
├── src\
│   └── dmark.ps1
│
├── install.ps1
├── README.md
└── .gitignore
```

### `src/dmark.ps1`

Contiene la funcionalidad principal:

* administración de marcadores;
* navegación;
* listado;
* apertura de directorios;
* ayuda;
* alias `dm`.

### `install.ps1`

Se encarga de:

* crear `~\.dmark`;
* crear `~\.dmark\bin`;
* instalar `dmark.ps1`;
* configurar `$PROFILE`;
* cargar `dmark` en PowerShell.

## Configuración de PowerShell

Durante la instalación se agrega un bloque administrado por `dmark` al `$PROFILE`:

```powershell
# >>> dmark >>>
# Carga dmark - Directory Marks

$DMarkScript = Join-Path $HOME ".dmark\bin\dmark.ps1"

if (Test-Path $DMarkScript) {
    . $DMarkScript
}

# <<< dmark <<<
```

El instalador identifica este bloque para evitar duplicarlo durante una reinstalación.

## Filosofía del proyecto

`dmark` busca mantenerse:

**Simple.** Un comando corto para llegar rápidamente a los directorios frecuentes.

**Ligero.** Implementado únicamente con PowerShell.

**Portable.** La configuración personal está separada del código de la herramienta.

**No limitado a proyectos.** Un marcador puede apuntar a cualquier directorio:

```powershell
dm add trabajo D:\Trabajo
dm add descargas C:\Users\Usuario\Downloads
dm add logs D:\Logs
dm add scripts C:\Scripts
```

## Roadmap

Entre las funcionalidades consideradas para próximas versiones se encuentran:

* actualización mediante `dm update`;
* desinstalador;
* autocompletado con `TAB`;
* instalación remota;
* mejoras en `dm doctor`;
* administración y respaldo de marcadores;
* soporte para nuevas plataformas/shells.

## Versión actual

```text
dmark 0.2.0
```

## Repositorio

GitHub:

```text
https://github.com/FrEaKAlL/dmark
```

## Licencia

La licencia del proyecto se definirá antes de la primera versión estable.

