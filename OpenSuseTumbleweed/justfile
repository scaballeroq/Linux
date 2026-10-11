# openSUSE Tumbleweed Environment Configuration Justfile
# (openSUSE Tumbleweed + KDE Plasma 6)

# Instala todo el entorno por defecto (Auto-detección de CPU / Portátil AMD)
setup-all: post-install multimedia flatpak chrome steam laptop tuning kde-setup shell security fonts fastfetch kitty yt-dlp virtualization cockpit ides git-setup languages podman-setup
    @echo "🚀 Entorno completo de openSUSE Tumbleweed (KDE Plasma 6) configurado. Por favor, reinicia el sistema."

# Perfil completo para Portátil de desarrollo (AMD Ryzen + Virtualización + Contenedores)
setup-laptop-amd: post-install-amd multimedia flatpak chrome steam laptop tuning kde-setup shell security fonts fastfetch kitty yt-dlp virtualization cockpit ides git-setup languages podman-setup
    @echo "🚀 Entorno Portátil AMD Ryzen (KDE Plasma 6) configurado con éxito. Por favor, reinicia el sistema."

# Perfil para Sobremesa Centro Multimedia (Intel Core / Media Center - Sin virtualización ni batería)
setup-media-desktop: post-install-intel multimedia chrome tuning kde-setup shell security fonts fastfetch kitty yt-dlp kodi
    @echo "🚀 Entorno Sobremesa Intel (KDE Plasma 6) configurado con éxito. Por favor, reinicia el sistema."

# =============================================================================
# CONFIGURACIÓN BASE DEL SISTEMA
# =============================================================================

# Configuración base post-instalación (Auto-detección inteligente: AMD Ryzen vs Intel Core)
post-install:
    ./Setup/post-install.sh

# Configuración post-instalación para AMD Ryzen (Kernel, OpenH264, RADV, Mesa, PipeWire, Flatpak, KDE Plasma 6, ZRAM)
post-install-amd:
    ./Setup/post-install-amd.sh

# Configuración post-instalación para Intel Haswell/Core (Microcódigo Intel, i965/iHD VA-API, Kodi, PipeWire, KDE Plasma 6)
post-install-intel:
    ./Setup/post-install-intel.sh

# Optimización para portátiles de desarrollo (power-profiles-daemon, Bluetooth FastConnectable, cierre de tapa con multimonitor, Touchpad Wayland y PowerDevil Plasma 6)
laptop:
    ./Setup/laptop-setup.sh

# Autenticación y desbloqueo por huella dactilar (fprintd, PAM con pam-config)
fingerprint *args:
    ./Setup/fingerprint-setup.sh {{args}}

# Estado y diagnóstico de la autenticación por huella dactilar
fingerprint-status:
    ./Setup/fingerprint-setup.sh --status

# Optimizar SDDM para contraseña inmediata sin retardo y desbloqueo de KWallet
fingerprint-sddm-bypass:
    ./Setup/fingerprint-setup.sh --sddm-bypass

# Configuración de impresoras HP (CUPS, HPLIP, plugin propietario para LaserJet M15w)
printer:
    ./Setup/hp-printer-setup.sh

# Estado del sistema de impresión HP
printer-status:
    ./Setup/hp-printer-setup.sh --status

# Personalización y configuración de KDE Plasma 6 (Breeze Dark, KWin botones, Dolphin KIO servicemenu, atajos)
kde-setup:
    ./Setup/kde-settings.sh

# Aplicar tema oscuro completo en KDE Plasma 6 (Breeze Dark + GTK Breeze-Dark)
kde-theme-dark:
    ./Setup/kde-settings.sh --dark

# Aplicar tema claro completo en KDE Plasma 6 (Breeze Light)
kde-theme-light:
    ./Setup/kde-settings.sh --light

# Diagnóstico y estado de la configuración de KDE Plasma 6
kde-status:
    ./Setup/kde-settings.sh --status

# Optimizaciones avanzadas de rendimiento (Sysctl, límites, Snapper retention, Baloo exclusions, Distrobox)
tuning:
    ./Setup/tumbleweed-tuning.sh

# Estado actual de las optimizaciones y métricas de rendimiento
tuning-status:
    ./Setup/tumbleweed-tuning.sh --status

# Utilidades de terminal modernas (eza, bat, fzf, zoxide, ripgrep, fd, duf, dust, btop)
shell:
    ./Setup/shell.sh

# Diagnóstico y estado de utilidades CLI de terminal (eza, bat, fzf, zoxide, ripgrep...)
shell-status:
    ./Setup/shell.sh --status

# Starship Prompt moderno (Instalar / Activar)
starship:
    ./Setup/starship.sh --enable

# Desactivar Starship y restaurar prompt nativo
starship-disable:
    ./Setup/starship.sh --disable

# Estado de Starship prompt
starship-status:
    ./Setup/starship.sh --status

# Seguridad y cortafuegos (Firewalld con servicios kdeconnect, mdns, ssh, KVM virbr0, Podman rootless, Sysctl)
security:
    ./Setup/seguridad.sh

# Estado y diagnóstico de seguridad, cortafuegos y sysctl
security-status:
    ./Setup/seguridad.sh --status

