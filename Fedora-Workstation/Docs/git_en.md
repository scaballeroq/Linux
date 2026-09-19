---
sidebar_position: 4
---

# Git & Version Control Setup on Fedora 44

This guide details the version control environment and tools located in [`IDE/git.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora/IDE/git.sh) and [`IDE/github-cli.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora/IDE/github-cli.sh).

The toolchain includes **Git**, **Git-Delta** visual diff pager, **Lazygit** interactive TUI, and the official **GitHub CLI (gh)**.

---

## 1. Automated Git, Delta & Lazygit Setup (`IDE/git.sh`)

Automates installation and best-practice configurations:

1. **Git & Git-Delta Installation**:
   ```bash
   sudo dnf5 install -y git git-delta
   ```

2. **Global User Configuration**:
   ```bash
   git config --global user.name "Sergio Caballero"
   git config --global user.email "scaballeroq@gmail.com"
   ```

3. **Modern Best Practices**:
   - Default initial branch: `develop` (`init.defaultBranch develop`).
   - Clean syncing: Default pull rebase (`pull.rebase true`).
   - Default core editor: `nvim` (`core.editor nvim`).

4. **Enhanced Visual Highlighting (Git-Delta)**:
   Replaces the native diff pager with semantic syntax highlighting, side-by-side view, line numbers, and 3-way conflict styling (`zdiff3`):
   ```bash
   git config --global core.pager "delta"
   git config --global interactive.diffFilter "delta --color-only"
   git config --global delta.navigate true
   git config --global delta.light false
   git config --global delta.side-by-side true
   git config --global delta.line-numbers true
   git config --global merge.conflictstyle zdiff3
   ```

5. **Lazygit TUI Installation**:
   Installs Lazygit via Fedora COPR or precompiled GitHub releases:
   ```bash
   sudo dnf5 copr enable -y dejan/lazygit
   sudo dnf5 install -y lazygit
   ```

---

## 2. GitHub Command-Line Interface (`IDE/github-cli.sh`)

Installs the official GitHub CLI (`gh`) via DNF5 to manage repositories, Pull Requests, Issues, and secrets from the terminal:

```bash
sudo dnf5 install -y gh
```

To authenticate with your GitHub account:
```bash
gh auth login
```

---

## 3. Automation with Just

To deploy the entire Git setup in a single step:

```bash
just git-setup
# or ./IDE/git.sh && ./IDE/github-cli.sh
```

---

## Verification

- **Git-Delta**: Run `git diff` on any repository with unstaged changes to verify the side-by-side visual diff.
- **Lazygit**: Run `lazygit` inside a repository to open the terminal GUI.
- **GitHub CLI**: Run `gh status` or `gh repo list` to check your authenticated session.
