---
sidebar_position: 6
---

# Programming Languages Management on CachyOS

This guide details the installation, control, and maintenance of programming languages and their development environments managed in the `ProgrammingLanguages` folder.

Environment management is centralized through **Mise** (runtimes and SDKs) and **Rustup** (Rust toolchain), supplemented by automated tasks configured via a `justfile` and natively integrated with **KDE Plasma 6 (Wayland / systemd user session)** as well as **Zsh** and **Bash** shells.

---

## 1. Version Manager Mise (`mise.sh`)

Mise is a modern CLI version manager that replaces older tools like `asdf`, `nvm`, or `pyenv`. It downloads and configures development environments globally or locally.

1. **Installation on CachyOS**:
   ```bash
   sudo pacman -S --needed --noconfirm mise
   ```

2. **Session and Shell Activation**:
   - For KDE Plasma 6 & desktop environments: `~/.config/environment.d/10-mise.conf`
   - For Zsh: `~/.zshrc` (`eval "$(mise activate zsh)"`) and `_mise` completions
   - For Bash: `~/.bashrc.d/mise.sh`

---

## 2. Language Runtimes and SDKs (Latest LTS Versions)

Once Mise is installed, the following development environments are deployed globally:

### Node.js (`nodejs.sh`)
* **Dependencies**: Checks and installs `base-devel`, `curl`, `python`, `gcc`, and `make` via Pacman, required to build native npm dependencies (`node-gyp`).
* **Installation**: Installs and sets the **latest active Node.js LTS** release globally:
  ```bash
  mise use --global node@lts
  ```
* **Corepack (pnpm / yarn)**: Enables Corepack non-interactively (`COREPACK_ENABLE_DOWNLOAD_PROMPT=0`) for instant `pnpm` and `yarn` package management:
  ```bash
  mise exec node@lts -- corepack enable
  mise reshim
  ```

### Angular CLI (`angular.sh`)
* **Installation**: Installs the official Angular CLI globally:
  ```bash
  mise use --global npm:@angular/cli@latest
  ```
* **Optimizations**: Automatically disables interactive analytics prompts (`ng config -g cli.analytics false`) and sets up Zsh/Bash autocompletions.

### Python & uv (`python.sh`)
* **Dependencies**: Checks and installs system libraries required to build C extensions for Python (`openssl`, `zlib`, `bzip2`, `readline`, `sqlite`, `libffi`, etc.) with PGO + LTO compiler optimizations.
* **Installation**: Installs the latest stable Python runtime and the ultra-fast **uv** package manager via Mise:
  ```bash
  mise use --global python@latest
  mise use --global uv@latest
  mise exec python@latest -- python -m pip install --upgrade pip setuptools wheel
  ```
* **KDE Plasma 6 & Shells**: Generates `~/.config/environment.d/10-python.conf`, `~/.zshrc.d/python.zsh` and native Zsh/Bash autocompletions (`_uv`, `_uvx`, `_pip`).

### .NET SDK (`dotnet.sh`)
* **Dependencies**: Native runtime libraries (`icu`, `krb5`, `openssl`, `zlib`, `libunwind`).
* **Installation**: Installs the latest Long Term Support **LTS** version of the .NET SDK:
  ```bash
  mise use --global dotnet@lts
  ```
* **KDE Plasma 6 & IDEs**: Configures `DOTNET_ROOT` in `~/.config/environment.d/10-dotnet.conf` for JetBrains Rider, VS Code, and Antigravity, while opting out of build telemetry.

---

## 3. Rust Environment (`rust.sh`)

Rust is managed through its official standard toolchain installer **Rustup** using the **Stable** production channel (Rust's release model).

1. **System Build Dependencies**:
   ```bash
   sudo pacman -S --needed --noconfirm base-devel cmake openssl pkgconf curl git
   ```

2. **Rustup Installation & Stable Channel**:
   Downloads the installer fixing the `stable` toolchain:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile default --no-modify-path
   ```

3. **IDE Development Components**:
   Installs `rust-analyzer`, `clippy`, `rustfmt`, and `rust-src` for seamless out-of-the-box support in VS Code, RustRover, and Antigravity:
   ```bash
   rustup component add rust-src rust-analyzer clippy rustfmt
   ```

4. **KDE Plasma 6 and Shell Integration**:
   - KDE Plasma 6: `~/.config/environment.d/10-rust.conf`
   - Bash & Zsh: `~/.bashrc.d/rust.sh` and `~/.zshrc.d/rust.zsh`
   - Autocompletions: `_cargo` and `_rustup` for Zsh and Bash.

5. **Fast Binary Installer (`cargo-binstall`)**:
   Downloads and integrates `cargo-binstall`, which installs Rust-written CLI tools directly from GitHub pre-compiled binaries instead of compiling them from source locally.

---

## 4. OpenJDK Java (`java.sh`)

Installs OpenJDK LTS for CachyOS via Pacman:
* **Packages**: `jdk25-openjdk` / `jdk21-openjdk` (LTS) along with `nss` and `pcsclite` (AutoFirma and DNIe / Smartcard reader support).
* **JVM Management**: Configures the active runtime using `archlinux-java`.
* **KDE Plasma 6 Integration**: Exports `JAVA_HOME=/usr/lib/jvm/default` in `~/.config/environment.d/10-java.conf` for Android Studio, IntelliJ IDEA, Gradle, and Maven.

---

## 5. Task Automation (`justfile`)

A `justfile` is included to trigger individual runtime installations using simple commands:

```make
# Installs Mise
mise:
    ./mise.sh

# Installs Node.js LTS
node:
    ./nodejs.sh

# Installs Python
python:
    ./python.sh

# Installs Rust Stable
rust:
    ./rust.sh

# Installs .NET SDK LTS
dotnet:
    ./dotnet.sh

# Installs Java OpenJDK LTS
java:
    ./java.sh

# Installs Angular CLI
angular:
    ./angular.sh
```

You can execute any recipe with `just <recipe>` inside the `ProgrammingLanguages` folder.
