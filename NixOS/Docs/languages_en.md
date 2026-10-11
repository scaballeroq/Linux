---
sidebar_position: 6
---

# Programming Languages Management in openSUSE Tumbleweed

This guide details the installation, management, and maintenance of programming languages and developer toolchains in `ProgrammingLanguages/`.

Environments are centrally managed via **Mise** (runtimes and SDKs) and **Rustup** (Rust toolchain), automated by `justfile` recipes and seamlessly integrated with **KDE Plasma 6 (Wayland / systemd user session)** and both **Bash** (default) and **Zsh** (conditionally supported).

---

## 1. Mise Version Manager (`mise.sh`)

Mise is a high-performance Rust-written CLI tool replacing legacy tools like `asdf`, `nvm`, and `pyenv`. It provides fast downloads and isolation for global and project-level runtimes.

1. **Installation & Official RPM Repository (Zypper)**:
   ```bash
   sudo rpm --import https://mise.jdx.dev/gpg-key.pub
   sudo zypper ar -f -c https://mise.jdx.dev/rpm mise
   sudo zypper --non-interactive install -y mise
   ```

2. **Shell & Desktop Environment Hooks**:
   - KDE Plasma & GUI applications: `~/.config/environment.d/10-mise.conf`
   - Bash (default): `~/.bashrc.d/mise.sh` and Bash completions
   - Zsh (compatible if `~/.zshrc` exists): `~/.zshrc.d/mise.zsh` (`eval "$(mise activate zsh)"`) and `_mise` completions

---

## 2. Language Runtimes & SDKs (Latest LTS Versions)

Once Mise is installed, the following development stacks are configured:

### Node.js (`nodejs.sh`)
* **Dependencies**: Checks and installs native build tools (`devel_basis`, `gcc-c++`, `make`, `curl`, `python3`) via Zypper for native npm compilation (`node-gyp`).
* **Installation**: Installs and pins the **active LTS release**:
  ```bash
  mise use --global node@lts
  ```
* **Corepack (pnpm / yarn)**: Enables Corepack unattended (`COREPACK_ENABLE_DOWNLOAD_PROMPT=0`) for out-of-the-box `pnpm` and `yarn`:
  ```bash
  mise exec node@lts -- corepack enable
  mise reshim
  ```

### Angular CLI (`angular.sh`)
* **Installation**: Installs the latest official CLI via Mise-managed npm:
  ```bash
  mise use --global npm:@angular/cli@latest
  ```
* **Optimizations**: Disables telemetry prompts (`ng config -g cli.analytics false`) and sets up completions for Bash and Zsh.

### Python & uv (`python.sh` & `python-uv-init.sh`)
* **Dependencies**: Ensures `python3`, `python3-pip`, `python3-devel` via Zypper while protecting system Python integrity.
* **Installation**: Installs the high-speed **uv** package manager via Mise (`mise use --global uv@latest`).
* **Project Generator**: Includes the `python-uv-init.sh` (`py-project`) CLI to bootstrap isolated projects with templates (FastAPI, CLI, Data Science).
* **Detailed Guide**: See [python_uv_es.md](file:///home/caballero/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Docs/python_uv_es.md) for workflows.
* **KDE Plasma & Shells**: Generates `~/.config/environment.d/10-python.conf`, `~/.bashrc.d/python.sh` (and `~/.zshrc.d/python.zsh`), with completions for `uv`, `uvx`, and `pip`.

### .NET SDK (`dotnet.sh`)
* **Dependencies**: System libraries (`libicu`, `libopenssl-devel`, `krb5-devel`, `zlib-devel`, `libunwind`).
* **Installation**: Installs and pins the **LTS release** of .NET:
  ```bash
  mise use --global dotnet@lts
  ```
* **KDE Plasma & IDEs**: Configures `DOTNET_ROOT` in `~/.config/environment.d/10-dotnet.conf` for JetBrains Rider, VS Code, and Antigravity.

---

## 3. Rust Toolchain (`rust.sh`)

Rust is managed via its official, standalone **Rustup** tool on the **Stable** channel.

1. **System Compilers & Dependencies**:
   ```bash
   sudo zypper --non-interactive install -y -t pattern devel_basis devel_C_C++
   sudo zypper --non-interactive install -y cmake libopenssl-devel pkg-config curl git lld clang-devel
   ```

2. **Rustup Installer (Stable Channel)**:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile default --no-modify-path
   ```

3. **IDE Development Components**:
   Installs `rust-analyzer`, `clippy`, `rustfmt`, and `rust-src`:
   ```bash
   rustup component add rust-src rust-analyzer clippy rustfmt
   ```

4. **KDE Plasma & Shell Integration**:
   - KDE Plasma / Systemd: `~/.config/environment.d/10-rust.conf`
   - Bash & Zsh: `~/.bashrc.d/rust.sh` (and `~/.zshrc.d/rust.zsh`)
   - Completions: `cargo` and `rustup` for Bash and Zsh.

5. **Fast Binary Installer (`cargo-binstall`)**:
   Integrates `cargo-binstall` to install precompiled Rust binaries directly from GitHub releases without full compilation.

---

## 4. OpenJDK Java (`java.sh`)

Installs OpenJDK LTS for openSUSE Tumbleweed via Zypper:
* **Packages**: `java-21-openjdk`, `java-21-openjdk-devel` alongside `pcsc-lite`, `mozilla-nss-tools`, and `maven` (digital certificate and smart card support).
* **JVM Path**: Auto-detected and linked to `/usr/lib64/jvm/java-21-openjdk`.
* **KDE Plasma Integration**: Configures `JAVA_HOME` in `~/.config/environment.d/10-java.conf` for Android Studio, IntelliJ IDEA, Gradle, and Maven.

---

## 5. Task Automation (`justfile`)

Use `just` recipes to selectively manage language environments:

```bash
# Install Mise
just mise

# Install Node.js LTS
just node

# Install Python with UV
just python

# Project initializer
just python-uv

# Install Rust
just rust

# Install .NET SDK LTS
just dotnet

# Install Java OpenJDK LTS
just java

# Install Angular CLI
just angular

# Install all languages
just languages
```
