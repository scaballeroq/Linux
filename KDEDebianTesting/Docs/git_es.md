---
sidebar_position: 4
---

# Configuración de Git en Debian Testing (KDE Plasma 6)

Esta guía detalla el entorno de control de versiones y el conjunto de herramientas optimizadas mediante [`IDE/git.sh`](file:///home/caballero/Workspace/Repositorios/Linux/KDEDebianTesting/IDE/git.sh).

El entorno incluye el cliente **Git**, el formateador visual de diferencias **Git-Delta**, la interfaz de terminal **Lazygit** y la herramienta oficial **GitHub CLI (gh)**.

---

## 1. Automatización de Git (`git.sh`)

1. **Instalación de Git y Git-Delta**:
   ```bash
   sudo apt update
   sudo apt install -y git git-delta
   ```

2. **Configuración Global del Usuario**:
   ```bash
   git config --global user.name "Sergio Caballero"
   git config --global user.email "scaballeroq@gmail.com"
   ```

3. **Buenas Prácticas**:
   - Rama predeterminada: `main` (`init.defaultBranch main`).
   - Sincronización: Rebase por defecto (`pull.rebase true`).
   - Editor: `nvim` o `nano` (`core.editor nvim`).

4. **Resaltado Visual (Git-Delta)**:
   ```bash
   git config --global core.pager "delta"
   git config --global interactive.diffFilter "delta --color-only"
   git config --global delta.navigate true
   git config --global delta.light false
   git config --global merge.conflictstyle zdiff3
   ```

5. **Instalación de Lazygit (TUI)**:
   Instalado automáticamente en `/usr/local/bin` desde la última release oficial de GitHub.

---

## 2. Cliente de GitHub en Consola (`gh`)

Instalación con repositorio oficial de GitHub firmado por clave dearmored en `/etc/apt/keyrings/githubcli-archive-keyring.gpg`:
```bash
sudo apt update
sudo apt install -y gh
```

---

## Verificación

- **Git-Delta**: Ejecuta `git diff`.
- **Lazygit**: Ejecuta `lazygit`.
- **GitHub CLI**: Ejecuta `gh auth status` o `gh auth login`.
