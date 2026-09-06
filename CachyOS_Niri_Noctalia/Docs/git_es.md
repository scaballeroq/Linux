---
sidebar_position: 4
---

# Configuración de Git en CachyOS

Esta guía detalla el entorno de control de versiones y el conjunto de herramientas optimizadas en [IDE/git.sh](../IDE/git.sh).

El entorno incluye el cliente clásico **Git**, el formateador visual de diferencias **Git-Delta**, la interfaz interactiva de terminal **Lazygit** y la utilidad oficial **GitHub CLI (gh)** unificados en un único script de instalación.

---

## 1. Automatización Integral (`git.sh`)

El script principal automatiza la instalación vía `pacman` y define las mejores prácticas de control de versiones:

1. **Instalación de Paquetes**:
   ```bash
   sudo pacman -S --needed --noconfirm git git-delta lazygit github-cli
   ```

2. **Configuración Global del Usuario**:
   ```bash
   git config --global user.name "Sergio Caballero"
   git config --global user.email "scaballeroq@gmail.com"
   ```

3. **Buenas Prácticas Modernas**:
   - Rama predeterminada: `main` (`init.defaultBranch main`).
   - Sincronización limpia: Rebase por defecto al hacer pull (`pull.rebase true`).
   - Rebase seguro: Auto-stash antes de rebasear (`rebase.autoStash true`).
   - Publicación ágil: Configurar remoto automáticamente al hacer push (`push.autoSetupRemote true`).
   - Limpieza de ramas remotas eliminadas: `fetch.prune true`.
   - Editor por defecto: `nvim` (`core.editor nvim`).
   - Ordenación de ramas: Por fecha del último commit (`branch.sort -committerdate`).

4. **Resaltado Visual (Git-Delta)**:
   Mejora la legibilidad de las diferencias en consola reemplazando el paginador nativo y activando colores semánticos, navegación intuitiva y visualización mejorada de conflictos (`zdiff3`):
   ```bash
   git config --global core.pager "delta"
   git config --global interactive.diffFilter "delta --color-only"
   git config --global delta.navigate true
   git config --global delta.light false
   git config --global delta.side-by-side true
   git config --global delta.line-numbers true
   git config --global merge.conflictstyle zdiff3
   ```

5. **GitHub CLI (`gh`)**:
   Configura el protocolo SSH y Neovim como editor predeterminado:
   ```bash
   gh config set editor nvim
   gh config set git_protocol ssh
   ```

---

## Verificación

Para verificar que el entorno de Git y sus herramientas asociadas estén correctamente configurados:

- **Git-Delta**: Ejecuta `git diff` en cualquier repositorio con cambios locales. Deberías ver las diferencias formateadas con números de línea y colores provistos por Delta.
- **Lazygit**: Ejecuta `lazygit` dentro de un repositorio de Git para abrir la interfaz de terminal.
- **GitHub CLI**: Ejecuta `gh auth status` o `gh auth login` para iniciar sesión con tu cuenta de GitHub.
