---
sidebar_position: 5
---

# Development Environments & IDEs in openSUSE Tumbleweed

This guide details development tools, AI-assisted platforms, and version control utilities managed in the `IDE/` folder.

All tools are optimized for **openSUSE Tumbleweed**, **Wayland**, **KDE Plasma 6**, and both **Bash** (default) and **Zsh** (compatible if `~/.zshrc` exists).

---

## 1. Google Antigravity Suite

Google Antigravity is the next-generation AI-assisted development and coding platform.

### Google Antigravity Desktop (`antigravity.sh`)
Installs the Google Antigravity desktop application:
- Deploys to `/opt/antigravity` with `4755` permissions for the Chromium/Electron sandbox.
- Creates desktop entry (`antigravity.desktop`) and icon in `/usr/share/pixmaps/antigravity.png`.
- Configures contextual integration with **Dolphin** via KIO Servicemenus to open folders directly:
  `~/.local/share/kio/servicemenus/open-in-antigravity.desktop`.

### Google Antigravity CLI (`antigravity-cli.sh`)
Installs the command-line interface (`agy`), allowing seamless invocation of agents, workflows, and terminal coding tasks.

### Google Antigravity IDE Engine (`antigravity-ide.sh`)
Installs the standalone Antigravity IDE engine, linking binaries, the KDE Plasma launcher, and the contextual Dolphin servicemenu (`~/.local/share/kio/servicemenus/open-in-antigravity-ide.desktop`).

---

## 2. Git Version Control Tools (`git.sh`)

Installs and optimizes modern Git tooling in openSUSE Tumbleweed:
- **git**: Distributed version control via Zypper.
- **delta** (`git-delta`): Syntax-highlighting pager for `git diff` and `git show`.
- **lazygit**: Interactive terminal UI (TUI) for Git workflows.
- **github-cli** (`gh`): Official GitHub command-line client.

Configures recommended global options:
```bash
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global init.defaultBranch "main"
```

---

## 3. OpenCode AI CLI (`opencode.sh`)

Installs the OpenCode AI CLI assistant for terminal workflows, providing LLM-driven coding support and configuring the `PATH` across Bash and Zsh.

---

## 4. Native KDE Plasma Text Editors

- **Kate**: Feature-packed text editor with syntax highlighting, embedded terminal, and project management.
- **KWrite**: Fast and lightweight text editor for quick edits and notes.
- **Dolphin Integration**: Contextual menus to open projects directly in Google Antigravity.

---

## Verification

To check tool status:

```bash
# Git, Delta, Lazygit, and GitHub CLI
git --version
delta --version
lazygit --version
gh --version

# Antigravity CLI
agy --version 2>/dev/null || antigravity --version

# OpenCode
opencode --version 2>/dev/null || true
```
