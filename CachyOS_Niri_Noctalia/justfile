# CachyOS Environment Configuration Justfile
# (CachyOS + Niri & Noctalia Shell)

# Instala todo el entorno por defecto (Auto-deteccion de CPU / Portatil AMD)
setup-all: post-install niri-setup laptop tuning shell security fonts fastfetch kitty yt-dlp virtualization cockpit ides git-setup languages podman-setup
    @echo "🚀 Entorno completo de CachyOS (Niri + Noctalia Shell) configurado. Por favor, reinicia el sistema."

# Perfil completo para Portatil de desarrollo (AMD Ryzen + Virtualizacion + Contenedores)
setup-laptop-amd: post-install-amd niri-setup laptop tuning shell security fonts fastfetch kitty yt-dlp virtualization cockpit ides git-setup languages podman-setup
    @echo "🚀 Entorno Portatil AMD Ryzen configurado con exito. Por favor, reinicia el sistema."

# Perfil para Sobremesa (Intel Core - Sin virtualizacion ni bateria)
setup-media-desktop: post-install-intel niri-setup tuning shell security fonts fastfetch kitty yt-dlp
    @echo "🚀 Entorno Sobremesa Intel configurado con exito. Por favor, reinicia el sistema."

# =============================================================================
# CONFIGURACION BASE DEL SISTEMA
# =============================================================================

# Configuracion base post-instalacion (Auto-deteccion inteligente: AMD Ryzen vs Intel Core)
post-install:
    ./Setup/post-install.sh

# Configuracion post-instalacion para AMD Ryzen (Kernel, firmware-amd, RADV, Mesa, PipeWire, Niri)
post-install-amd:
    ./Setup/post-install-amd.sh

# Configuracion post-instalacion para Intel Core (Kernel, microcodigo Intel, VA-API Intel, PipeWire, Niri)
post-install-intel:
    ./Setup/post-install-intel.sh

# Configuracion e integracion de Niri y Noctalia Shell (Wayland)
niri-setup:
    ./Setup/niri-setup.sh

# Estado y diagnostico de Niri y Noctalia Shell
niri-status:
    ./Setup/niri-setup.sh --status

# Optimizacion para portatiles de desarrollo (Touchpad, Bateria, Bluetooth, tuned-ppd, persistencia de brillo)
laptop:
    ./Setup/laptop-setup.sh

# Optimizaciones avanzadas de rendimiento (Sysctl, limites, Systemd, Wayland para CachyOS + Niri)
tuning:
    ./Setup/cachyos-tuning.sh

# Estado actual de las optimizaciones y metricas de rendimiento
tuning-status:
    ./Setup/cachyos-tuning.sh --status

# Utilidades de terminal modernas (eza, bat, fzf, zoxide, ripgrep)
shell:
    ./Setup/shell.sh


# Seguridad y cortafuegos (Firewalld, LAN domestica, QEMU/KVM, Podman, Sysctl)
security:
    ./Setup/seguridad.sh

# Estado y diagnostico de la seguridad y Firewalld
security-status:
    ./Setup/seguridad.sh --status

# Fuentes de desarrollo (Nerd Fonts: JetBrainsMono, FiraCode, CascadiaCode...)
fonts:
    ./Setup/fonts.sh

# Informacion estetica del sistema (Fastfetch)
fastfetch:
    ./Setup/fastfetch.sh

# Terminal Kitty acelerada por GPU con tema oscuro y opacidad/blur
kitty:
    ./Setup/kitty.sh

# Multimedia (yt-dlp stack, FFmpeg, AtomicParsley, aria2, motor JS Deno)
yt-dlp:
    ./Setup/yt-dlp-setup.sh

# =============================================================================
# CONFIGURACION DE RED Y VIRTUALIZACION
# =============================================================================

# Configuracion de KVM/QEMU y Libvirt (Optimizado para distribuciones Linux)
virtualization:
    ./Virtualizacion/virtualization.sh

# Diagnostico y estado de la virtualizacion KVM/QEMU
virtualization-status:
    ./Virtualizacion/virtualization.sh --status

# Administracion Web (Cockpit)
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
# LENGUAJES DE PROGRAMACION
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

# Configuracion completa de Podman Rootless y Quadlets
podman-setup:
    ./Podman/install/podman-install.sh
    ./Podman/install/quadlets-setup.sh

# Configuracion base de Podman Rootless
podman-base:
    ./Podman/install/podman-install.sh

# Configuracion de servicios Quadlets de Podman
podman-quadlets:
    ./Podman/install/quadlets-setup.sh

# Estado y diagnostico de Podman y Quadlets
podman-status:
    ./Podman/install/podman-install.sh --status
    ./Podman/lib/podman-utils.sh doctor

# =============================================================================
# JUEGOS
# =============================================================================

# Steam + Proton Cachyos
steam:
    ./Juegos/steam.sh
