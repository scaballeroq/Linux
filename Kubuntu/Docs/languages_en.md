---
sidebar_position: 6
---

# Programming Languages Management on Kubuntu / Ubuntu

This guide details the installation, control, and maintenance of programming languages and their development environments managed in the `ProgrammingLanguages` folder.

Environment management is centralized through **Mise** (runtimes and SDKs) and **Rustup** (Rust toolchain), supplemented by automated tasks configured via a `justfile`.

---

## 1. Version Manager Mise (`mise.sh`)

Mise is a modern CLI version manager that replaces older tools like `asdf`, `nvm`, or `pyenv`. It downloads and configures development environments globally or locally.

1. **Official Repository Registration and Installation**:
   ```bash
   sudo apt update
   sudo apt install -y curl gpg
   sudo mkdir -p -m 755 /etc/apt/keyrings
   curl -fsSL https://mise.jdx.dev/gpg-key.pub | sudo gpg --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg
   echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list > /dev/null
   sudo apt update
   sudo apt install -y mise
   ```

2. **Shell Activation**:
   Mise initialization is added to `~/.bashrc.d/mise.sh`:
   ```bash
   eval "$(mise activate bash)"
   ```

---

## 2. Language Runtimes and SDKs

Once Mise is installed, the following development environments are deployed globally:

### Node.js and pnpm (`nodejs.sh` and `angular.sh`)
* **Dependencies**: Installs `build-essential`, `python3`, `g++`, and `make` via APT, which are required to build native npm dependencies (`node-gyp`).
* **Installation**: Configures the global Node.js LTS 22 release:
  ```bash
  mise use --global node@22
  ```
* **Safe NPM Updates**: Cleans npm cache and pre-installs the `promise-retry` package to bypass common npm registry upgrade errors, then updates NPM:
  ```bash
  mise exec node@22 -- npm install -g npm@latest
  ```
* **pnpm Package Manager**: Enables **Corepack** natively and configures the latest release of **pnpm**. PNPM is a faster, disk-space efficient, and more secure alternative to traditional npm due to its content-addressable storage structure and non-flat node_modules layout.
* **Angular CLI**: Installs the official Angular CLI globally:
  ```bash
  mise use --global npm:@angular/cli@latest
  ```

### Python (`python.sh`)
* **Dependencies**: Installs system libraries required to build C extensions for Python (`libssl-dev`, `zlib1g-dev`, `libffi-dev`, etc.).
* **Installation**: Installs the optimized 3.12 branch and updates the pip package manager:
  ```bash
  mise use --global python@3.12
  mise exec python@3.12 -- python -m pip install --upgrade pip
  ```

### .NET SDK (`dotnet.sh`)
* **Installation**: Installs the latest major version of the .NET SDK:
  ```bash
  mise use --global dotnet@10
  ```

### Gemini CLI (`gemini.sh`)
* **Installation**: Installs the Google Gemini command-line helper interface:
  ```bash
  mise use --global npm:@google/gemini-cli@latest
  ```

---

## 3. Rust Environment (`rust.sh`)

Rust is managed through its official standard toolchain installer **Rustup**.

1. **System Build Dependencies**:
   ```bash
   sudo apt install -y build-essential cmake libssl-dev pkg-config curl
   ```

2. **Rustup Installation**:
   Downloads the installation script without directly modifying the global environment path to preserve modular loading:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
   ```

3. **Modular Environment Loading**:
   Adds the Cargo bin path variables inside `~/.bashrc.d/rust.sh`:
   ```bash
   if [ -f "$HOME/.cargo/env" ]; then
       . "$HOME/.cargo/env"
   fi
   ```

4. **Fast Binary Installer (`cargo-binstall`)**:
   Downloads and integrates `cargo-binstall`, which installs Rust-written CLI tools directly from GitHub pre-compiled binaries instead of compiling them from source locally (saving massive compilation times):
   ```bash
   curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
   ```

---

## 4. OpenJDK Java compatible with AutoFirma (`java.sh`)

AutoFirma requires Java Virtual Machine integration and NSS tools. These are installed system-wide via APT:
```bash
sudo apt install -y default-jre default-jdk libnss3-tools
```

---

## 5. Task Automation (`justfile`)

A `justfile` is included to trigger individual runtime installations using simple commands:

```make
# Installs Mise
mise:
    ./mise.sh

# Installs Node
node:
    ./nodejs.sh

# Installs Python
python:
    ./python.sh

# Installs Rust
rust:
    ./rust.sh

# Installs Gemini CLI
gemini:
    ./gemini.sh
```

You can execute any recipe with `just <recipe>` inside the `ProgrammingLanguages` folder.
