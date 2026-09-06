#!/usr/bin/env bash
# ==============================================================================
# niri-setup.sh - Instalador y Optimizador para Niri + Noctalia Shell en CachyOS
# ==============================================================================
# Configura el compositor scrollable-tiling Niri y la shell Noctalia en Wayland
#
# Uso:
#   ./niri-setup.sh           -> Instala dependencias y aplica configuraciones optimizadas
#   ./niri-setup.sh --status  -> Comprueba el estado de Niri, Noctalia y herramientas Wayland
#   ./niri-setup.sh --help    -> Muestra la ayuda
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🌀 INICIANDO CONFIGURACIÓN DE NIRI + NOCTALIA SHELL - CACHYOS"
echo "================================================================="

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

show_status() {
    echo "🔍 ESTADO DEL ENTORNO NIRI + NOCTALIA SHELL:"
    echo "• Niri Compositor:        $(command -v niri &>/dev/null && echo 'Instalado ('"$(niri --version 2>/dev/null || echo 'OK')"')' || echo 'No instalado')"
    echo "• Xwayland Satellite:     $(command -v xwayland-satellite &>/dev/null && echo 'Instalado' || echo 'No instalado')"
    echo "• Noctalia Shell:         $(command -v noctalia &>/dev/null && echo 'Instalado' || echo 'No instalado')"
    echo "• Portales Wayland:       $(pacman -Q xdg-desktop-portal-gnome xdg-desktop-portal-gtk 2>/dev/null | tr '\n' ' ' || echo 'Incompleto')"
    echo "• Clipboard (wl-copy):    $(command -v wl-copy &>/dev/null && echo 'Instalado' || echo 'No instalado')"
    echo "• Capturas (grim/slurp):  $(command -v grim &>/dev/null && command -v slurp &>/dev/null && echo 'Instalados' || echo 'Incompletos')"
    echo "• Audio GUI (pavucontrol):$(command -v pavucontrol &>/dev/null && echo 'Instalado' || echo 'No instalado')"
    echo "• Bluetooth GUI (blueman):$(command -v blueman-manager &>/dev/null && echo 'Instalado' || echo 'No instalado')"
    echo "• Config Niri:            $([ -f "$USER_HOME/.config/niri/config.kdl" ] && echo 'Presente' || echo 'No encontrada')"
}

if [ "${1:-}" = "--status" ] || [ "${1:-}" = "-s" ]; then
    show_status
    exit 0
fi

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    cat <<EOF
Uso: $0 [OPCION]
Opciones:
  (sin argumentos)   Instala paquetes y aplica integración Niri + Noctalia Shell.
  --status, -s       Comprueba el estado del stack Niri y utilidades Wayland.
  --help, -h         Muestra este mensaje de ayuda.
EOF
    exit 0
fi

# 1. Instalación de paquetes esenciales para Niri y Wayland
echo "ℹ️ [1/4] Instalando paquetes de Niri, portales y herramientas Wayland..."
$SUDO pacman -S --needed --noconfirm \
    niri \
    xwayland-satellite \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    wl-clipboard \
    grim \
    slurp \
    satty \
    brightnessctl \
    playerctl \
    pavucontrol \
    blueman \
    network-manager-applet \
    polkit-gnome \
    qt5-wayland \
    qt6-wayland \
    qt6ct \
    kvantum \
    papirus-icon-theme 2>/dev/null || true

# Comprobar Noctalia Shell (repositorio oficial, CachyOS o AUR)
if ! command -v noctalia &>/dev/null; then
    echo "ℹ️ Intentando instalar Noctalia Shell..."
    $SUDO pacman -S --needed --noconfirm noctalia-shell 2>/dev/null || \
    $SUDO pacman -S --needed --noconfirm noctalia 2>/dev/null || {
        if command -v paru &>/dev/null; then
            run_as_user paru -S --needed --noconfirm noctalia-shell 2>/dev/null || true
        elif command -v yay &>/dev/null; then
            run_as_user yay -S --needed --noconfirm noctalia-shell 2>/dev/null || true
        else
            echo "⚠️ No se pudo instalar Noctalia automáticamente con pacman. Puedes instalarlo vía AUR (noctalia-shell)."
        fi
    }
