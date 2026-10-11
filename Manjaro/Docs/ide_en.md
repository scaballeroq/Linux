---
sidebar_position: 5
---

# Development Environments (IDEs) on Manjaro Linux

This guide details the installation and setup of editors and development tools located in the `IDE` directory.

---

## 1. Neovim & LazyVim (`neovim.sh`)

Installs Neovim with LazyVim starter config for a terminal-based IDE workflow.

```bash
./IDE/neovim.sh
```

---

## 2. Visual Studio Code (`vscode.sh`)

Installs official VS Code from Microsoft's APT repository.

```bash
./IDE/vscode.sh
```

---

## 3. Google Antigravity Desktop 2.0, CLI & IDE Engine (`antigravity.sh`, `antigravity-cli.sh`, `antigravity-ide.sh`)

Full suite of installation scripts for Google Antigravity:

- **Google Antigravity Desktop 2.0 (`antigravity.sh`)**: Full installer configuring `/opt/antigravity`, `/usr/local/bin/update-antigravity`, desktop application launcher, and Chromium SUID sandbox (`4755`).
- **Google Antigravity CLI (`antigravity-cli.sh`)**: Terminal CLI tool installer.
- **Google Antigravity IDE Engine (`antigravity-ide.sh`)**: Standalone IDE engine installer.

```bash
just antigravity
just antigravity-cli
just antigravity-ide
```

---

## 4. OpenCode AI CLI/Editor (`opencode.sh`)

Automated installer for OpenCode AI tool with version specification (`1.18.13`).

```bash
./IDE/opencode.sh
# Or using just:
just opencode
```
