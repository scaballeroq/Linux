---
sidebar_position: 4
---

# Git Configuration in OpenSUSE Tumbleweed

This guide details version control tools in `Git/` including **Git**, **Git-Delta**, **Lazygit**, and **GitHub CLI (gh)**.

---

## 1. Git Automation (`git.sh`)

Installs Git, sets up Delta pager, global author configuration, and installs Lazygit:

```bash
just git-setup
```

---

## 2. GitHub CLI (`github-cli.sh`)

Installed natively via Zypper:
```bash
sudo zypper install -y gh
```
