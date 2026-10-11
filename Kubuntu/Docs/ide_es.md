---
title: Entornos de Desarrollo (IDEs)
sidebar_position: 5
---

# Entornos de Desarrollo (IDEs) en Kubuntu

Esta guía detalla la instalación y configuración de los editores y entornos de desarrollo integrados presentes en la carpeta `IDE`.

El entorno cubre el editor de consola moderno **Neovim** (potenciado con LazyVim), el editor de escritorio **Visual Studio Code**, el cliente de IA **OpenCode** y la suite completa de **Google Antigravity Desktop / CLI / IDE Engine**.

---

## 1. Neovim + LazyVim (`neovim.sh`)

Instala y configura un entorno de edición ultrarrápido y modular en la terminal utilizando Neovim y la distribución preconfigurada LazyVim.

1. **Instalación de Neovim y dependencias**:
   ```bash
   sudo apt update
   sudo apt install -y neovim gcc make g++ ripgrep fd-find xclip wl-copy git
   ```
   *(Nota: Se instalan compiladores de C/C++ y ripgrep/fd, esenciales para el funcionamiento de buscadores difusos y servidores de lenguaje LSP dentro de Neovim).*

2. **Compatibilidad de Comandos**:
   Se asegura de mapear `fdfind` (nombre del comando de `fd` en Kubuntu/Ubuntu) como `fd` en el path local del usuario:
   ```bash
   mkdir -p ~/.local/bin
   [ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind ~/.local/bin/fd
   ```

3. **Despliegue de LazyVim**:
   Clona la plantilla de inicio oficial de LazyVim en el directorio de configuración del usuario:
   ```bash
   git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
   rm -rf "$HOME/.config/nvim/.git"
   ```

---

## 2. Visual Studio Code (`vscode.sh`)

Automatiza la instalación del popular editor Visual Studio Code desde los repositorios oficiales de Microsoft para garantizar actualizaciones automáticas seguras.

1. **Dependencias iniciales**:
   ```bash
   sudo apt update
   sudo apt install -y wget gpg apt-transport-https
   ```

2. **Importación de Clave GPG**:
   ```bash
   wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
   sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
   rm -f packages.microsoft.gpg
   ```

3. **Registro del Repositorio Oficial**:
   ```bash
   sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
   ```

4. **Instalación**:
   ```bash
   sudo apt update
   sudo apt install -y code
   ```

---

## 3. Google Antigravity Desktop, CLI e IDE (`antigravity.sh`, `antigravity-cli.sh`, `antigravity-ide.sh`)

Scripts completos para la instalación y actualización de la plataforma de IA de Google Antigravity:

- **Google Antigravity Desktop (`antigravity.sh`)**: Instalador rápido vía repositorio oficial de Google Artifact Registry o helper automatizado.
- **Google Antigravity CLI (`antigravity-cli.sh`)**: Instalador de la CLI de terminal (`agy`) con verificación de integridad y helper de actualización `update-antigravity-cli`.
- **Google Antigravity IDE Engine (`antigravity-ide.sh`)**: Instalador independiente del motor IDE con sandbox de Chromium y helper `update-antigravity-ide`.

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

- **Neovim**: Ejecuta `nvim` en tu terminal (o Konsole). En la primera ejecución se descargarán automáticamente los plugins de LazyVim. Una vez completado, puedes ejecutar `:LazyHealth` para evaluar el estado de tus LSPs y compiladores integrados.
- **VS Code**: Ejecuta `code` o búscalo en el menú de aplicaciones de KDE Plasma.
- **Google Antigravity**: Ejecuta `antigravity` o `agy --version`.
- **OpenCode**: Ejecuta `opencode --version`.
