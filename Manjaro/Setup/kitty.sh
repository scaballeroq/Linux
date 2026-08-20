#!/usr/bin/env bash
# kitty.sh - Instalación y Configuración Estética de Kitty Terminal para Manjaro Linux + GNOME
#
# Características configuradas:
# - Esquema de color oscuro moderno (Catppuccin Mocha)
# - Opacidad/Transparencia (85%) con desenfoque (blur)
# - Integración con tipografía JetBrainsMono Nerd Font
# - Barra de pestañas estilo Powerline inclinada
# - Control dinámico de opacidad con atajos de teclado
# - Integración con Nautilus y GNOME

set -euo pipefail

echo "==========================================================="
echo "🐱 Iniciando instalación y configuración de Kitty en Manjaro"
echo "==========================================================="

# 1. Instalar Kitty
echo "📦 [1/4] Instalando Kitty Terminal vía Pacman..."
sudo pacman -S --needed --noconfirm kitty

# 2. Crear directorio de configuración
echo "⚙️ [2/4] Creando directorios de configuración..."
mkdir -p "$HOME/.config/kitty"

# 3. Generar kitty.conf con tema oscuro, opacidad y efectos
echo "🎨 [3/4] Configurando tema oscuro, opacidad (85%) y efectos visuales..."
cat <<'EOF' > "$HOME/.config/kitty/kitty.conf"
# =============================================================================
# KITTY CONFIGURATION - MANJARO LINUX + GNOME
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

# --- Rendimiento y Gráficos ---
repaint_delay   10
input_delay     3
sync_to_monitor yes

# --- Desactivar campana molesta ---
enable_audio_bell no
visual_bell_duration 0.0

# --- Atajos de teclado útiles ---
map ctrl+shift+a>m set_background_opacity +0.05
map ctrl+shift+a>l set_background_opacity -0.05
map ctrl+shift+a>d set_background_opacity default
map ctrl+shift+a>1 set_background_opacity 1.0

map ctrl+shift+t new_tab_with_cwd
map ctrl+shift+enter new_window_with_cwd
EOF

# 4. Integración con Nautilus y GNOME GSettings
echo "📁 [4/4] Configurando integración con el entorno GNOME..."

if command -v gsettings &>/dev/null; then
    if gsettings list-schemas | grep -q "com.github.stunkymonkey.nautilus-open-any-terminal"; then
        echo "ℹ️ Configurando Kitty en extensión Nautilus Open Any Terminal..."
        gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal kitty 2>/dev/null || true
    fi
fi

NAUTILUS_SCRIPTS_DIR="$HOME/.local/share/nautilus/scripts"
mkdir -p "$NAUTILUS_SCRIPTS_DIR"
cat <<'EOF' > "$NAUTILUS_SCRIPTS_DIR/Abrir en Kitty"
#!/usr/bin/env bash
if [ -n "${NAUTILUS_SCRIPT_CURRENT_URI:-}" ]; then
    TARGET_DIR=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | sed 's|%20| |g')
    kitty --directory "$TARGET_DIR" &
else
    kitty &
fi
EOF
chmod +x "$NAUTILUS_SCRIPTS_DIR/Abrir en Kitty"

echo "==========================================================="
echo "✅ Kitty se ha instalado y configurado correctamente en Manjaro."
echo "==========================================================="
