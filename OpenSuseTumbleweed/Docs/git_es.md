---
sidebar_position: 4
---

# Configuración de Git en OpenSUSE Tumbleweed

Esta guía detalla el entorno de control de versiones y el conjunto de herramientas optimizadas mediante `IDE/git.sh`.

El entorno incluye el cliente **Git**, el formateador visual de diferencias **Git-Delta**, la interfaz de terminal **Lazygit** y la herramienta oficial **GitHub CLI (gh)**.

---

## 1. Automatización de Git (`git.sh`)

1. **Instalación de Git y Git-Delta**:
   ```bash
   sudo zypper install -y git git-delta
   ```

2. **Configuración Global del Usuario**:
   ```bash
   git config --global user.name "Sergio Caballero"
   git config --global user.email "scaballeroq@gmail.com"
   ```

3. **Buenas Prácticas**:
   - Rama predeterminada: `main` (`init.defaultBranch main`).
   - Sincronización: Rebase por defecto (`pull.rebase true`).
   - Editor: `nvim` (`core.editor nvim`).

4. **Resaltado Visual (Git-Delta)**:
   ```bash
   git config --global core.pager "delta"
   git config --global interactive.diffFilter "delta --color-only"
   git config --global delta.navigate true
   git config --global delta.light false
   git config --global merge.conflictstyle zdiff3
   ```

5. **Instalación de Lazygit (TUI)**:
   Instalado automáticamente en `/usr/local/bin`.

---

## 2. Cliente de GitHub en Consola (`github-cli.sh`)

Instalación nativa vía Zypper:
```bash
sudo zypper install -y gh
```

---

## Verificación

- **Git-Delta**: Ejecuta `git diff`.
- **Lazygit**: Ejecuta `lazygit`.
- **GitHub CLI**: Ejecuta `gh auth status`.
