# dmark

**Directory Marks for PowerShell**

`dmark` es una herramienta ligera para guardar directorios con nombres cortos y navegar rápidamente entre ellos desde PowerShell.

En lugar de escribir rutas completas:

```powershell
cd C:\Users\usuario\Documents\Proyectos\MiAplicacion
```

puedes guardar la ubicación una sola vez:

```powershell
dm add proyecto
```

y posteriormente regresar desde cualquier directorio con:

```powershell
dm proyecto
```

---

## Características

- Marcadores persistentes de directorios.
- Navegación con comandos cortos.
- Alias `dm`.
- Autocompletado con `TAB`.
- Apertura de directorios en el Explorador de Windows.
- Consulta de rutas sin cambiar de directorio.
- Renombrado y eliminación de marcadores.
- Actualización mediante `dm update`.
- Instalación remota desde GitHub.
- Compatible con Windows PowerShell 5.1.
- Compatible con PowerShell 7+.
- Los mismos marcadores se comparten entre ambas versiones de PowerShell.
- No requiere modificar `PATH`.
- Los marcadores se conservan al actualizar o reinstalar.

---

# Instalación

## Instalación rápida

Ejecuta en PowerShell:

```powershell
irm https://raw.githubusercontent.com/FrEaKAlL/dmark/main/install.ps1 | iex
```

El instalador:

1. Crea el directorio `~\.dmark`.
2. Descarga `dmark.ps1`.
3. Instala la herramienta en `~\.dmark\bin`.
4. Configura Windows PowerShell 5.1.
5. Configura PowerShell 7+.
6. Conserva los marcadores existentes en caso de reinstalación.

Después de la instalación puedes ejecutar:

```powershell
dm --version
```

---

## Instalación desde el repositorio

Para desarrollo o para trabajar directamente con el código fuente:

```powershell
git clone https://github.com/FrEaKAlL/dmark.git
cd dmark
.\install.ps1
```

Cuando el instalador detecta `src\dmark.ps1` utiliza automáticamente el archivo local en lugar de descargarlo.

---

# Uso rápido

Guardar el directorio actual:

```powershell
dm add proyecto
```

Ir al directorio:

```powershell
dm proyecto
```

Guardar una ruta específica:

```powershell
dm add descargas C:\Users\usuario\Downloads
```

Ahora puedes ejecutar:

```powershell
dm descargas
```

desde cualquier ubicación.

---

# Comandos

| Comando | Descripción |
|---|---|
| `dm` | Lista todos los marcadores |
| `dm <nombre>` | Navega al marcador |
| `dm add <nombre>` | Guarda el directorio actual |
| `dm add <nombre> <ruta>` | Guarda una ruta específica |
| `dm rm <nombre>` | Elimina un marcador |
| `dm remove <nombre>` | Elimina un marcador |
| `dm rename <actual> <nuevo>` | Renombra un marcador |
| `dm path <nombre>` | Muestra la ruta del marcador |
| `dm open <nombre>` | Abre el directorio en el Explorador |
| `dm update` | Busca e instala una nueva versión |
| `dm --version` | Muestra la versión instalada |
| `dm --help` | Muestra la ayuda |

También puede utilizarse el nombre completo:

```powershell
dmark
dmark proyecto
dmark --help
```

---

# Ejemplos

## Guardar directorios

```powershell
cd C:\Proyectos\Api
dm add api

cd C:\Proyectos\Frontend
dm add frontend
```

Lista los marcadores:

```powershell
dm
```

Ejemplo:

```text
api       C:\Proyectos\Api
frontend  C:\Proyectos\Frontend
```

---

## Navegar

Desde cualquier ubicación:

```powershell
dm api
```

dmark cambia el directorio de la sesión actual a:

```text
C:\Proyectos\Api
```

---

## Consultar una ruta

```powershell
dm path frontend
```

Resultado:

```text
C:\Proyectos\Frontend
```

Esto no cambia el directorio actual.

---

## Abrir en el Explorador

```powershell
dm open frontend
```

---

## Renombrar

```powershell
dm rename frontend web
```

Ahora puedes utilizar:

```powershell
dm web
```

---

## Eliminar

```powershell
dm rm web
```

También:

```powershell
dm remove web
```

---

# Autocompletado

dmark incluye autocompletado mediante `TAB`.

