---
sidebar_position: 5
---

# Development Environments & IDEs on Fedora 44 (KDE Plasma 6)

This guide details the developer tools, Artificial Intelligence coding platforms, and version control utilities managed in the `IDE` directory.

All tools are optimized for **Fedora 44**, the **DNF5** package manager, the **Wayland** display server, the **KDE Plasma 6** desktop environment, and the **Bash** shell (with modular support via `~/.bashrc.d/` and `~/.config/environment.d/`).

---

## 1. Google Antigravity Suite

Google Antigravity is the next-generation AI-assisted developer environment and agent orchestration platform.

### Google Antigravity Desktop (`antigravity.sh`)
Installs the Google Antigravity desktop application:
- Deploys into `/opt/antigravity` with `4755` permissions for the Chromium/Electron sandbox (`chrome-sandbox`).
- Verifies native Fedora package dependencies (`nss`, `libdrm`, `mesa-libgbm`, `libsecret`, `python3`).
- Creates desktop launcher (`antigravity.desktop`) and icon in `/usr/share/pixmaps/antigravity.png`.
- Configures contextual integration with **Dolphin** via KIO Servicemenus to open folders with right-click:
  `~/.local/share/kio/servicemenus/open-in-antigravity.desktop`.
- Includes atomic updater `/usr/local/bin/update-antigravity` with `--status`, `--check`, `--force`, and `--uninstall` options.

### Google Antigravity CLI (`antigravity-cli.sh`)
Installs the Antigravity command-line interface (`agy`):
- Rootless installation in `~/.local/bin/agy`.
- Modular shell integration in `~/.bashrc.d/antigravity-cli.sh` and graphical session in `~/.config/environment.d/10-antigravity-cli.conf`.
- CLI commands: `--status`, `--check`, `--update`, `--force`, `--uninstall`.

### Google Antigravity IDE Engine (`antigravity-ide.sh`)
Installs the standalone Antigravity IDE engine:
- Links binaries to `/usr/local/bin/antigravity-ide`.
- KDE Plasma 6 desktop shortcut and Dolphin contextual servicemenu (`~/.local/share/kio/servicemenus/open-in-antigravity-ide.desktop`).
- Configures Nerd Fonts (`JetBrainsMono Nerd Font Mono`) in `settings.json`.

---

## 2. Git & Version Control Tools (`git.sh`)

Installs and optimizes modern Git developer tools on Fedora 44:
- **git**: Core version control system via DNF5.
- **delta** (`git-delta`): Syntax-highlighted diff pager for `git diff` and `git show`.
- **lazygit**: Fast terminal UI (TUI) with Delta pager integration and KDE Breeze Dark theme.
- **github-cli** (`gh`): Official GitHub command-line interface.

Configures recommended global Git settings:
```bash
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global init.defaultBranch "main"
git config --global merge.conflictstyle "zdiff3"
```

---

## 3. OpenCode AI CLI (`opencode.sh`)

Installs the OpenCode AI CLI developer assistant for terminal:
- 100% rootless installation in `~/.opencode/bin/` and symlink in `~/.local/bin/opencode`.
- Modular PATH integration in `~/.bashrc.d/opencode.sh` and Wayland session in `~/.config/environment.d/10-opencode.conf`.
- Supports specific versions (`-v 1.18.32`), latest release (`-l`), and system diagnostics (`--status`).

---

## 4. Native KDE Plasma Text Editors

- **Kate**: Feature-rich advanced text editor with syntax highlighting, embedded terminal, and project management.
- **KWrite**: Fast and lightweight editor for quick edits.
- **Dolphin Integration**: Context menus to open projects directly in Google Antigravity and Antigravity IDE.

---

## 5. IDE Automation with Just

To deploy or manage environments using `just`:

```bash
just ides             # Deploys Antigravity, Antigravity CLI, Antigravity IDE, and OpenCode
just git-setup        # Deploys and configures Git, Delta, Lazygit, and GitHub CLI
just antigravity      # Installs/updates Antigravity Desktop
just antigravity-cli  # Installs/updates Antigravity CLI
just antigravity-ide  # Installs/updates Antigravity IDE Engine
just opencode         # Installs/updates OpenCode AI CLI
```

---

## Verification

To verify all installed tools:

```bash
# Git, Delta, Lazygit, and GitHub CLI
./IDE/git.sh --status

# Antigravity Suite
./IDE/antigravity.sh --status
./IDE/antigravity-cli.sh --status
./IDE/antigravity-ide.sh --status

# OpenCode
./IDE/opencode.sh --status
```
