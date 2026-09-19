---
sidebar_position: 4
---

# Configuración de Git y Control de Versiones en Fedora 44

Esta guía detalla el entorno de control de versiones y el conjunto de herramientas optimizadas ubicadas en [`IDE/git.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora/IDE/git.sh) e [`IDE/github-cli.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora/IDE/github-cli.sh).

El entorno incluye el cliente clásico **Git**, el formateador visual de diferencias **Git-Delta**, la interfaz de terminal interactiva **Lazygit** y la herramienta oficial **GitHub CLI (gh)**.

---

## 1. Automatización de Git, Delta y Lazygit (`IDE/git.sh`)

El script principal automatiza la instalación y define las mejores prácticas de control de versiones:

1. **Instalación de Git y Git-Delta**:
   ```bash
   sudo dnf5 install -y git git-delta
   ```

2. **Configuración Global del Usuario**:
   ```bash
   git config --global user.name "Sergio Caballero"
   git config --global user.email "scaballeroq@gmail.com"
   ```

3. **Mejores Prácticas Modernas**:
   - Rama predeterminada: `develop` (`init.defaultBranch develop`).
   - Sincronización limpia: Rebase por defecto al hacer pull (`pull.rebase true`).
   - Editor por defecto: `nvim` (`core.editor nvim`).

4. **Resaltado Visual Mejorado (Git-Delta)**:
   Reemplaza el paginador nativo activando colores semánticos, navegación intuitiva, números de línea, vista lado a lado y visualización mejorada de conflictos (`zdiff3`):
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
   Instala automáticamente Lazygit mediante el repositorio COPR oficial o desde el binario compilado de GitHub releases:
   ```bash
   sudo dnf5 copr enable -y dejan/lazygit
   sudo dnf5 install -y lazygit
   ```

---

## 2. Cliente de GitHub en Consola (`IDE/github-cli.sh`)

Instala la herramienta oficial de GitHub (`gh`) vía DNF5 para gestionar repositorios, Pull Requests, Issues y secretos desde la terminal:

```bash
sudo dnf5 install -y gh
```

Para autenticarte con tu cuenta de GitHub:
```bash
gh auth login
```

---

## 3. Automatización con Just

Para desplegar todo el entorno de Git en un solo comando:

```bash
just git-setup
# o ./IDE/git.sh && ./IDE/github-cli.sh
```

---

## Verificación

- **Git-Delta**: Ejecuta `git diff` en cualquier repositorio con cambios locales para verificar la vista lado a lado y colores.
- **Lazygit**: Ejecuta `lazygit` dentro de un repositorio para abrir la interfaz interactiva.
- **GitHub CLI**: Ejecuta `gh status` o `gh repo list` para verificar tu sesión autenticada.
