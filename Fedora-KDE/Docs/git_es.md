---
sidebar_position: 4
---

# Configuración de Git en Fedora 44 (KDE Plasma 6)

Esta guía detalla el entorno de control de versiones y el conjunto de herramientas optimizadas mediante [`IDE/git.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora-KDE/IDE/git.sh).

El entorno incluye el cliente **Git**, el formateador visual de diferencias **Git-Delta**, la interfaz de terminal interactiva **Lazygit** y la herramienta oficial **GitHub CLI (gh)**.

---

## 1. Automatización de Git (`git.sh`)

1. **Instalación de Git y Git-Delta**:
   ```bash
   sudo dnf5 install -y git git-delta
   ```

2. **Configuración Global del Usuario**:
   ```bash
   git config --global user.name "Tu Nombre"
   git config --global user.email "tu_email@ejemplo.com"
   ```

3. **Buenas Prácticas Modernas**:
   - Rama predeterminada: `main` (`init.defaultBranch main`).
   - Sincronización limpia: Rebase por defecto (`pull.rebase true`).
   - Editor: detección inteligente de `nvim`, `kate`, `micro` o `nano`.
   - Resolución de conflictos avanzada: `merge.conflictstyle zdiff3`.

4. **Resaltado Visual (Git-Delta)**:
   ```bash
   git config --global core.pager "delta"
   git config --global interactive.diffFilter "delta --color-only"
   git config --global delta.navigate true
   git config --global delta.light false
   git config --global delta.side-by-side true
   git config --global delta.line-numbers true
   git config --global merge.conflictstyle zdiff3
   ```

5. **Instalación de Lazygit (TUI)**:
   Instalado mediante los repositorios de Fedora / COPR (`dejan/lazygit`), con fallback automático a la release oficial de GitHub si fuera necesario. Se configura automáticamente con tema KDE Breeze Dark (`~/.config/lazygit/config.yml`).

---

## 2. Cliente de GitHub en Consola (`gh`)

Instalación nativa con repositorios oficiales de Fedora vía DNF5:
```bash
sudo dnf5 install -y gh
```

Para autenticarte con tu cuenta de GitHub:
```bash
gh auth login
```

---

## 3. Automatización con Just

Para desplegar y verificar todo el entorno de Git en un solo comando:
```bash
just git-setup
# o ./IDE/git.sh --status
```

---

## Verificación

- **Git-Delta**: Ejecuta `git diff`.
- **Lazygit**: Ejecuta `lazygit`.
- **GitHub CLI**: Ejecuta `gh auth status` o `gh auth login`.
