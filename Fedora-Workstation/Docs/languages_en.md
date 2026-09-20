---
sidebar_position: 6
---

# Programming Languages Management on Fedora 44 Workstation

This guide details the installation, control, and maintenance of programming languages and their development environments managed in the `ProgrammingLanguages` folder.

Environment management is centralized through **Mise** (runtimes and SDKs) and **Rustup** (Rust toolchain), supplemented by automated tasks configured via a `justfile` and integrated natively with **GNOME (Wayland / systemd user session)** and terminal shells **Bash** (default) and **Zsh** (conditional compatibility).

---

## 1. Version Manager Mise (`mise.sh`)

Mise is a high-performance polyglot runtime and version manager written in Rust that replaces older tools like `asdf`, `nvm`, or `pyenv`. It downloads and configures development environments globally or locally.

1. **Official RPM Repository Registration and DNF5 Installation**:
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

2. **Shell and GNOME / Wayland Session Integration**:
   - For GNOME & Graphical Environments: `~/.config/environment.d/10-mise.conf`
   - For Bash (default): `~/.bashrc.d/mise.sh` and native bash completions
   - For Zsh (compatible if `~/.zshrc` exists): `~/.zshrc.d/mise.zsh` (`eval "$(mise activate zsh)"`) and `_mise` completions

---

## 2. Language Runtimes and SDKs (Latest LTS Versions)

Once Mise is installed, the following optimized development environments are deployed globally:

### Node.js (`nodejs.sh`)
* **Dependencies**: Checks and installs `@development-tools`, `gcc-c++`, `make`, `curl`, `python3`, and `libstdc++-devel` via DNF5, required to compile native npm dependencies (`node-gyp`).
* **Dynamic LTS Installation**: Automatically installs and sets the **latest active LTS release** of Node.js:
  ```bash
  mise use --global node@lts
  ```
* **Corepack (pnpm / yarn)**: Enables Corepack unattended (`COREPACK_ENABLE_DOWNLOAD_PROMPT=0`) to make `pnpm` and `yarn` immediately available natively:
  ```bash
  mise exec node@lts -- corepack enable
  mise reshim
  ```

### Angular CLI (`angular.sh`)
* **Installation**: Installs the latest official Angular CLI globally using npm managed by Mise:
  ```bash
  mise use --global npm:@angular/cli@latest
  ```
* **Optimizations**: Disables interactive telemetry prompts (`ng config -g cli.analytics false`) and generates completions for Bash (and Zsh if present).

### Python & uv (`python.sh` & `python-uv-init.sh`)
* **Dependencies**: Ensures `python3`, `python3-pip`, and `python3-gobject` along with system development headers via DNF5 for full GNOME integration.
* **Installation**: Installs the high-performance **uv** package manager via Mise (`mise use --global uv@latest`) and preserves system Python intact to avoid breaking core utilities like *GNOME Tweaks* (`gnome-tweaks`).
* **Project Generator**: Includes the scaffolding tool `python-uv-init.sh` to generate isolated projects with templates (FastAPI, CLI, Data Science).
* **Complete Guide**: Refer to [python_uv_es.md](file:///home/caballero/Workspace/Repositorios/Linux/Fedora-Workstation/Docs/python_uv_es.md) for workflow details.
* **GNOME & Shells**: Generates `~/.config/environment.d/10-python.conf`, `~/.bashrc.d/python.sh` (and `~/.zshrc.d/python.zsh` if `~/.zshrc` exists) and native completions for Bash and Zsh (`uv`, `uvx`, `pip`).

### .NET SDK (`dotnet.sh`)
* **Dependencies**: Native CoreCLR runtime libraries (`libicu`, `openssl-devel`, `krb5-devel`, `zlib-devel`, `libunwind`).
* **Installation**: Automatically installs and configures the Long Term Support **LTS** version of .NET:
  ```bash
  mise use --global dotnet@lts
  ```
* **GNOME & IDEs**: Configures `DOTNET_ROOT` in `~/.config/environment.d/10-dotnet.conf` for JetBrains Rider, VS Code, and Antigravity, disabling telemetry.

---

## 3. Rust Environment (`rust.sh`)

Rust is managed through its official standard toolchain installer **Rustup** tracking the **Stable** channel.

1. **System Build Dependencies**:
   ```bash
   sudo dnf5 install -y @development-tools cmake openssl-devel pkgconf-pkg-config curl git lld clang-devel
   ```

2. **Rustup Installer & Stable Channel**:
   Downloads the installer and locks to the `stable` profile:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile default --no-modify-path
   ```

3. **IDE Development Components**:
   Installs `rust-analyzer`, `clippy`, `rustfmt`, and `rust-src` for full IDE support:
   ```bash
   rustup component add rust-src rust-analyzer clippy rustfmt
   ```

4. **GNOME & Shell Session Integration**:
   - GNOME / Systemd: `~/.config/environment.d/10-rust.conf`
   - Bash & Zsh: `~/.bashrc.d/rust.sh` (and `~/.zshrc.d/rust.zsh` if `~/.zshrc` exists)
   - Completions: `cargo` and `rustup` for Bash (and `_cargo` / `_rustup` for Zsh).

5. **Fast Binary Installer (`cargo-binstall`)**:
   Downloads and integrates `cargo-binstall`, which installs Rust CLI binaries directly from GitHub release assets without compiling from source locally.

---

## 4. OpenJDK Java (`java.sh`)

Installs Fedora's OpenJDK LTS package via DNF5:
* **Packages**: `java-latest-openjdk`, `java-latest-openjdk-devel` (with support for OpenJDK 25 / 21 LTS), along with `pcsc-lite`, `nss-tools`, and `maven` (smartcard, AutoFirma, FNMT, and DNIe support).
* **JVM Management**: Auto-detects and sets the default Java environment in `/usr/lib/jvm/java-openjdk`.
* **GNOME Integration**: Sets `JAVA_HOME` in `~/.config/environment.d/10-java.conf` for Android Studio, IntelliJ IDEA, Gradle, and Maven.

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

# Installs Rust
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

# Installs all languages
all: mise node python rust dotnet java angular
```

You can execute any recipe with `just <recipe>` inside the `ProgrammingLanguages` folder.
