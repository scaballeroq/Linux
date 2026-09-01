# =============================================================================
# Kubuntu Environment Configuration Justfile (KDE Plasma 6)
# =============================================================================

# Perfiles de instalacion completa
setup-all: post-install zram workspace laptop fingerprint printer kde widgets kde-custom konsole kitty shell security security-dot fonts tuning fastfetch apariencia firefox yt-dlp screensaver virtualization cockpit git-setup mise languages ides podman-setup
    echo "Entorno completo de Kubuntu configurado. Reinicia el sistema."

# Perfil portatil AMD Ryzen
setup-laptop-amd: post-install-amd zram workspace laptop fingerprint printer kde widgets kde-custom konsole kitty shell security security-dot fonts tuning fastfetch apariencia firefox yt-dlp screensaver virtualization cockpit git-setup mise languages ides podman-setup
    echo "Entorno Portatil AMD Ryzen configurado. Reinicia el sistema."

# Perfil portatil Intel Core
setup-laptop-intel: post-install-intel zram workspace laptop fingerprint printer kde widgets kde-custom konsole kitty shell security security-dot fonts tuning fastfetch apariencia firefox yt-dlp screensaver virtualization cockpit git-setup mise languages ides podman-setup
    echo "Entorno Portatil Intel Core configurado. Reinicia el sistema."

# Perfil sobremesa AMD (sin laptop/bateria)
setup-desktop-amd: post-install-amd zram kde widgets kde-custom konsole kitty shell security security-dot fonts tuning fastfetch apariencia firefox yt-dlp virtualization cockpit git-setup mise languages ides podman-setup
    echo "Entorno Sobremesa AMD configurado. Reinicia el sistema."

# Perfil sobremesa Intel (sin laptop/bateria)
setup-desktop-intel: post-install-intel zram kde widgets kde-custom konsole kitty shell security security-dot fonts tuning fastfetch apariencia firefox yt-dlp virtualization cockpit git-setup mise languages ides podman-setup
    echo "Entorno Sobremesa Intel configurado. Reinicia el sistema."

# =============================================================================
# CONFIGURACION BASE DEL SISTEMA
# =============================================================================

# Configuracion base post-instalacion (auto-deteccion CPU)
post-install:
    ./Setup/post-install.sh

# Post-instalacion AMD Ryzen
post-install-amd:
    ./Setup/post-install-amd.sh

# Post-instalacion Intel Core
post-install-intel:
    ./Setup/post-install-intel.sh

# ZRAM con compresion ZSTD
zram:
    ./Setup/zram-setup.sh

# Automontaje permanente de la particion Workspace
workspace:
    ./Setup/mount-workspace.sh

# Optimizacion para portatiles
laptop:
    ./Setup/laptop-setup.sh

# Autenticacion por huella dactilar
fingerprint:
    ./Setup/fingerprint-setup.sh

# Impresora HP LaserJet Pro M15w
printer:
    ./Setup/hp-printer-setup.sh

# Personalizacion de KDE Plasma 6/5
kde:
    ./Setup/kde-settings.sh

# Widgets, Klipper y Atajos
widgets:
    ./Setup/kde-widgets.sh

# Personalizacion avanzada KDE (Material You, plasmoids)
kde-custom:
    ./Setup/kde-plasma-customization.sh

# Terminal Konsole translucido
konsole:
    ./Setup/konsole.sh

# Terminal Kitty GPU
kitty:
    ./Setup/kitty.sh

# Utilidades de terminal y prompt
shell:
    ./Setup/shell.sh

# Seguridad avanzada (UFW + Fail2ban + sysctl)
security:
    ./Setup/seguridad.sh

# DNS-over-TLS
security-dot:
    ./Setup/seguridad-dot.sh

# Fuentes de desarrollo
fonts:
    ./Setup/fonts.sh

# Optimizaciones de rendimiento
tuning:
    ./Setup/kubuntu-tuning.sh

# Estado de optimizaciones
tuning-status:
    ./Setup/kubuntu-tuning.sh --status

# Informacion estetica del sistema
fastfetch:
    ./Setup/fastfetch.sh

# Apariencia (Temas e iconos)
apariencia:
    ./Setup/apariencia.sh

# Firefox nativo (.deb)
firefox:
    ./Setup/firefox.sh

# Multimedia (yt-dlp, ffmpeg, Deno)
yt-dlp:
    ./Setup/yt-dlp-setup.sh

# Pantalla de bloqueo
screensaver:
    ./Setup/screensaver-setup.sh

# =============================================================================
# CONFIGURACION DE RED Y VIRTUALIZACION
# =============================================================================

# KVM/QEMU, Libvirt, bridge br0, virt-manager
virtualization:
    ./Virtualizacion/virtualization.sh

# Administracion Web (Cockpit)
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
# LENGUAJES DE PROGRAMACION
# =============================================================================

languages: node python rust dotnet java
    echo "Lenguajes instalados."

node:
    ./ProgrammingLanguages/nodejs.sh

python:
    ./ProgrammingLanguages/python.sh

rust:
    ./ProgrammingLanguages/rust.sh

dotnet:
    ./ProgrammingLanguages/dotnet.sh

java:
    ./ProgrammingLanguages/java.sh

# =============================================================================
# HERRAMIENTAS DE IA Y FRAMEWORKS
# =============================================================================

gemini:
    ./ProgrammingLanguages/gemini.sh

angular:
    ./ProgrammingLanguages/angular.sh

# =============================================================================
# ENTORNOS DE DESARROLLO (IDEs)
# =============================================================================

ides: nvim vscode antigravity antigravity-cli antigravity-ide opencode
    echo "IDEs instalados."

nvim:
    ./IDE/neovim.sh

vscode:
    ./IDE/vscode.sh

antigravity:
    ./IDE/antigravity.sh

antigravity-cli:
    ./IDE/antigravity-cli.sh

antigravity-ide:
    ./IDE/antigravity-ide.sh

opencode:
    ./IDE/opencode.sh

# =============================================================================
# APLICACIONES Y JUEGOS
# =============================================================================

meld:
    ./Apps/meld.sh

steam:
    ./Juegos/steam.sh

# =============================================================================
# PODMAN Y CONTENEDORES QUADLETS
# =============================================================================

# Configuracion completa de Podman Rootless y Quadlets
podman-setup:
    ./Podman/install/podman-install.sh
    ./Podman/install/quadlets-setup.sh

# Podman base
podman-base:
    ./Podman/install/podman-install.sh

# Quadlets
podman-quadlets:
    ./Podman/install/quadlets-setup.sh

# Estado de Podman
podman-status:
    ./Podman/install/podman-install.sh --status
    ./Podman/lib/podman-utils.sh doctor
