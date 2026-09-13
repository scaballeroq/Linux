#!/usr/bin/env bash
#
# kitty.sh - Instalación y Configuración Estética de Kitty Terminal para CachyOS + Niri + DMS
#
# Uso:
#   ./kitty.sh                       -> Instala y aplica configuración estética con opacidad al 75% y blur 32
#   ./kitty.sh --opacity 0.70        -> Configura una opacidad personalizada (ej: 0.70, 0.65, 0.80)
#   ./kitty.sh 0.70                  -> Equivalente abreviado
#   ./kitty.sh --help                -> Muestra la ayuda interactiva

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecución con sudo
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

# Opacidad por defecto (0.75 = 75% opacidad / 25% transparencia translúcida con blur)
OPACITY="0.75"
BLUR_RADIUS="32"

show_help() {
    cat <<EOF
🐱 Configuración Estética de Kitty Terminal - CachyOS (Niri + Dank Material Shell)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)           Instala Kitty y aplica opacidad al 75% (0.75) con desenfoque suave (blur 32).
  --opacity <VALOR>, -o      Configura un valor de opacidad personalizado entre 0.10 y 1.0 (ej: 0.70, 0.65).
  <VALOR_NUMERICO>           Atajo directo para opacidad (ej: $0 0.70).
  --help, -h                 Muestra este mensaje de ayuda.

Atajos al vuelo dentro de Kitty:
  • Ctrl+Alt+Arriba:         Aumentar opacidad (+5% más opaco)
  • Ctrl+Alt+Abajo:          Reducir opacidad (-5% más transparente)
  • Ctrl+Alt+0:              Restaurar opacidad predeterminada
  • Ctrl+Alt+1:              Modo 100% opaco (sin transparencia)
  • Ctrl+Shift+F5:           Recargar configuración de Kitty en caliente
EOF
}

# Procesar argumentos
if [ $# -gt 0 ]; then
    case "$1" in
        --help|-h|help)
            show_help
            exit 0
            ;;
        --opacity|-o)
            if [ -n "${2:-}" ]; then
                OPACITY="$2"
            else
                echo "❌ Error: Debes especificar un valor de opacidad (ej: 0.70)."
                exit 1
            fi
            ;;
        0.*|1.0|1)
            OPACITY="$1"
            ;;
        *)
            echo "❌ Opción no reconocida: $1"
            show_help
            exit 1
            ;;
    esac
fi

OPACITY_PERCENT=$(awk "BEGIN {print int($OPACITY * 100)}")

echo "==========================================================="
echo "🐱 Configurando Kitty Terminal en CachyOS (Niri + DMS)"
echo "🎨 Nivel de opacidad seleccionado: ${OPACITY} (${OPACITY_PERCENT}% opaco, $((100 - OPACITY_PERCENT))% transparente)"
echo "==========================================================="

# 1. Instalar Kitty y dependencias si no está instalado
if ! command -v kitty &> /dev/null; then
    echo "📦 [1/4] Instalando Kitty Terminal con Pacman..."
    if [ -n "$SUDO" ]; then
        $SUDO pacman -S --needed --noconfirm kitty
    else
        pacman -S --needed --noconfirm kitty
    fi
else
    echo "📦 [1/4] Kitty Terminal ya se encuentra instalado."
fi

# 2. Crear directorio de configuración
echo "⚙️ [2/4] Creando directorios de configuración en $USER_HOME/.config/kitty..."
run_as_user mkdir -p "$USER_HOME/.config/kitty"

# 3. Generar kitty.conf con integración nativa a Dank Material Shell y Wayland
echo "🎨 [3/4] Generando configuración integrada con DMS (Opacidad ${OPACITY}, Blur ${BLUR_RADIUS})..."
cat <<EOF | run_as_user tee "$USER_HOME/.config/kitty/kitty.conf" > /dev/null
# =============================================================================
# KITTY CONFIGURATION - CACHYOS + NIRI WAYLAND + DANK MATERIAL SHELL (DMS)
# =============================================================================

# --- Integracion Wayland y Rendimiento ---
linux_display_server       wayland
wayland_enable_ime         yes
repaint_delay              10
input_delay                3
sync_to_monitor            yes

