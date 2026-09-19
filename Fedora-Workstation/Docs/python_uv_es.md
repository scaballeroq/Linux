---
sidebar_position: 7
---

# Guía de Desarrollo en Python con uv en Fedora 44 Workstation

Esta guía describe el flujo de trabajo moderno y seguro para el desarrollo en **Python** en Fedora 44 Workstation, utilizando **`uv`** y entornos virtuales aislados sin interferir con las aplicaciones ni las herramientas del sistema operativo (**GNOME Tweaks / Retoques**, Pacman, extensiones, etc.).

---

## 🧠 Filosofía y Arquitectura del Entorno

En distribuciones rolling-release como **Arch Linux** y **Fedora 44 Workstation**, muchas herramientas críticas del sistema operativo (como *Retoques de GNOME*, *Lutris*, scripts de empaquetado y utilidades del sistema) dependen de **`/usr/bin/python3`** y sus librerías empaquetadas por Pacman (`python-gobject`, `libadwaita`, etc.).

> [!CAUTION]
> **Nunca registres una versión de Python global en gestores como Mise (`mise use --global python@...`)**.
> Esto genera ejecutables simulados (*shims*) en el `PATH` que interceptan `#!/usr/bin/env python3`, provocando fallos de `ModuleNotFoundError: No module named 'gi'` en herramientas como **Retoques**.

### Estructura de aislamiento recomendada:
* **Sistema operativo:** Gestionado exclusivamente por Pacman con `/usr/bin/python3`.
* **Proyectos y desarrollo:** Aislados con **`uv`** (o con **Mise** a nivel local de proyecto), manteniendo cada proyecto con su propia versión y dependencias sin tocar el sistema.

---

## 🚀 Creación Rápida de Proyectos con `py-project`

Para facilitar y agilizar la creación de proyectos aislados, dispones de la utilidad **`py-project`** (enlazada en `~/.local/bin/py-project` a partir de `ProgrammingLanguages/python-uv-init.sh`).

### 1. Modo Interactivo (Asistente guiado)
Ejecuta simplemente:
```bash
py-project
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
py-project mi-app 3.12 basic

# Proyecto FastAPI con Python 3.12
py-project mi-api 3.12 fastapi

# Herramienta de terminal (CLI) con Python 3.13
py-project mi-cli 3.13 cli

# Entorno de análisis de datos con Python 3.12
py-project mi-analisis 3.12 data
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
Si tus herramientas o tu IDE prefieren la activación manual tradicional del `.venv`:
```bash
source .venv/bin/activate

# El prompt mostrará (.venv)
python main.py
deactivate
```

---

## 🔄 Alternativa por Proyecto con Mise (`.mise.toml`)

Si prefieres que **Mise** gestione la versión del runtime para un proyecto específico en lugar de `uv`:

```bash
cd ~/Workspace/mi-proyecto

# Fijar la versión SOLO para este proyecto (sin flag --global)
mise use python@3.12
```

Esto generará un archivo `.mise.toml` en la raíz del proyecto:
```toml
[tools]
python = "3.12"
```

* **Dentro del proyecto**: La terminal usará Python 3.12.
* **Fuera del proyecto**: La terminal y el escritorio volverán inmediatamente al Python nativo de Fedora 44 Workstation.

---

## 📋 Resumen de Comandos Frecuentes de `uv`

| Comando | Descripción |
|---|---|
| `py-project <nombre> [ver] [tipo]` | Generador automatizado de proyectos con plantilla |
| `uv init --app <nombre>` | Inicializa un nuevo proyecto Python estándar |
| `uv venv --python 3.12` | Crea un entorno virtual `.venv` con versión específica |
| `uv run <script.py>` | Ejecuta un script dentro del entorno virtual automáticamente |
| `uv add <paquete>` | Añade e instala una dependencia en `pyproject.toml` |
| `uv add --dev <paquete>` | Añade una dependencia de desarrollo |
| `uv remove <paquete>` | Desinstala una dependencia |
| `uv pip install <paquete>` | Interfaz compatible con `pip install` dentro de `.venv` |
| `uv pip list` | Lista los paquetes instalados en el entorno virtual actual |
