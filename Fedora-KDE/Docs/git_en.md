---
sidebar_position: 4
---

# Git & Version Control Setup on Fedora 44 (KDE Plasma 6)

This guide details the version control environment and tools optimized via [`IDE/git.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora-KDE/IDE/git.sh).

The toolchain includes **Git**, **Git-Delta** visual diff pager, **Lazygit** interactive TUI, and the official **GitHub CLI (gh)**.

---

## 1. Automated Git Setup (`git.sh`)

1. **Git & Git-Delta Installation**:
   ```bash
   sudo dnf5 install -y git git-delta
   ```

2. **Global User Configuration**:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your_email@example.com"
   ```

3. **Modern Best Practices**:
   - Default initial branch: `main` (`init.defaultBranch main`).
   - Clean syncing: Default pull rebase (`pull.rebase true`).
   - Editor: intelligent detection of `nvim`, `kate`, `micro`, or `nano`.
   - Advanced conflict styling: `merge.conflictstyle zdiff3`.

4. **Enhanced Visual Highlighting (Git-Delta)**:
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
   Installs Lazygit via Fedora / COPR repositories (`dejan/lazygit`) with automatic fallback to GitHub releases. It automatically configures the KDE Breeze Dark theme (`~/.config/lazygit/config.yml`).

---

## 2. GitHub Command-Line Interface (`gh`)

Native installation via Fedora official repositories using DNF5:
```bash
sudo dnf5 install -y gh
```

To authenticate with your GitHub account:
```bash
gh auth login
```

---

## 3. Automation with Just

To deploy and verify the entire Git toolchain in a single step:
```bash
just git-setup
# or ./IDE/git.sh --status
```

---

## Verification

- **Git-Delta**: Run `git diff`.
- **Lazygit**: Run `lazygit`.
- **GitHub CLI**: Run `gh auth status` or `gh auth login`.