fi

# 2. Desactivar servicios residuales de KDE si estuvieran activos
echo "ℹ️ [2/4] Verificando y limpiando servicios residuales de KDE..."
run_as_user systemctl --user disable --now plasma-plasmashell.service 2>/dev/null || true
run_as_user systemctl --user disable --now kde-baloo 2>/dev/null || true

# 3. Configuración de Niri (~/.config/niri/config.kdl)
echo "ℹ️ [3/4] Configurando integración de Niri con Noctalia Shell..."
NIRI_DIR="$USER_HOME/.config/niri"
NIRI_CONF="$NIRI_DIR/config.kdl"
run_as_user mkdir -p "$NIRI_DIR"

if [ -f "$NIRI_CONF" ]; then
    echo "  📄 Archivo config.kdl detectado. Creando respaldo de seguridad..."
    BACKUP_FILE="$NIRI_DIR/config.kdl.bak.$(date +%Y%m%d_%H%M%S)"
    run_as_user cp "$NIRI_CONF" "$BACKUP_FILE"
    echo "  ✅ Respaldo guardado en: $BACKUP_FILE"

    # Asegurar autoinicio de noctalia si no está presente
    if ! grep -q 'spawn-at-startup "noctalia"' "$NIRI_CONF" 2>/dev/null; then
        echo -e '\n// Autoinicio de Noctalia Shell\nspawn-at-startup "noctalia"' | run_as_user tee -a "$NIRI_CONF" > /dev/null
        echo "  ➕ Añadido autoinicio de Noctalia Shell a config.kdl"
    fi

    # Asegurar xwayland-satellite si no está presente
    if ! grep -q 'spawn-at-startup "xwayland-satellite"' "$NIRI_CONF" 2>/dev/null; then
        echo -e 'spawn-at-startup "xwayland-satellite"' | run_as_user tee -a "$NIRI_CONF" > /dev/null
        echo "  ➕ Añadido autoinicio de Xwayland-satellite a config.kdl"
    fi

    # Asegurar integración de activación para notificaciones y Noctalia
    if ! grep -q 'honor-xdg-activation-with-invalid-serial' "$NIRI_CONF" 2>/dev/null; then
        echo -e '\ndebug {\n    honor-xdg-activation-with-invalid-serial\n}' | run_as_user tee -a "$NIRI_CONF" > /dev/null
        echo "  ➕ Añadido honor-xdg-activation-with-invalid-serial a config.kdl"
    fi
else
    echo "  ✨ Creando configuración base optimizada para Niri + Noctalia Shell..."
    cat << 'EOF' | run_as_user tee "$NIRI_CONF" > /dev/null
// =============================================================================
// NIRI CONFIGURATION - CachyOS + Noctalia Shell
// =============================================================================

// Procesos que inician automáticamente al arrancar Niri
spawn-at-startup "noctalia"
spawn-at-startup "xwayland-satellite"
spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"

// Variables de compatibilidad y debug para Wayland Shell
debug {
    honor-xdg-activation-with-invalid-serial
}

// Configuración de Entrada (Touchpad, Teclado)
input {
    keyboard {
        xkb {
            layout "es"
        }
        repeat-delay 300
        repeat-rate 40
    }

    touchpad {
        tap
        natural-scroll
        dwt
        accel-speed 0.2
    }

    mouse {
        accel-speed 0.0
    }
}

// Configuración de Salidas de Pantalla (Monitores)
output "eDP-1" {
    scale 1.0
    variable-refresh-rate
}

// Diseño y apariencia
layout {
    gaps 8
    center-focused-column "never"

    preset-column-widths {
        proportion 0.33333
        proportion 0.5
        proportion 0.66667
    }

    default-column-width { proportion 0.5; }

    focus-ring {
        width 2
        active-color "#7aa2f7"
        inactive-color "#24283b"
    }

    border {
        off
    }
}

