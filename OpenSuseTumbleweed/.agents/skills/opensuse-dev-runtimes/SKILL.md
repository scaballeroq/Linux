---
name: opensuse-dev-runtimes
description: >-
  Use this skill when managing programming languages and developer runtimes with Mise (Node.js, Rust, Go, Java, .NET), scaffolding isolated Python environments with uv (PEP 668 compliant), or executing build/setup tasks with the Justfile on openSUSE Tumbleweed.
---

# Development Runtimes & Tooling Skill (Mise, uv, Just) - openSUSE Tumbleweed

Esta skill proporciona las pautas y flujos de trabajo recomendados para la gestión de lenguajes de programación, entornos virtuales y automatización de tareas en openSUSE Tumbleweed.

---

## 1. Filosofía de Entornos Aislados (PEP 668 en openSUSE)

openSUSE Tumbleweed protege el intérprete de Python del sistema contra sobreescrituras accidentales mediante el archivo marcador `/usr/lib/python3.*/EXTERNALLY-MANAGED` (**PEP 668**).

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
mise exec node@20 -- node -v

# Actualizar todas las herramientas gestionadas por Mise
mise upgrade
```

### Integración en el entorno del usuario:
- **Bash / Zsh**: `Bash.Setup/environment.sh` activa los shims y autocompletado mediante `eval "$(mise activate bash --shims)"`.
- **Systemd User**: `~/.config/environment.d/` asegura que las variables de entorno de Mise estén disponibles para lanzadores gráficos de KDE Plasma 6.

---

## 3. Entornos Python Ultrarrápidos con `uv`

`uv` (desarrollado por Astral) gestiona paquetes y entornos virtuales de Python con velocidades entre 10x y 100x respecto a `pip`:

```bash
# Crear un entorno virtual aislado en el proyecto (.venv)
uv venv
source .venv/bin/activate

# Añadir dependencias a máxima velocidad (respeta wheels cacheados)
uv pip install fastapi uvicorn rich

# Ejecutar scripts con dependencias en línea (sin necesidad de crear entorno previo)
uv run script.py

# Scaffolding automatizado de proyectos Python según el repositorio:
bash ProgrammingLanguages/python-uv-init.sh --help
```

> [!TIP]
> En `Bash.Setup/environment.sh` está configurada la variable `UV_LINK_MODE=copy` para garantizar compatibilidad total con Btrfs y sistemas de archivos montados en red/contenedores.

---

## 4. Otros Runtimes y Ecosistemas en el Repositorio

- **Node.js**:
  - Administrado vía Mise (`mise use -g node@lts`).
  - Gestores de paquetes alternativos disponibles vía Corepack: `corepack enable pnpm` o `corepack enable yarn`.
- **Rust**:
  - Administrado por `rustup` en `~/.cargo/bin/`.
  - Componentes recomendados: `rust-analyzer`, `clippy`, `rustfmt`.
- **Java**:
  - OpenJDK 21 LTS (`java-21-openjdk` y `java-21-openjdk-devel`) optimizado para 16 hilos en AMD Ryzen 7 PRO, soporte Wayland Swing/AWT y certificados digitales en `/var/lib/ca-certificates/java-cacerts`.
- **.NET**:
  - .NET SDK LTS con `DOTNET_ROOT` configurado para compatibilidad con CLI y herramientas de desarrollo.

---

## 5. Automatización de Tareas con `Just` ([justfile](file:///home/caballero/Workspace/Repositorios/Linux/OpenSuseTumbleweed/justfile))

El archivo [justfile](file:///home/caballero/Workspace/Repositorios/Linux/OpenSuseTumbleweed/justfile) en la raíz del repositorio orquesta el aprovisionamiento y mantenimiento de todo el equipo:

```bash
# Listar todas las recetas y tareas disponibles en el repositorio
just -f OpenSuseTumbleweed/justfile --list

# Despliegues por perfil de hardware:
just -f OpenSuseTumbleweed/justfile setup-laptop-amd      # Portátil AMD Ryzen (entorno completo con Podman y Virtualización)
just -f OpenSuseTumbleweed/justfile setup-media-desktop   # Centro multimedia Intel (sin virtualización ni batería)

# Comprobaciones de estado individuales:
just -f OpenSuseTumbleweed/justfile laptop                # Optimización de energía, touchpad y Bluetooth para portátil
just -f OpenSuseTumbleweed/justfile virtualization        # Ejecuta Virtualizacion/virtualization.sh
just -f OpenSuseTumbleweed/justfile kdeconnect-status     # Diagnóstico de integración KDE Connect y Firewalld
just -f OpenSuseTumbleweed/justfile fingerprint-status    # Diagnóstico de autenticación biométrica por huella
just -f OpenSuseTumbleweed/justfile printer-status        # Diagnóstico de impresora HP y CUPS
```
