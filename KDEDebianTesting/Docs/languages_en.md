---
sidebar_position: 6
---

# Programming Languages Management on Debian Testing

This guide details the installation, management, and maintenance of programming languages and SDKs in the `ProgrammingLanguages` directory.

Environment orchestration is driven by **Mise** (runtimes and SDKs) and **Rustup** (Rust toolchain), managed via the root `justfile` and integrated with **KDE Plasma 6 (Wayland / systemd user session)** and **Bash** (default) / **Zsh** (compatible).

---

## 1. Mise Version Manager (`mise.sh`)

Mise is a high-performance polyglot tool version manager written in Rust that replaces `asdf`, `nvm`, and `pyenv`.

1. **Installation via Official APT Repository**:
   ```bash
   sudo mkdir -p -m 755 /etc/apt/keyrings
   curl -fsSL https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg > /dev/null
   sudo chmod 644 /etc/apt/keyrings/mise-archive-keyring.gpg
   echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list > /dev/null
   sudo apt update
   sudo apt install -y mise
   ```

2. **Shell and Desktop Activation**:
   - KDE Plasma & GUI session: `~/.config/environment.d/10-mise.conf`
   - Bash: `~/.bashrc.d/mise.sh` and completions
   - Zsh: `~/.zshrc.d/mise.zsh` (`eval "$(mise activate zsh)"`) and completions

---

## 2. Runtimes and SDKs (LTS Versions)

### Node.js (`nodejs.sh`)
* **Dependencies**: Ensures `build-essential`, `g++`, `make`, `curl`, `python3` via APT for native npm package compilation (`node-gyp`).
* **Installation**: Installs and pins **active LTS**:
  ```bash
  mise use --global node@lts
  ```
* **Corepack (pnpm / yarn)**: Automatically enables Corepack:
  ```bash
  mise exec node@lts -- corepack enable
  mise reshim
  ```

### Angular CLI (`angular.sh`)
* **Installation**: Installed globally via Mise-managed npm:
  ```bash
  mise use --global npm:@angular/cli@latest
  ```
* **Optimizations**: Disables interactive analytics prompts and generates shell completions.

### Python & uv (`python.sh` & `python-uv-init.sh`)
* **Dependencies**: Ensures `python3`, `python3-pip`, `python3-venv`, `python3-dev` to comply with PEP 668.
* **Installation**: Installs **uv** via Mise (`mise use --global uv@latest`) and configures `UV_LINK_MODE=copy`.
* **Project Initializer**: Includes `python-uv-init.sh` (`py-project`) for templated environments (FastAPI, CLI, Data Science).
* **Detailed Guide**: See [python_uv_es.md](file:///home/caballero/Workspace/Repositorios/Linux/KDEDebianTesting/Docs/python_uv_es.md).

### .NET SDK (`dotnet.sh`)
* **Dependencies**: `libicu-dev`, `libssl-dev`, `libkrb5-dev`, `zlib1g-dev`, `libunwind-dev`.
* **Installation**: Installs LTS version:
  ```bash
  mise use --global dotnet@lts
  ```
* **Environment**: Configures `DOTNET_ROOT` in `~/.config/environment.d/10-dotnet.conf`.

---

## 3. Rust Environment (`rust.sh`)

Managed via official standard toolchain **Rustup** on the **Stable** channel.

1. **System Compilers**:
   ```bash
   sudo apt update
   sudo apt install -y build-essential cmake libssl-dev pkg-config curl git lld clang
   ```

2. **Rustup Installer**:
   Installs `stable` profile without polluting system paths:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile default --no-modify-path
   ```

3. **IDE Components**:
   `rust-src`, `rust-analyzer`, `clippy`, `rustfmt`.

4. **KDE Plasma & Shell Integration**:
   - `~/.config/environment.d/10-rust.conf`
   - `~/.bashrc.d/rust.sh` / `~/.zshrc.d/rust.zsh`

5. **Fast Binary Installer (`cargo-binstall`)**:
   Downloads pre-compiled crates directly from GitHub releases.

---

## 4. OpenJDK Java (`java.sh`)

Installs OpenJDK LTS:
* **Packages**: `openjdk-21-jdk`, `openjdk-21-jre`, `pcscd`, `libpcsclite1`, `libnss3-tools`, `maven`.
* **JVM Detection**: Sets `JAVA_HOME` in `~/.config/environment.d/10-java.conf` pointing to `/usr/lib/jvm/java-21-openjdk-amd64`.

---

## 5. Task Automation (`justfile`)

```bash
just mise
just node
just python
just python-uv
just rust
just dotnet
just java
just angular
just languages
```
