---
name: debian-testing-dev-runtimes
description: >-
  Use this skill when managing programming languages and developer runtimes with Mise (Node.js, Rust, Go, Java, .NET), scaffolding isolated Python environments with uv (PEP 668 compliant), or executing build/setup tasks with the Justfile on Debian Testing.
---

# Development Runtimes & Tooling Skill (Mise, uv, Just)

Esta skill proporciona las pautas y flujos de trabajo recomendados para la gestión de lenguajes de programación, entornos virtuales y automatización de tareas en Debian Testing.

---

## 1. Filosofía de Entornos Aislados (PEP 668 en Debian)

Debian Testing protege el intérprete de Python del sistema contra sobreescrituras accidentales mediante el archivo marcador `/usr/lib/python3.*/EXTERNALLY-MANAGED` (**PEP 668**).

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
- **Bash**: `~/.bashrc.d/mise.sh` activa los shims y autocompletado.
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
> En `Bash.Setup/environment.sh` está configurada la variable `UV_LINK_MODE=copy` para garantizar compatibilidad total con particiones ext4 y sistemas de archivos montados en red/contenedores.

---

## 4. Otros Runtimes y Ecosistemas en el Repositorio

- **Node.js**:
  - Administrado vía Mise (`mise use -g node@lts`).
  - Gestores de paquetes alternativos disponibles vía Corepack: `corepack enable pnpm` o `corepack enable yarn`.
- **Rust**:
  - Administrado por `rustup` en `~/.cargo/bin/`.
  - Componentes recomendados: `rust-analyzer`, `clippy`, `rustfmt`.
- **Java**:
  - OpenJDK 21 LTS (`default-jdk` de Debian) integrado para desarrollo y compatibilidad con certificados digitales (AutoFirma / DNIe).
- **.NET**:
  - .NET SDK LTS con `DOTNET_ROOT` configurado para compatibilidad con CLI y herramientas de desarrollo.

---

## 5. Automatización de Tareas con `Just` ([justfile](file:///home/caballero/Workspace/Repositorios/Linux/KDEDebianTesting/justfile))

El archivo [justfile](file:///home/caballero/Workspace/Repositorios/Linux/KDEDebianTesting/justfile) en la raíz del repositorio orquesta el aprovisionamiento y mantenimiento de todo el equipo:

```bash
# Listar todas las recetas y tareas disponibles en el repositorio
just --list

# Despliegues por perfil de hardware:
just setup-laptop-amd      # Portátil AMD Ryzen (entorno completo con Podman y Virtualización)
just setup-media-desktop   # Centro multimedia Intel (sin virtualización ni batería)

# Comprobaciones de estado individuales:
just laptop                # Optimización de energía, touchpad y Bluetooth para portátil
just virtualization        # Ejecuta Virtualizacion/virtualization.sh
just fingerprint-status    # Diagnóstico de autenticación biométrica por huella
just printer-status        # Diagnóstico de impresora HP y CUPS
```
