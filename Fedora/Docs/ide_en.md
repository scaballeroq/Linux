---
sidebar_position: 5
---

# Development Environments (IDEs) & Developer Tools on Fedora 44

This guide details the installation and setup of editors, AI assistants, and developer tools located in the `IDE` directory.

The suite includes **Neovim** (powered by LazyVim), **Visual Studio Code**, **OpenCode AI**, version control utilities (**Git, Delta, GitHub CLI**), and the full **Google Antigravity Desktop 2.0 / CLI / IDE Engine** ecosystem.

---

## 1. Neovim & LazyVim (`IDE/neovim.sh`)

Installs and configures a modular, fast terminal development environment using Neovim and the LazyVim starter distribution:

```bash
./IDE/neovim.sh
# Or using just:
just nvim
```

Installs essential build dependencies (`gcc`, `make`, `g++`, `ripgrep`, `fd-find`, `wl-copy`), clones LazyVim into `~/.config/nvim`, and initializes plugins.

---

## 2. Visual Studio Code (`IDE/vscode.sh`)

Configures Microsoft's official DNF5 RPM repository and installs native Visual Studio Code:

```bash
./IDE/vscode.sh
# Or using just:
just vscode
```

---

## 3. Google Antigravity Desktop 2.0, CLI & IDE (`antigravity.sh`, `antigravity-cli.sh`, `antigravity-ide.sh`)

Complete suite for installing and updating Google Antigravity:

- **Google Antigravity Desktop 2.0 (`antigravity.sh`)**: Full installer configuring Google CDN downloads, `/opt/antigravity`, update helper `/usr/local/bin/update-antigravity`, desktop launcher, high-resolution icon, and SUID `4755` Chromium sandbox.
- **Google Antigravity CLI (`antigravity-cli.sh`)**: Terminal CLI interface installer.
- **Google Antigravity IDE Engine (`antigravity-ide.sh`)**: Standalone IDE engine installer with `/usr/local/bin/update-antigravity-ide`.

```bash
just antigravity      # Install Antigravity Desktop 2.0
just antigravity-cli  # Install Antigravity CLI
just antigravity-ide  # Install Antigravity IDE
```

---

## 4. OpenCode AI CLI/Editor (`IDE/opencode.sh`)

Automated installer for OpenCode AI assistant with support for explicit version pinning or latest stable release:

```bash
./IDE/opencode.sh
# Or specify a version:
./IDE/opencode.sh 1.18.13
# Or using just:
just opencode
```

---

## 5. Version Control with Git & GitHub CLI (`git.sh`, `github-cli.sh`)

Configures Git with Git-Delta diff visualizer (`zdiff3`, side-by-side view), Lazygit, and official GitHub CLI:

```bash
just git-setup
# or ./IDE/git.sh && ./IDE/github-cli.sh
```

---

## 6. Automating All IDEs with Just

To deploy all development environments in a single command:

```bash
just ides
```

---

## Verification

- **Neovim**: Run `nvim` in your terminal. On first launch, LazyVim plugins will download automatically.
- **VS Code**: Run `code` or find it in the KDE Plasma application menu.
- **Google Antigravity**: Run `antigravity` in the terminal or search for "Antigravity" in the application launcher.
- **OpenCode**: Run `opencode --version`.
- **GitHub CLI**: Run `gh --version` and `gh auth login`.