# Fuentes de desarrollo (Nerd Fonts: JetBrainsMono, FiraCode, CascadiaCode, Meslo, Hack)
fonts:
    ./Setup/fonts.sh

# Estado y diagnóstico de fuentes de desarrollo (Nerd Fonts)
fonts-status:
    ./Setup/fonts.sh --status


# Información estética del sistema (Fastfetch)
fastfetch *args:
    ./Setup/fastfetch.sh {{args}}

# Estado y diagnóstico de la configuración de Fastfetch
fastfetch-status:
    ./Setup/fastfetch.sh --status

# Terminal Kitty acelerada por GPU con tema Catppuccin Mocha, opacidad/blur y atajo Ctrl+Alt+T
kitty:
    ./Setup/kitty.sh

# Multimedia (yt-dlp stack, FFmpeg, aria2, motor JS Deno vía Mise)
yt-dlp *args:
    ./Setup/yt-dlp-setup.sh {{args}}

# Diagnóstico y estado de yt-dlp y herramientas multimedia
yt-dlp-status:
    ./Setup/yt-dlp-setup.sh --status

# Códecs multimedia oficiales (OpenH264 Cisco) y entorno multimedia Flatpak (sin Packman)
multimedia:
    ./Setup/multimedia.sh

# Estado de repositorios multimedia (OpenH264), códecs oficiales y Flatpak
multimedia-status:
    ./Setup/multimedia.sh --status

# Aplicaciones y herramientas desacopladas vía Flatpak (Flatseal, Podman Desktop, Warehouse, VLC...)
flatpak *args:
    ./Setup/flatpak.sh {{args}}

# Diagnóstico y estado de Flatpak, repositorio Flathub y aplicaciones instaladas
flatpak-status:
    ./Setup/flatpak.sh --status

# Actualizar todas las aplicaciones y runtimes de Flatpak
flatpak-update:
    ./Setup/flatpak.sh --update

# Limpiar runtimes huérfanos y dependencias no utilizadas de Flatpak
flatpak-clean:
    ./Setup/flatpak.sh --clean

# Navegador Google Chrome oficial (Instalación, actualización u opciones)
chrome *args:
    ./Setup/chrome.sh {{args}}

# Diagnóstico y estado de Google Chrome, repositorio oficial y Wayland
chrome-status:
    ./Setup/chrome.sh --status

# Steam nativo, GameMode, MangoHud y drivers Vulkan 32-bit
steam:
    ./Setup/steam.sh

# Centro Multimedia (Kodi + complementos de streaming)
kodi:
    sudo zypper --non-interactive install -y kodi kodi-inputstream-adaptive kodi-inputstream-rtmp kodi-pvr-iptvsimple

# Actualización continua del sistema Tumbleweed (zypper dup)
dup:
    sudo zypper dup

# Listar instantáneas de Snapper en Btrfs
snapshots:
    snapper list

# =============================================================================
# CONFIGURACIÓN DE RED Y VIRTUALIZACIÓN
# =============================================================================

# Configuración de KVM/QEMU y Libvirt (Optimizado para distribuciones Linux, KDE Wayland y virt-manager)
virtualization:
    ./Virtualizacion/virtualization.sh

# Diagnóstico y estado de la virtualización KVM/QEMU
virtualization-status:
    ./Virtualizacion/virtualization.sh --status

# Administración Web (Cockpit + Podman + Snapper + Máquinas Virtuales)
cockpit *args:
    ./Setup/cockpit.sh {{args}}

# Estado del servicio y módulos de Cockpit
cockpit-status:
    ./Setup/cockpit.sh --status

# Abrir Cockpit en el navegador web (https://localhost:9090)
cockpit-open:
    ./Setup/cockpit.sh --open

# Lanzar Cockpit Client Launcher (aplicación nativa de escritorio openSUSE)
cockpit-client:
    ./Setup/cockpit.sh --client

# Desinstalar y bloquear módulo de bootloader (GRUB2) en sistemas con systemd-boot
cockpit-remove-bootloader:
    ./Setup/cockpit.sh --remove-bootloader

# =============================================================================
# CONTROL DE VERSIONES
# =============================================================================

# Git, Delta, Lazygit, GH CLI
git-setup:
    ./IDE/git.sh

# =============================================================================
# GESTORES DE RUNTIMES
# =============================================================================

# Gestor de versiones Mise (Instalación, actualización u opciones)
mise *args:
    ./ProgrammingLanguages/mise.sh {{args}}

# Diagnóstico y estado de Mise y runtimes de desarrollo
mise-status:
    ./ProgrammingLanguages/mise.sh --status

# =============================================================================
# LENGUAJES DE PROGRAMACIÓN
# =============================================================================

# Todos los lenguajes
languages: mise node python rust dotnet java angular
    @echo "✅ Lenguajes instalados."

# Node.js LTS
node:
    ./ProgrammingLanguages/nodejs.sh

# Python con UV package manager
python:
    ./ProgrammingLanguages/python.sh

# Inicializador de proyectos Python con UV
python-uv:
    ./ProgrammingLanguages/python-uv-init.sh

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
