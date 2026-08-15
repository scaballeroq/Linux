# KDEDebian Environment Configuration Justfile
# (Debian Testing + KDE Plasma 6)

# Instala todo el entorno (Post-install, Workspace, Laptop, Fingerprint, Tuning, Widgets, Screensaver, Shell, Virtualización, Mise, Cockpit, KDE, Konsole, etc.)
setup-all: post-install workspace laptop fingerprint tuning widgets screensaver shell security fonts virtualization mise cockpit ides git-setup languages yt-dlp fastfetch kde konsole firefox
    echo "🚀 Entorno completo de KDEDebian (Debian Testing + KDE Plasma 6) configurado. Por favor, reinicia el sistema."

# =============================================================================
# CONFIGURACIÓN BASE DEL SISTEMA
# =============================================================================

# Configuración base post-instalación (Repositorios contrib, non-free, firmware, ZRAM, PipeWire, KDE Suite)
post-install:
    ./Setup/post-install.sh

# Automontaje permanente de la partición Workspace (/home/caballero/Workspace) en /etc/fstab
workspace:
    ./Setup/mount-workspace.sh

# Compilador de Kernel Linux optimizado para x86_64-v3 y ajustado a tu portátil
build-kernel:
    ./Setup/build-custom-kernel.sh

# Actualización del último Kernel Linux oficial y Firmware desde repositorios de Debian Testing
kernel-update:
    ./Setup/install-backports-kernel.sh

# Optimización para portátiles de desarrollo (Touchpad, Batería, Bluetooth, HiDPI, VRR)
laptop:
    ./Setup/laptop-setup.sh

# Autenticación y desbloqueo por huella dactilar (fprintd, PAM, sudo, SDDM, KDE lock screen, polkit)
fingerprint:
    ./Setup/fingerprint-setup.sh

# Configuración e instalación de impresora HP LaserJet Pro M15w (USB) con print-manager de KDE
printer:
    ./Setup/hp-printer-setup.sh

# Optimizaciones avanzadas de Debian Testing (Sysctl, Distrobox)
tuning:
    ./Setup/debian-tuning.sh

# Configuración de Widgets, Klipper y Atajos de KDE Plasma 6
widgets:
    ./Setup/kde-widgets.sh

# Alias para widgets
kde-addons: widgets

# Configuración de bloqueo de pantalla con KScreenLocker y salvapantallas
screensaver:
    ./Setup/screensaver-setup.sh

# Utilidades de terminal y prompt (eza, bat, fzf, starship)
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

# Personalización de KDE Plasma 6 (kwriteconfig, temas, luz nocturna, botones)
kde:
    ./Setup/kde-settings.sh

# Personalización avanzada y estética moderna (Klassy, Kvantum Fluent, Material You, Panel Colorizer, Tela Icons)
kde-custom:
    ./Setup/kde-plasma-customization.sh

# Apariencia (Temas Breeze Dark, iconos Papirus e integración Qt/GTK)
apariencia:
    ./Setup/apariencia.sh

# Información estética del sistema (Fastfetch)
fastfetch:
    ./Setup/fastfetch.sh

# Terminal Konsole translúcida con blur + integración en Dolphin
konsole:
    ./Setup/konsole.sh

# Terminal Kitty acelerada por GPU con tema oscuro y opacidad/blur
kitty:
    ./Setup/kitty.sh


# Multimedia (yt-dlp, ffmpeg)
yt-dlp:
    ./Setup/yt-dlp-setup.sh

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

# Firefox nativo (.deb)
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
