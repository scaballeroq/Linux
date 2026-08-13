# Debian Environment Configuration Justfile

# Instala todo el entorno (Post-install, Workspace, Laptop, Fingerprint, Tuning, Extensions, Screensaver, Shell, Virtualización, Mise, Cockpit, etc.)
setup-all: post-install workspace laptop fingerprint tuning extensions screensaver shell security fonts virtualization mise cockpit ides git-setup languages yt-dlp fastfetch gnome ptyxis firefox
    echo "🚀 Entorno completo de Debian configurado. Por favor, reinicia el sistema."

# =============================================================================
# CONFIGURACIÓN BASE DEL SISTEMA
# =============================================================================

# Configuración base post-instalación (Repositorios contrib, non-free, backports)
post-install:
    ./Setup/post-install.sh

# Automontaje permanente de la partición Workspace (/home/caballero/Workspace) en /etc/fstab
workspace:
    ./Setup/mount-workspace.sh

# Compilador de Kernel Linux optimizado para x86_64-v3 y ajustado a tu portátil
build-kernel:
    ./Setup/build-custom-kernel.sh

# Instalación del último Kernel Linux oficial y Firmware desde Debian Backports
kernel-backports:
    ./Setup/install-backports-kernel.sh

# Optimización para portátiles de desarrollo (Touchpad, Batería, Bluetooth, HiDPI)
laptop:
    ./Setup/laptop-setup.sh

# Autenticación y desbloqueo por huella dactilar (fprintd, PAM, sudo, polkit)
fingerprint:
    ./Setup/fingerprint-setup.sh

# Configuración e instalación de impresora HP LaserJet Pro M15w (USB)
printer:
    ./Setup/hp-printer-setup.sh

# Optimizaciones avanzadas de Debian (Sysctl, Distrobox)
tuning:
    ./Setup/debian-tuning.sh

# Instalación automatizada de conectores y las 17 extensiones de GNOME
extensions:
    ./Setup/gnome-extensions.sh

# Configuración de salvapantallas 3D/Matrix al bloquear la pantalla
screensaver:
    ./Setup/screensaver-setup.sh

# Utilidades de terminal y prompt (eza, bat, fzf, starship)
shell:
    ./Setup/shell.sh

# Seguridad básica (UFW firewall)
security:
    ./Setup/seguridad.sh

# Seguridad avanzada (DNS-over-TLS)
security-dot:
    ./Setup/seguridad-dot.sh

# Fuentes de desarrollo (Nerd Fonts)
fonts:
    ./Setup/fonts.sh

# Personalización de GNOME (gsettings)
gnome:
    ./Setup/gnome-settings.sh

# Información estética del sistema
fastfetch:
    ./Setup/fastfetch.sh

# Apariencia (temas e iconos)
apariencia:
    ./Setup/apariencia.sh

# Terminal Ptyxis + integración Nautilus
ptyxis:
    ./Setup/ptyxis.sh

# Multimedia (yt-dlp, ffmpeg)
yt-dlp:
    ./Setup/yt-dlp-setup.sh

# =============================================================================
# CONFIGURACIÓN DE RED Y VIRTUALIZACIÓN
# =============================================================================

# Configuración de KVM/QEMU
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

# Meld (diff viewer)
meld:
    ./Apps/meld.sh

# Steam y herramientas de juegos
steam:
    ./Juegos/steam.sh

# =============================================================================
# PODMAN - BASE
# =============================================================================

# Podman base (instalación y configuración rootless)
podman-base:
    ./Podman/podman.sh

# =============================================================================
# PODMAN - SERVICIOS
# =============================================================================

# Bases de datos
podman-postgres:
    ./Podman/podman-postgres.sh

podman-mysql:
    ./Podman/podman-mysql.sh

podman-mongodb:
    ./Podman/podman-mongodb.sh

podman-redis:
    ./Podman/podman-redis.sh

# Almacenamiento
podman-minio:
    ./Podman/podman-minio.sh

# Monitoreo y Observabilidad
podman-grafana:
    ./Podman/podman-grafana.sh

podman-prometheus:
    ./Podman/podman-prometheus.sh

podman-jaeger:
    ./Podman/podman-jaeger.sh

podman-dozzle:
    ./Podman/podman-dozzle.sh

# Administración
podman-portainer:
    ./Podman/podman-portainer.sh

podman-adminer:
    ./Podman/podman-adminer.sh

# Autenticación
podman-keycloak:
    ./Podman/podman-keycloak.sh

# Web y Proxy
podman-nginx:
    ./Podman/podman-nginx.sh

# CMS
podman-wordpress:
    ./Podman/podman-wordpress.sh

# Mensajería
podman-rabbitmq:
    ./Podman/podman-rabbitmq.sh

podman-mailhog:
    ./Podman/podman-mailhog.sh

# Testing
podman-browserless:
    ./Podman/podman-browserless.sh

podman-storybook:
    ./Podman/podman-storybook.sh

# Stack de desarrollo completo (todas las bases de datos)
podman-databases: podman-postgres podman-mysql podman-mongodb podman-redis
    echo "✅ Bases de datos iniciadas."

# Stack de monitoreo completo
podman-monitoring: podman-prometheus podman-grafana podman-jaeger podman-dozzle
    echo "✅ Stack de monitoreo iniciado."

# Stack de administración completo
podman-admin: podman-portainer podman-adminer podman-keycloak
    echo "✅ Stack de administración iniciado."
