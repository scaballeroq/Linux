---
name: fedora-dev-runtimes
description: Gestión de lenguajes de programación y runtimes con Mise (Node.js, Rust, Go, Java, .NET, Angular), entornos aislados de Python con uv respetando PEP 668 en Fedora 45 Workstation con GNOME 51, orquestación mediante Justfile y configuración de IDEs (Google Antigravity, OpenCode).
---

# Entornos de Desarrollo, Lenguajes y Runtimes (Mise, uv, Just) - Fedora 45 Workstation

Esta skill define las pautas, herramientas y flujos de trabajo estándar para la gestión de lenguajes de programación, entornos virtuales desacoplados y automatización de compilaciones en **Fedora 45 Workstation (GNOME Shell 51 Wayland)**.

---

## 1. Filosofía de Aislamiento y Cumplimiento de PEP 668

Fedora 45 protege la integridad del sistema operativo y de los módulos internos de GNOME Shell 51 y DNF5 contra modificaciones involuntarias mediante la directiva **PEP 668** (`/usr/lib/python3.*/EXTERNALLY-MANAGED`).

### Principios Fundamentales:
- **NUNCA** utilices `sudo pip install` ni `pip install` globalmente contra `/usr/bin/python3`.
- Todo desarrollo en Python se realiza dentro de entornos virtuales creados y gestionados por **`uv`**.
- La gestión de versiones de herramientas y lenguajes polyglot (Node.js, Rust, Java, .NET, Go) se realiza a través de **Mise** (`~/.local/bin/mise`).

---

## 2. Gestor Políglota de Versiones: Mise

Mise gestiona runtimes y variables de entorno de forma ultrarrápida mediante su binario en Rust instalado en `~/.local/bin/mise`.

### 2.1. Comandos Principales de Mise:
```bash
# Diagnóstico del entorno Mise
mise doctor

# Listar lenguajes y versiones instaladas
mise ls

# Fijar versiones globales de lenguajes:
mise use -g node@lts
mise use -g java@openjdk-21

# Ejecutar comandos puntuales bajo un runtime específico:
mise exec node@22 -- node -v

# Actualizar todos los plugins y SDKs gestionados por Mise:
mise upgrade
```

### 2.2. Integración en el Entorno de Usuario:
- **Bash / Zsh**: Las configuraciones en `Bash.Setup/environment.sh` y `Setup/zsh-setup.sh` inyectan los shims y autocompletado en el PATH (`eval "$(mise activate bash --shims)"`).
- **Systemd User**: Asegura que las variables de entorno de desarrollo estén sincronizadas con los lanzadores de GNOME Shell 51.

---

## 3. Entornos Python de Alto Rendimiento con `uv`

`uv` (desarrollado por Astral en Rust) reemplaza y acelera los flujos tradicionales de `pip`, `venv` y `poetry`:

```bash
# Crear un entorno virtual aislado en el proyecto (.venv)
uv venv
source .venv/bin/activate

# Instalar dependencias respetando el bloqueo de versiones:
uv pip install fastapi uvicorn pydantic

# Ejecutar scripts o herramientas aisladas directamente:
uv run python main.py

# Herramientas CLI aisladas sin instalar en el sistema:
uvx ruff check .
```

---

## 4. Herramientas de Desarrollo e IDEs

El repositorio integra scripts modulares para aprovisionar las herramientas de control de versiones y entornos de desarrollo:

### 4.1. Git, LazyGit y GitHub CLI:
```bash
# Diagnóstico de Git, Delta y Lazygit
./IDE/git.sh --status
just git-status

# Configuración interactiva o despliegue
./IDE/git.sh
just git
```

### 4.2. Suite Antigravity y OpenCode:
```bash
# Diagnóstico de Antigravity Desktop, CLI e IDE Engine
./IDE/antigravity.sh --status
./IDE/antigravity-cli.sh --status
./IDE/antigravity-ide.sh --status
./IDE/opencode.sh --status
just ide-status

# Instalación y actualización de la suite
just ide
```

---

## 5. Recetas Justfile para Lenguajes y Runtimes

```bash
# Instalación del conjunto completo de lenguajes:
just languages

# Gestión individual de runtimes:
just mise          # Instala y actualiza Mise
just python        # Configura Python con uv y shims
just node          # Configura Node.js LTS y gestores de paquetes (pnpm/yarn)
just rust          # Instala Rustup toolchain (stable)
just java          # Instala OpenJDK 21 LTS y Maven
just dotnet        # Configura Microsoft .NET SDK
just angular       # Instala Angular CLI
```
