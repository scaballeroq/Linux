#!/usr/bin/env bash
# ==============================================================================
# kitty.sh - Instalación y Configuración Estética de Kitty Terminal para openSUSE Tumbleweed
# Entorno: KDE Plasma 6 (Wayland) + Modo Oscuro Catppuccin Mocha
# ==============================================================================
# Características configuradas:
# - Esquema de color oscuro moderno (Catppuccin Mocha)
# - Opacidad/Transparencia (85%) con soporte para desenfoque (blur)
# - Integración con tipografía JetBrainsMono Nerd Font (ligaduras y símbolos)
# - Barra de pestañas estilo Powerline inclinada
# - Padding interno elegante y cursor tipo barra con animación
# - Control dinámico de opacidad con atajos de teclado
# - Integración con Dolphin (KIO Servicemenus) y atajo global KDE Ctrl+Alt+T
# ==============================================================================

set -euo pipefail

echo "==========================================================="
echo "🐱 Iniciando instalación y configuración estética de Kitty en KDE 6"
echo "==========================================================="

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

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# 1. Instalar Kitty y dependencias
echo "📦 [1/4] Instalando Kitty Terminal vía Zypper..."
$SUDO zypper --non-interactive install -y kitty 2>/dev/null || true

# 2. Crear directorio de configuración
echo "⚙️ [2/4] Creando directorios de configuración..."
run_as_user mkdir -p "$USER_HOME/.config/kitty"

# 3. Generar kitty.conf con tema oscuro, opacidad y efectos
echo "🎨 [3/4] Configurando tema oscuro Catppuccin Mocha, opacidad (85%) y efectos..."
cat <<'EOF' | run_as_user tee "$USER_HOME/.config/kitty/kitty.conf" > /dev/null
# =============================================================================
# KITTY CONFIGURATION - OPENSUSE TUMBLEWEED (KDE PLASMA 6)
# =============================================================================

# --- Fuentes & Tipografía ---
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        11.5
disable_ligatures never

# --- Transparencia y Opacidad ---
background_opacity         0.85
dynamic_background_opacity yes
background_blur            20

# --- Ventana y Márgenes ---
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

# --- Barra de Pestañas (Tab Bar) ---
tab_bar_edge          top
tab_bar_style         powerline
tab_powerline_style   slanted
tab_title_template    " {title}{' [' + num_windows.__str__() + ']' if num_windows > 1 else ''} "
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

# --- Rendimiento & Wayland ---
repaint_delay   10
input_delay     3
sync_to_monitor yes

# --- Desactivar campana acústica/visual molesta ---
enable_audio_bell no
visual_bell_duration 0.0

# --- Atajos de teclado útiles ---
# Control de opacidad en tiempo real:
map ctrl+shift+a>m set_background_opacity +0.05
map ctrl+shift+a>l set_background_opacity -0.05
map ctrl+shift+a>d set_background_opacity default
map ctrl+shift+a>1 set_background_opacity 1.0

# Gestión de pestañas y splits:
map ctrl+shift+t new_tab_with_cwd
map ctrl+shift+enter new_window_with_cwd
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
Icon=kitty
Exec=kitty --directory "%f"
EOF
run_as_user chmod +x "$SERVICEMENUS_DIR/open-in-kitty.desktop" 2>/dev/null || true

echo "==========================================================="
echo "✅ Kitty se ha instalado y configurado correctamente para KDE Plasma 6."
echo "   - Tema Catppuccin Mocha con opacidad 85% y blur."
echo "   - Atajo global Ctrl+Alt+T configurado."
echo "   - Acción 'Abrir en Kitty' añadida al menú contextual de Dolphin."
echo "==========================================================="
