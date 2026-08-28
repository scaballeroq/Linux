# Fedora 44 Environment Configuration Justfile
# (Fedora 44 + KDE Plasma 6)

# Instala todo el entorno por defecto (Auto-detección de CPU / Portátil AMD)
setup-all: post-install laptop tuning plymouth shell security fonts apariencia fastfetch kitty yt-dlp virtualization cockpit ides git-setup languages podman-setup
    @echo "🚀 Entorno completo de Fedora 44 (KDE Plasma 6) configurado. Por favor, reinicia el sistema."

# Perfil completo para Portátil de desarrollo (AMD Ryzen + Virtualización + Contenedores)
setup-laptop-amd: post-install-amd laptop tuning plymouth shell security fonts apariencia fastfetch kitty yt-dlp virtualization cockpit ides git-setup languages podman-setup
    @echo "🚀 Entorno Portátil AMD Ryzen configurado con éxito. Por favor, reinicia el sistema."

# Perfil para Sobremesa Centro Multimedia (Intel Haswell / Media Center - Sin virtualización ni batería)
setup-media-desktop: post-install-intel tuning plymouth shell security fonts apariencia fastfetch kitty yt-dlp kodi
    @echo "🚀 Entorno Sobremesa Intel Media Center configurado con éxito. Por favor, reinicia el sistema."

# =============================================================================
# CONFIGURACIÓN BASE DEL SISTEMA
# =============================================================================

# Configuración base post-instalación (Auto-detección inteligente: AMD Ryzen vs Intel Core)
post-install:
    ./Setup/post-install.sh

# Configuración post-instalación para AMD Ryzen (Kernel, firmware-amd, RADV, Mesa, PipeWire, KDE Plasma)
post-install-amd:
    ./Setup/post-install-amd.sh

# Configuración post-instalación para Intel Haswell/Core (Kernel, microcódigo Intel, i965 VA-API, Kodi, PipeWire, KDE Plasma)
post-install-intel:
    ./Setup/post-install-intel.sh

# Optimización para portátiles de desarrollo (Touchpad, Batería, Bluetooth, tuned-ppd, persistencia de brillo 95%)
laptop:
    ./Setup/laptop-setup.sh

# Configuración e instalación de impresora HP LaserJet Pro M15w (USB)
printer:
    ./Setup/hp-printer-setup.sh

# Optimizaciones avanzadas de rendimiento (Sysctl, límites, Systemd, Baloo, Distrobox para Fedora 44 + KDE Plasma)
tuning:
    ./Setup/fedora-tuning.sh

# Configuración y activación de Splash Screen visual de arranque (Plymouth: Breeze / BGRT / Spinner)
plymouth:
    ./Setup/plymouth-setup.sh

# Utilidades de terminal y prompt (eza, bat, fzf, zoxide, ripgrep, starship)
shell:
    ./Setup/shell.sh

# Seguridad y cortafuegos (Firewalld - Zona FedoraWorkstation, DNS-over-TLS, MAC Randomization, Sysctl)
security:
    ./Setup/seguridad.sh

# Fuentes de desarrollo (Nerd Fonts: JetBrainsMono, FiraCode, CascadiaCode...)
fonts:
    ./Setup/fonts.sh

# Apariencia (Temas Breeze Dark, iconos Papirus e integración visual GTK/Qt en KDE Plasma 6)
apariencia:
    ./Setup/apariencia.sh

# Información estética del sistema (Fastfetch)
fastfetch:
    ./Setup/fastfetch.sh

# Terminal Kitty acelerada por GPU con tema oscuro y opacidad/blur
kitty:
    ./Setup/kitty.sh

# Multimedia (yt-dlp stack, FFmpeg, AtomicParsley, aria2, motor JS Deno)
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
    ./IDE/git.sh
    ./IDE/github-cli.sh

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
languages: node python rust dotnet java angular gemini
    @echo "✅ Lenguajes instalados."

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
ides: nvim vscode antigravity antigravity-cli antigravity-ide opencode
    @echo "✅ IDEs instalados."

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
# PODMAN Y CONTENEDORES QUADLETS
# =============================================================================

# Configuración completa de Podman Rootless y Quadlets
podman-setup:
    ./Podman/install/podman-install.sh
    ./Podman/install/quadlets-setup.sh

# Configuración base de Podman Rootless
podman-base:
    ./Podman/install/podman-install.sh

# Configuración de servicios Quadlets de Podman
podman-quadlets:
    ./Podman/install/quadlets-setup.sh

# Estado y diagnóstico de Podman y Quadlets
podman-status:
    ./Podman/install/podman-install.sh --status
    ./Podman/lib/podman-utils.sh doctor
