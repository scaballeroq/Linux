---
sidebar_position: 5
---

# Entornos de Desarrollo (IDEs) en Manjaro Linux

Esta guía detalla la instalación y configuración de los editores y herramientas de desarrollo integradas presentes en la carpeta `IDE`.

El entorno cubre el editor de consola moderno **Neovim** (potenciado con LazyVim), el editor de escritorio **Visual Studio Code**, el cliente de IA **OpenCode** y la suite completa de **Google Antigravity Desktop 2.0 / CLI / IDE**.

---

## 1. Neovim y LazyVim (`neovim.sh`)

Instala y configura un entorno de edición ultrarrápido y modular en la terminal utilizando Neovim y la distribución preconfigurada LazyVim.

```bash
sudo pacman -Syu
sudo pacman -S -y neovim gcc make g++ ripgrep fd-find xclip wl-copy git
git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
rm -rf "$HOME/.config/nvim/.git"
```

---

## 2. Visual Studio Code (`vscode.sh`)

Automatiza la instalación del popular editor Visual Studio Code desde los repositorios oficiales de Microsoft para garantizar actualizaciones automáticas seguras.

```bash
./IDE/vscode.sh
```

---

## 3. Google Antigravity Desktop 2.0, CLI e IDE (`antigravity.sh`, `antigravity-cli.sh`, `antigravity-ide.sh`)

Scripts completos para la instalación y actualización de la plataforma de IA de Google Antigravity:

- **Google Antigravity Desktop 2.0 (`antigravity.sh`)**: Instalador de 510 líneas que gestiona la descarga del tarball desde Google CDN, despliegue en `/opt/antigravity`, helper `/usr/local/bin/update-antigravity`, lanzador `.desktop`, icono en alta resolución y permisos `4755` del sandbox de Chromium.
- **Google Antigravity CLI (`antigravity-cli.sh`)**: Instalador de la CLI de terminal.
- **Google Antigravity IDE Engine (`antigravity-ide.sh`)**: Instalador del motor IDE independiente.

```bash
just antigravity
just antigravity-cli
just antigravity-ide
```

---

## 4. OpenCode AI CLI/Editor (`opencode.sh`)

Instalación automatizada del cliente de IA OpenCode con control de versión explícito (ej. `v1.18.13`).

```bash
./IDE/opencode.sh
# O especifica una versión:
./IDE/opencode.sh 1.18.13
# O usando just:
just opencode
```

---

## Verificación

Para comprobar el correcto funcionamiento de los editores:

- **Neovim**: Ejecuta `nvim` en tu terminal. En la primera ejecución se descargarán automáticamente los plugins de LazyVim.
- **VS Code**: Ejecuta `code` o búscalo en el lanzador de aplicaciones del escritorio.
- **Google Antigravity**: Ejecuta `antigravity` en la terminal o busca "Antigravity" en el menú de aplicaciones.
- **OpenCode**: Ejecuta `opencode --version`.
