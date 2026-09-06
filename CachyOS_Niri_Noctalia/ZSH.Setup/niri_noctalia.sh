# =============================================================================
# CONFIGURACIÓN Y ALIASES PARA NIRI + NOCTALIA SHELL (niri_noctalia.sh) - CachyOS
# =============================================================================
# Integración de entorno, IPC y utilidades para Niri (Wayland) y Noctalia Shell
# Compatible con Zsh y Bash.

# -----------------------------------------------------------------------------
# 1. CONTROL E IPC DE NIRI (Compositor Scrollable-Tiling)
# -----------------------------------------------------------------------------

# Recargar configuración de Niri en caliente
alias niri-reload="niri msg action reload-config"

# Validar sintaxis del archivo de configuración (~/.config/niri/config.kdl)
alias niri-validate="niri validate"

# Inspección de ventanas y estado
alias niri-windows="niri msg windows"
alias niri-focused="niri msg focused-window"
alias niri-outputs="niri msg outputs"

# Salir de Niri de forma limpia
alias niri-quit="niri msg action quit"

# Transición de pantalla / re-render
alias niri-transition="niri msg action do-screen-transition"

# -----------------------------------------------------------------------------
# 2. CONTROL E IPC DE NOCTALIA SHELL
# -----------------------------------------------------------------------------

# Recargar Noctalia Shell
alias noctalia-reload="noctalia msg reload 2>/dev/null || systemctl --user restart noctalia.service 2>/dev/null || echo 'Noctalia no está en ejecución.'"

# Lanzador de aplicaciones
alias noctalia-launcher="noctalia msg panel-toggle launcher"

# Centro de Control (Quick Settings, Red, Bluetooth, Audio)
alias noctalia-control="noctalia msg panel-toggle control-center"

# Ajustes de Noctalia Shell
alias noctalia-settings="noctalia msg settings-toggle"

# Bloqueo de sesión
alias noctalia-lock="noctalia msg session lock"

# Control de audio vía Noctalia
alias noctalia-volup="noctalia msg volume-up"
alias noctalia-voldown="noctalia msg volume-down"
alias noctalia-mute="noctalia msg volume-mute"

# Fijar fondo de pantalla vía Noctalia o swww/hyprpaper fallback
noctalia-set-wallpaper() {
    if [ -z "${1:-}" ] || [ ! -f "$1" ]; then
        echo "Uso: noctalia-set-wallpaper /ruta/a/imagen.jpg"
        return 1
    fi
    local img="$1"
    if command -v noctalia &>/dev/null; then
        noctalia msg wallpaper set "$img" 2>/dev/null && {
            echo "🖼️ Fondo de pantalla actualizado con Noctalia: $img"
            return 0
        }
    fi
    if command -v swww &>/dev/null; then
        swww img "$img" --transition-type wipe --transition-step 90 2>/dev/null && {
            echo "🖼️ Fondo de pantalla actualizado con swww: $img"
            return 0
        }
    fi
    echo "❌ No se pudo aplicar el fondo de pantalla (Noctalia o swww no activos)."
    return 1
}

# -----------------------------------------------------------------------------
# 3. PANELES Y AJUSTES RÁPIDOS DE HARDWARE (GUI)
# -----------------------------------------------------------------------------

# Control de Audio (PulseAudio / PipeWire GUI)
if command -v pavucontrol &>/dev/null; then
    alias audio-settings="pavucontrol &>/dev/null &"
fi

# Gestor de Bluetooth
if command -v blueman-manager &>/dev/null; then
    alias bluetooth-settings="blueman-manager &>/dev/null &"
fi

# Gestor de Redes Wi-Fi / Ethernet
if command -v nm-connection-editor &>/dev/null; then
    alias wifi-settings="nm-connection-editor &>/dev/null &"
fi

# -----------------------------------------------------------------------------
# 4. CAPTURAS Y GRABACIÓN WAYLAND NATIVO (Grim, Slurp, wl-screenrec)
# -----------------------------------------------------------------------------

# Captura de región interactiva directa al portapapeles
if command -v grim &>/dev/null && command -v slurp &>/dev/null; then
    alias captura='grim -g "$(slurp)" - | wl-copy'
    alias captura-pantalla='grim - | wl-copy'

    # Captura guardando a disco en ~/Imágenes/Capturas/
    captura-archivo() {
        local target_dir="$HOME/Imágenes/Capturas"
        mkdir -p "$target_dir"
        local file="$target_dir/captura_$(date +%Y%m%d_%H%M%S).png"
        grim -g "$(slurp)" "$file" && wl-copy < "$file"
        echo "📸 Captura guardada y copiada: $file"
    }
fi

# Grabación de pantalla Wayland (wl-screenrec)
if command -v wl-screenrec &>/dev/null && command -v slurp &>/dev/null; then
    grabacion() {
        local target_dir="$HOME/Vídeos/Grabaciones"
        mkdir -p "$target_dir"
        local file="$target_dir/grabacion_$(date +%Y%m%d_%H%M%S).mp4"
        echo "🎥 Selecciona la región a grabar (Presiona Ctrl+C para detener)..."
        local geometry
        geometry=$(slurp)
        if [ -n "$geometry" ]; then
            echo "⏺️ Grabando en $file..."
            wl-screenrec -g "$geometry" -f "$file"
            echo "✅ Grabación finalizada: $file"
        else
            echo "❌ Grabación cancelada (no se seleccionó región)."
        fi
    }
fi

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Configuración y utilidades de Niri + Noctalia Shell cargadas"
