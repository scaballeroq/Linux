---
sidebar_position: 5
---

# Entornos de Desarrollo (IDEs) en Kubuntu

Esta guía detalla la instalación y configuración de los editores y entornos de desarrollo integrados presentes en la carpeta `IDE`.

El entorno cubre el editor de consola moderno **Neovim** (potenciado con LazyVim), el editor de escritorio **Visual Studio Code** e integraciones de herramientas como **Google Antigravity**.

---

## 1. Neovim y LazyVim (`neovim.sh`)

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

## 3. Google Antigravity CLI (`antigravity.sh`)

Instala la herramienta corporativa de inteligencia artificial y desarrollo de Google Antigravity para Kubuntu/Ubuntu.

1. **Configuración de Llaveros e Importación de GPG**:
   ```bash
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
   sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
   ```

2. **Añadir Repositorio de Google Artifact Registry**:
   ```bash
   echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
   sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null
   ```

3. **Instalación de la herramienta**:
   ```bash
   sudo apt update
   sudo apt install -y antigravity
   ```

---

## Verificación

Para comprobar el correcto funcionamiento de los editores:

- **Neovim**: Ejecuta `nvim` en tu terminal. En la primera ejecución se descargarán e instalarán automáticamente los plugins de LazyVim. Una vez completado, puedes ejecutar `:LazyHealth` para evaluar el estado de tus LSPs y compiladores integrados.
- **VS Code**: Ejecuta `code` o búscalo en el lanzador de aplicaciones del escritorio.
- **Antigravity**: Verifica que responda correctamente ejecutando `antigravity --version` o ejecutando sus comandos CLI asignados.
