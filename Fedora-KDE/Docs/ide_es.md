---
sidebar_position: 5
---

# Entornos de Desarrollo (IDEs) y Herramientas en Fedora 44

Esta guía detalla la instalación y configuración de los editores, plataformas de desarrollo y asistentes de IA integrados en la carpeta `IDE`.

El entorno cubre el editor de consola moderno **Neovim** (potenciado con LazyVim), el editor de escritorio **Visual Studio Code**, el cliente de IA **OpenCode**, las herramientas de control de versiones (**Git, Delta, GitHub CLI**) y la suite completa de **Google Antigravity Desktop 2.0 / CLI / IDE Engine**.

---

## 1. Neovim y LazyVim (`IDE/neovim.sh`)

Instala y configura un entorno de edición ultrarrápido y modular en la terminal utilizando Neovim y la distribución preconfigurada LazyVim:

```bash
./IDE/neovim.sh
# O usando just:
just nvim
```

Instala dependencias esenciales de compilación y búsqueda (`gcc`, `make`, `g++`, `ripgrep`, `fd-find`, `wl-copy`), clona el starter de LazyVim en `~/.config/nvim` y prepara el árbol de plugins.

---

## 2. Visual Studio Code (`IDE/vscode.sh`)

Automatiza la configuración del repositorio oficial RPM de Microsoft para DNF5 e instala Visual Studio Code nativo:

```bash
./IDE/vscode.sh
# O usando just:
just vscode
```

---

## 3. Google Antigravity Desktop 2.0, CLI e IDE (`antigravity.sh`, `antigravity-cli.sh`, `antigravity-ide.sh`)

Suite completa para la instalación y actualización de la plataforma de IA de Google Antigravity:

- **Google Antigravity Desktop 2.0 (`antigravity.sh`)**: Instalador integral que gestiona la descarga desde Google CDN, despliegue en `/opt/antigravity`, helper de actualización `/usr/local/bin/update-antigravity`, lanzador `.desktop`, icono de alta resolución y permisos `4755` del sandbox Chromium.
- **Google Antigravity CLI (`antigravity-cli.sh`)**: Instalador de la herramienta CLI de terminal.
- **Google Antigravity IDE Engine (`antigravity-ide.sh`)**: Instalador del motor IDE independiente con helper `/usr/local/bin/update-antigravity-ide`.

```bash
just antigravity      # Instala Antigravity Desktop 2.0
just antigravity-cli  # Instala Antigravity CLI
just antigravity-ide  # Instala Antigravity IDE
```

---

## 4. OpenCode AI CLI/Editor (`IDE/opencode.sh`)

Instalación automatizada del cliente de IA OpenCode con soporte para especificar versión o descargar la última versión estable:

```bash
./IDE/opencode.sh
# O especifica una versión:
./IDE/opencode.sh 1.18.13
# O usando just:
just opencode
```

---

## 5. Control de Versiones Git y GitHub CLI (`git.sh`, `github-cli.sh`)

Configura Git con paginador Delta (`zdiff3`, vista lado a lado), Lazygit y el cliente oficial GitHub CLI:

```bash
just git-setup
# o ./IDE/git.sh && ./IDE/github-cli.sh
```

---

## 6. Automatización de Todos los IDEs con Just

Para desplegar simultáneamente todos los entornos de desarrollo:

```bash
just ides
```

---

## Verificación

- **Neovim**: Ejecuta `nvim` en tu terminal. En la primera ejecución se descargarán automáticamente los plugins de LazyVim.
- **VS Code**: Ejecuta `code` o búscalo en el lanzador de aplicaciones de KDE Plasma.
- **Google Antigravity**: Ejecuta `antigravity` en la terminal o busca "Antigravity" en el menú de aplicaciones.
- **OpenCode**: Ejecuta `opencode --version`.
- **GitHub CLI**: Ejecuta `gh --version` y `gh auth login`.
