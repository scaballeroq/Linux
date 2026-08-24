# Omarchy Environment Configuration Justfile
# (Arch Linux + Omarchy)

# Instala todo el entorno por defecto
setup-all: post-install security fonts bash-setup virtualization mise cockpit ides git-setup languages yt-dlp fastfetch
    echo "🚀 Entorno completo de Omarchy (Arch Linux) configurado. Por favor, reinicia el sistema."

# =============================================================================
# CONFIGURACIÓN BASE DEL SISTEMA
# =============================================================================

# Configuración base post-instalación (Pacman, AUR, Flatpak, Codecs)
post-install:
    ./Setup/post-install.sh

# Seguridad básica (UFW firewall)
security:
    ./Setup/seguridad.sh

# Fuentes de desarrollo (Nerd Fonts: JetBrainsMono, FiraCode, CascadiaCode...)
fonts:
    ./Setup/fonts.sh

# Configuración modular de Bash (Aliases, Funciones, Entorno)
bash-setup:
    ./Bash.Setup/setup.sh

# Información estética del sistema (Fastfetch)
fastfetch:
    ./Setup/fastfetch.sh

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

# Antigravity CLI
antigravity-ai:
    ./AI/antigravity-CLI.sh

# =============================================================================
# ENTORNOS DE DESARROLLO (IDEs)
# =============================================================================

# Todos los IDEs
ides: nvim vscode antigravity antigravity-cli antigravity-ide opencode
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
# JUEGOS
# =============================================================================

# Steam y herramientas de juegos
steam:
    ./Juegos/steam.sh

# =============================================================================
# PODMAN
# =============================================================================

# Todos los servicios de Podman
podman-all: podman-base podman-nginx podman-postgres podman-redis podman-mongodb podman-mysql podman-minio podman-portainer podman-dozzle podman-grafana podman-prometheus podman-adminer podman-mailhog podman-rabbitmq podman-keycloak podman-wordpress podman-browserless podman-storybook podman-jaeger
    echo "✅ Todos los servicios de Podman configurados."

# Podman base
podman-base:
    ./Podman/podman.sh

# Servicios individuales de Podman
podman-nginx:
    ./Podman/podman-nginx.sh

podman-postgres:
    ./Podman/podman-postgres.sh

podman-redis:
    ./Podman/podman-redis.sh

podman-mongodb:
    ./Podman/podman-mongodb.sh

podman-mysql:
    ./Podman/podman-mysql.sh

podman-minio:
    ./Podman/podman-minio.sh

podman-portainer:
    ./Podman/podman-portainer.sh

podman-dozzle:
    ./Podman/podman-dozzle.sh

podman-grafana:
    ./Podman/podman-grafana.sh

podman-prometheus:
    ./Podman/podman-prometheus.sh

podman-adminer:
    ./Podman/podman-adminer.sh

podman-mailhog:
    ./Podman/podman-mailhog.sh

podman-rabbitmq:
    ./Podman/podman-rabbitmq.sh

podman-keycloak:
    ./Podman/podman-keycloak.sh

podman-wordpress:
    ./Podman/podman-wordpress.sh

podman-browserless:
    ./Podman/podman-browserless.sh

podman-storybook:
    ./Podman/podman-storybook.sh

podman-jaeger:
    ./Podman/podman-jaeger.sh
