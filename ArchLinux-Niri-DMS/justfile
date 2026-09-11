# Arch Linux Environment Configuration Justfile
# (Arch Linux + Niri & Dank Material Shell)

# Instala todo el entorno por defecto (Auto-detección de CPU / Portátil AMD)
setup-all: post-install shell security fonts fastfetch kitty yt-dlp virtualization cockpit ides git-setup languages podman-setup dms-setup
    @echo "🚀 Entorno completo de Arch Linux (Niri + Dank Material Shell) configurado. Por favor, reinicia el sistema."

# Perfil completo para Portátil de desarrollo (AMD Ryzen + Virtualización + Contenedores)
setup-laptop-amd: post-install-amd shell security fonts fastfetch kitty yt-dlp virtualization cockpit ides git-setup languages podman-setup dms-setup
    @echo "🚀 Entorno Portátil AMD Ryzen configurado con éxito. Por favor, reinicia el sistema."

# Perfil para Sobremesa (Intel Core - Sin virtualización ni batería)
setup-media-desktop: post-install-intel shell security fonts fastfetch kitty yt-dlp dms-setup
    @echo "🚀 Entorno Sobremesa Intel configurado con éxito. Por favor, reinicia el sistema."

# =============================================================================
# CONFIGURACIÓN BASE DEL SISTEMA
# =============================================================================

# Configuración base post-instalación (Auto-detección inteligente: AMD Ryzen vs Intel Core)
post-install:
    ./Setup/post-install.sh

# Configuración post-instalación para AMD Ryzen (Kernel, firmware AMD, RADV, Mesa, PipeWire, Niri, DMS)
post-install-amd:
    ./Setup/post-install-amd.sh

# Configuración post-instalación para Intel Core (Kernel, microcódigo Intel, VA-API Intel, PipeWire, Niri, DMS)
post-install-intel:
    ./Setup/post-install-intel.sh

# Utilidades de terminal modernas (eza, bat, fzf, zoxide, ripgrep, starship, zsh)
shell:
    ./Setup/shell.sh

# Seguridad y cortafuegos (Firewalld, LAN doméstica, QEMU/KVM, Podman, Sysctl)
security:
    ./Setup/seguridad.sh

# Estado y diagnóstico de la seguridad y Firewalld
security-status:
    ./Setup/seguridad.sh --status

# Fuentes de desarrollo (Nerd Fonts: JetBrainsMono, FiraCode, CascadiaCode, Inter Variable...)
fonts:
    ./Setup/fonts.sh

# Información estética del sistema (Fastfetch)
fastfetch:
    ./Setup/fastfetch.sh

# Terminal Kitty acelerada por GPU con tema dinámico Material You y opacidad/blur
kitty:
    ./Setup/kitty.sh

# Multimedia (yt-dlp stack, FFmpeg, AtomicParsley, aria2, motor JS Deno/Node)
yt-dlp:
    ./Setup/yt-dlp-setup.sh

# =============================================================================
# DANK MATERIAL SHELL (DMS)
# =============================================================================

# Verificación y configuración del servicio y componentes de DMS
dms-setup:
    ./Setup/dms-setup.sh

# Diagnóstico de salud de DMS (dms doctor)
dms-doctor:
    ./Setup/dms-setup.sh --status

# Reiniciar Dank Material Shell
dms-restart:
    ./Setup/dms-setup.sh --restart

# Regenerar temas dinámicos Material You (Matugen)
dms-theme:
    ./Setup/dms-setup.sh --theme

# =============================================================================
# CONFIGURACIÓN DE RED Y VIRTUALIZACIÓN
# =============================================================================

# Configuración de KVM/QEMU y Libvirt (Optimizado para distribuciones Linux)
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
# ENTORNOS DE DESARROLLO (IDEs) Y HERRAMIENTAS
# =============================================================================

# Todos los IDEs principales
ides: antigravity antigravity-cli antigravity-ide opencode
    @echo "✅ IDEs principales instalados."

# Google Antigravity Desktop 2.0 (Completo)
antigravity:
    ./IDE/antigravity.sh

# Google Antigravity CLI (agy)
antigravity-cli:
    ./IDE/antigravity-cli.sh

# Google Antigravity IDE Engine
antigravity-ide:
    ./IDE/antigravity-ide.sh

# OpenCode AI CLI/Editor
opencode:
    ./IDE/opencode.sh

# Visual Studio Code (AUR visual-studio-code-bin)
vscode:
    ./IDE/vscode.sh

# Neovim + LazyVim
neovim:
    ./IDE/neovim.sh

# Herramienta visual de diferencias Meld
meld:
    ./Apps/meld.sh

# Google Gemini CLI
gemini:
    ./AI/gemini.sh

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

# =============================================================================
# COPIAS DE SEGURIDAD
# =============================================================================

# Copia de seguridad de configuraciones de Niri y Dank Material Shell
backup:
    ./Setup/backup-niri-dms.sh

# Listar copias de seguridad disponibles
backup-list:
    ./Setup/backup-niri-dms.sh --list

# Restaurar última copia de seguridad
backup-restore:
    ./Setup/backup-niri-dms.sh --restore
