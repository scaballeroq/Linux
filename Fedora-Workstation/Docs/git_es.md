---
sidebar_position: 4
---

# Configuración de Git en Fedora 44

Esta guía detalla el entorno de control de versiones y el conjunto de herramientas optimizadas en [IDE/git.sh](../IDE/git.sh).

El entorno incluye el cliente clásico **Git**, el formateador visual de diferencias **Git-Delta**, la interfaz interactiva de terminal **Lazygit** y la utilidad oficial **GitHub CLI (gh)** unificados en un único script de instalación.

---

## 1. Automatización Integral (`git.sh`)

El script principal automatiza la instalación y define las mejores prácticas de control de versiones:

1. **Instalación de Paquetes**:
   ```bash
   sudo dnf5 install -y git git-delta gh
   # Lazygit vía COPR o release oficial:
   sudo dnf5 copr enable -y dejan/lazygit && sudo dnf5 install -y lazygit
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
   - Editor por defecto: Detección inteligente (`nvim` -> `micro` -> `vim` -> `nano`).
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
   git config --global delta.hyperlinks true
   git config --global merge.conflictstyle zdiff3
   ```

5. **GitHub CLI (`gh`)**:
   Configura el protocolo SSH y el editor predeterminado:
   ```bash
   gh config set editor "$DEFAULT_EDITOR"
   gh config set git_protocol ssh
   ```

---

## 2. Automatización con Just

Para desplegar todo el entorno de control de versiones en un solo paso:

```bash
just git-setup
```

---

## Verificación

Para verificar que el entorno de Git y sus herramientas asociadas estén correctamente configurados:

- **Git-Delta**: Ejecuta `git diff` en cualquier repositorio con cambios locales. Deberías ver las diferencias formateadas con vista lado a lado, números de línea y colores provistos por Delta.
- **Lazygit**: Ejecuta `lazygit` dentro de un repositorio de Git para abrir la interfaz interactiva de terminal.
- **GitHub CLI**: Ejecuta `gh auth status` o `gh auth login` para verificar tu sesión o iniciar sesión con tu cuenta de GitHub.
