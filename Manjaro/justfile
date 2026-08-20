# Manjaro Linux Environment Configuration Justfile
# (Manjaro Linux + GNOME)

# Instala todo el entorno por defecto (Auto-detección de CPU / Portátil AMD)
setup-all: post-install workspace laptop fingerprint tuning extensions screensaver plymouth shell security fonts virtualization mise cockpit ides git-setup languages yt-dlp fastfetch gnome ptyxis firefox
    echo "🚀 Entorno completo de Manjaro Linux (Manjaro + GNOME) configurado. Por favor, reinicia el sistema."

# Perfil completo para Portátil de desarrollo (AMD Ryzen + Huella + Virtualización)
setup-laptop-amd: post-install-amd workspace laptop fingerprint tuning extensions screensaver plymouth shell security fonts virtualization mise cockpit ides git-setup languages yt-dlp fastfetch gnome ptyxis firefox
    echo "🚀 Entorno Portátil AMD Ryzen configurado con éxito en Manjaro. Por favor, reinicia el sistema."

# Perfil para Sobremesa Centro Multimedia (Intel Haswell / Media Center - Sin virtualización ni batería)
setup-media-desktop: post-install-intel workspace tuning extensions screensaver plymouth shell security fonts gnome apariencia fastfetch ptyxis firefox kodi
    echo "🚀 Entorno Sobremesa Intel Media Center configurado con éxito en Manjaro. Por favor, reinicia el sistema."

# =============================================================================
# CONFIGURACIÓN BASE DEL SISTEMA
# =============================================================================

# Optimización y ordenación rápida de servidores réplica (espejos) de Manjaro
mirrors:
    sudo pacman-mirrors --fasttrack 5 && sudo pacman -Syy

# Configuración base post-instalación (Auto-detección inteligente: AMD Ryzen vs Intel Core)
post-install:
    ./Setup/post-install.sh

# Configuración post-instalación para AMD Ryzen (mhwd, microcódigo AMD, RADV, Mesa, PipeWire, GNOME)
post-install-amd:
    ./Setup/post-install-amd.sh

# Configuración post-instalación para Intel Haswell/Core (Intel microcódigo, Intel VA-API, Kodi, PipeWire, GNOME)
post-install-intel:
    ./Setup/post-install-intel.sh

# Automontaje permanente de la partición Workspace (/home/caballero/Workspace) en /etc/fstab
workspace:
    ./Setup/mount-workspace.sh

# Compilador de Kernel Linux optimizado para x86_64-v3 y ajustado a tu hardware
build-kernel:
    ./Setup/build-custom-kernel.sh

# Optimización para portátiles de desarrollo (Touchpad, Batería, Bluetooth, HiDPI, VRR)
laptop:
    ./Setup/laptop-setup.sh

# Autenticación y desbloqueo por huella dactilar (fprintd, PAM, sudo, polkit, GNOME)
fingerprint:
    ./Setup/fingerprint-setup.sh

# Configuración e instalación de impresora HP LaserJet Pro M15w (USB)
printer:
    ./Setup/hp-printer-setup.sh

# Optimizaciones avanzadas de Manjaro (Sysctl dev, Pacman paralelo, Pamac, Distrobox)
tuning:
    ./Setup/manjaro-tuning.sh

# Instalación automatizada de conectores y las 17 extensiones de GNOME
extensions:
    ./Setup/gnome-extensions.sh

# Configuración de salvapantallas 3D/Matrix al bloquear la pantalla
screensaver:
    ./Setup/screensaver-setup.sh

# Configuración y activación de Splash Screen visual de arranque (Plymouth: BGRT / Manjaro)
plymouth:
    ./Setup/plymouth-setup.sh

# Utilidades de terminal y prompt ZSH / Bash (eza, bat, fzf, starship, zsh plugins)
shell:
    ./Setup/shell.sh

# Seguridad básica (UFW firewall)
security:
    ./Setup/seguridad.sh

# Seguridad avanzada (DNS-over-TLS con systemd-resolved)
security-dot:
    ./Setup/seguridad-dot.sh

