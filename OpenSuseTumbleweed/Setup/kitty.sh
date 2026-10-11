#!/usr/bin/env bash
# ==============================================================================
# kitty.sh - Instalación y Configuración Estética de Kitty Terminal para openSUSE Tumbleweed
# Entorno: KDE Plasma 6 (Wayland) + Modo Oscuro Catppuccin Mocha
# ==============================================================================
# Características configuradas:
# - Esquema de color oscuro moderno (Catppuccin Mocha)
# - Opacidad/Transparencia (75%) con desenfoque (blur 32) nativo en Wayland / KWin
# - Tipografía JetBrainsMono Nerd Font (ligaduras completas y símbolos glyphs)
# - Barra de pestañas estilo Powerline inclinada (slanted)
# - Cursor tipo barra (beam) con estela de movimiento suave (cursor_trail)
# - Control dinámico de opacidad, navegación de pestañas y splits con atajos
# - Integración completa con Dolphin (KIO Servicemenus) y atajo global KDE Ctrl+Alt+T
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
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

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$REAL_UID/bus}" \
            "$@"
    else
        "$@"
    fi
}

show_help() {
    cat <<EOF
🐱 Configuración de Kitty Terminal - openSUSE Tumbleweed (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala Kitty vía Zypper, genera configuración estética Catppuccin Mocha
                      y configura la integración con KDE Plasma 6 (atajo Ctrl+Alt+T y Dolphin).
  --status, -s        Muestra el estado de instalación de Kitty, fuentes e integración en KDE.
  --help, -h          Muestra este mensaje de ayuda.

Características aplicadas:
  • Tema:             Catppuccin Mocha con fondo oscuro (#181825).
  • Tipografía:       JetBrainsMono Nerd Font (ligaduras activas).
  • Efectos Wayland:  Opacidad 75% con desenfoque (blur 32) acelerado por GPU (Mesa/RADV).
  • Cursor & Pestañas: Cursor beam con estela suave (cursor_trail) y pestañas powerline slanted.
  • Integración KDE:  Terminal predeterminada, atajo global Ctrl+Alt+T y menú contextual en Dolphin.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE KITTY TERMINAL - OPENSUSE TUMBLEWEED (KDE 6)"
    echo "================================================================="
    echo "• Kitty instalado:          $(if command -v kitty &>/dev/null; then echo "✅ Kitty ($(kitty --version 2>/dev/null | awk '{print $2}'))"; else echo "❌ No instalado"; fi)"
    echo "• JetBrainsMono Nerd Font:  $(if fc-list "JetBrainsMono Nerd Font" 2>/dev/null | grep -i "JetBrainsMono" >/dev/null; then echo "✅ Disponible"; else echo "⚠️ No detectada (se usará fallback)"; fi)"
    echo "• Configuración kitty.conf: $(if [ -f "$USER_HOME/.config/kitty/kitty.conf" ]; then echo "✅ Presente ($USER_HOME/.config/kitty/kitty.conf)"; else echo "❌ No presente"; fi)"
    echo "• Terminal KDE Plasma 6:    $(if [ "$(run_as_user kreadconfig6 --file kdeglobals --group General --key TerminalApplication 2>/dev/null)" = "kitty" ]; then echo "✅ Kitty (predeterminada)"; else echo "ℹ️ Otra o por defecto"; fi)"
    echo "• Atajo KDE (Ctrl+Alt+T):   $(if grep -qi "Ctrl+Alt+T" "$USER_HOME/.config/kglobalshortcutsrc" 2>/dev/null; then echo "✅ Configurado"; else echo "❌ No configurado"; fi)"
    echo "• KIO Servicemenu Dolphin:  $(if [ -f "$USER_HOME/.local/share/kio/servicemenus/open-in-kitty.desktop" ]; then echo "✅ Instalado (Abrir en Kitty)"; else echo "❌ No instalado"; fi)"
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "==========================================================="
echo "🐱 INICIANDO CONFIGURACIÓN DE KITTY TERMINAL EN KDE PLASMA 6"
echo "==========================================================="

# 1. Instalar Kitty y dependencias
echo "📦 [1/4] Instalando Kitty Terminal vía Zypper..."
if ! command -v kitty &>/dev/null; then
    $SUDO zypper --non-interactive install -y kitty 2>/dev/null || true
else
    echo "   ✅ Kitty ya está instalado en el sistema ($(kitty --version 2>/dev/null | awk '{print $2}'))."
fi

# 2. Crear directorios y respaldar configuración previa si existe
echo "⚙️ [2/4] Preparando directorios de configuración..."
run_as_user mkdir -p "$USER_HOME/.config/kitty"

if [ -f "$USER_HOME/.config/kitty/kitty.conf" ]; then
    run_as_user cp -n "$USER_HOME/.config/kitty/kitty.conf" "$USER_HOME/.config/kitty/kitty.conf.bak" 2>/dev/null || true
fi

# 3. Generar kitty.conf con tema Catppuccin Mocha, opacidad y efectos
echo "🎨 [3/4] Generando configuración optimizada para KDE Plasma 6 (Wayland)..."
cat <<'EOF' | run_as_user tee "$USER_HOME/.config/kitty/kitty.conf" > /dev/null
# =============================================================================
# KITTY CONFIGURATION - OPENSUSE TUMBLEWEED (KDE PLASMA 6 WAYLAND)
# =============================================================================

# --- Fuentes & Tipografía ---
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        11.5
disable_ligatures never
box_drawing_scale 0.001, 1, 1.5, 2

# --- Transparencia, Desenfoque y Wayland ---
background_opacity         0.75
dynamic_background_opacity yes
background_blur            32
linux_display_server       auto
wayland_titlebar_color     background

# --- Ventana y Márgenes ---
window_padding_width    10
placement_strategy      center
hide_window_decorations no
confirm_os_window_close 0
remember_window_size    yes
initial_window_width    950
initial_window_height   600

# --- Cursor Moderno con Estela ---
cursor_shape                beam
cursor_beam_thickness       1.8
cursor_blink_interval       0.5
cursor_trail                3
cursor_trail_decay          0.1 0.4
cursor_trail_start_threshold 2

# --- Barra de Pestañas (Tab Bar) ---
tab_bar_edge          top
tab_bar_style         powerline
tab_powerline_style   slanted
tab_title_template    " {index}: {title}{' [' + num_windows.__str__() + ']' if num_windows > 1 else ''} "
active_tab_font_style bold

# --- Esquema de Color Oscuro (Catppuccin Mocha) ---
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
open_url_with         default
detect_urls           yes

# Colores de pestañas
active_tab_foreground   #11111b
active_tab_background   #cba6f7
inactive_tab_foreground #cdd6f4
inactive_tab_background #181825
tab_bar_background      #11111b

# Colores ANSI Estándar
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

# --- Rendimiento, Scrollback & Portapapeles ---
repaint_delay            10
input_delay              3
sync_to_monitor          yes
scrollback_lines         10000
scrollback_pager_history_size 20
wheel_scroll_multiplier  3.0
touch_scroll_multiplier  2.0
mouse_hide_wait          3.0
copy_on_select           yes
strip_trailing_spaces    smart
shell_integration        enabled

# --- Silenciar Campanas ---
enable_audio_bell    no
visual_bell_duration 0.0
window_alert_on_bell no
bell_on_tab          no

# --- Atajos de Teclado Optimizados ---
# Portapapeles estándar:
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard

# Control dinámico de opacidad:
map ctrl+shift+a>m set_background_opacity +0.05
map ctrl+shift+a>l set_background_opacity -0.05
map ctrl+shift+a>d set_background_opacity default
map ctrl+shift+a>1 set_background_opacity 1.0

# Gestión de pestañas:
map ctrl+shift+t     new_tab_with_cwd
map ctrl+shift+q     close_tab
map ctrl+shift+right next_tab
map ctrl+shift+left  previous_tab
map alt+1 goto_tab 1
map alt+2 goto_tab 2
map alt+3 goto_tab 3
map alt+4 goto_tab 4
map alt+5 goto_tab 5

# Splits y ventanas internas:
map ctrl+shift+enter new_window_with_cwd
map ctrl+shift+w     close_window
map ctrl+shift+]     next_window
map ctrl+shift+[     previous_window

# Ajuste dinámico de tamaño de fuente:
map ctrl+equal       change_font_size all +1.0
map ctrl+plus        change_font_size all +1.0
map ctrl+kp_add      change_font_size all +1.0
map ctrl+minus       change_font_size all -1.0
map ctrl+kp_subtract change_font_size all -1.0
map ctrl+0           change_font_size all 0

# Recargar configuración en vivo:
map ctrl+shift+f5    load_config_file
EOF

# 4. Integración con KDE Plasma 6 y Dolphin
echo "📁 [4/4] Configurando integración con KDE Plasma 6 y Dolphin..."

# Terminal predeterminada en KDE
run_as_user kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "kitty" 2>/dev/null || true
run_as_user kwriteconfig6 --file kdeglobals --group General --key TerminalService "kitty.desktop" 2>/dev/null || true

# Atajo global Ctrl+Alt+T en KDE
run_as_user kwriteconfig6 --file kglobalshortcutsrc --group "services" --group "kitty.desktop" --key "_launch" "Ctrl+Alt+T,none,Kitty Terminal" 2>/dev/null || true

# Acción de menú contextual en Dolphin (KIO Servicemenus)
SERVICEMENUS_DIR="$USER_HOME/.local/share/kio/servicemenus"
run_as_user mkdir -p "$SERVICEMENUS_DIR"
cat <<'EOF' | run_as_user tee "$SERVICEMENUS_DIR/open-in-kitty.desktop" > /dev/null
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=inode/directory;
Actions=openInKitty;
X-KDE-Priority=TopLevel

[Desktop Action openInKitty]
Name=Abrir en Kitty
Name[es]=Abrir en Kitty
Name[en]=Open in Kitty
Icon=kitty
Exec=kitty --directory "%f"
EOF
run_as_user chmod +x "$SERVICEMENUS_DIR/open-in-kitty.desktop" 2>/dev/null || true

echo "==========================================================="
echo "✅ Kitty se ha configurado exitosamente para KDE Plasma 6."
echo "   • Tema: Catppuccin Mocha con opacidad 75% y blur 32."
echo "   • Fuente: JetBrainsMono Nerd Font (ligaduras activas)."
echo "   • Atajo global: Ctrl+Alt+T asignado en KDE."
echo "   • Menú Dolphin: 'Abrir en Kitty' disponible en clic derecho."
echo "==========================================================="
