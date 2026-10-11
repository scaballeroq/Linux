---
sidebar_position: 4
---

# Configuración de Git en Kubuntu

Esta guía detalla el entorno de control de versiones y el conjunto de herramientas optimizadas en la carpeta `Git`.

El entorno incluye el cliente clásico **Git**, el formateador visual de diferencias **Git-Delta**, y la interfaz gráfica de terminal **Lazygit**, además de la utilidad oficial **GitHub CLI (gh)**.

---

## 1. Automatización de Git (`git.sh`)

El script principal de Git automatiza la instalación y define las mejores prácticas de control de versiones:

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

3. **Buenas Prácticas Modernas**:
   - Rama predeterminada: `main` (`init.defaultBranch main`).
   - Sincronización limpia: Rebase por defecto al hacer pull (`pull.rebase true`).
   - Editor por defecto: `nvim` (`core.editor nvim`).

4. **Resaltado Visual (Git-Delta)**:
   Mejora significativamente la legibilidad de las diferencias en consola reemplazando el paginador nativo y activando colores semánticos, navegación intuitiva y visualización mejorada de conflictos (`zdiff3`):
   ```bash
   git config --global core.pager "delta"
   git config --global interactive.diffFilter "delta --color-only"
   git config --global delta.navigate true
   git config --global delta.light false
   git config --global merge.conflictstyle zdiff3
   ```

5. **Instalación de Lazygit (TUI)**:
   Si no se encuentra instalado en `/usr/local/bin`, se descarga e instala automáticamente el binario compilado de la última versión oficial desde GitHub:
   ```bash
   LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
   curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
   tar xf lazygit.tar.gz lazygit
   sudo install lazygit /usr/local/bin
   rm lazygit lazygit.tar.gz
   ```

---

## 2. Cliente de GitHub en Consola (`github-cli.sh`)

Instala la herramienta de consola oficial de GitHub (`gh`) que permite gestionar repositorios, Pull Requests, Issues y secretos directamente desde la terminal.

1. **Dependencias y Clave GPG del repositorio oficial**:
   ```bash
   sudo apt update
   sudo apt install -y curl gpg
   sudo mkdir -p -m 755 /etc/apt/keyrings
   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
   sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
   ```

2. **Registro del Repositorio de GitHub**:
   ```bash
   echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
   ```

3. **Instalación**:
   ```bash
   sudo apt update
   sudo apt install -y gh
   ```

---

## Verificación

Para verificar que el entorno de Git y sus herramientas asociadas estén correctamente configurados:

- **Git-Delta**: Ejecuta `git diff` en cualquier repositorio con cambios locales. Deberías ver las diferencias formateadas con números de línea y colores estéticos provistos por Delta.
- **Lazygit**: Ejecuta `lazygit` dentro de un repositorio de Git. Se debe abrir la interfaz interactiva.
- **GitHub CLI**: Ejecuta `gh --version` para verificar su instalación. Para autenticarte con tu cuenta de GitHub, inicia el asistente mediante `gh auth login`.
