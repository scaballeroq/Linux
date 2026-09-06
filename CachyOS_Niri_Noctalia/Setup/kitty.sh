#!/usr/bin/env bash
#
# kitty.sh - Instalacion y Configuracion Estetica de Kitty Terminal para CachyOS + Niri
#
# Uso:
#   ./kitty.sh                       -> Instala y aplica configuracion estetica con opacidad al 75% y blur 32
#   ./kitty.sh --opacity 0.70        -> Configura una opacidad personalizada (ej: 0.70, 0.65, 0.80)
#   ./kitty.sh 0.70                  -> Equivalente abreviado
#   ./kitty.sh --help                -> Muestra la ayuda interactiva

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no esta disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecucion con sudo
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

# Opacidad por defecto (0.75 = 75% opacidad / 25% transparencia translucida con blur)
OPACITY="0.75"
BLUR_RADIUS="32"

show_help() {
    cat <<EOF
🐱 Configuracion Estetica de Kitty Terminal - CachyOS (Niri + Noctalia)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)           Instala Kitty y aplica opacidad al 75% (0.75) con desenfoque suave (blur 32).
  --opacity <VALOR>, -o      Configura un valor de opacidad personalizado entre 0.10 y 1.0 (ej: 0.70, 0.65).
  <VALOR_NUMERICO>           Atajo directo para opacidad (ej: $0 0.70).
  --help, -h                 Muestra este mensaje de ayuda.

Atajos al vuelo dentro de Kitty:
  • Ctrl+Alt+Arriba:         Aumentar opacidad (+5% mas opaco)
  • Ctrl+Alt+Abajo:          Reducir opacidad (-5% mas transparente)
  • Ctrl+Alt+0:              Restaurar opacidad predeterminada
  • Ctrl+Alt+1:              Modo 100% opaco (sin transparencia)
  • Ctrl+Shift+F5:           Recargar configuracion de Kitty en caliente
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
            echo "❌ Opcion no reconocida: $1"
            show_help
            exit 1
            ;;
    esac
fi

OPACITY_PERCENT=$(awk "BEGIN {print int($OPACITY * 100)}")

echo "==========================================================="
echo "🐱 Configurando Kitty Terminal en CachyOS (Niri Wayland)"
echo "🎨 Nivel de opacidad seleccionado: ${OPACITY} (${OPACITY_PERCENT}% opaco, $((100 - OPACITY_PERCENT))% transparente)"
echo "==========================================================="

# 1. Instalar Kitty y dependencias solo si no esta instalado
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

# 2. Crear directorio de configuracion
echo "⚙️ [2/4] Creando directorios de configuracion en $USER_HOME/.config/kitty..."
mkdir -p "$USER_HOME/.config/kitty"

# 3. Generar kitty.conf con tema oscuro, opacidad translucida y efectos
echo "🎨 [3/4] Generando configuracion (Opacidad ${OPACITY}, Blur ${BLUR_RADIUS})..."
cat <<EOF > "$USER_HOME/.config/kitty/kitty.conf"
# =============================================================================
# KITTY CONFIGURATION - CACHYOS + NIRI WAYLAND
# =============================================================================

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

# --- Ventana y Margenes ---
window_padding_width 10
hide_window_decorations no
confirm_os_window_close 0
remember_window_size   yes
initial_window_width   950
initial_window_height  600

# --- Cursor ---
cursor_shape          beam
cursor_beam_thickness 1.8
cursor_blink_interval 0.5
cursor_trail          3

# --- Barra de Pestanas (Tab Bar) ---
tab_bar_edge          top
tab_bar_style         powerline
tab_powerline_style   slanted
tab_title_template    " {title}{' [' + num_windows.__str__() + ']' if num_windows > 1 else ''} "
active_tab_font_style bold

# --- Esquema de Color Oscuro (Tokyo Night / Catppuccin Mocha) ---
foreground            #cdd6f4
background            #181825
selection_foreground  #1e1e2e
selection_background  #f5e0dc

# Cursor
cursor                #f5e0dc
cursor_text_color     #11111b

# URL
url_color             #89b4fa
url_style             curly

# Colores de pestanas
active_tab_foreground   #11111b
active_tab_background   #cba6f7
inactive_tab_foreground #cdd6f4
inactive_tab_background #181825
tab_bar_background      #11111b

# Colores ANSI Estandar
# Black
color0  #45475a
color8  #585b70

# Red
color1  #f38ba8
color9  #f38ba8

# Green
color2  #a6e3a1
color10 #a6e3a1

# Yellow
color3  #f9e2af
color11 #f9e2af

# Blue
color4  #89b4fa
color12 #89b4fa

# Magenta
color5  #f5c2e7
color13 #f5c2e7

# Cyan
color6  #94e2d5
color14 #94e2d5

# White
color7  #bac2de
color15 #a6adc8

# --- Rendimiento y Graficos ---
repaint_delay   10
input_delay     3
sync_to_monitor yes

# --- Desactivar campana acustica/visual molesta ---
enable_audio_bell no
visual_bell_duration 0.0

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
EOF

# 4. Integracion con Niri y Terminal Predeterminado del Sistema
echo "📁 [4/4] Configurando Kitty como terminal predeterminado..."

# Exportar TERMINAL=kitty en la sesión del usuario
ENV_DIR="$USER_HOME/.config/environment.d"
run_as_user mkdir -p "$ENV_DIR"
echo "TERMINAL=kitty" | run_as_user tee "$ENV_DIR/10-terminal.conf" > /dev/null

if command -v gsettings &>/dev/null; then
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec-arg '-e' 2>/dev/null || true
fi

# Recargar configuracion en caliente si hay instancias activas de Kitty
killall -USR1 kitty 2>/dev/null || true

echo "==========================================================="
echo "✅ Kitty se ha configurado con opacidad al ${OPACITY} (${OPACITY_PERCENT}%) y blur ${BLUR_RADIUS}."
echo "💡 Atajos rapidos en Kitty:"
echo "   - Opacidad directa: Ctrl+Alt+Arriba (+5%) | Ctrl+Alt+Abajo (-5%) | Ctrl+Alt+0 (Default) | Ctrl+Alt+1 (100% Opaco)"
echo "   - Opacidad por F-Keys: Ctrl+Shift+F11 (+5%) | Ctrl+Shift+F10 (-5%) | Ctrl+Shift+F9 (Default)"
echo "   - Atajo global en Niri: Mod+Return para abrir Kitty."
echo "   - Recargar configuracion en vivo: Ctrl+Shift+F5"
echo "   - Nueva pestana en mismo directorio: Ctrl+Shift+T"
echo "   - Nueva ventana dividida: Ctrl+Shift+Enter"
echo "==========================================================="
