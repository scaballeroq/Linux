---
sidebar_position: 5
---

# Development Environments and IDEs on Debian Testing

This guide details the developer tools, Artificial Intelligence platforms, and version control utilities managed in the `IDE` directory.

All tools are tailored for **Debian Testing (Trixie/Sid)**, **Wayland**, **KDE Plasma 6**, and **Bash** (default) / **Zsh** (compatible if `~/.zshrc` exists).

---

## 1. Google Antigravity Suite

Google Antigravity is the next-generation AI coding environment and pair-programming assistant.

### Google Antigravity Desktop (`antigravity.sh`)
Installs the Google Antigravity desktop application:
- Installs to `/opt/antigravity` with SUID `4755` permissions for the Chromium/Electron sandbox (`chrome-sandbox`).
- Ensures required system libraries (`libnss3`, `libgbm1`, `libasound2t64`, etc.).
- Creates desktop launcher (`antigravity.desktop`) and icon in `/usr/share/pixmaps/antigravity.png`.
- Configures **Dolphin** integration via KIO Servicemenus for right-click folder opening:
  `~/.local/share/kio/servicemenus/open-in-antigravity.desktop`.

### Google Antigravity CLI (`antigravity-cli.sh`)
Installs the Antigravity command-line interface (`agy`), allowing fast terminal task invocation and workflow management.

### Google Antigravity IDE Engine (`antigravity-ide.sh`)
Installs the standalone Antigravity IDE engine, registering system shortcuts, binaries, and Dolphin contextual menus (`~/.local/share/kio/servicemenus/open-in-antigravity-ide.desktop`).

---

## 2. Git Version Control Toolchain (`git.sh`)

Deploys and tunes modern Git tooling on Debian Testing:
- **git**: Core version control via APT.
- **delta** (`git-delta`): Modern visual syntax highlighter for `git diff` and `git show`.
- **lazygit**: Terminal UI for interactive Git workflows.
- **github-cli** (`gh`): Official GitHub command-line interface.

Applies recommended global settings:
```bash
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global init.defaultBranch "main"
```

---

## 3. OpenCode AI CLI (`opencode.sh`)

Installs the OpenCode AI CLI assistant for terminal sessions, integrating LLM completions and shell toolchains.

---

## 4. KDE Plasma Native Editors

- **Kate**: Feature-rich editor with syntax highlighting, project support, and integrated terminal.
- **KWrite**: Lightweight text editor for quick edits.
- **Dolphin Integration**: Contextual actions to open projects in Google Antigravity.

---

## Verification

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
