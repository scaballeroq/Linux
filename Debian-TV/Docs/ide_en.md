---
sidebar_position: 5
---

# Integrated Development Environments (IDEs) on Debian 13

This guide details the installation and configuration of the code editors and development environments managed in the `IDE` folder.

The environment covers the modern terminal editor **Neovim** (boosted with LazyVim), the desktop editor **Visual Studio Code**, and developer integrations like **Google Antigravity**.

---

## 1. Neovim and LazyVim (`neovim.sh`)

Installs and configures an ultra-fast, modular terminal editing environment using Neovim and the LazyVim pre-configured layout.

1. **Neovim and Dependency Installation**:
   ```bash
   sudo apt update
   sudo apt install -y neovim gcc make g++ ripgrep fd-find xclip wl-copy git
   ```
   *(Note: C/C++ compilers, ripgrep, and fd are installed since they are essential for fuzzy finders and LSP server operations inside Neovim).*

2. **Command Compatibility Symlinks**:
   Maps `fdfind` (Debian's package binary name) to `fd` in the user's local path:
   ```bash
   mkdir -p ~/.local/bin
   [ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind ~/.local/bin/fd
   ```

3. **LazyVim Deployment**:
   Clones the official starter template to the user's config directory:
   ```bash
   git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
   rm -rf "$HOME/.config/nvim/.git"
   ```

---

## 2. Visual Studio Code (`vscode.sh`)

Automates Visual Studio Code installation directly from Microsoft's official repositories to guarantee secure, automatic updates.

1. **Initial Dependencies**:
   ```bash
   sudo apt update
   sudo apt install -y wget gpg apt-transport-https
   ```

2. **GPG Key Import**:
   ```bash
   wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
   sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
   rm -f packages.microsoft.gpg
   ```

3. **Official Repository Registration**:
   ```bash
   sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
   ```

4. **Installation**:
   ```bash
   sudo apt update
   sudo apt install -y code
   ```

---

## 3. Google Antigravity CLI (`antigravity.sh`)

Installs the corporate AI-assisted coding and developer CLI helper tool for Debian.

1. **Keyring Setup and GPG Import**:
   ```bash
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
   sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
   ```

2. **Google Artifact Registry Repository Registration**:
   ```bash
   echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
   sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null
   ```

3. **Tool Installation**:
   ```bash
   sudo apt update
   sudo apt install -y antigravity
   ```

---

## Verification

To verify that the code editors are working correctly:

- **Neovim**: Run `nvim` in your terminal. On the first launch, it will automatically download and set up the default LazyVim plugins. Once done, you can run `:LazyHealth` to verify language servers (LSPs) and compilers.
- **VS Code**: Run `code` in the terminal or search for "Visual Studio Code" in your desktop application drawer.
- **Antigravity**: Confirm it responds properly by running `antigravity --version` or executing its assigned CLI commands.
