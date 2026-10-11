---
sidebar_position: 5
---

# Development Environments & Artificial Intelligence (IDEs & AI) on CachyOS

This guide details the installation, configuration, and maintenance of editors, AI-assisted development tools, and utilities located in the `IDE` directory.

The environment is fully optimized for **CachyOS (Arch Linux)** running on top of the **Niri** Wayland compositor with seamless **Zsh** terminal integration.

---

## 1. Google Antigravity Desktop (`antigravity.sh`)

Automates the installation of **Google Antigravity Desktop** (full graphical edition):

1. **Package Dependencies**:
   ```bash
   sudo pacman -Syu --noconfirm --needed ca-certificates curl tar desktop-file-utils python
   ```

2. **Niri and Wayland Integration**:
   - Integrated with `ELECTRON_OZONE_PLATFORM_HINT="auto"` for crisp native Wayland rendering without XWayland fractional blur.
   - Installs the desktop entry at `/usr/share/applications/antigravity.desktop`, fully indexed by the **Noctalia Shell** application launcher.

3. **System Update Helper (`update-antigravity`)**:
   Provides an update helper binary at `/usr/local/bin/update-antigravity`, accessible via terminal alias:
   ```bash
   update-antigravity
   ```

---

## 2. Google Antigravity CLI (`antigravity-cli.sh`)

Installs the Google Antigravity command line interface (`agy`):

1. **Binary Deployment**:
   Downloads and verifies the executable binary in `~/.local/bin/agy`.
2. **Validation**:
   The installer validates executable signatures and functionality:
   ```bash
   agy --version
   agy --help
   ```
3. **Self-Updating**:
   Update the CLI directly using its built-in command:
   ```bash
   agy update
   ```

---

## 3. Google Antigravity IDE Engine (`antigravity-ide.sh`)

Deploys the core Antigravity IDE development engine for CachyOS:

1. **Installation & Symlinks**:
   Configures the engine at `/opt/antigravity-ide` with binary link at `/usr/local/bin/antigravity-ide`.
2. **Update Helper**:
   Installs `/usr/local/bin/update-antigravity-ide` and creates shell shortcuts in `ZSH.Setup`:
   ```bash
   update-antigravity-ide
   ```

---

## 4. OpenCode AI CLI (`opencode.sh`)

Installs the terminal-based coding assistant **OpenCode AI**:

1. **Automated Setup**:
   Fetches and executes the official OpenCode runtime installer:
   ```bash
   curl -fsSL https://opencode.ai/install | bash
   ```
2. **Zsh Integration**:
   Automatically ensures `~/.opencode/bin` is exported to `PATH` in `~/.zshrc`.
3. **Usage**:
   ```bash
   opencode --version
   ```

---

## 5. Modern Git Toolchain (`git.sh`)

Configures an advanced version control stack with Wayland clipboard integration:

1. **Packages**:
   ```bash
   sudo pacman -S --needed --noconfirm git git-delta lazygit github-cli
   ```
2. **Git-Delta**: Side-by-side syntax-highlighted diffs with line numbering and `zdiff3` conflict visualizer.
3. **Lazygit**: Fast terminal UI for Git repository management.
4. **Wayland Clipboard**: Native `wl-copy` support for copying commit SHAs and patches directly to clipboard.

---

## 6. Automation via `justfile`

Run any recipe from the repository root:

```bash
just antigravity        # Antigravity Desktop GUI
just antigravity-cli    # Antigravity CLI (agy)
just antigravity-ide    # Antigravity IDE Engine
just opencode           # OpenCode AI CLI
just git-setup          # Git + Delta + Lazygit + GH CLI
just ides               # Install all IDEs and AI tools
```

---

## Verification

- **Antigravity Desktop**: Launch from Noctalia launcher (`Super` key) or run `antigravity &`.
- **Antigravity CLI**: Verify with `agy --version`.
- **OpenCode**: Check with `opencode --help`.
- **Git**: Verify with `git --version` and `lazygit`.
