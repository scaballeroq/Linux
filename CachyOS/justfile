# CachyOS Environment Configuration Justfile

# Instala todo el entorno (Post-install, Workspace, Laptop, Tuning, Extensions, Shell, Virtualización, Mise, Cockpit, etc.)
setup-all: post-install workspace laptop tuning extensions shell security fonts virtualization mise cockpit ides git-setup languages yt-dlp fastfetch gnome
    echo "🚀 Entorno completo de CachyOS configurado. Por favor, reinicia el sistema."

# Administración Web
cockpit:
    ./Setup/cockpit.sh

# Configuración base del sistema (Pacman / CachyOS Repos)
post-install:
    ./Setup/post-install.sh

# Automontaje permanente de la partición Workspace (/home/caballero/Workspace) en /etc/fstab
workspace:
    ./Setup/mount-workspace.sh

# Compilador de Kernel Linux optimizado para x86_64-v3 y ajustado a tu portátil
build-kernel:
    ./Setup/build-custom-kernel.sh

# Optimización específica para Portátiles de desarrollo (Touchpad, Batería, Bluetooth, HiDPI)
laptop:
    ./Setup/laptop-setup.sh

# Autenticación y desbloqueo por huella dactilar (fprintd, PAM, sudo, polkit)
fingerprint:
    ./Setup/fingerprint-setup.sh

# Optimizaciones avanzadas de CachyOS (Sysctl, Ananicy-cpp, Distrobox)
tuning:
    ./Setup/cachyos-tuning.sh

# Instalación automatizada de conectores y las 17 extensiones de GNOME
extensions:
    ./Setup/gnome-extensions.sh

# Utilidades de terminal y prompt
shell:
    ./Setup/shell.sh

# Configuración de KVM/QEMU
virtualization:
    ./Virtualizacion/virtualization.sh

# Gestor de runtimes Mise
mise:
    ./ProgrammingLanguages/mise.sh

# Seguridad y Endurecimiento (UFW)
security:
    ./Setup/seguridad.sh

# Fuentes de desarrollo
fonts:
    ./Setup/fonts.sh

# Personalización de GNOME
gnome:
    ./Setup/gnome-settings.sh

# Información estética del sistema
fastfetch:
    ./Setup/fastfetch.sh

# Instalación de IDEs (Neovim, VS Code, Antigravity, OpenCode)
ides: nvim vscode antigravity opencode
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

antigravity-cli:
    ./IDE/antigravity-cli.sh

antigravity-ide:
    ./IDE/antigravity-ide.sh

opencode:
    ./IDE/opencode.sh

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
