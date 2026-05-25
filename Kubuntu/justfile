# Kubuntu Environment Configuration Justfile

# Instala todo el entorno (Post-install, Shell, Mise, Cockpit, etc.)
setup-all: post-install shell security fonts mise cockpit ides git-setup languages yt-dlp fastfetch
    echo "🚀 Entorno completo configurado. Por favor, reinicia el sistema."

# Administración Web
cockpit:
    ./Setup/cockpit.sh

# Configuración base del sistema
post-install:
    ./Setup/post-install.sh

# Utilidades de terminal y prompt
shell:
    ./Setup/shell.sh

# Gestor de runtimes Mise
mise:
    ./ProgrammingLanguages/mise.sh

# Seguridad y Endurecimiento
security:
    ./Setup/seguridad.sh

# Fuentes de desarrollo
fonts:
    ./Setup/fonts.sh

# Personalización de GNOME (Compatibilidad)
gnome:
    echo "ℹ️ Kubuntu utiliza KDE Plasma."

# Información estética del sistema
fastfetch:
    ./Setup/fastfetch.sh

# Instalación de IDEs (Neovim, VS Code, Antigravity)
ides: nvim vscode antigravity
    echo "✅ IDEs instalados."

# Control de versiones (Git, Delta, Lazygit, GH CLI)
git-setup:
    ./Git/git.sh
    ./Git/github-cli.sh

nvim:
    ./IDE/neovim.sh

vscode:
    ./IDE/vscode.sh

antigravity:
    ./IDE/antigravity.sh

# Multimedia (yt-dlp, ffmpeg)
yt-dlp:
    ./Setup/yt-dlp-setup.sh

# Instalación de Lenguajes (Node, Python)
languages: node python
    echo "✅ Lenguajes instalados."

node:
    ./ProgrammingLanguages/nodejs.sh

python:
    ./ProgrammingLanguages/python.sh

gemini:
    ./ProgrammingLanguages/gemini.sh

# Desplegar servicios comunes (Podman)
podman-base:
    ./Podman/podman.sh
