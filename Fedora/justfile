# Fedora 44 Environment Configuration Justfile
# (Fedora 44 + KDE Plasma)

# Instala todo el entorno por defecto (Auto-detección de CPU / Portátil AMD)
setup-all: post-install workspace laptop fingerprint tuning screensaver plymouth shell security fonts virtualization mise cockpit ides git-setup languages yt-dlp fastfetch firefox
    echo "🚀 Entorno completo de Fedora 44 (KDE Plasma) configurado. Por favor, reinicia el sistema."

# Perfil completo para Portátil de desarrollo (AMD Ryzen + Huella + Virtualización)
setup-laptop-amd: post-install-amd workspace laptop fingerprint tuning screensaver plymouth shell security fonts virtualization mise cockpit ides git-setup languages yt-dlp fastfetch firefox
    echo "🚀 Entorno Portátil AMD Ryzen configurado con éxito. Por favor, reinicia el sistema."

# Perfil para Sobremesa Centro Multimedia (Intel Haswell / Media Center - Sin virtualización ni batería)
setup-media-desktop: post-install-intel workspace tuning screensaver plymouth shell security fonts apariencia fastfetch firefox kodi
    echo "🚀 Entorno Sobremesa Intel Media Center configurado con éxito. Por favor, reinicia el sistema."

# =============================================================================
# CONFIGURACIÓN BASE DEL SISTEMA
# =============================================================================

# Configuración base post-instalación (Auto-detección inteligente: AMD Ryzen vs Intel Core)
post-install:
    ./Setup/post-install.sh

# Configuración post-instalación para AMD Ryzen (Kernel, firmware-amd, RADV, Mesa, PipeWire, GNOME)
post-install-amd:
    ./Setup/post-install-amd.sh

# Configuración post-instalación para Intel Haswell/Core (Kernel, microcódigo Intel, i965 VA-API, Kodi, PipeWire, GNOME)
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

# Optimizaciones avanzadas de Fedora 44 (Sysctl, Distrobox)
tuning:
    ./Setup/fedora-tuning.sh


# Configuración de salvapantallas 3D/Matrix al bloquear la pantalla
screensaver:
    ./Setup/screensaver-setup.sh

# Configuración y activación de Splash Screen visual de arranque (Plymouth: BGRT / Spinner / Tema)
plymouth:
    ./Setup/plymouth-setup.sh

# Utilidades de terminal y prompt (eza, bat, fzf, starship)
shell:
    ./Setup/shell.sh

# Seguridad básica (Firewalld - Zona FedoraWorkstation)
security:
    ./Setup/seguridad.sh

# Seguridad avanzada (DNS-over-TLS con systemd-resolved)
security-dot:
    ./Setup/seguridad-dot.sh

# Fuentes de desarrollo (Nerd Fonts: JetBrainsMono, FiraCode, CascadiaCode...)
fonts:
    ./Setup/fonts.sh


# Apariencia (Temas Adwaita Dark, iconos Papirus e integración GTK/Qt)
apariencia:
    ./Setup/apariencia.sh

# Información estética del sistema (Fastfetch)
fastfetch:
    ./Setup/fastfetch.sh

# Terminal Kitty acelerada por GPU con tema oscuro y opacidad/blur
kitty:
    ./Setup/kitty.sh

# Multimedia (yt-dlp, ffmpeg)
yt-dlp:
    ./Setup/yt-dlp-setup.sh

# Centro Multimedia (Kodi + complementos de streaming)
kodi:
    sudo dnf5 install -y kodi kodi-inputstream-adaptive kodi-inputstream-rtmp kodi-pvr-iptvsimple

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

# Firefox nativo (RPM)
firefox:
    ./Setup/firefox.sh

# Steam y herramientas de juegos
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
