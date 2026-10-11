---
sidebar_position: 6
---

# Gestión de Lenguajes de Programación en Fedora 44

Esta guía detalla la instalación, control y mantenimiento de lenguajes de programación y sus herramientas de desarrollo en la carpeta `ProgrammingLanguages`.

La gestión de entornos se centraliza principalmente a través de **Mise** (runtimes y SDKs) y **Rustup** (entorno de Rust), complementados por un gestor de tareas automatizado mediante un `justfile`.

---

## 1. Gestor de Versiones Mise (`mise.sh`)

Mise es una herramienta de terminal moderna de alto rendimiento escrita en Rust que reemplaza a herramientas como `asdf`, `nvm` o `pyenv`. Se encarga de descargar y configurar rápidamente entornos de desarrollo locales o globales.

1. **Instalación y Repositorio Oficial RPM (DNF5)**:
   ```bash
   sudo rpm --import https://mise.jdx.dev/gpg-key.pub
   sudo tee /etc/yum.repos.d/mise.repo << 'EOF'
   [mise]
   name=Mise
   baseurl=https://mise.jdx.dev/rpm
   enabled=1
   gpgcheck=1
   gpgkey=https://mise.jdx.dev/gpg-key.pub
   EOF
   sudo dnf5 install -y mise
   ```

2. **Integración con Shell y Sesión KDE Plasma / Wayland**:
   - **KDE Plasma / Wayland (`~/.config/environment.d/10-mise.conf`)**: Registra la ruta de shims `~/.local/share/mise/shims` en la sesión gráfica para que IDEs (VS Code, JetBrains), KRunner y Dolphin detecten Node/Python/Rust automáticamente.
   - **Shell (`~/.bashrc.d/mise.sh`)**: Carga modularmente `eval "$(mise activate bash)"`.
   - **Autocompletado**: Se genera el autocompletado en `~/.local/share/bash-completion/completions/mise`.

```bash
# Ejecución mediante just o script:
./ProgrammingLanguages/mise.sh

# Ver estado de herramientas:
./ProgrammingLanguages/mise.sh --status
```

---

## 2. Runtimes de Lenguajes y SDKs

Una vez instalado Mise, se despliegan de forma global los siguientes lenguajes:

### Node.js (`nodejs.sh` y `angular.sh`)
* **Dependencias**: Instala `@development-tools`, `gcc-c++`, `make`, `curl` y `python3` vía DNF5, necesarios para compilar dependencias nativas de npm (`node-gyp`).
* **Instalación LTS Dinámica**: Configura la versión LTS más reciente de Node.js de forma global y prepara Corepack (`pnpm` / `yarn`):
  ```bash
  ./ProgrammingLanguages/nodejs.sh
  # o manualmente con mise:
  mise use --global node@lts
  ```
* **Corepack**: Habilita `pnpm` y `yarn` de forma nativa e integrada sin instalaciones globales conflictivas:
  ```bash
  corepack enable
  ```
* **Angular CLI**: Se instala globalmente el CLI oficial utilizando Mise:
  ```bash
  mise use --global npm:@angular/cli@latest
  ```

### Python (`python.sh`)
* **Dependencias**: Instala cabeceras y librerías del sistema para compilar extensiones nativas C/Rust (`openssl-devel`, `zlib-devel`, `libffi-devel`, `sqlite-devel`, `bzip2-devel`, `readline-devel`).
* **Instalación Estable (Soporte Extendido)**: Instala la versión recomendada de producción con soporte extendido (3.12/3.13) y actualiza las herramientas de construcción (`pip`, `setuptools`, `wheel`):
  ```bash
  ./ProgrammingLanguages/python.sh
  # o para una versión específica (ej: 3.13):
  ./ProgrammingLanguages/python.sh --version 3.13
  ```

### .NET SDK (`dotnet.sh`)
* **Dependencias**: Instala `libicu`, `openssl-devel`, `krb5-devel` y `zlib-devel` para el runtime CoreCLR.
* **Instalación LTS**: Instala la versión oficial LTS de .NET SDK vía Mise (`dotnet@lts` / `dotnet@8`) y desactiva la telemetría:
  ```bash
  ./ProgrammingLanguages/dotnet.sh
  ```

### Gemini CLI (`gemini.sh`)
* **Instalación**: Herramienta de interfaz de comandos de Google Gemini:
  ```bash
  mise use --global npm:@google/gemini-cli@latest
  ```

---

## 3. Entorno de Rust (`rust.sh`)

Rust se gestiona mediante su herramienta estándar **Rustup** fijada al canal oficial **Stable**.

1. **Compiladores y Herramientas del Sistema**:
   ```bash
   sudo dnf5 install -y @development-tools cmake openssl-devel pkgconf-pkg-config curl lld clang-devel
   ```

2. **Instalador Rustup y Componentes IDE**:
   Descarga la cadena Stable y añade `rust-analyzer` (LSP), `clippy`, `rustfmt` y `rust-src`:
   ```bash
   ./ProgrammingLanguages/rust.sh
   ```

3. **Carga de Sesión KDE Plasma y Shell**:
   Registra `~/.cargo/bin` en `~/.config/environment.d/10-rust.conf` (sesión Wayland de KDE) y `~/.bashrc.d/rust.sh`.

4. **Instalador de Binarios Rápidos (`cargo-binstall`)**:
   Descarga e integra `cargo-binstall`, que permite descargar e instalar herramientas escritas en Rust directamente en binarios precompilados de sus repositorios de GitHub en lugar de compilarlas desde cero.

---

## 4. OpenJDK Java (LTS) compatible con AutoFirma (`java.sh`)

Instala la versión oficial OpenJDK LTS de Fedora con compilador completo, Apache Maven, herramientas NSS para AutoFirma/FNMT y configura la variable `JAVA_HOME` en la sesión de KDE Plasma:
```bash
./ProgrammingLanguages/java.sh
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
