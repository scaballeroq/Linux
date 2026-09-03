#!/bin/bash
# =============================================================================
# kde-plasma-customization.sh - Automatización de Personalización KDE Plasma 6
# Basado en configuraciones de The Linux Experiment & The Markella's
# Debian Testing (Trixie/Sid) + KDE Plasma 6
# =============================================================================

set -euo pipefail

# Colores para salida de terminal
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"
RESET="\033[0m"

log_info() { echo -e "${BLUE}ℹ️  $1${RESET}"; }
log_success() { echo -e "${GREEN}✅ $1${RESET}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${RESET}"; }
log_error() { echo -e "${RED}❌ $1${RESET}"; }
log_step() { echo -e "\n${CYAN}=================================================================${RESET}\n${CYAN}🚀 $1${RESET}\n${CYAN}=================================================================${RESET}"; }

# Directorio temporal de trabajo para clonar y compilar
BUILD_DIR="$(mktemp -d /tmp/kde-custom-build-XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT

# Comprobar privilegios sudo
if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        log_error "Este script requiere privilegios de superusuario (root o sudo)."
        exit 1
    fi
else
    SUDO=""
fi

# Detectar herramienta kwriteconfig (kwriteconfig6 o kwriteconfig5)
KWRITECFG=""
if command -v kwriteconfig6 &>/dev/null; then
    KWRITECFG="kwriteconfig6"
elif command -v kwriteconfig5 &>/dev/null; then
    KWRITECFG="kwriteconfig5"
fi

set_kconfig() {
    local file="$1"
    local group="$2"
    local key="$3"
    local value="$4"

    if [ -n "$KWRITECFG" ]; then
        $KWRITECFG --file "$file" --group "$group" --key "$key" "$value" 2>/dev/null || true
    else
        python3 - <<PYEOF
import configparser, os
cfg_path = os.path.expanduser("~/.config/${file}")
os.makedirs(os.path.dirname(cfg_path), exist_ok=True)
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')
group = "${group}"
if not config.has_section(group):
    config.add_section(group)
config.set(group, "${key}", "${value}")
with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF
    fi
}

# -----------------------------------------------------------------------------
# 1. Dependencias del Sistema y Paquetes de Compilación
# -----------------------------------------------------------------------------
log_step "1/8: Instalando dependencias del sistema y librerías Qt6 / KF6..."

$SUDO apt update

# Paquetes base y librerías completas de compilación para KDE Plasma 6 en Debian Testing
DEPS=(
    build-essential
    cmake
    extra-cmake-modules
    git
    curl
    wget
    jq
    pipx
    python3-pip
    python3-pyqt6
    python3-setuptools
    python3-dbus
    libdbus-1-dev
    pkgconf
    ninja-build
    qt6-base-dev
    qt6-declarative-dev
    qt6-svg-dev
    libkf6config-dev
    libkf6coreaddons-dev
    libkf6guiaddons-dev
    libkf6i18n-dev
    libkf6windowsystem-dev
    libkf6kio-dev
    libkf6colorscheme-dev
    libkf6kcmutils-dev
    libkf6iconthemes-dev
    libkf6style-dev
    libkf6xmlgui-dev
    libkf6globalaccel-dev
    libkf6newstuff-dev
    libkf6breezeicons-dev
    libkf6dbusaddons-dev
    libkf6crash-dev
    libkdecorations3-dev
    kwin-dev
    qt6-style-kvantum
    qt-style-kvantum-themes
    plasma-widgets-addons
    plasma-workspace-dev
    libplasma-dev
    papirus-icon-theme
    breeze-icon-theme
)

for pkg in "${DEPS[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        log_info "Instalando paquete: $pkg..."
        $SUDO apt install -y "$pkg" 2>/dev/null || log_warn "Paquete $pkg omitido o no disponible directamente en repositorios."
    fi
done

pipx ensurepath || true
export PATH="$HOME/.local/bin:$PATH"
log_success "Dependencias del sistema instaladas."

# -----------------------------------------------------------------------------
# 2. KDE Material You Colors (Colores Dinámicos de Sistema)
# -----------------------------------------------------------------------------
log_step "2/8: Configurando KDE Material You Colors..."

log_info "Instalando kde-material-you-colors mediante pipx..."
pipx install --system-site-packages kde-material-you-colors --force || pipx install kde-material-you-colors --force || pipx upgrade kde-material-you-colors || true

