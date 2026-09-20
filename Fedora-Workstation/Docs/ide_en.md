---
sidebar_position: 5
---

# Development Environments and IDEs on Fedora 44

This guide details the developer tools, AI coding assistants, and version control utilities managed in the `IDE` folder.

All tools are optimized for **Fedora 44 Workstation**, the **Wayland** display server, the **GNOME** desktop environment, and **Bash** (default) and **Zsh** (compatible if `~/.zshrc` exists) shells.

---

## 1. Google Antigravity Suite

Google Antigravity is an AI-assisted agentic software development environment.

### Google Antigravity Desktop (`antigravity.sh`)
Installs the Google Antigravity desktop application:
- Deploys to `/opt/antigravity` with SUID `4755` Chromium sandbox permissions.
- Creates the desktop launcher entry (`antigravity.desktop`).
- Sets up native **Nautilus** context menu integration: right-click script to open any folder with Antigravity (`~/.local/share/nautilus/scripts/Abrir con Antigravity`).

### Google Antigravity CLI (`antigravity-cli.sh`)
Installs the Antigravity command-line tool (`agy`), enabling agents, workflows, and terminal operations.

### Google Antigravity IDE Engine (`antigravity-ide.sh`)
Installs the standalone Antigravity IDE engine, symlinks binaries, and configures the Nautilus context script (`Abrir con Antigravity IDE`).

---

## 2. Git Version Control Tools (`git.sh`)

Installs and optimizes the modern Git ecosystem on Fedora 44:
- **git**: Core version control system via DNF5.
- **delta** (`git-delta`): Modern syntax-highlighting pager for `git diff` and `git show`.
- **lazygit**: Terminal UI (TUI) for interactive Git workflows (installed via COPR or official release binary).
- **github-cli** (`gh`): Official GitHub command-line tool.

Configures recommended global Git settings:
```bash
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global init.defaultBranch "main"
```

---

## 3. OpenCode AI CLI (`opencode.sh`)

Installs the OpenCode AI terminal tool, providing CLI-based AI coding assistance with automated PATH configuration for Bash and Zsh.

---

## Verification

To verify that the tools are properly installed:

```bash
# Git, Delta, Lazygit and GitHub CLI
git --version
delta --version
lazygit --version
gh --version

# Antigravity CLI
agy --version 2>/dev/null || antigravity --version

# OpenCode
opencode --version 2>/dev/null || true
```