# Fuentes de desarrollo (Nerd Fonts: JetBrainsMono, FiraCode, CascadiaCode...)
fonts:
    ./Setup/fonts.sh

# Personalización de GNOME (gsettings, luz nocturna, 24h, temas)
gnome:
    ./Setup/gnome-settings.sh

# Apariencia (Temas Adwaita Dark, iconos Papirus e integración GTK/Qt)
apariencia:
    ./Setup/apariencia.sh

# Información estética del sistema (Fastfetch)
fastfetch:
    ./Setup/fastfetch.sh

# Terminal Ptyxis + integración Nautilus
ptyxis:
    ./Setup/ptyxis.sh

# Terminal Kitty acelerada por GPU con tema oscuro y opacidad/blur
kitty:
    ./Setup/kitty.sh

# Multimedia (yt-dlp, ffmpeg)
yt-dlp:
    ./Setup/yt-dlp-setup.sh

# Centro Multimedia (Kodi + complementos de streaming nativos)
kodi:
    sudo pacman -S --needed --noconfirm kodi kodi-addon-inputstream-adaptive kodi-addon-inputstream-rtmp kodi-addon-pvr-iptvsimple

# =============================================================================
# CONFIGURACIÓN DE RED Y VIRTUALIZACIÓN
# =============================================================================

# Configuración de KVM/QEMU y Libvirt
virtualization:
    ./Virtualizacion/virtualization.sh

# Administración Web (Cockpit)
cockpit:
    ./Setup/cockpit.sh

# =============================================================================
# CONTROL DE VERSIONES
# =============================================================================

# Git, Delta, Lazygit, GH CLI
git-setup:
    ./Git/git.sh
    ./Git/github-cli.sh

# =============================================================================
# GESTORES DE RUNTIMES
# =============================================================================

# Gestor de versiones Mise
mise:
    ./ProgrammingLanguages/mise.sh

# =============================================================================
# LENGUAJES DE PROGRAMACIÓN
# =============================================================================

# Todos los lenguajes
languages: node python rust dotnet java
    echo "✅ Lenguajes instalados."

# Node.js LTS
node:
    ./ProgrammingLanguages/nodejs.sh

# Python
python:
    ./ProgrammingLanguages/python.sh

# Rust
rust:
    ./ProgrammingLanguages/rust.sh

# .NET SDK
dotnet:
    ./ProgrammingLanguages/dotnet.sh

# Java (OpenJDK)
java:
    ./ProgrammingLanguages/java.sh

# =============================================================================
# HERRAMIENTAS DE IA
# =============================================================================

# Gemini CLI
gemini:
    ./ProgrammingLanguages/gemini.sh

# Angular CLI
angular:
    ./ProgrammingLanguages/angular.sh

# =============================================================================
# ENTORNOS DE DESARROLLO (IDEs)
# =============================================================================

# Todos los IDEs
ides: nvim vscode antigravity opencode
    echo "✅ IDEs instalados."

# Neovim + LazyVim
nvim:
    ./IDE/neovim.sh

# Visual Studio Code
vscode:
    ./IDE/vscode.sh

# Google Antigravity Desktop 2.0 (Completo)
antigravity:
    ./IDE/antigravity.sh

# Google Antigravity CLI
antigravity-cli:
    ./IDE/antigravity-cli.sh

# Google Antigravity IDE Engine
antigravity-ide:
    ./IDE/antigravity-ide.sh

# OpenCode AI CLI/Editor
opencode:
    ./IDE/opencode.sh

# =============================================================================
# NAVEGADORES Y JUEGOS
# =============================================================================

# Firefox nativo de repositorios oficiales
firefox:
    ./Setup/firefox.sh

# Steam y herramientas de juegos nativas
steam:
    ./Juegos/steam.sh

# =============================================================================
# PODMAN - BASE
# =============================================================================

# Podman base (instalación y configuración rootless)
podman-base:
    ./Podman/install/podman-install.sh

# =============================================================================
# PODMAN - SERVICIOS Y TEMPLATES
# =============================================================================

# Configuración Quadlets de Podman
podman-quadlets:
    ./Podman/install/quadlets-setup.sh
