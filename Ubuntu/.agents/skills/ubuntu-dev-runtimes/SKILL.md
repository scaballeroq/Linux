---
name: ubuntu-dev-runtimes
description: >-
  Use this skill when managing programming languages and developer runtimes with Mise (Node.js, Rust, Go, Java, .NET), scaffolding isolated Python environments with uv (PEP 668 compliant), or executing build/setup tasks with the Justfile on Ubuntu Workstation.
---

# Development Runtimes & Tooling Skill (Mise, uv, Just) - Ubuntu Workstation

Esta skill proporciona las pautas y flujos de trabajo recomendados para la gestión de lenguajes de programación, entornos virtuales y automatización de tareas en Ubuntu Workstation (GNOME Shell 50 Wayland).

---

## 1. Filosofía de Entornos Aislados (PEP 668 en Ubuntu)

Ubuntu protege el intérprete de Python del sistema contra sobreescrituras accidentales mediante el archivo marcador `/usr/lib/python3.*/EXTERNALLY-MANAGED` (**PEP 668**).

### Principio Fundamental:
- **NUNCA** utilices `sudo pip install` ni `pip install` globalmente contra `/usr/bin/python3`.
- Todo desarrollo en Python se realiza dentro de entornos virtuales creados y gestionados por **`uv`**.
- La gestión de versiones de herramientas y lenguajes (Node.js, Rust, Go, Java, .NET) se realiza a través de **Mise** (`~/.local/bin/mise`).

---

## 2. Gestor de Versiones de Lenguajes: Mise

Mise reemplaza a asdf, nvm, rbenv y similares con un binario ultrarrápido en Rust instalado en `~/.local/bin/mise`.

### Comandos habituales:
```bash
# Diagnóstico y estado de Mise
mise doctor

# Listar lenguajes y versiones instaladas
mise ls

# Instalar y fijar una versión global o local de un lenguaje:
mise use -g node@lts        # Node.js LTS global
mise use python@latest      # Python última versión en el directorio actual (.tool-versions o mise.toml)

# Ejecutar un comando con un runtime específico sin activarlo permanentemente
mise exec node@22 -- node -v

# Actualizar todas las herramientas gestionadas por Mise
mise upgrade
```

### Integración en el entorno del usuario:
- **Bash / Zsh**: `Bash.Setup/environment.sh` activa los shims y autocompletado mediante `eval "$(mise activate bash --shims)"`.
- **Systemd User**: `~/.config/environment.d/10-mise.conf` asegura que las variables de entorno de Mise estén disponibles para lanzadores gráficos de GNOME Shell.

---

## 3. Entornos Python Ultrarrápidos con `uv`

`uv` (desarrollado por Astral) gestiona paquetes y entornos virtuales de Python con velocidades entre 10x y 100x respecto a `pip`:

```bash
# Crear un entorno virtual aislado en el proyecto (.venv)
uv venv
source .venv/bin/activate

# Instalar dependencias respetando el bloqueo de versiones
uv pip install fastapi uvicorn pydantic

# Ejecutar comandos dentro del entorno sin activarlo explícitamente
uv run python app.py

# Crear un nuevo proyecto Python completamente configurado desde la receta del Justfile
just python-uv
```

---

## 4. Orquestación y Automatización con Just

El repositorio utiliza **`just`** (`justfile`) como interfaz centralizada de ejecución.

### Recetas de lenguajes y herramientas:
```bash
# Instalar todo el conjunto de lenguajes de desarrollo
just languages

# Gestión individual de herramientas
just mise            # Instalar/actualizar Mise
just mise-status     # Diagnóstico de Mise y SDKs
just node            # Node.js LTS + Corepack (pnpm/yarn)
just python          # Python nativo de Ubuntu + uv
just java            # OpenJDK 21 LTS + Maven + Gradle
just rust            # Rust Stable toolchain
just dotnet          # .NET SDK
just angular         # Angular CLI
```
