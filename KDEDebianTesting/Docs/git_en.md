---
sidebar_position: 4
---

# Git Configuration on Debian Testing (KDE Plasma 6)

This guide details the version control environment and developer toolchain optimized via [`IDE/git.sh`](file:///home/caballero/Workspace/Repositorios/Linux/KDEDebianTesting/IDE/git.sh).

The environment incorporates **Git**, the visual diff syntax-highlighter **Git-Delta**, the terminal user interface **Lazygit**, and the official **GitHub CLI (gh)**.

---

## 1. Git Automation (`git.sh`)

1. **Git and Git-Delta Installation**:
   ```bash
   sudo apt update
   sudo apt install -y git git-delta
   ```

2. **Global User Configuration**:
   ```bash
   git config --global user.name "Sergio Caballero"
   git config --global user.email "scaballeroq@gmail.com"
   ```

3. **Best Practices**:
   - Default branch: `main` (`init.defaultBranch main`).
   - Clean synchronization: Rebase on pull (`pull.rebase true`).
   - Default editor: `nvim` or `nano` (`core.editor nvim`).

4. **Visual Enhancements (Git-Delta)**:
   ```bash
   git config --global core.pager "delta"
   git config --global interactive.diffFilter "delta --color-only"
   git config --global delta.navigate true
   git config --global delta.light false
   git config --global merge.conflictstyle zdiff3
   ```

5. **Lazygit (TUI) Installation**:
   Installed automatically to `/usr/local/bin` from official GitHub releases.

---

## 2. GitHub CLI (`gh`)

Installed via official GitHub APT repository signed by dearmored keyring in `/etc/apt/keyrings/githubcli-archive-keyring.gpg`:
```bash
sudo apt update
sudo apt install -y gh
```

---

## Verification

- **Git-Delta**: Run `git diff`.
- **Lazygit**: Run `lazygit`.
- **GitHub CLI**: Run `gh auth status` or `gh auth login`.
