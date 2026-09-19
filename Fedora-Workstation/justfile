# Fedora 44 Environment Configuration Justfile
# (Fedora 44 Workstation + GNOME)

# Instala todo el entorno por defecto (Auto-detección de CPU / Portátil AMD)
setup-all: post-install multimedia chrome steam laptop tuning gnome-setup shell security fonts fastfetch kitty yt-dlp virtualization cockpit ides git-setup languages podman-setup
    @echo "🚀 Entorno completo de Fedora 44 Workstation (GNOME) configurado. Por favor, reinicia el sistema."

# Perfil completo para Portátil de desarrollo (AMD Ryzen + Virtualización + Contenedores)
setup-laptop-amd: post-install-amd multimedia chrome steam laptop tuning gnome-setup shell security fonts fastfetch kitty yt-dlp virtualization cockpit ides git-setup languages podman-setup
    @echo "🚀 Entorno Portátil AMD Ryzen (GNOME) configurado con éxito. Por favor, reinicia el sistema."

# Perfil para Sobremesa (Intel Core - Sin virtualización ni batería)
setup-media-desktop: post-install-intel multimedia chrome tuning gnome-setup shell security fonts fastfetch kitty yt-dlp
    @echo "🚀 Entorno Sobremesa Intel (GNOME) configurado con éxito. Por favor, reinicia el sistema."

# =============================================================================
# CONFIGURACIÓN BASE DEL SISTEMA
# =============================================================================

# Configuración base post-instalación (Auto-detección inteligente: AMD Ryzen vs Intel Core)
post-install:
    ./Setup/post-install.sh

# Configuración post-instalación para AMD Ryzen (Kernel, firmware-amd, RADV, Mesa, PipeWire, GNOME)
post-install-amd:
    ./Setup/post-install-amd.sh

# Configuración post-instalación para Intel Core (Kernel, microcódigo Intel, VA-API Intel, PipeWire, GNOME)
post-install-intel:
    ./Setup/post-install-intel.sh

# Optimización para portátiles de desarrollo (Touchpad, Batería, Bluetooth, persistencia de brillo al 95%)
laptop:
    ./Setup/laptop-setup.sh

# Personalización y configuración de GNOME (Modo oscuro, gsettings, Mutter VRR, Nautilus, atajos)
gnome-setup:
    ./Setup/gnome-settings.sh

# Extensiones de GNOME Shell desde repositorios oficiales y extensions.gnome.org (Dash to Dock, AppIndicator, Blur, etc.)
gnome-extensions:
    ./Setup/gnome-extensions.sh

# Estado de las extensiones de GNOME Shell
gnome-extensions-status:
    ./Setup/gnome-extensions.sh --status

# Optimizaciones avanzadas de rendimiento (Sysctl, límites, Systemd, Tracker 3, Distrobox para Fedora 44 + GNOME)
tuning:
    ./Setup/fedora-tuning.sh

# Estado actual de las optimizaciones y métricas de rendimiento
tuning-status:
    ./Setup/fedora-tuning.sh --status

# Utilidades de terminal modernas (eza, bat, fzf, zoxide, ripgrep)
shell:
    ./Setup/shell.sh

# Starship Prompt opcional (Instalar / Activar)
starship:
    ./Setup/starship.sh

# Desactivar Starship y restaurar prompt nativo
starship-disable:
    ./Setup/starship.sh --disable

# Seguridad y cortafuegos (Firewalld zona FedoraWorkstation / GSConnect, DNS-over-TLS, MAC Randomization, Sysctl)
security:
    ./Setup/seguridad.sh

# Fuentes de desarrollo (Nerd Fonts: JetBrainsMono, FiraCode, CascadiaCode...)
fonts:
    ./Setup/fonts.sh

# Información estética del sistema (Fastfetch)
fastfetch:
    ./Setup/fastfetch.sh

# Terminal Kitty acelerada por GPU con tema oscuro Catppuccin Mocha y opacidad/blur
kitty:
    ./Setup/kitty.sh

# Multimedia (yt-dlp stack, FFmpeg, AtomicParsley, aria2, motor JS Deno)
yt-dlp:
    ./Setup/yt-dlp-setup.sh

# Codecs multimedia completos, FFmpeg completo y drivers privativos (RPM Fusion Free/Nonfree/Tainted)
multimedia:
    ./Setup/multimedia.sh

# Navegador Google Chrome oficial
chrome:
    ./Setup/chrome.sh

# Steam nativo, GameMode, MangoHud y drivers Vulkan 32-bit (RPM Fusion Non-Free)
steam:
    ./Setup/steam.sh

# =============================================================================
# CONFIGURACIÓN DE RED Y VIRTUALIZACIÓN
# =============================================================================

# Configuración de KVM/QEMU y Libvirt (Optimizado para distribuciones Linux y virt-manager)
virtualization:
    ./Virtualizacion/virtualization.sh

# Diagnóstico y estado de la virtualización KVM/QEMU
virtualization-status:
    ./Virtualizacion/virtualization.sh --status

# Administración Web (Cockpit)
cockpit:
    ./Setup/cockpit.sh

# =============================================================================
# CONTROL DE VERSIONES
# =============================================================================

# Git, Delta, Lazygit, GH CLI
git-setup:
    ./IDE/git.sh

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
languages: node python rust dotnet java angular
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

# Angular CLI
angular:
    ./ProgrammingLanguages/angular.sh

# =============================================================================
# ENTORNOS DE DESARROLLO (IDEs)
# =============================================================================

# Todos los IDEs
ides: antigravity antigravity-cli antigravity-ide opencode
    @echo "✅ IDEs instalados."

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
