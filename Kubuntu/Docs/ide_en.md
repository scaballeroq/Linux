---
title: Development Environments (IDEs)
sidebar_position: 5
---

# Development Environments (IDEs) in Kubuntu

This guide details the installation and configuration of editors and integrated development environments located in the `IDE` directory.

The environment covers the modern terminal editor **Neovim** (powered by LazyVim), the desktop editor **Visual Studio Code**, the AI client **OpenCode**, and the full suite of **Google Antigravity Desktop / CLI / IDE Engine**.

---

## 1. Neovim + LazyVim (`neovim.sh`)

Installs and configures an ultra-fast, modular editing environment in the terminal using Neovim and the pre-configured LazyVim distribution.

1. **Neovim and Dependencies Installation**:
   ```bash
   sudo apt update
   sudo apt install -y neovim gcc make g++ ripgrep fd-find xclip wl-copy git
   ```

2. **Command Compatibility**:
   Ensures `fdfind` is mapped to `fd` in the user's local bin path:
   ```bash
   mkdir -p ~/.local/bin
   [ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind ~/.local/bin/fd
   ```

3. **Deploy LazyVim**:
   Clones the official starter template to the user configuration directory:
   ```bash
   git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
   rm -rf "$HOME/.config/nvim/.git"
   ```

---

## 2. Visual Studio Code (`vscode.sh`)

Automates the installation of Visual Studio Code from official Microsoft repositories to guarantee secure automatic updates.

1. **Prerequisites**:
   ```bash
   sudo apt update
   sudo apt install -y wget gpg apt-transport-https
   ```

2. **Import GPG Key**:
   ```bash
   wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
   sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
   rm -f packages.microsoft.gpg
   ```

3. **Register Official Repository**:
   ```bash
   sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
   ```

4. **Installation**:
   ```bash
   sudo apt update
   sudo apt install -y code
   ```

---

## 3. Google Antigravity Desktop, CLI & IDE (`antigravity.sh`, `antigravity-cli.sh`, `antigravity-ide.sh`)

Complete scripts for installing and updating the Google Antigravity AI development platform:

- **Google Antigravity Desktop (`antigravity.sh`)**: Quick installer via Google Artifact Registry official repository or helper.
- **Google Antigravity CLI (`antigravity-cli.sh`)**: Terminal CLI (`agy`) installer with integrity checks and `update-antigravity-cli` helper.
- **Google Antigravity IDE Engine (`antigravity-ide.sh`)**: Standalone IDE engine installer with Chromium sandbox configuration and `update-antigravity-ide` helper.

```bash
just antigravity
just antigravity-cli
just antigravity-ide
```

---

## 4. OpenCode AI CLI/Editor (`opencode.sh`)

Automated installation of OpenCode AI client with explicit version support (e.g. `v1.18.13`).

```bash
./IDE/opencode.sh
# Or specify a version:
./IDE/opencode.sh 1.18.13
# Or using just:
just opencode
```

---

## Verification

To check proper functionality:

- **Neovim**: Run `nvim` in your terminal (or Konsole). On first launch, LazyVim plugins will download automatically. Run `:LazyHealth` to check LSP health.
- **VS Code**: Run `code` or open it from the KDE Plasma application launcher.
- **Google Antigravity**: Run `antigravity` or `agy --version`.
- **OpenCode**: Run `opencode --version`.
