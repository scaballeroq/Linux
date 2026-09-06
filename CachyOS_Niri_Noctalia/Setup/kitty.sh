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
    echo "📦 [1/5] Instalando Kitty Terminal con Pacman..."
    if [ -n "$SUDO" ]; then
        $SUDO pacman -S --needed --noconfirm kitty
    else
        pacman -S --needed --noconfirm kitty
    fi
else
    echo "📦 [1/5] Kitty Terminal ya se encuentra instalado."
fi

# 2. Crear directorio de configuracion
echo "⚙️ [2/5] Creando directorios de configuracion en $USER_HOME/.config/kitty..."
run_as_user mkdir -p "$USER_HOME/.config/kitty/themes"

# 3. Generar kitty.conf con integracion nativa a Noctalia Shell y Wayland
echo "🎨 [3/5] Generando configuracion integrada con Noctalia (Opacidad ${OPACITY}, Blur ${BLUR_RADIUS})..."
cat <<EOF | run_as_user tee "$USER_HOME/.config/kitty/kitty.conf" > /dev/null
# =============================================================================
# KITTY CONFIGURATION - CACHYOS + NIRI WAYLAND + NOCTALIA
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
# TEMA DINAMICO NOCTALIA (Renderizado automaticamente por Noctalia Shell)
# =============================================================================
include themes/noctalia.conf
EOF

# Aplicar plantilla de tema Noctalia para Kitty si Noctalia esta instalado
if command -v noctalia &>/dev/null; then
    run_as_user noctalia msg templates-apply 2>/dev/null || true
elif [ -f "/usr/share/noctalia/assets/templates/kitty/apply.sh" ]; then
    run_as_user bash /usr/share/noctalia/assets/templates/kitty/apply.sh 2>/dev/null || true
fi

# Asegurar propiedad correcta del directorio y archivo de configuracion
if [ -n "$SUDO" ] || [ "$EUID" -eq 0 ]; then
    chown -R "$REAL_USER:" "$USER_HOME/.config/kitty"
fi

# 4. Configurar Kitty como terminal predeterminado del sistema
echo "📁 [4/5] Estableciendo Kitty como terminal predeterminado del sistema..."

# A) Exportar TERMINAL=kitty en la sesión del usuario (environment.d para systemd user session)
ENV_DIR="$USER_HOME/.config/environment.d"
run_as_user mkdir -p "$ENV_DIR"
echo "TERMINAL=kitty" | run_as_user tee "$ENV_DIR/10-terminal.conf" > /dev/null

# B) Definir TERMINAL=kitty global en /etc/environment (si tenemos privilegios)
if [ -n "$SUDO" ] || [ "$EUID" -eq 0 ]; then
    if [ -f "/etc/environment" ]; then
        if grep -q "^TERMINAL=" /etc/environment; then
            $SUDO sed -i 's/^TERMINAL=.*/TERMINAL=kitty/' /etc/environment
        else
            echo "TERMINAL=kitty" | $SUDO tee -a /etc/environment > /dev/null
        fi
    fi
    # Enlace simbolico para scripts clasicos que invocan x-terminal-emulator
    if [ -x "/usr/bin/kitty" ]; then
        $SUDO ln -sf /usr/bin/kitty /usr/local/bin/x-terminal-emulator
    fi
fi

# C) Esquemas GSettings / GNOME / Portales
if command -v gsettings &>/dev/null; then
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec-arg '-e' 2>/dev/null || true
fi

# D) Registrar esquema MIME de terminal para gestores de archivos y aplicaciones XDG
if command -v xdg-mime &>/dev/null; then
    run_as_user xdg-mime default kitty.desktop x-scheme-handler/terminal 2>/dev/null || true
fi

# 5. Integrar Kitty en Niri y Noctalia Shell (Mod+Return -> Kitty)
echo "⌨️ [5/5] Vinculando atajo de teclado global en Niri (Mod+Return -> Kitty)..."

update_niri_keybind() {
    local target_file="$1"
    if [ -f "$target_file" ]; then
        # Crear respaldo si no existe
        if [ ! -f "${target_file}.kitty_bak" ]; then
            run_as_user cp "$target_file" "${target_file}.kitty_bak"
        fi

        # Actualizar la linea con hotkey-overlay de Noctalia (ej: Open Terminal: Alacritty -> Kitty)
        if grep -q 'hotkey-overlay-title=.*Open Terminal' "$target_file"; then
            sed -i -E 's/(Mod\+Return[^{]*hotkey-overlay-title="Open Terminal:)[^"]+(" *\{ *spawn ")[^"]+("; *\})/\1 Kitty\2kitty\3/' "$target_file"
        fi

        # Formato estandar sin overlay o si quedo algun spawn alacritty/foot
        sed -i -E 's/(Mod\+Return *\{ *spawn *")[^"]+("; *\})/\1kitty\2/' "$target_file"
        sed -i -E 's/spawn "alacritty"/spawn "kitty"/g' "$target_file"
        sed -i -E 's/spawn "foot"/spawn "kitty"/g' "$target_file"
        sed -i -E 's/hotkey-overlay-title="Open Terminal: Alacritty"/hotkey-overlay-title="Open Terminal: Kitty"/g' "$target_file"

        if [ -n "$SUDO" ] || [ "$EUID" -eq 0 ]; then
            chown "$REAL_USER:" "$target_file"
        fi
        echo "   -> Atajo Mod+Return actualizado en $(basename "$target_file")"
    fi
}

update_niri_keybind "$USER_HOME/.config/niri/cfg/keybinds.kdl"
update_niri_keybind "$USER_HOME/.config/niri/config.kdl"

# Recargar Niri en caliente si el compositor esta activo
if command -v niri &>/dev/null; then
    run_as_user niri msg action reload-config 2>/dev/null || true
fi

# Recargar instancias activas de Kitty
killall -USR1 kitty 2>/dev/null || true

echo "==========================================================="
echo "✅ Kitty se ha configurado y establecido como terminal por defecto."
echo "🎨 Opacidad: ${OPACITY} (${OPACITY_PERCENT}%) | Desenfoque (Blur): ${BLUR_RADIUS} | Wayland nativo"
echo "💡 Atajos rapidos y uso:"
echo "   - Atajo global en Niri / Noctalia: Mod+Return (Super+Enter) para abrir Kitty."
echo "   - Opacidad directa: Ctrl+Alt+Arriba (+5%) | Ctrl+Alt+Abajo (-5%) | Ctrl+Alt+0 (Default) | Ctrl+Alt+1 (100% Opaco)"
echo "   - Opacidad por F-Keys: Ctrl+Shift+F11 (+5%) | Ctrl+Shift+F10 (-5%) | Ctrl+Shift+F9 (Default)"
echo "   - Recargar configuracion en vivo: Ctrl+Shift+F5"
echo "   - Nueva pestana en mismo directorio: Ctrl+Shift+T"
echo "   - Nueva ventana dividida: Ctrl+Shift+Enter"
echo "==========================================================="
