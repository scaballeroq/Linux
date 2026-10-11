---
sidebar_position: 4
---

# Git & Version Control Configuration on Fedora 44

This guide details the version control environment and optimized toolchain configured in [IDE/git.sh](../IDE/git.sh).

The environment includes the standard **Git** client, the **Git-Delta** visual diff tool, the **Lazygit** terminal UI, and the official **GitHub CLI (gh)** unified into a single setup script.

---

## 1. Unified Automation (`git.sh`)

The main script automates installation via DNF5 and establishes modern version control best practices:

1. **Package Installation**:
   ```bash
   sudo dnf5 install -y git git-delta gh
   # Lazygit via COPR or official release binary:
   sudo dnf5 copr enable -y dejan/lazygit && sudo dnf5 install -y lazygit
   ```

2. **Global User Configuration**:
   ```bash
   git config --global user.name "Sergio Caballero"
   git config --global user.email "scaballeroq@gmail.com"
   ```

3. **Modern Best Practices**:
   - Default branch: `main` (`init.defaultBranch main`).
   - Clean synchronization: Default to rebase on pull (`pull.rebase true`).
   - Safe rebase: Automatic stash before rebase (`rebase.autoStash true`).
   - Seamless push: Automatically set upstream on push (`push.autoSetupRemote true`).
   - Clean stale remotes: `fetch.prune true`.
   - Default editor: Smart detection (`nvim` -> `micro` -> `vim` -> `nano`).
   - Branch ordering: Sorted by most recent commit date (`branch.sort -committerdate`).

4. **Visual Highlighting (Git-Delta)**:
   Enhances terminal diff readability by replacing the default pager with semantic coloring, side-by-side view, line numbers, hyperlinks, and improved conflict display (`zdiff3`):
   ```bash
   git config --global core.pager "delta"
   git config --global interactive.diffFilter "delta --color-only"
   git config --global delta.navigate true
   git config --global delta.light false
   git config --global delta.side-by-side true
   git config --global delta.line-numbers true
   git config --global delta.hyperlinks true
   git config --global merge.conflictstyle zdiff3
   ```

5. **GitHub CLI (`gh`)**:
   Sets SSH as default git protocol and configures the preferred editor:
   ```bash
   gh config set editor "$DEFAULT_EDITOR"
   gh config set git_protocol ssh
   ```

---

## 2. Automation with Just

To deploy the entire version control toolchain with a single command:

```bash
just git-setup
```

---

## Verification

To verify that the Git environment and its associated tools are properly configured:

- **Git-Delta**: Run `git diff` in any repository with local changes to see side-by-side formatted diffs.
- **Lazygit**: Run `lazygit` inside any Git repository to launch the terminal UI.
- **GitHub CLI**: Run `gh auth status` or `gh auth login` to authenticate with your GitHub account.