# --- Fuentes & Tipografia ---
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        11.5
disable_ligatures never

# --- Transparencia y Opacidad ---
background_opacity         ${OPACITY}
dynamic_background_opacity yes
background_blur            ${BLUR_RADIUS}

# --- Ventana y Estetica Niri Tiling ---
window_padding_width    10
hide_window_decorations yes
confirm_os_window_close 0
remember_window_size    yes
initial_window_width    950
initial_window_height   600

# --- Desplazamiento y Scrollback para Desarrollo ---
scrollback_lines               10000
scrollback_pager_history_size  64
wheel_scroll_multiplier        5.0
touch_scroll_multiplier        2.0

# --- Portapapeles e Interaccion ---
clipboard_control       write-clipboard write-primary read-clipboard read-primary
detect_urls             yes
copy_on_select          no

# --- Cursor ---
cursor_shape          beam
cursor_blink_interval 0.5

# --- Barra de Pestanas (Tab Bar) ---
tab_bar_edge          top
tab_bar_style         powerline
tab_powerline_style   slanted
tab_title_template    " {title}{' [' + num_windows.__str__() + ']' if num_windows > 1 else ''} "
active_tab_font_style bold

# --- Desactivar campana acustica/visual molesta ---
enable_audio_bell     no
visual_bell_duration  0.0

# --- Atajos de teclado utiles ---
# 1. Control directo de opacidad (Ctrl+Alt + Flechas / +/-):
map ctrl+alt+up          set_background_opacity +0.05
map ctrl+alt+down        set_background_opacity -0.05
map ctrl+alt+equal       set_background_opacity +0.05
map ctrl+alt+plus        set_background_opacity +0.05
map ctrl+alt+minus       set_background_opacity -0.05
map ctrl+alt+kp_add      set_background_opacity +0.05
map ctrl+alt+kp_subtract set_background_opacity -0.05
map ctrl+alt+0           set_background_opacity default
map ctrl+alt+1           set_background_opacity 1.0

# 2. Control de opacidad mediante teclas de funcion (F9-F12):
map ctrl+shift+f11       set_background_opacity +0.05
map ctrl+shift+f10       set_background_opacity -0.05
map ctrl+shift+f9        set_background_opacity default
map ctrl+shift+f12       set_background_opacity 1.0

# 3. Secuencia de dos pasos (Ctrl+Shift+A seguido de M/L/D/1):
map ctrl+shift+a>m       set_background_opacity +0.05
map ctrl+shift+a>shift+m set_background_opacity +0.05
map ctrl+shift+a>l       set_background_opacity -0.05
map ctrl+shift+a>shift+l set_background_opacity -0.05
map ctrl+shift+a>d       set_background_opacity default
map ctrl+shift+a>shift+d set_background_opacity default
map ctrl+shift+a>1       set_background_opacity 1.0
map ctrl+shift+a>0       set_background_opacity default

# Gestion de pestanas y splits:
map ctrl+shift+t         new_tab_with_cwd
map ctrl+shift+enter     new_window_with_cwd
map ctrl+shift+f5        load_config_file

# =============================================================================
# TEMA DINAMICO DANK MATERIAL SHELL (Generado por Matugen / DMS)
# =============================================================================
include ./dank-theme.conf
include ./dank-tabs.conf
EOF

# 4. Regenerar tema dinámico con DMS si está disponible
echo "🌈 [4/4] Sincronizando paleta de color Material You..."
if command -v dms &>/dev/null; then
    run_as_user dms matugen generate 2>/dev/null || true
fi

echo "==========================================================="
echo "✅ Kitty configurado con éxito para CachyOS + Niri + DMS:"
echo "  • Archivo:   $USER_HOME/.config/kitty/kitty.conf"
echo "  • Opacidad:  ${OPACITY} (Fondo dinámico translúcido)"
echo "  • Blur:      ${BLUR_RADIUS} (Desenfoque Wayland)"
echo "  • Temas:     dank-theme.conf & dank-tabs.conf (Material You)"
echo "💡 Usa Ctrl+Alt+Arriba/Abajo para graduar la transparencia al vuelo."
echo "==========================================================="
