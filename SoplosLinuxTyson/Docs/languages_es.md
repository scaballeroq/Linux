---
sidebar_position: 6
---

# Gestión de Lenguajes de Programación en Debian 13 (Testing / Trixie)

Esta guía detalla la instalación, control y mantenimiento de lenguajes de programación y sus herramientas de desarrollo en la carpeta `ProgrammingLanguages`.

La gestión de entornos se centraliza principalmente a través de **Mise** (runtimes y SDKs) y **Rustup** (entorno de Rust), complementados por un gestor de tareas automatizado mediante un `justfile`.

---

## 1. Gestor de Versiones Mise (`mise.sh`)

Mise es una herramienta de terminal moderna que reemplaza a herramientas como `asdf`, `nvm` o `pyenv`. Se encarga de descargar y configurar rápidamente entornos de desarrollo locales o globales.

1. **Instalación y Repositorio Oficial**:
   ```bash
   sudo apt update
   sudo apt install -y curl gpg
   sudo install -m 0755 -d /etc/apt/keyrings
   curl -fsSL https://mise.jdx.dev/gpg-key.pub | sudo gpg --dearmor --yes -o /etc/apt/keyrings/mise-archive-keyring.gpg
   sudo chmod 644 /etc/apt/keyrings/mise-archive-keyring.gpg
   echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list > /dev/null
   sudo apt update
   sudo apt install -y mise
   ```

2. **Activación Modular de Shell**:
   Se crea de manera modular la inicialización de Mise y la carga de shims en `~/.bashrc.d/mise.sh`:
   ```bash
   export PATH="$HOME/.local/share/mise/shims:$PATH"
   eval "$(mise activate bash)"
   ```

---

## 2. Runtimes de Lenguajes y SDKs

Una vez instalado Mise, se despliegan de forma global los siguientes lenguajes:

### Node.js, PNPM y Yarn (`nodejs.sh` y `angular.sh`)
* **Dependencias**: Instala `build-essential`, `python3`, `g++` y `make` vía APT, necesarios para compilar dependencias nativas de npm (`node-gyp`).
* **Instalación**: Configura la versión LTS 22 global y gestores modernos de paquetes (`pnpm`, `yarn`):
  ```bash
  mise use --global node@22
  mise use --global pnpm@latest yarn@latest
  mise reshim
  ```
* **Angular CLI**: Se instala globalmente el CLI oficial utilizando el backend npm integrado en Mise:
  ```bash
  mise use --global npm:@angular/cli@latest
  ```

### Python y UV (`python.sh`)
* **Dependencias**: Instala librerías del sistema para compilar extensiones de Python (`libssl-dev`, `zlib1g-dev`, `libreadline-dev`, `libncurses-dev`, `libffi-dev`, etc.).
* **Instalación**: Instala la rama estable 3.13, actualiza `pip`, `setuptools`, `wheel` e incorpora **`uv`** (el gestor ultrarrápido estándar de paquetes y entornos virtuales):
  ```bash
  mise use --global python@3.13
  mise exec python@3.13 -- python -m pip install --upgrade pip setuptools wheel
  mise use --global uv@latest
  mise reshim
  ```

### Go / Golang (`go.sh`)
* **Instalación**: Instala la última versión estable de Go vía Mise:
  ```bash
  mise use --global go@latest
  mise reshim
  ```
* **Variables de entorno**: Configura `GOPATH` y `GOBIN` (`$HOME/go/bin`) en `~/.bashrc.d/go.sh`.

### .NET SDK (`dotnet.sh`)
* **Dependencias**: Instala `libicu-dev`, `libssl-dev` y `zlib1g` vía APT (imprescindibles para soporte de internacionalización y SSL en Debian).
* **Instalación**: Instala el SDK de .NET mediante Mise:
  ```bash
  mise use --global dotnet@latest
  mise reshim
  ```

### Gemini CLI (`gemini.sh`)
* **Instalación**: Herramienta de interfaz de comandos de Google Gemini:
  ```bash
  mise use --global npm:@google/gemini-cli@latest
  mise reshim
  ```

---

## 3. Entorno de Rust (`rust.sh`)

Rust se gestiona mediante su herramienta estándar e independiente **Rustup**.

1. **Compiladores y Herramientas del Sistema**:
   ```bash
   sudo apt install -y build-essential cmake libssl-dev pkg-config curl
   ```

2. **Instalador Rustup y Componentes**:
   Se descarga el script de instalación sin modificar directamente el PATH global para mantener la estructura modular, e instala herramientas oficiales de análisis y formateo:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain stable
   rustup component add clippy rustfmt
   ```

3. **Carga Modular de Entorno**:
   Se añade a la carpeta `~/.bashrc.d/rust.sh` el cargador de variables de entorno de Cargo:
   ```bash
   if [ -f "$HOME/.cargo/env" ]; then
       . "$HOME/.cargo/env"
   fi
   ```

4. **Instalador de Binarios Rápidos (`cargo-binstall`)**:
   Descarga e integra `cargo-binstall`, que permite descargar e instalar herramientas escritas en Rust directamente en binarios precompilados de sus repositorios de GitHub en lugar de compilarlas desde cero (ahorrando tiempo valioso):
   ```bash
   curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
   ```

---

## 4. OpenJDK Java compatible con AutoFirma (`java.sh`)

AutoFirma requiere interactuar con el almacén de claves NSS y la máquina virtual Java de Debian. Se instala a nivel de sistema APT y se exporta `JAVA_HOME`:
```bash
sudo apt install -y default-jre default-jdk libnss3-tools
```
Genera la configuración modular en `~/.bashrc.d/java.sh`:
```bash
export JAVA_HOME="/usr/lib/jvm/default-java"
export PATH="$JAVA_HOME/bin:$PATH"
```

---

## 5. Automatización de Tareas (`justfile`)

Se incluye un archivo de tareas `just` (`justfile`) para facilitar la instalación selectiva de los diferentes lenguajes con comandos rápidos:

```make
# Instala Mise
mise:
    ./mise.sh

# Instala Node.js, npm, pnpm y yarn
node:
    ./nodejs.sh

# Instala Python 3.13, pip y uv
python:
    ./python.sh

# Instala Rust, Clippy, Rustfmt y cargo-binstall
rust:
    ./rust.sh

# Instala Go (Golang)
go:
    ./go.sh

# Instala .NET SDK
dotnet:
    ./dotnet.sh

# Instala OpenJDK Java
java:
    ./java.sh

# Instala Angular CLI
angular:
    ./angular.sh

# Instala Gemini CLI
gemini:
    ./gemini.sh
```

Puedes ejecutar cualquiera de estas tareas con el comando `just <tarea>` en la raíz de la carpeta `ProgrammingLanguages`, o desde la raíz del repositorio con `just languages` o `just setup-all`.