// Animaciones fluidas
animations {
    slowdown 1.0
}

// Reglas de Ventanas (Floating para utilidades del sistema)
window-rule {
    match app-id=r#"^pavucontrol$"#
    open-floating true
}

window-rule {
    match app-id=r#"^blueman-manager$"#
    open-floating true
}

window-rule {
    match app-id=r#"^nm-connection-editor$"#
    open-floating true
}

// Atajos de teclado
binds {
    // Noctalia Shell Controls
    Mod+Space { spawn-sh "noctalia msg panel-toggle launcher"; }
    Mod+D { spawn-sh "noctalia msg panel-toggle launcher"; }
    Mod+S { spawn-sh "noctalia msg panel-toggle control-center"; }
    Mod+Comma { spawn-sh "noctalia msg settings-toggle"; }
    Mod+Shift+E { spawn-sh "noctalia msg session lock"; }

    // Terminal Kitty
    Mod+Return { spawn "kitty"; }

    // Navegación de Columnas y Ventanas
    Mod+Left  { focus-column-left; }
    Mod+Right { focus-column-right; }
    Mod+H     { focus-column-left; }
    Mod+L     { focus-column-right; }

    Mod+Down { focus-window-down; }
    Mod+Up   { focus-window-up; }
    Mod+J    { focus-window-down; }
    Mod+K    { focus-window-up; }

    // Movimiento de Ventanas
    Mod+Shift+Left  { move-column-left; }
    Mod+Shift+Right { move-column-right; }
    Mod+Shift+H     { move-column-left; }
    Mod+Shift+L     { move-column-right; }

    Mod+Shift+Down { move-window-down; }
    Mod+Shift+Up   { move-window-up; }
    Mod+Shift+J    { move-window-down; }
    Mod+Shift+K    { move-window-up; }

    // Gestión de Ventanas
    Mod+Q { close-window; }
    Mod+F { maximize-column; }
    Mod+Shift+F { fullscreen-window; }
    Mod+W { toggle-window-floating; }

    // Capturas de pantalla Wayland (Grim + Slurp)
    Print { spawn-sh "grim -g \"$(slurp)\" - | wl-copy"; }
    Mod+Print { spawn-sh "grim - | wl-copy"; }
    Shift+Print { spawn-sh "satty --filename - --fullscreen"; }

    // Control Multimedia y Brillo
    XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
    XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
    XF86AudioMute        allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }

    XF86MonBrightnessUp   allow-when-locked=true { spawn "brightnessctl" "set" "+5%"; }
    XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "set" "5%-"; }

    // Recargar Niri y Salir
    Mod+Shift+R { reload-config; }
    Mod+Shift+Q { quit; }
}
EOF
    echo "  ✅ Archivo base config.kdl generado con éxito."
fi

# 4. Configurar variables de sesión para Systemd (environment.d)
echo "ℹ️ [4/4] Configurando variables de entorno de sesión de usuario..."
ENV_DIR="$USER_HOME/.config/environment.d"
run_as_user mkdir -p "$ENV_DIR"
cat << 'EOF' | run_as_user tee "$ENV_DIR/10-wayland-niri.conf" > /dev/null
# Entorno Wayland para Niri y Noctalia Shell
XDG_CURRENT_DESKTOP=niri
XDG_SESSION_TYPE=wayland
QT_QPA_PLATFORM=wayland;xcb
QT_WAYLAND_DISABLE_WINDOWDECORATION=1
QT_QPA_PLATFORMTHEME=qt6ct
MOZ_ENABLE_WAYLAND=1
ELECTRON_OZONE_PLATFORM_HINT=auto
SDL_VIDEODRIVER=wayland
_JAVA_AWT_WM_NONREPARENTING=1
EOF

echo "================================================================="
echo "✅ Instalación y optimización de Niri + Noctalia Shell finalizada."
echo "💡 Puedes iniciar sesión en Niri desde tu display manager (SDDM/GDM)."
echo "================================================================="
