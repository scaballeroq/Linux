#!/usr/bin/env bash
# kitty.sh - Instalacion y Configuracion de Kitty Terminal para Kubuntu + KDE Plasma
#
# Uso:
#   ./kitty.sh                       -> Instala y aplica configuracion con opacidad 0.75 y blur 32
#   ./kitty.sh --opacity 0.70        -> Opacidad personalizada
#   ./kitty.sh 0.70                  -> Atajo directo
#   ./kitty.sh --help                -> Ayuda

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "Error: 'sudo' no esta disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    USER_HOME="${HOME}"
fi

OPACITY="0.75"
BLUR_RADIUS="32"

show_help() {
    cat <<EOF
Configuracion de Kitty Terminal - Kubuntu (KDE Plasma 6)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)           Instala Kitty y aplica opacidad 0.75 con blur 32.
  --opacity <VALOR>, -o      Opacidad personalizada (0.10 a 1.0).
  <VALOR_NUMERICO>           Atajo directo (ej: $0 0.70).
  --help, -h                 Muestra esta ayuda.

Atajos en Kitty:
  Ctrl+Alt+Arriba:           Aumentar opacidad (+5%)
  Ctrl+Alt+Abajo:            Reducir opacidad (-5%)
  Ctrl+Alt+0:                Restaurar opacidad predeterminada
  Ctrl+Alt+1:                Modo 100% opaco
  Ctrl+Shift+F5:             Recargar configuracion
EOF
}

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
                echo "Error: Debes especificar un valor de opacidad."
                exit 1
            fi
            ;;
        0.*|1.0|1)
            OPACITY="$1"
            ;;
        *)
            echo "Opcion no reconocida: $1"
            show_help
            exit 1
            ;;
    esac
fi

OPACITY_PERCENT=$(awk "BEGIN {print int($OPACITY * 100)}")

echo "==========================================================="
echo "Configurando Kitty Terminal en Kubuntu (KDE Plasma)"
echo "Opacidad: ${OPACITY} (${OPACITY_PERCENT}%)"
echo "==========================================================="

# 1. Instalar Kitty
if ! command -v kitty &> /dev/null; then
    echo "Instalando Kitty Terminal..."
    $SUDO apt update
    $SUDO apt install -y kitty
else
    echo "Kitty Terminal ya instalado."
fi

# 2. Crear directorios
echo "Creando directorios de configuracion..."
mkdir -p "$USER_HOME/.config/kitty"

# 3. Generar kitty.conf
echo "Generando configuracion de Kitty..."
cat <<EOF > "$USER_HOME/.config/kitty/kitty.conf"
# KITTY CONFIGURATION - KUBUNTU + KDE PLASMA

# Fuentes
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        11.5
disable_ligatures never

# Transparencia
background_opacity         ${OPACITY}
dynamic_background_opacity yes
background_blur            ${BLUR_RADIUS}

# Ventana
window_padding_width 10
hide_window_decorations no
confirm_os_window_close 0
remember_window_size   yes
initial_window_width   950
initial_window_height  600

# Cursor
cursor_shape          beam
cursor_beam_thickness 1.8
cursor_blink_interval 0.5
cursor_trail          3

# Tab Bar
tab_bar_edge          top
tab_bar_style         powerline
tab_powerline_style   slanted
tab_title_template    " {title}{' [' + num_windows.__str__() + ']' if num_windows > 1 else ''} "
active_tab_font_style bold

# Colores (Catppuccin Mocha)
foreground            #cdd6f4
background            #181825
selection_foreground  #1e1e2e
selection_background  #f5e0dc
cursor                #f5e0dc
cursor_text_color     #11111b
url_color             #89b4fa
url_style             curly
active_tab_foreground   #11111b
active_tab_background   #cba6f7
inactive_tab_foreground #cdd6f4
inactive_tab_background #181825
tab_bar_background      #11111b

# ANSI Colors
color0  #45475a
color8  #585b70
color1  #f38ba8
color9  #f38ba8
color2  #a6e3a1
color10 #a6e3a1
color3  #f9e2af
color11 #f9e2af
color4  #89b4fa
color12 #89b4fa
color5  #f5c2e7
color13 #f5c2e7
color6  #94e2d5
color14 #94e2d5
color7  #bac2de
color15 #a6adc8

# Rendimiento
repaint_delay   10
input_delay     3
sync_to_monitor yes

# Sin campana
enable_audio_bell no
visual_bell_duration 0.0

# Atajos de opacidad
map ctrl+alt+up          set_background_opacity +0.05
map ctrl+alt+down        set_background_opacity -0.05
map ctrl+alt+equal       set_background_opacity +0.05
map ctrl+alt+plus        set_background_opacity +0.05
map ctrl+alt+minus       set_background_opacity -0.05
map ctrl+alt+0           set_background_opacity default
map ctrl+alt+1           set_background_opacity 1.0
map ctrl+shift+f5        load_config_file

# Gestion de pestanas
map ctrl+shift+t         new_tab_with_cwd
map ctrl+shift+enter     new_window_with_cwd
EOF

# 4. Integracion con KDE
echo "Configurando integracion con KDE Plasma y Dolphin..."

if command -v kwriteconfig6 &> /dev/null; then
    kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "kitty" 2>/dev/null || true
    kwriteconfig6 --file kdeglobals --group General --key TerminalService "kitty.desktop" 2>/dev/null || true
    kwriteconfig6 --file kglobalshortcutsrc --group kitty.desktop --key _launch "Ctrl+Alt+T,none,kitty" 2>/dev/null || true
    kwriteconfig6 --file kglobalshortcutsrc --group kitty.desktop --key _k_friendly_name "Kitty" 2>/dev/null || true
    if command -v qdbus6 &>/dev/null; then
        qdbus6 org.kde.kglobalaccel /kglobalaccel reloadConfig 2>/dev/null || true
    fi
elif command -v kwriteconfig5 &> /dev/null; then
    kwriteconfig5 --file kdeglobals --group General --key TerminalApplication "kitty" 2>/dev/null || true
    kwriteconfig5 --file kdeglobals --group General --key TerminalService "kitty.desktop" 2>/dev/null || true
    kwriteconfig5 --file kglobalshortcutsrc --group kitty.desktop --key _launch "Ctrl+Alt+T,none,kitty" 2>/dev/null || true
    kwriteconfig5 --file kglobalshortcutsrc --group kitty.desktop --key _k_friendly_name "Kitty" 2>/dev/null || true
fi

# Dolphin service menu
DOLPHIN_SERVICES_DIR="$USER_HOME/.local/share/kio/servicemenus"
mkdir -p "$DOLPHIN_SERVICES_DIR"

cat <<'EOF' > "$DOLPHIN_SERVICES_DIR/open_in_kitty.desktop"
[Desktop Entry]
Type=Service
MimeType=inode/directory;
Actions=openInKitty;
X-KDE-Priority=TopLevel

[Desktop Action openInKitty]
Name=Abrir en Kitty
Name[es]=Abrir en Kitty
Name[en]=Open in Kitty
Icon=kitty
Exec=kitty --directory %f
EOF
chmod +x "$DOLPHIN_SERVICES_DIR/open_in_kitty.desktop" 2>/dev/null || true

# Recargar Kitty si esta activo
killall -USR1 kitty 2>/dev/null || true

echo "==========================================================="
echo "Kitty configurado con opacidad ${OPACITY} (${OPACITY_PERCENT}%) y blur ${BLUR_RADIUS}."
echo "Atajo global: Ctrl+Alt+T | Menu Dolphin: clic derecho -> Abrir en Kitty"
echo "==========================================================="
