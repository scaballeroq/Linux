#!/usr/bin/env bash
#
# kitty.sh - Instalación y Configuración Estética de Kitty Terminal para Fedora 44 + KDE Plasma
#
# Características configuradas:
# - Esquema de color oscuro moderno (Catppuccin Mocha / Tokyo Night dark palette)
# - Opacidad/Transparencia (85%) con soporte para desenfoque (blur)
# - Integración con tipografía JetBrainsMono Nerd Font (ligaduras y símbolos)
# - Barra de pestañas estilo Powerline inclinada
# - Padding interno elegante y cursor tipo barra con animación
# - Control dinámico de opacidad con atajos de teclado
# - Integración con Dolphin (ServiceMenu y terminal predeterminado) y atajo global Ctrl+Alt+T en KDE Plasma

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

echo "==========================================================="
echo "🐱 Iniciando instalación y configuración estética de Kitty en Fedora 44 (KDE Plasma)"
echo "==========================================================="

# 1. Instalar Kitty y dependencias
echo "📦 [1/4] Instalando Kitty Terminal con DNF5..."
$SUDO dnf5 install -y kitty

# 2. Crear directorio de configuración
echo "⚙️ [2/4] Creando directorios de configuración..."
mkdir -p "$HOME/.config/kitty"

# 3. Generar kitty.conf con tema oscuro, opacidad y efectos
echo "🎨 [3/4] Configurando tema oscuro, opacidad (85%) y efectos visuales..."
cat <<'EOF' > "$HOME/.config/kitty/kitty.conf"
# =============================================================================
# KITTY CONFIGURATION - FEDORA 44 + KDE PLASMA
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

# --- Rendimiento y Gráficos ---
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

# 4. Integración con Dolphin y KDE Plasma
echo "📁 [4/4] Configurando integración con Dolphin y atajos de KDE Plasma..."

# Configurar Kitty como terminal por defecto y atajo Ctrl+Alt+T en KDE Plasma
if command -v kwriteconfig6 &> /dev/null; then
    # Terminal predeterminado de KDE
    kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "kitty"
    kwriteconfig6 --file kdeglobals --group General --key TerminalService "kitty.desktop"
    
    # Atajo global Ctrl+Alt+T
    kwriteconfig6 --file kglobalshortcutsrc --group kitty.desktop --key _launch "Ctrl+Alt+T,none,kitty"
    kwriteconfig6 --file kglobalshortcutsrc --group kitty.desktop --key _k_friendly_name "Kitty"
    qdbus6 org.kde.kglobalaccel /kglobalaccel reloadConfig 2>/dev/null || true
elif command -v kwriteconfig5 &> /dev/null; then
    kwriteconfig5 --file kdeglobals --group General --key TerminalApplication "kitty"
    kwriteconfig5 --file kdeglobals --group General --key TerminalService "kitty.desktop"
    kwriteconfig5 --file kglobalshortcutsrc --group kitty.desktop --key _launch "Ctrl+Alt+T,none,kitty"
    kwriteconfig5 --file kglobalshortcutsrc --group kitty.desktop --key _k_friendly_name "Kitty"
    qdbus org.kde.kglobalaccel /kglobalaccel reloadConfig 2>/dev/null || true
fi

# Añadir acción de menú contextual para Dolphin (ServiceMenu "Abrir en Kitty")
DOLPHIN_SERVICES_DIR="$HOME/.local/share/kio/servicemenus"
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
chmod +x "$DOLPHIN_SERVICES_DIR/open_in_kitty.desktop"

# Compatibilidad con Plasma 5 si existe el directorio
if [ -d "$HOME/.local/share/kservices5/ServiceMenus" ]; then
    cp "$DOLPHIN_SERVICES_DIR/open_in_kitty.desktop" "$HOME/.local/share/kservices5/ServiceMenus/" 2>/dev/null || true
fi

echo "==========================================================="
echo "✅ Kitty se ha instalado y configurado correctamente en KDE Plasma."
echo "💡 Características añadidas:"
echo "   - Menú contextual en Dolphin: Clic derecho -> 'Abrir en Kitty'."
echo "   - Terminal predeterminado del sistema (Shift+F4 en Dolphin)."
echo "   - Atajo global: Ctrl+Alt+T para abrir Kitty en cualquier momento."
echo "   - Atajos de opacidad al vuelo: Ctrl+Shift+A seguido de M (+5%), L (-5%) o 1 (Opaco 100%)."
echo "   - Nueva pestaña en mismo directorio: Ctrl+Shift+T"
echo "   - Nueva ventana dividida: Ctrl+Shift+Enter"
echo "==========================================================="
