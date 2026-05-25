---
sidebar_position: 4
---

# Git Configuration on Kubuntu

This guide details the version control environment and optimized tools configured via the scripts in the `Git` folder.

The environment includes the classic **Git** client, the **Git-Delta** syntax-highlighting diff pager, the **Lazygit** terminal UI, and the official **GitHub CLI (gh)** utility.

---

## 1. Git Automation (`git.sh`)

The main Git script automates installation and defines version control best practices:

1. **Git and Git-Delta Installation**:
   ```bash
   sudo apt update
   sudo apt install -y git git-delta
   ```

2. **Global User Settings**:
   ```bash
   git config --global user.name "Sergio Caballero"
   git config --global user.email "scaballeroq@gmail.com"
   ```

3. **Modern Best Practices**:
   - Default branch: `main` (`init.defaultBranch main`).
   - Clean syncing: Rebase by default on pull (`pull.rebase true`).
   - Default editor: `nvim` (`core.editor nvim`).

4. **Visual Enhancements (Git-Delta)**:
   Significantly improves diff readability in the console by replacing the native pager, activating semantic colors, simple navigation, and enhanced conflict styles (`zdiff3`):
   ```bash
   git config --global core.pager "delta"
   git config --global interactive.diffFilter "delta --color-only"
   git config --global delta.navigate true
   git config --global delta.light false
   git config --global merge.conflictstyle zdiff3
   ```

5. **Lazygit Installation (TUI)**:
   If not already present in `/usr/local/bin`, the script automatically downloads and installs the latest pre-compiled binary from GitHub:
   ```bash
   LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
   curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
   tar xf lazygit.tar.gz lazygit
   sudo install lazygit /usr/local/bin
   rm lazygit lazygit.tar.gz
   ```

---

## 2. Console GitHub Client (`github-cli.sh`)

Installs the official GitHub console tool (`gh`) that allows you to manage repositories, Pull Requests, Issues, and secrets directly from the terminal.

1. **Dependencies and Official Repository GPG Key**:
   ```bash
   sudo apt update
   sudo apt install -y curl gpg
   sudo mkdir -p -m 755 /etc/apt/keyrings
   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
   sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
   ```

2. **GitHub Repository Registration**:
   ```bash
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
   ```

3. **Installation**:
   ```bash
   sudo apt update
   sudo apt install -y gh
   ```

---

## Verification

To verify that the Git environment and its associated tools are properly configured:

- **Git-Delta**: Run `git diff` inside any repository with local changes. You should see the differences formatted with line numbers and Delta's aesthetic colors.
- **Lazygit**: Run `lazygit` inside a Git repository. The interactive TUI panel should open.
- **GitHub CLI**: Run `gh --version` to check its installation. To authenticate your GitHub account, start the interactive setup via `gh auth login`.
