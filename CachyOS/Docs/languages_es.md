---
sidebar_position: 6
---

# Gestión de Lenguajes de Programación en CachyOS

Esta guía detalla la instalación, control y mantenimiento de lenguajes de programación y sus herramientas de desarrollo en la carpeta `ProgrammingLanguages`.

La gestión de entornos se centraliza principalmente a través de **Mise** (runtimes y SDKs) y **Rustup** (entorno de Rust), complementados por un gestor de tareas automatizado mediante un `justfile` e integrados de forma nativa con **KDE Plasma 6 (Wayland / systemd user session)** y las terminales **Zsh** y **Bash**.

---

## 1. Gestor de Versiones Mise (`mise.sh`)

Mise es una herramienta de terminal moderna que reemplaza a herramientas como `asdf`, `nvm` o `pyenv`. Se encarga de descargar y configurar rápidamente entornos de desarrollo locales o globales.

1. **Instalación en CachyOS**:
   ```bash
   sudo pacman -S --needed --noconfirm mise
   ```

2. **Activación de Shell y Entorno Gráfico**:
   - Para KDE Plasma 6 y entornos gráficos: `~/.config/environment.d/10-mise.conf`
   - Para Zsh: `~/.zshrc` (`eval "$(mise activate zsh)"`) y autocompletados `_mise`
   - Para Bash: `~/.bashrc.d/mise.sh`

---

## 2. Runtimes de Lenguajes y SDKs (Últimas versiones LTS)

Una vez instalado Mise, se despliegan de forma global los siguientes lenguajes optimizados:

### Node.js (`nodejs.sh`)
* **Dependencias**: Comprueba e instala `base-devel`, `curl`, `python`, `gcc` y `make` vía Pacman, necesarios para compilar dependencias nativas de npm (`node-gyp`).
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
* **Optimizaciones**: Desactiva las preguntas interactivas de telemetría (`ng config -g cli.analytics false`) y genera autocompletados para Zsh y Bash.

### Python (`python.sh`)
* **Dependencias**: Comprueba e instala librerías del sistema para compilar extensiones nativas (`openssl`, `zlib`, `bzip2`, `readline`, `sqlite`, `libffi`, etc.).
* **Instalación**: Instala la última versión estable/LTS vía Mise y actualiza el gestor de paquetes pip:
  ```bash
  mise use --global python@latest
  mise exec python@latest -- python -m pip install --upgrade pip
  ```

### .NET SDK (`dotnet.sh`)
* **Dependencias**: Librerías nativas del sistema (`icu`, `krb5`, `openssl`, `zlib`, `libunwind`).
* **Instalación**: Instala y fija automáticamente la versión con soporte a largo plazo **LTS** de .NET:
  ```bash
  mise use --global dotnet@lts
  ```
* **KDE Plasma 6 & IDEs**: Configura `DOTNET_ROOT` en `~/.config/environment.d/10-dotnet.conf` para JetBrains Rider, VS Code y Antigravity, desactivando telemetría de compilación.

---

## 3. Entorno de Rust (`rust.sh`)

Rust se gestiona mediante su herramienta oficial estándar e independiente **Rustup** en su canal **Stable** (producción/LTS).

1. **Compiladores y Herramientas del Sistema**:
   ```bash
   sudo pacman -S --needed --noconfirm base-devel cmake openssl pkgconf curl git
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

4. **Integración con KDE Plasma 6 y Shells**:
   - KDE Plasma 6: `~/.config/environment.d/10-rust.conf`
   - Bash & Zsh: `~/.bashrc.d/rust.sh` y `~/.zshrc.d/rust.zsh`
   - Autocompletados: `_cargo` y `_rustup` para Zsh y Bash.

5. **Instalador de Binarios Rápidos (`cargo-binstall`)**:
   Descarga e integra `cargo-binstall`, permitiendo descargar e instalar herramientas escritas en Rust directamente en binarios precompilados de sus repositorios de GitHub en lugar de compilarlas desde cero.

---

## 4. OpenJDK Java (`java.sh`)

Instalación de OpenJDK LTS para CachyOS vía Pacman:
* **Paquetes**: `jdk25-openjdk` / `jdk21-openjdk` (LTS) junto con `nss` y `pcsclite` (soporte para AutoFirma, DNIe y lectores de tarjetas inteligentes).
* **Gestión JVM**: Configuración del runtime activo con `archlinux-java`.
* **Integración KDE Plasma 6**: Configuración de `JAVA_HOME=/usr/lib/jvm/default` en `~/.config/environment.d/10-java.conf` para Android Studio, IntelliJ IDEA, Gradle y Maven.

---

## 5. Automatización de Tareas (`justfile`)

Se incluye un archivo de tareas `just` (`justfile`) para facilitar la instalación selectiva de los diferentes lenguajes con comandos rápidos:

```make
# Instala Mise
mise:
    ./mise.sh

# Instala Node.js LTS
node:
    ./nodejs.sh

# Instala Python
python:
    ./python.sh

# Instala Rust
rust:
    ./rust.sh

# Instala .NET SDK LTS
dotnet:
    ./dotnet.sh

# Instala Java OpenJDK LTS
java:
    ./java.sh

# Instala Angular CLI
angular:
    ./angular.sh
```

Puedes ejecutar cualquiera de estas tareas con el comando `just <tarea>` en la raíz de la carpeta `ProgrammingLanguages`.
