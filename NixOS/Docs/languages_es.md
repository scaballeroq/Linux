---
sidebar_position: 6
---

# Gestión de Lenguajes de Programación en openSUSE Tumbleweed

Esta guía detalla la instalación, control y mantenimiento de lenguajes de programación y sus herramientas de desarrollo en la carpeta `ProgrammingLanguages`.

La gestión de entornos se centraliza principalmente a través de **Mise** (runtimes y SDKs) y **Rustup** (entorno de Rust), complementados por un gestor de tareas automatizado mediante un `justfile` e integrados de forma nativa con **KDE Plasma 6 (Wayland / systemd user session)** y las terminales **Bash** (predeterminada) y **Zsh** (compatible condicionalmente).

---

## 1. Gestor de Versiones Mise (`mise.sh`)

Mise es una herramienta de terminal moderna de alto rendimiento escrita en Rust que reemplaza a herramientas como `asdf`, `nvm` o `pyenv`. Se encarga de descargar y configurar rápidamente entornos de desarrollo locales o globales.

1. **Instalación y Repositorio Oficial RPM (Zypper)**:
   ```bash
   sudo rpm --import https://mise.jdx.dev/gpg-key.pub
   sudo zypper ar -f -c https://mise.jdx.dev/rpm mise
   sudo zypper --non-interactive install -y mise
   ```

2. **Activación de Shell y Entorno Gráfico**:
   - Para KDE Plasma y entornos gráficos: `~/.config/environment.d/10-mise.conf`
   - Para Bash (predeterminado): `~/.bashrc.d/mise.sh` y autocompletados de Bash
   - Para Zsh (compatible si existe `~/.zshrc`): `~/.zshrc.d/mise.zsh` (`eval "$(mise activate zsh)"`) y autocompletados `_mise`

---

## 2. Runtimes de Lenguajes y SDKs (Últimas versiones LTS)

Una vez instalado Mise, se despliegan de forma global los siguientes lenguajes optimizados:

### Node.js (`nodejs.sh`)
* **Dependencias**: Comprueba e instala herramientas de compilación (`devel_basis`, `gcc-c++`, `make`, `curl`, `python3`) vía Zypper, necesarios para compilar dependencias nativas de npm (`node-gyp`).
* **Instalación**: Instala y fija automáticamente la **última versión LTS activa** de Node.js:
  ```bash
  mise use --global node@lts
  ```
* **Corepack (pnpm / yarn)**: Se activa Corepack de forma desatendida (`COREPACK_ENABLE_DOWNLOAD_PROMPT=0`) para disponer de `pnpm` y `yarn` de forma nativa e inmediata:
  ```bash
  mise exec node@lts -- corepack enable
  mise reshim
  ```

### Angular CLI (`angular.sh`)
* **Instalación**: Se instala globalmente la última versión del CLI oficial utilizando npm manejado por Mise:
  ```bash
  mise use --global npm:@angular/cli@latest
  ```
* **Optimizaciones**: Desactiva las preguntas interactivas de telemetría (`ng config -g cli.analytics false`) y genera autocompletados para Bash (y Zsh si está disponible).

### Python & uv (`python.sh` & `python-uv-init.sh`)
* **Dependencias**: Asegura `python3`, `python3-pip`, `python3-devel` y cabeceras del sistema vía Zypper para máxima estabilidad del sistema.
* **Instalación**: Instala el gestor ultrarrápido **uv** vía Mise (`mise use --global uv@latest`) y mantiene el Python nativo del sistema protegido.
* **Generador de Proyectos**: Se incluye la utilidad `python-uv-init.sh` (`py-project`) para crear proyectos aislados con plantillas (FastAPI, CLI, Data Science).
* **Guía Completa**: Consulta [python_uv_es.md](file:///home/caballero/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Docs/python_uv_es.md) para ver instrucciones detalladas de flujo de trabajo.
* **KDE Plasma & Shells**: Genera `~/.config/environment.d/10-python.conf`, `~/.bashrc.d/python.sh` (y `~/.zshrc.d/python.zsh` si existe `~/.zshrc`) y autocompletados nativos para Bash y Zsh (`uv`, `uvx`, `pip`).

### .NET SDK (`dotnet.sh`)
* **Dependencias**: Librerías nativas del sistema (`libicu`, `libopenssl-devel`, `krb5-devel`, `zlib-devel`, `libunwind`).
* **Instalación**: Instala y fija automáticamente la versión con soporte a largo plazo **LTS** de .NET:
  ```bash
  mise use --global dotnet@lts
  ```
* **KDE Plasma & IDEs**: Configura `DOTNET_ROOT` en `~/.config/environment.d/10-dotnet.conf` para JetBrains Rider, VS Code y Antigravity, desactivando telemetría de compilación.

---

## 3. Entorno de Rust (`rust.sh`)

Rust se gestiona mediante su herramienta oficial estándar e independiente **Rustup** en su canal **Stable** (producción/LTS).

1. **Compiladores y Herramientas del Sistema**:
   ```bash
   sudo zypper --non-interactive install -y -t pattern devel_basis devel_C_C++
   sudo zypper --non-interactive install -y cmake libopenssl-devel pkg-config curl git lld clang-devel
   ```

2. **Instalador Rustup y Canal Stable**:
   Se descarga el script de instalación fijando el toolchain `stable`:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile default --no-modify-path
   ```

3. **Herramientas de Desarrollo para IDEs**:
   Instala `rust-analyzer`, `clippy`, `rustfmt` y `rust-src` para soporte total en VS Code, RustRover y Antigravity:
   ```bash
   rustup component add rust-src rust-analyzer clippy rustfmt
   ```

4. **Integración con KDE Plasma y Shells**:
   - KDE Plasma / Systemd: `~/.config/environment.d/10-rust.conf`
   - Bash & Zsh: `~/.bashrc.d/rust.sh` (y `~/.zshrc.d/rust.zsh` si existe `~/.zshrc`)
   - Autocompletados: `cargo` y `rustup` para Bash (y `_cargo` / `_rustup` para Zsh).

5. **Instalador de Binarios Rápidos (`cargo-binstall`)**:
   Descarga e integra `cargo-binstall`, permitiendo descargar e instalar herramientas escritas en Rust directamente en binarios precompilados de sus repositorios de GitHub en lugar de compilarlas desde cero.

---

## 4. OpenJDK Java (`java.sh`)

Instalación de OpenJDK LTS para openSUSE Tumbleweed vía Zypper:
* **Paquetes**: `java-21-openjdk`, `java-21-openjdk-devel` junto con `pcsc-lite`, `mozilla-nss-tools` y `maven` (soporte para AutoFirma, FNMT, DNIe y lectores de tarjetas inteligentes).
* **Gestión JVM**: Detección y configuración automática del entorno en `/usr/lib64/jvm/java-21-openjdk`.
* **Integración KDE Plasma**: Configuración de `JAVA_HOME` en `~/.config/environment.d/10-java.conf` para Android Studio, IntelliJ IDEA, Gradle y Maven.

---

## 5. Automatización de Tareas (`justfile`)

Se incluye un archivo de tareas `just` (`justfile`) para facilitar la instalación selectiva de los diferentes lenguajes con comandos rápidos:

```bash
# Instala Mise
just mise

# Instala Node.js LTS
just node

# Instala Python con UV
just python

# Inicializador de proyectos Python
just python-uv

# Instala Rust
just rust

# Instala .NET SDK LTS
just dotnet

# Instala Java OpenJDK LTS
just java

# Instala Angular CLI
just angular

# Instala todos los lenguajes
just languages
```
