---
sidebar_position: 6
---

# Programming Languages Management on Debian 13 (Testing / Trixie)

This guide details the installation, control, and maintenance of programming languages and their development environments managed in the `ProgrammingLanguages` folder.

Environment management is centralized through **Mise** (runtimes and SDKs) and **Rustup** (Rust toolchain), supplemented by automated tasks configured via a `justfile`.

---

## 1. Version Manager Mise (`mise.sh`)

Mise is a modern CLI version manager that replaces older tools like `asdf`, `nvm`, or `pyenv`. It downloads and configures development environments globally or locally.

1. **Official Repository Registration and Installation**:
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

2. **Modular Shell Activation**:
   Mise initialization and shims loading are added to `~/.bashrc.d/mise.sh`:
   ```bash
   export PATH="$HOME/.local/share/mise/shims:$PATH"
   eval "$(mise activate bash)"
   ```

---

## 2. Language Runtimes and SDKs

Once Mise is installed, the following development environments are deployed globally:

### Node.js, PNPM, and Yarn (`nodejs.sh` and `angular.sh`)
* **Dependencies**: Installs `build-essential`, `python3`, `g++`, and `make` via APT, which are required to build native npm dependencies (`node-gyp`).
* **Installation**: Configures the global Node.js LTS 22 release along with modern package managers (`pnpm`, `yarn`):
  ```bash
  mise use --global node@22
  mise use --global pnpm@latest yarn@latest
  mise reshim
  ```
* **Angular CLI**: Installs the official Angular CLI globally via Mise's npm backend:
  ```bash
  mise use --global npm:@angular/cli@latest
  ```

### Python and UV (`python.sh`)
* **Dependencies**: Installs system libraries required to build C extensions for Python (`libssl-dev`, `zlib1g-dev`, `libreadline-dev`, `libncurses-dev`, `libffi-dev`, etc.).
* **Installation**: Installs the stable 3.13 series, updates `pip`, `setuptools`, `wheel`, and installs **`uv`** (the ultra-fast standard package and virtualenv manager):
  ```bash
  mise use --global python@3.13
  mise exec python@3.13 -- python -m pip install --upgrade pip setuptools wheel
  mise use --global uv@latest
  mise reshim
  ```

### Go / Golang (`go.sh`)
* **Installation**: Installs the latest stable Go version via Mise:
  ```bash
  mise use --global go@latest
  mise reshim
  ```
* **Environment Variables**: Sets `GOPATH` and `GOBIN` (`$HOME/go/bin`) in `~/.bashrc.d/go.sh`.

### .NET SDK (`dotnet.sh`)
* **Dependencies**: Installs `libicu-dev`, `libssl-dev`, and `zlib1g` via APT (essential for ICU globalization and SSL on Debian).
* **Installation**: Installs the latest .NET SDK via Mise:
  ```bash
  mise use --global dotnet@latest
  mise reshim
  ```

### Gemini CLI (`gemini.sh`)
* **Installation**: Installs the Google Gemini command-line helper interface:
  ```bash
  mise use --global npm:@google/gemini-cli@latest
  mise reshim
  ```

---

## 3. Rust Environment (`rust.sh`)

Rust is managed through its official standard toolchain installer **Rustup**.

1. **System Build Dependencies**:
   ```bash
   sudo apt install -y build-essential cmake libssl-dev pkg-config curl
   ```

2. **Rustup Installation and Toolchain Components**:
   Downloads the installation script without directly modifying the global environment path to preserve modular loading, and installs essential dev components:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain stable
   rustup component add clippy rustfmt
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

AutoFirma requires Java Virtual Machine integration and NSS tools. These are installed system-wide via APT and exports `JAVA_HOME`:
```bash
sudo apt install -y default-jre default-jdk libnss3-tools
```
Creates modular configuration in `~/.bashrc.d/java.sh`:
```bash
export JAVA_HOME="/usr/lib/jvm/default-java"
export PATH="$JAVA_HOME/bin:$PATH"
```

---

## 5. Task Automation (`justfile`)

A `justfile` is included to trigger individual runtime installations using simple commands:

```make
# Installs Mise
mise:
    ./mise.sh

# Installs Node.js, npm, pnpm and yarn
node:
    ./nodejs.sh

# Installs Python 3.13, pip and uv
python:
    ./python.sh

# Installs Rust, Clippy, Rustfmt and cargo-binstall
rust:
    ./rust.sh

# Installs Go (Golang)
go:
    ./go.sh

# Installs .NET SDK
dotnet:
    ./dotnet.sh

# Installs OpenJDK Java
java:
    ./java.sh

# Installs Angular CLI
angular:
    ./angular.sh

# Installs Gemini CLI
gemini:
    ./gemini.sh
```

You can execute any recipe with `just <recipe>` inside the `ProgrammingLanguages` folder, or from repository root with `just languages` or `just setup-all`.
