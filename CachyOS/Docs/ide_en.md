---
sidebar_position: 5
---

# Development Environments and IDEs on CachyOS

This guide details the developer tools, AI coding assistants, and version control utilities managed in the `IDE` folder.

All tools are optimized for **CachyOS**, the **Wayland** display server, the **GNOME** desktop environment, and **Zsh** and **Bash** shells.

---

## 1. Google Antigravity Suite

Google Antigravity is an AI-assisted agentic software development environment.

### Google Antigravity Desktop (`antigravity.sh`)
Installs the Google Antigravity desktop application:
- Creates the desktop entry (`antigravity.desktop`).
- Sets up native **Nautilus** context menu integration: right-click script to open any folder with Antigravity (`~/.local/share/nautilus/scripts/Abrir con Antigravity`).

### Google Antigravity CLI (`antigravity-cli.sh`)
Installs the Antigravity command-line tool (`agy`), enabling agents, workflows, and terminal workflows.

### Google Antigravity IDE Engine (`antigravity-ide.sh`)
Installs the Antigravity IDE engine, symlinks binaries, and configures the Nautilus context script (`Abrir con Antigravity IDE`).

---

## 2. Git Version Control Tools (`git.sh`)

Installs and optimizes the modern Git ecosystem on CachyOS:
- **git**: Core version control system.
- **delta** (`git-delta`): Modern syntax-highlighting pager for `git diff` and `git show`.
- **lazygit**: Terminal UI (TUI) for Git workflows.
- **github-cli** (`gh`): Official GitHub command-line tool.

Configures recommended global Git settings:
```bash
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global init.defaultBranch "main"
```

---

## 3. OpenCode AI CLI (`opencode.sh`)

Installs the OpenCode AI terminal tool, providing CLI-based AI coding assistance.

---

## Verification

To verify that the tools are properly installed:

```bash
# Git and Delta
git --version
delta --version
lazygit --version
gh --version

# Antigravity CLI
agy --version 2>/dev/null || antigravity --version

# OpenCode
opencode --version 2>/dev/null || true
```
