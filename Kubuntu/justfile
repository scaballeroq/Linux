# =============================================================================
# Kubuntu Environment Configuration Justfile (KDE Plasma)
# =============================================================================

# Instala todo el entorno (Post-install, Workspace, Laptop, Fingerprint, KDE, Shell, Seguridad, Fuentes, Virtualización, Mise, Cockpit, etc.)
setup-all: post-install workspace laptop fingerprint printer kde shell security fonts virtualization mise cockpit ides git-setup languages yt-dlp fastfetch apariencia firefox
    echo "🚀 Entorno completo de Kubuntu configurado. Por favor, reinicia el sistema."

# =============================================================================
# CONFIGURACIÓN BASE DEL SISTEMA
# =============================================================================

# Configuración base post-instalación (Repositorios universe/multiverse, flatpak, codecs)
post-install:
    ./Setup/post-install.sh

# Automontaje permanente de la partición Workspace (/home/caballero/Workspace) en /etc/fstab
workspace:
    ./Setup/mount-workspace.sh

# Optimización para portátiles de desarrollo en Kubuntu (Touchpad, Batería, Bluetooth)
laptop:
    ./Setup/laptop-setup.sh

# Autenticación y desbloqueo por huella dactilar (fprintd, PAM, sudo, polkit, SDDM)
fingerprint:
    ./Setup/fingerprint-setup.sh

# Configuración e instalación de impresora HP LaserJet Pro M15w (USB)
printer:
    ./Setup/hp-printer-setup.sh

# Personalización y optimización de KDE Plasma 6 / 5 (Night Color, atajos, KWin, energía)
kde:
    ./Setup/kde-settings.sh

# Utilidades de terminal y prompt (eza, bat, fzf, zoxide, starship)
shell:
    ./Setup/shell.sh

# Seguridad básica (UFW firewall con reglas de desarrollo)
security:
    ./Setup/seguridad.sh

# Fuentes de desarrollo (Nerd Fonts)
fonts:
    ./Setup/fonts.sh

# Información estética del sistema
fastfetch:
    ./Setup/fastfetch.sh

# Apariencia (Temas e iconos Papirus y Breeze)
apariencia:
    ./Setup/apariencia.sh

# Navegador Firefox nativo (.deb oficial de Mozilla con APT Pinning)
firefox:
    ./Setup/firefox.sh

# Multimedia (yt-dlp, ffmpeg, motor Deno)
yt-dlp:
    ./Setup/yt-dlp-setup.sh

# =============================================================================
# CONFIGURACIÓN DE RED Y VIRTUALIZACIÓN
# =============================================================================

# Configuración de KVM/QEMU, Libvirt, bridge br0 y virt-manager
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

# Todos los lenguajes principales
languages: node python rust dotnet java
    echo "✅ Lenguajes instalados."

# Node.js LTS + pnpm vía Corepack
node:
    ./ProgrammingLanguages/nodejs.sh

# Python 3.12 vía Mise
python:
    ./ProgrammingLanguages/python.sh

# Rust vía rustup + cargo-binstall
rust:
    ./ProgrammingLanguages/rust.sh

# .NET SDK
dotnet:
    ./ProgrammingLanguages/dotnet.sh

# Java (OpenJDK)
java:
    ./ProgrammingLanguages/java.sh

# =============================================================================
# HERRAMIENTAS DE IA Y FRAMEWORKS
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

# Google Antigravity Desktop
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
# APLICACIONES Y JUEGOS
# =============================================================================

# Meld (visor de diffs y merges)
meld:
    ./Apps/meld.sh

# Steam y Proton-GE via Flatpak
steam:
    ./Juegos/steam.sh

# =============================================================================
# PODMAN - BASE Y SERVICIOS
# =============================================================================

# Podman base (instalación y configuración rootless)
podman-base:
    ./Podman/podman.sh

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

# Stacks completos agrupados
podman-databases: podman-postgres podman-mysql podman-mongodb podman-redis
    echo "✅ Bases de datos iniciadas."

podman-monitoring: podman-prometheus podman-grafana podman-jaeger podman-dozzle
    echo "✅ Stack de monitoreo iniciado."

podman-admin: podman-portainer podman-adminer podman-keycloak
    echo "✅ Stack de administración iniciado."