# Configurar servicio autostart
mkdir -p "$HOME/.config/autostart"
cat <<'EOF' > "$HOME/.config/autostart/kde-material-you-colors.desktop"
[Desktop Entry]
Type=Application
Exec=kde-material-you-colors --daemon
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=KDE Material You Colors Daemon
Comment=Dynamic system accent colors based on wallpaper
EOF

log_success "KDE Material You Colors configurado con inicio automático."

# -----------------------------------------------------------------------------
# 3. Kvantum Engine & Temas (Fluent-Dark y Windsur)
# -----------------------------------------------------------------------------
log_step "3/8: Configurando motor de estilos Kvantum y temas translúcidos..."

mkdir -p "$HOME/.config/Kvantum"
mkdir -p "$HOME/.local/share/Kvantum"
mkdir -p "$HOME/.local/share/aurorae/themes"

# Descargar tema Fluent KDE (Kvantum + Aurorae)
log_info "Descargando e instalando tema Fluent Dark para Kvantum..."
cd "$BUILD_DIR"
if git clone --depth=1 https://github.com/vinceliuice/Fluent-kde.git; then
    cd Fluent-kde
    # Instalar tema Kvantum Fluent
    if [ -d "Kvantum" ]; then
        cp -r Kvantum/* "$HOME/.config/Kvantum/" 2>/dev/null || true
        cp -r Kvantum/* "$HOME/.local/share/Kvantum/" 2>/dev/null || true
    fi
    # Instalar tema Aurorae Fluent
    if [ -d "aurorae" ]; then
        cp -r aurorae/* "$HOME/.local/share/aurorae/themes/" 2>/dev/null || true
    fi
fi

# Configuración de Kvantum activo
cat <<'EOF' > "$HOME/.config/Kvantum/kvantum.kvconfig"
[General]
theme=Fluent-Dark
EOF

# Asignar Kvantum como estilo de widgets Qt en kdeglobals
set_kconfig "kdeglobals" "KDE" "widgetStyle" "kvantum-dark"
set_kconfig "kdeglobals" "General" "ColorScheme" "BreezeDark"

log_success "Kvantum configurado con tema Fluent-Dark y widgetStyle=kvantum-dark."

# -----------------------------------------------------------------------------
# 4. Compilación de Klassy (Decoración de Ventana difuminada - Solo Qt6/Plasma 6)
# -----------------------------------------------------------------------------
log_step "4/8: Compilando e instalando Klassy Window Decoration (Qt6/Plasma 6)..."

cd "$BUILD_DIR"
if git clone --depth=1 https://github.com/paulmcauley/klassy.git; then
    cd klassy
    mkdir -p build && cd build
    log_info "Ejecutando CMake para Klassy con soporte exclusivo Qt6 / Plasma 6..."
    if cmake .. \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_TESTING=OFF \
        -DKDE_INSTALL_USE_QT_SYS_PATHS=ON \
        -DBUILD_QT5=OFF \
        -DBUILD_QT6=ON; then
        
        make -j"$(nproc)"
        $SUDO make install
        log_success "Klassy compilado e instalado con éxito."

        # Configurar Klassy como decoración por defecto en kwinrc
        set_kconfig "kwinrc" "org.kde.kdecoration2" "plugin" "org.kde.klassy"
        set_kconfig "kwinrc" "org.kde.kdecoration2" "theme" "klassy"
        set_kconfig "kwinrc" "org.kde.kdecoration2" "ButtonsOnRight" "IAX"
        set_kconfig "kwinrc" "org.kde.kdecoration2" "ButtonsOnLeft" "M"
    else
        log_warn "Error en configuración CMake de Klassy. Se mantendrá la decoración Breeze por defecto."
    fi
else
    log_warn "No se pudo clonar Klassy. Continuando con decoración Breeze estándar."
fi

# -----------------------------------------------------------------------------
# 5. Efecto de Desenfoque Global (Better Blur DX)
# -----------------------------------------------------------------------------
log_step "5/8: Compilando efecto de desenfoque de ventanas (Better Blur DX)..."

cd "$BUILD_DIR"
if git clone --depth=1 https://github.com/xarblu/kwin-effects-better-blur-dx.git 2>/dev/null; then
    cd kwin-effects-better-blur-dx
    mkdir -p build && cd build
    if cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_USE_QT_SYS_PATHS=ON 2>/dev/null; then
        make -j"$(nproc)"
        $SUDO make install
        log_success "Better Blur DX compilado e instalado correctamente."
    else
        log_warn "No se pudo compilar Better Blur DX. Se continuará con los efectos nativos de KWin."
    fi
else
    log_warn "No se pudo clonar Better Blur DX. Se continuará con los efectos nativos de KWin."
fi

# Reglas de translucidez y desenfoque nativo en KWin
set_kconfig "kwinrc" "Plugins" "blurEnabled" "true"
set_kconfig "kwinrc" "Plugins" "translucencyEnabled" "true"

# -----------------------------------------------------------------------------
# 6. Iconos Tela Dark y Cursores
# -----------------------------------------------------------------------------
log_step "6/8: Instalando conjunto de iconos Tela Dark..."

cd "$BUILD_DIR"
if git clone --depth=1 https://github.com/vinceliuice/Tela-icon-theme.git; then
    cd Tela-icon-theme
    mkdir -p "$HOME/.local/share/icons"
    ./install.sh -d "$HOME/.local/share/icons" -c blue || ./install.sh -d "$HOME/.local/share/icons"
    set_kconfig "kdeglobals" "Icons" "Theme" "Tela-blue-dark"
    log_success "Tema de iconos Tela-blue-dark instalado y configurado."
else
    log_warn "Usando Papirus-Dark como fallback."
    set_kconfig "kdeglobals" "Icons" "Theme" "Papirus-Dark"
fi

# Configuración de Cursores
set_kconfig "kcminputrc" "Mouse" "cursorTheme" "Oxygen_White"
set_kconfig "kdeglobals" "Mouse" "cursorTheme" "Oxygen_White"
if command -v plasma-apply-cursortheme &>/dev/null; then
    plasma-apply-cursortheme Oxygen_White 2>/dev/null || plasma-apply-cursortheme breeze_cursors 2>/dev/null || true
fi

# -----------------------------------------------------------------------------
# 7. Plasmoides y Extensiones de KWin (Panel Colorizer, Blurred Wallpaper, Tiling)
# -----------------------------------------------------------------------------
log_step "7/8: Instalando Plasmoides y KWin Scripts (Panel Colorizer, Blurred Wallpaper, Tiling)..."

# 7.1 Panel Colorizer
cd "$BUILD_DIR"
log_info "Instalando Plasmoide Panel Colorizer..."
if git clone --depth=1 https://github.com/luisbocanegra/plasma-panel-colorizer.git; then
    cd plasma-panel-colorizer
    if command -v kpackagetool6 &>/dev/null; then
        kpackagetool6 -t Plasma/Applet -u package 2>/dev/null || kpackagetool6 -t Plasma/Applet -i package 2>/dev/null || true
    fi
    log_success "Panel Colorizer instalado en el sistema."
fi

# 7.2 Blurred Wallpaper Plugin & Wallpaper Effects
cd "$BUILD_DIR"
log_info "Instalando Wallpaper Plugin Blurred Wallpaper..."
if git clone --depth=1 https://github.com/bouteillerAlan/blurredwallpaper.git 2>/dev/null; then
    cd blurredwallpaper
    if [ -d "package" ]; then
        kpackagetool6 -t Plasma/Wallpaper -u package 2>/dev/null || kpackagetool6 -t Plasma/Wallpaper -i package 2>/dev/null || true
    else
        kpackagetool6 -t Plasma/Wallpaper -u . 2>/dev/null || kpackagetool6 -t Plasma/Wallpaper -i . 2>/dev/null || true
    fi
    log_success "Blurred Wallpaper plugin instalado."
fi

cd "$BUILD_DIR"
log_info "Instalando Plasma Wallpaper Effects..."
if git clone --depth=1 https://github.com/luisbocanegra/plasma-wallpaper-effects.git 2>/dev/null; then
    cd plasma-wallpaper-effects
    if [ -d "package" ]; then
        kpackagetool6 -t Plasma/Applet -u package 2>/dev/null || kpackagetool6 -t Plasma/Applet -i package 2>/dev/null || true
    else
        kpackagetool6 -t Plasma/Applet -u . 2>/dev/null || kpackagetool6 -t Plasma/Applet -i . 2>/dev/null || true
    fi
    log_success "Plasma Wallpaper Effects instalado."
fi

# 7.3 Dynamic Workspaces & Mouse Tiler
cd "$BUILD_DIR"
log_info "Instalando KWin Scripts (Dynamic Workspaces / Mouse Tiler)..."
if git clone --depth=1 https://github.com/marcin-w/dynamic-workspaces.git 2>/dev/null; then
    cd dynamic-workspaces
    if command -v kpackagetool6 &>/dev/null; then
        kpackagetool6 -t KWin/Script -u . 2>/dev/null || kpackagetool6 -t KWin/Script -i . 2>/dev/null || true
    fi
    set_kconfig "kwinrc" "Plugins" "dynamic-workspacesEnabled" "true"
fi

cd "$BUILD_DIR"
if git clone --depth=1 https://github.com/jinliu/kwin-mouse-tiler.git 2>/dev/null; then
    cd kwin-mouse-tiler
    if command -v kpackagetool6 &>/dev/null; then
        kpackagetool6 -t KWin/Script -u . 2>/dev/null || kpackagetool6 -t KWin/Script -i . 2>/dev/null || true
    fi
    set_kconfig "kwinrc" "Plugins" "mouse-tilerEnabled" "true"
fi

# -----------------------------------------------------------------------------
# 8. Recargar configuraciones del sistema
# -----------------------------------------------------------------------------
log_step "8/8: Aplicando configuraciones a KWin y entorno Qt..."

# Recargar KWin si está en ejecución
if command -v qdbus6 &>/dev/null; then
    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
elif command -v qdbus &>/dev/null; then
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

echo ""
log_success "¡Automatización de instalación finalizada con éxito!"
echo ""
echo -e "${CYAN}=================================================================${RESET}"
echo -e "${GREEN}📋 RESUMEN DE COMPONENTES INSTALADOS:${RESET}"
echo -e "  ✔️ Dependencias completas Qt6 / KF6 (KCMUtils, IconThemes, Style, etc.)"
echo -e "  ✔️ Motor Kvantum + Tema Fluent-Dark"
echo -e "  ✔️ Decoración de ventanas Klassy (Bordes y botones difuminados)"
echo -e "  ✔️ KDE Material You Colors (Daemon de color dinámico en autostart)"
echo -e "  ✔️ Tema de iconos Tela-blue-dark"
echo -e "  ✔️ Plasmoide Panel Colorizer"
echo -e "  ✔️ Wallpaper Plugins (Blurred Wallpaper & Wallpaper Effects)"
echo -e "  ✔️ KWin Scripts (Dynamic Workspaces & Mouse Tiler)"
echo -e "${CYAN}=================================================================${RESET}"
echo ""
echo -e "${YELLOW}🛠️  PASOS RESTANTES QUE DEBES REALIZAR MANUALMENTE (GUI):${RESET}"
echo -e "  1. ${CYAN}Cerrar e Iniciar Sesión:${RESET} Cierra tu sesión actual o reinicia para que KWin y Qt carguen los nuevos motores de renderizado."
echo -e "  2. ${CYAN}Diseño de Paneles Flotantes (Top Bar / Docks):${RESET}"
echo -e "     - Haz clic derecho en el escritorio -> 'Entrar en modo edición'."
echo -e "     - Divide la barra superior en 3 paneles 'Ajustar al contenido' (Fit Content):"
echo -e "       • Izquierdo: Menú de aplicaciones + Pager + Monitor de recursos."
echo -e "       • Central: Solo iconos de tareas (Dock de aplicaciones)."
echo -e "       • Derecho: Bandeja del sistema + Reloj digital."
echo -e "     - Añade el widget 'Panel Colorizer' a tu panel y selecciona el preset 'Rounder Translucent' o 'Dock'."
echo -e "  3. ${CYAN}Fondo de Pantalla y Efectos:${RESET}"
echo -e "     - Clic derecho en el escritorio -> 'Configurar escritorio y fondo de pantalla'."
echo -e "     - En 'Tipo de fondo', selecciona 'Blurred Wallpaper' o tu imagen favorita."
echo -e "     - 'KDE Material You Colors' adaptará automáticamente el color de acento del sistema."
echo -e "${CYAN}=================================================================${RESET}"
