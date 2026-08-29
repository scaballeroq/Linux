---
sidebar_position: 6
---

# Programming Languages Management on Debian 13

This guide details the installation, control, and maintenance of programming languages and their development environments managed in the `ProgrammingLanguages` folder.

Environment management is centralized through **Mise** (runtimes and SDKs) and **Rustup** (Rust toolchain), supplemented by automated tasks configured via a `justfile`.

---

## 1. Version Manager Mise (`mise.sh`)

Mise is a modern CLI version manager that replaces older tools like `asdf`, `nvm`, or `pyenv`. It downloads and configures development environments globally or locally.

1. **Installation on CachyOS**:
   ```bash
   sudo pacman -S --needed --noconfirm mise
   ```

2. **Session and Shell Activation**:
   - For KDE Plasma 6 & desktop environments: `~/.config/environment.d/10-mise.conf`
   - For Zsh: `~/.zshrc` (`eval "$(mise activate zsh)"`)
   - For Bash: `~/.bashrc.d/mise.sh`

---

## 2. Language Runtimes and SDKs

Once Mise is installed, the following development environments are deployed globally:

### Node.js (`nodejs.sh` and `angular.sh`)
* **Dependencies**: Installs `base-devel`, `curl`, `python`, `gcc`, and `make` via Pacman, required to build native npm dependencies (`node-gyp`).
* **Installation**: Installs and sets the **latest active Node.js LTS** release globally:
  ```bash
  mise use --global node@lts
  ```
* **Corepack (pnpm / yarn)**: Enables Corepack out of the box for fast and native `pnpm` and `yarn` package management:
  ```bash
  mise exec node@lts -- corepack enable
  mise reshim
  ```
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
* **Installation**: Installs the LTS version of the .NET SDK:
  ```bash
  mise use --global dotnet@8
  ```

---

## 3. Rust Environment (`rust.sh`)

Rust is managed through its official standard toolchain installer **Rustup**.

1. **System Build Dependencies**:
   ```bash
   sudo pacman -S --needed --noconfirm base-devel cmake openssl pkgconf curl
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

## 4. OpenJDK Java (`java.sh`)

Installs OpenJDK LTS for CachyOS via Pacman:
```bash
sudo pacman -S --needed --noconfirm jdk-openjdk
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

# Installs .NET
dotnet:
    ./dotnet.sh

# Installs Java
java:
    ./java.sh

# Installs Angular CLI
angular:
    ./angular.sh
```

You can execute any recipe with `just <recipe>` inside the `ProgrammingLanguages` folder.