Por ejemplo, si existe:

```text
proyectos
```

puedes escribir:

```text
dm pro<TAB>
```

y PowerShell completará:

```text
dm proyectos
```

También funciona con subcomandos:

```text
dm op<TAB>
```

resultado:

```text
dm open
```

y con marcadores utilizados por un subcomando:

```text
dm open pro<TAB>
dm path pro<TAB>
dm rm pro<TAB>
```

El autocompletado funciona tanto con:

```text
dm
```

como con:

```text
dmark
```

---

# Actualización

dmark puede actualizarse directamente desde GitHub.

Ejecuta:

```powershell
dm update
```

La herramienta:

1. Consulta la versión publicada.
2. Compara la versión instalada.
3. Descarga el nuevo `dmark.ps1`.
4. Valida el archivo descargado.
5. Crea temporalmente una copia de seguridad.
6. Reemplaza la versión instalada.
7. Recarga dmark en la sesión.

Los marcadores no se eliminan durante una actualización.

Puedes consultar la versión instalada con:

```powershell
dm --version
```

---

# Almacenamiento

dmark utiliza:

```text
~\.dmark\
├── bin\
│   └── dmark.ps1
└── marks.json
```

El programa se almacena en:

```text
~\.dmark\bin\dmark.ps1
```

Los marcadores se almacenan por separado en:

```text
~\.dmark\marks.json
```

Esta separación permite actualizar o reinstalar dmark sin perder los directorios guardados.

---

# PowerShell 5.1 y PowerShell 7

En Windows, el instalador configura los perfiles de:

```text
Windows PowerShell 5.1
PowerShell 7+
```

Ambos cargan la misma instalación:

```text
~\.dmark\bin\dmark.ps1
```

y utilizan el mismo archivo:

```text
~\.dmark\marks.json
```

Por ejemplo, puedes crear un marcador desde PowerShell 7:

```powershell
dm add proyectos C:\Proyectos
```

y utilizarlo posteriormente desde Windows PowerShell 5.1:

```powershell
dm proyectos
```

---

# Desinstalación

Desde el repositorio ejecuta:

```powershell
.\uninstall.ps1
```

Por defecto se elimina dmark y su configuración de los perfiles de PowerShell, pero se conservan los marcadores:

```text
~\.dmark\marks.json
```

Esto permite reinstalar posteriormente la herramienta sin perderlos.

Para eliminar también los marcadores:

```powershell
.\uninstall.ps1 -Purge
```

> `-Purge` elimina permanentemente los marcadores guardados.

---

# Estructura del repositorio

```text
dmark/
├── src/
│   └── dmark.ps1
├── install.ps1
├── uninstall.ps1
├── README.md
├── LICENSE
└── .gitignore
```

`src\dmark.ps1` contiene la funcionalidad principal.

`install.ps1` permite instalación local o remota.

`uninstall.ps1` elimina la instalación y opcionalmente los datos.

---

# Filosofía

dmark busca resolver un problema pequeño con una herramienta pequeña.

La idea es mantener:

- comandos fáciles de recordar;
- instalación sencilla;
- bajo consumo de recursos;
- cero servicios ejecutándose en segundo plano;
- datos almacenados localmente;
- pocas dependencias;
- compatibilidad entre versiones de PowerShell.

dmark no intenta reemplazar un explorador de archivos ni un gestor de proyectos. Su función es simplemente permitir guardar una ruta y regresar a ella rápidamente.

---

# Roadmap

Implementado:

- [x] Marcadores persistentes
- [x] Navegación mediante `dm`
- [x] Agregar y eliminar marcadores
- [x] Renombrar marcadores
- [x] Abrir directorios en Explorer
- [x] Consultar rutas
- [x] Instalador
- [x] Desinstalador
- [x] `dm update`
- [x] Windows PowerShell 5.1
- [x] PowerShell 7+
- [x] Autocompletado con `TAB`
- [x] Instalación remota

Planeado:

- [ ] `dm doctor`
- [ ] Exportación e importación de marcadores
- [ ] Backup de marcadores
- [ ] Mejoras en diagnóstico de instalación
- [ ] Evaluar soporte para otros shells y plataformas

---

# Licencia

Este proyecto se distribuye bajo la licencia MIT.

Consulta [LICENSE](LICENSE) para más información.
