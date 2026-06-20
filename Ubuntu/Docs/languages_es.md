---
sidebar_position: 6
---

# Gestión de Lenguajes de Programación en Debian 13

Esta guía detalla la instalación, control y mantenimiento de lenguajes de programación y sus herramientas de desarrollo en la carpeta `ProgrammingLanguages`.

La gestión de entornos se centraliza principalmente a través de **Mise** (runtimes y SDKs) y **Rustup** (entorno de Rust), complementados por un gestor de tareas automatizado mediante un `justfile`.

---

## 1. Gestor de Versiones Mise (`mise.sh`)

Mise es una herramienta de terminal moderna que reemplaza a herramientas como `asdf`, `nvm` o `pyenv`. Se encarga de descargar y configurar rápidamente entornos de desarrollo locales o globales.

1. **Instalación y Repositorio Oficial**:
   ```bash
   sudo apt update
   sudo apt install -y curl gpg
   sudo mkdir -p -m 755 /etc/apt/keyrings
   curl -fsSL https://mise.jdx.dev/gpg-key.pub | sudo gpg --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg
   echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list > /dev/null
   sudo apt update
   sudo apt install -y mise
   ```

2. **Activación de Shell**:
   Se crea de manera modular la inicialización de Mise en `~/.bashrc.d/mise.sh`:
   ```bash
   eval "$(mise activate bash)"
   ```

---

## 2. Runtimes de Lenguajes y SDKs

Una vez instalado Mise, se despliegan de forma global los siguientes lenguajes:

### Node.js (`nodejs.sh` y `angular.sh`)
* **Dependencias**: Instala `build-essential`, `python3`, `g++` y `make` vía APT, necesarios para compilar dependencias nativas de npm (`node-gyp`).
* **Instalación**: Configura la versión LTS 22 global:
  ```bash
  mise use --global node@22
  ```
* **Actualización segura de NPM**: Se aplica una limpieza de caché de npm e instalación previa de `promise-retry` para evadir errores clásicos del instalador de npm en Debian antes de subir a la versión más reciente (`npm install -g npm@latest`).
* **Angular CLI**: Se instala globalmente el CLI oficial utilizando npm manejado por Mise:
  ```bash
  mise use --global npm:@angular/cli@latest
  ```

### Python (`python.sh`)
* **Dependencias**: Instala librerías del sistema para compilar extensiones de Python (`libssl-dev`, `zlib1g-dev`, `libffi-dev`, etc.).
* **Instalación**: Instala la rama optimizada 3.12 y actualiza el gestor de paquetes pip:
  ```bash
  mise use --global python@3.12
  mise exec python@3.12 -- python -m pip install --upgrade pip
  ```

### .NET SDK (`dotnet.sh`)
* **Instalación**: Instala la última versión mayor del SDK de .NET:
  ```bash
  mise use --global dotnet@10
  ```

### Gemini CLI (`gemini.sh`)
* **Instalación**: Herramienta de interfaz de comandos de Google Gemini:
  ```bash
  mise use --global npm:@google/gemini-cli@latest
  ```

---

## 3. Entorno de Rust (`rust.sh`)

Rust se gestiona mediante su herramienta estándar e independiente **Rustup**.

1. **Compiladores y Herramientas del Sistema**:
   ```bash
   sudo apt install -y build-essential cmake libssl-dev pkg-config curl
   ```

2. **Instalador Rustup**:
   Se descarga el script de instalación sin modificar directamente el PATH global para mantener la estructura modular:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
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

AutoFirma requiere interactuar con el almacén de claves NSS y la máquina virtual Java de Debian. Se instala a nivel de sistema APT:
```bash
sudo apt install -y default-jre default-jdk libnss3-tools
```

---

## 5. Automatización de Tareas (`justfile`)

Se incluye un archivo de tareas `just` (`justfile`) para facilitar la instalación selectiva de los diferentes lenguajes con comandos rápidos:

```make
# Instala Mise
mise:
    ./mise.sh

# Instala Node.js
node:
    ./nodejs.sh

# Instala Python
python:
    ./python.sh

# Instala Rust
rust:
    ./rust.sh

# Instala Gemini CLI
gemini:
    ./gemini.sh
```

Puedes ejecutar cualquiera de estas tareas con el comando `just <tarea>` en la raíz de la carpeta `ProgrammingLanguages`.
