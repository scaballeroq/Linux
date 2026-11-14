---
sidebar_position: 6
---

# Programming Languages Management on CachyOS Workstation

This guide details the installation, control, and maintenance of programming languages and their development toolchains in the `ProgrammingLanguages` folder.

Environment management is primarily handled through **Mise** (runtimes and SDKs) and **Rustup** (Rust toolchain), complemented by an automated task manager via `justfile` and natively integrated with **GNOME (Wayland / systemd user session)** and **Bash** (default) and **Zsh** (conditionally compatible).

---

## 1. Mise Version Manager (`mise.sh`)

Mise is a high-performance modern terminal tool written in Rust replacing legacy tools like `asdf`, `nvm`, or `pyenv`. It swiftly manages local or global language versions.

1. **Installation in User Space / CachyOS**:
   ```bash
   curl https://mise.run | sh
   # Or via official/AUR packages:
   # sudo pacman -S --needed mise
   ```

2. **Shell & Desktop Integration**:
   - For GNOME and GUI applications: `~/.config/environment.d/10-mise.conf`
   - For Bash (default): `~/.bashrc.d/mise.sh` and Bash completions
   - For Zsh (if `~/.zshrc` exists): `~/.zshrc.d/mise.zsh` (`eval "$(mise activate zsh)"`) and `_mise` completions

---

## 2. Language Runtimes & SDKs (Latest LTS Versions)

Once Mise is initialized, the following optimized runtimes are installed globally:

### Node.js (`nodejs.sh`)
* **Dependencies**: Ensures `base-devel`, `curl`, and `python` via Pacman, required for compiling native npm modules (`node-gyp`).
* **Installation**: Automatically installs and sets the **active LTS release** of Node.js:
  ```bash
  mise use --global node@lts
  ```
* **Corepack (pnpm / yarn)**: Enables Corepack unattended (`COREPACK_ENABLE_DOWNLOAD_PROMPT=0`) for native, immediate `pnpm` and `yarn` availability:
  ```bash
  mise exec node@lts -- corepack enable
  mise reshim
  ```

### Angular CLI (`angular.sh`)
* **Installation**: Installs the latest official CLI globally via Mise-managed npm:
  ```bash
  mise use --global npm:@angular/cli@latest
  ```
* **Optimizations**: Disables interactive telemetry prompts (`ng config -g cli.analytics false`) and generates completions.

### Python & uv (`python.sh` & `python-uv-init.sh`)
* **Dependencies**: Ensures `python`, `python-pip`, and `python-gobject` via Pacman for complete GNOME integration.
* **Installation**: Installs the high-performance **uv** package manager via Mise (`mise use --global uv@latest`) or Pacman (`sudo pacman -S uv`), preserving system Python integrity in compliance with PEP 668.
* **Project Scaffolding**: Includes `python-uv-init.sh` to generate isolated project structures (FastAPI, CLI, Data Science).
* **Complete Guide**: Refer to [python_uv_es.md](./python_uv_es.md) for detailed workflow instructions.
* **GNOME & Shells**: Generates `~/.config/environment.d/10-python.conf`, `~/.bashrc.d/python.sh` (and `~/.zshrc.d/python.zsh`) and shell completions.

### .NET SDK (`dotnet.sh`)
* **Dependencies**: Native system libraries (`icu`, `openssl`, `krb5`, `zlib`).
* **Installation**: Installs and sets the Long-Term Support **LTS** version of .NET:
  ```bash
  mise use --global dotnet@lts
  ```
* **GNOME & IDEs**: Configures `DOTNET_ROOT` in `~/.config/environment.d/10-dotnet.conf` for JetBrains Rider, VS Code, and Antigravity.

---

## 3. Rust Ecosystem (`rust.sh`)

Rust is managed through its official toolchain installer **Rustup** on the **Stable** channel, leveraging fast linkers (`mold` or `lld`) and build caching (`sccache`) on CachyOS.

1. **System Compilers & Build Tools**:
   ```bash
   sudo pacman -S --needed --noconfirm base-devel cmake openssl pkgconf curl git lld clang mold sccache
   ```

2. **Rustup Installer**:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile default --no-modify-path
   ```

3. **Developer Tools for IDEs**:
   Installs `rust-src`, `rust-analyzer`, `clippy`, and `rustfmt` for complete IDE support:
   ```bash
   rustup component add rust-src rust-analyzer clippy rustfmt
   ```

4. **Desktop & Shell Integration**:
   - GNOME / Systemd: `~/.config/environment.d/10-rust.conf`
   - Bash & Zsh: `~/.bashrc.d/rust.sh` (and `~/.zshrc.d/rust.zsh`)
   - Completions: `cargo` and `rustup` completions.

5. **Fast Binary Installer (`cargo-binstall`)**:
   Downloads and configures `cargo-binstall` to install precompiled Rust binaries directly from GitHub releases.

---

## 4. OpenJDK Java (`java.sh`)

Installs CachyOS OpenJDK LTS package via Pacman:
* **Packages**: `jdk21-openjdk`, `jre21-openjdk` (or current LTS) alongside `pcsclite`, `nss`, and `maven`.
* **JVM Management**: Automatic default Java environment configuration via `archlinux-java`.
* **GNOME Integration**: Sets `JAVA_HOME` in `~/.config/environment.d/10-java.conf` for Android Studio, IntelliJ IDEA, Gradle, and Maven.

---

## 5. Task Automation (`justfile`)

Includes a `justfile` for quick modular tasks:

```bash
just languages           # Installs all language runtimes (Mise, Node, Python, Rust, .NET, Java, Angular)
just mise                # Installs Mise runtime manager
just node                # Installs Node.js LTS
just python              # Sets up Python and UV
just python-uv <params>  # Creates isolated Python project template
just rust                # Installs and optimizes Rust toolchain
just dotnet              # Installs .NET SDK
just java                # Installs OpenJDK LTS and Maven
just angular             # Installs Angular CLI
```
