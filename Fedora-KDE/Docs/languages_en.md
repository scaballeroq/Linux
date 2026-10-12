---
sidebar_position: 6
---

# Programming Languages Management on Fedora 44

This guide details the installation, control, and maintenance of programming languages and their development environments managed in the `ProgrammingLanguages` folder.

Environment management is centralized through **Mise** (runtimes and SDKs) and **Rustup** (Rust toolchain), supplemented by automated tasks configured via a `justfile`.

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

2. **Shell and KDE Plasma / Wayland Session Integration**:
   - **KDE Plasma / Wayland (`~/.config/environment.d/10-mise.conf`)**: Registers shims path `~/.local/share/mise/shims` in the desktop session so GUI IDEs (VS Code, JetBrains), KRunner, and Dolphin detect Node/Python/Rust automatically.
   - **Shell (`~/.bashrc.d/mise.sh`)**: Loads `eval "$(mise activate bash)"` modularly.
   - **Shell Completions**: Generates native bash completion at `~/.local/share/bash-completion/completions/mise`.

```bash
# Execute via just or script:
./ProgrammingLanguages/mise.sh

# Check tool version status:
./ProgrammingLanguages/mise.sh --status
```

---

## 2. Language Runtimes and SDKs

Once Mise is installed, the following development environments are deployed globally:

### Node.js (`nodejs.sh` and `angular.sh`)
* **Dependencies**: Installs `@development-tools`, `gcc-c++`, `make`, `curl`, and `python3` via DNF5, which are required to build native C++ npm dependencies (`node-gyp`).
* **Dynamic LTS Installation**: Configures the latest active Node.js LTS release globally and prepares Corepack (`pnpm` / `yarn`):
  ```bash
  ./ProgrammingLanguages/nodejs.sh
  # or manually with mise:
  mise use --global node@lts
  ```
* **Corepack**: Natively enables `pnpm` and `yarn` without global package conflicts:
  ```bash
  corepack enable
  ```
* **Angular CLI**: Installs the official Angular CLI globally via Mise:
  ```bash
  mise use --global npm:@angular/cli@latest
  ```

### Python (`python.sh`)
* **Dependencies**: Installs system headers and libraries required to build native C/Rust extensions (`openssl-devel`, `zlib-devel`, `libffi-devel`, `sqlite-devel`, `bzip2-devel`, `readline-devel`).
* **Stable Production Installation (Extended Support)**: Installs the recommended production release with extended bugfix support (3.12/3.13) and updates build tools (`pip`, `setuptools`, `wheel`):
  ```bash
  ./ProgrammingLanguages/python.sh
  # or for a specific release (e.g., 3.13):
  ./ProgrammingLanguages/python.sh --version 3.13
  ```

### .NET SDK (`dotnet.sh`)
* **Dependencies**: Installs `libicu`, `openssl-devel`, `krb5-devel`, and `zlib-devel` for CoreCLR runtime support.
* **LTS Installation**: Installs the official .NET SDK LTS release via Mise (`dotnet@lts` / `dotnet@8`) and disables telemetry:
  ```bash
  ./ProgrammingLanguages/dotnet.sh
  ```

### Gemini CLI (`gemini.sh`)
* **Installation**: Installs the Google Gemini command-line helper interface:
  ```bash
  mise use --global npm:@google/gemini-cli@latest
  ```

---

## 3. Rust Environment (`rust.sh`)

Rust is managed through its official standard toolchain installer **Rustup** tracking the **Stable** channel.

1. **System Build Dependencies**:
   ```bash
   sudo dnf5 install -y @development-tools cmake openssl-devel pkgconf-pkg-config curl lld clang-devel
   ```

2. **Rustup Installer & IDE Components**:
   Downloads the Stable toolchain and adds `rust-analyzer` (LSP), `clippy`, `rustfmt`, and `rust-src`:
   ```bash
   ./ProgrammingLanguages/rust.sh
   ```

3. **KDE Plasma & Shell Session Integration**:
   Registers `~/.cargo/bin` inside `~/.config/environment.d/10-rust.conf` (KDE Wayland session) and `~/.bashrc.d/rust.sh`.

4. **Fast Binary Installer (`cargo-binstall`)**:
   Downloads and integrates `cargo-binstall`, which installs Rust-written CLI tools directly from GitHub pre-compiled binaries instead of compiling them from source locally.

---

## 4. OpenJDK Java (LTS) compatible with AutoFirma (`java.sh`)

Installs Fedora's official OpenJDK LTS package with full compiler support, Apache Maven, NSS tools for AutoFirma/FNMT, and configures the `JAVA_HOME` environment variable across KDE Plasma sessions:
```bash
./ProgrammingLanguages/java.sh
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
