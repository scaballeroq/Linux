---
sidebar_position: 7
---

# Guía de Desarrollo en Python con uv en Fedora 44

Esta guía describe el flujo de trabajo moderno, rápido y seguro para el desarrollo en **Python** en Fedora 44 (KDE Plasma 6), utilizando **`uv`** y entornos virtuales aislados sin interferir con las aplicaciones ni las herramientas del sistema operativo (DNF5, Firewalld, Libvirt, Cockpit, KDE Plasma, etc.).

---

## 🧠 Filosofía y Arquitectura del Entorno

En distribuciones como **Fedora Workstation**, muchas herramientas críticas del sistema operativo (como *DNF5*, *Firewalld*, scripts del sistema y extensiones de KDE) dependen de **`/usr/bin/python3`** y sus paquetes RPM (`python3-gobject`, `python3-dbus`, etc.).

> [!CAUTION]
> **Nunca registres una versión de Python global en gestores como Mise (`mise use --global python@...`)**.
> Esto genera ejecutables simulados (*shims*) en el `PATH` que interceptan `#!/usr/bin/env python3`, provocando fallos de `ModuleNotFoundError` en herramientas administrativas del sistema.

### Estructura de aislamiento recomendada:
* **Sistema operativo:** Gestionado exclusivamente por DNF5 con `/usr/bin/python3`.
* **Proyectos y desarrollo:** Aislados con **`uv`** (o con **Mise** a nivel local de proyecto), manteniendo cada proyecto con su propia versión y dependencias sin tocar el sistema.
* **Optimización Btrfs:** Configurado con `UV_LINK_MODE=copy` para garantizar compatibilidad con subvolúmenes y snapshots de Btrfs.

---

## 🚀 Creación Rápida de Proyectos con `python-uv-init.sh`

Para facilitar y agilizar la creación de proyectos aislados, dispones de la utilidad **`python-uv-init.sh`** (accesible mediante `just python-uv`).

### 1. Modo Interactivo (Asistente guiado)
Ejecuta simplemente:
```bash
just python-uv
```
El asistente te solicitará:
1. **Nombre del proyecto** (ej: `mi-api`, `scraper-datos`).
2. **Versión de Python deseada** (ej: `3.12`, `3.13` o Enter para `3.12` por defecto).
3. **Plantilla de inicio**:
   - `1) Básico / Minimalista`: Estructura estándar con `pyproject.toml` y `main.py`.
   - `2) FastAPI`: API REST lista con `fastapi`, `uvicorn[standard]` y `pydantic`.
   - `3) CLI Tool`: Herramienta de terminal con `typer` y formateo enriquecido con `rich`.
   - `4) Data Science`: Entorno con `numpy`, `pandas` y `matplotlib`.

### 2. Modo Directo por Línea de Comandos
Puedes inicializar proyectos directamente pasando los argumentos:

```bash
# Proyecto básico con Python 3.12
./ProgrammingLanguages/python-uv-init.sh mi-app 3.12 basic

# Proyecto FastAPI con Python 3.12
./ProgrammingLanguages/python-uv-init.sh mi-api 3.12 fastapi

# Herramienta de terminal (CLI) con Python 3.13
./ProgrammingLanguages/python-uv-init.sh mi-cli 3.13 cli

# Entorno de análisis de datos con Python 3.12
./ProgrammingLanguages/python-uv-init.sh mi-analisis 3.12 data
```

---

## 🛠️ Flujo de Trabajo en el Proyecto

Una vez creado el proyecto, el flujo con `uv` es limpio, instantáneo y no requiere pasos complejos:

### 1. Acceder al proyecto
```bash
cd mi-app
```

### 2. Ejecutar tu aplicación
`uv` gestiona el entorno virtual automáticamente sin necesidad de activarlo manualmente:
```bash
uv run main.py
```

### 3. Añadir o eliminar dependencias
Añadir librerías es hasta 10-100 veces más rápido que con pip tradicional:
```bash
# Instalar dependencias normales
uv add httpx requests pydantic

# Instalar dependencias de desarrollo
uv add --dev pytest ruff mypy

# Eliminar una dependencia
uv remove requests
```

### 4. Flujo clásico de activación (Opcional)
Si tus herramientas o tu editor (Kate, Neovim, Antigravity) prefieren la activación manual tradicional del `.venv`:
```bash
source .venv/bin/activate

# El prompt mostrará (.venv)
python main.py
deactivate
```
