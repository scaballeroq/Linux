# openSUSE Tumbleweed Environment Configuration Justfile
# (openSUSE Tumbleweed + KDE Plasma 6)

# Instala todo el entorno por defecto (Auto-detección de CPU / Portátil AMD)
setup-all: post-install multimedia chrome steam laptop tuning kde-setup shell security fonts fastfetch kitty yt-dlp virtualization cockpit ides git-setup languages podman-setup
    @echo "🚀 Entorno completo de openSUSE Tumbleweed (KDE Plasma 6) configurado. Por favor, reinicia el sistema."

# Perfil completo para Portátil de desarrollo (AMD Ryzen + Virtualización + Contenedores)
setup-laptop-amd: post-install-amd multimedia chrome steam laptop tuning kde-setup shell security fonts fastfetch kitty yt-dlp virtualization cockpit ides git-setup languages podman-setup
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

# Automontaje permanente de la partición Workspace (/home/caballero/Workspace) en /etc/fstab
workspace:
    ./Setup/mount-workspace.sh

# Optimización para portátiles de desarrollo (KDE Touchpad, PowerDevil, Bluetooth FastConnectable, persistencia de brillo al 95%)
laptop:
    ./Setup/laptop-setup.sh

# Autenticación y desbloqueo por huella dactilar (fprintd, PAM con pam-config)
fingerprint:
    ./Setup/fingerprint-setup.sh

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

# Seguridad avanzada (DNS-over-TLS con systemd-resolved)
security-dot:
    ./Setup/seguridad-dot.sh

# Fuentes de desarrollo (Nerd Fonts: JetBrainsMono, FiraCode, CascadiaCode...)
fonts:
    ./Setup/fonts.sh

# Apariencia e iconos (Papirus-Dark, Breeze-Dark e integración GTK 3/4 y Qt)
apariencia:
    ./Setup/apariencia.sh

# Información estética del sistema (Fastfetch)
fastfetch:
    ./Setup/fastfetch.sh

# Terminal Kitty acelerada por GPU con tema Catppuccin Mocha, opacidad/blur y atajo Ctrl+Alt+T
kitty:
    ./Setup/kitty.sh

# Multimedia (yt-dlp stack, FFmpeg, AtomicParsley, aria2, motor JS Deno)
yt-dlp:
    ./Setup/yt-dlp-setup.sh

# Códecs multimedia oficiales (OpenH264 Cisco) y entorno multimedia Flatpak (sin Packman)
multimedia:
    ./Setup/multimedia.sh

# Estado de repositorios multimedia (OpenH264), códecs oficiales y Flatpak
multimedia-status:
    ./Setup/multimedia.sh --status

# Navegador Google Chrome oficial
chrome:
    ./Setup/chrome.sh

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

# Administración Web (Cockpit + Cockpit Podman + Cockpit Snapper)
cockpit:
    ./Setup/cockpit.sh

# Estado del servicio Cockpit
cockpit-status:
    ./Setup/cockpit.sh --status

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
