# =============================================================================
# CONFIGURACIÓN Y ALIASES PARA NIRI + DANK MATERIAL SHELL (niri_dms.sh)
# =============================================================================
# Integración de entorno, IPC y utilidades para Niri (Wayland) y Dank Material Shell (DMS)
# Compatible con Zsh y Bash en Arch Linux.

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
# 2. CONTROL E IPC DE DANK MATERIAL SHELL (DMS)
# -----------------------------------------------------------------------------

# Recargar / reiniciar Dank Material Shell
alias dms-reload="dms restart 2>/dev/null || systemctl --user restart dms.service 2>/dev/null || echo 'DMS no está en ejecución.'"

# Diagnóstico de salud de DMS
alias dms-doc="dms doctor"

# Lanzador de aplicaciones (Application Launcher)
alias dms-launcher="dms ipc call launcher toggle"

# Centro de Control (Quick Settings, Red, Bluetooth, Audio, Brillo)
alias dms-control="dms ipc call control-center toggle"

# Ajustes de DMS
alias dms-settings="dms ipc call settings toggle"

# Gestor de portapapeles con vista previa
alias dms-clipboard="dms ipc call clipboard toggle"

# Menú de apagado / salida (Power menu)
alias dms-powermenu="dms ipc call powermenu toggle"

# Bloqueo de sesión
alias dms-lock="dms ipc call lock lock"

# Alternar tema claro / oscuro (Material You / Matugen)
alias dms-theme-toggle="dms ipc call theme toggle"

# Guía de atajos de teclado
alias dms-keybinds="dms ipc call keybinds toggle"

# Centro de notificaciones
alias dms-notifications="dms ipc call notifications toggle"

# Control de audio vía DMS
alias dms-volup="dms ipc call audio increment"
alias dms-voldown="dms ipc call audio decrement"
alias dms-mute="dms ipc call audio mute"

# Generación de copia de seguridad nativa de DMS
alias dms-backup-make="dms backup create"

# Fijar fondo de pantalla vía DMS o swww fallback
dms-set-wallpaper() {
    if [ -z "${1:-}" ] || [ ! -f "$1" ]; then
        echo "Uso: dms-set-wallpaper /ruta/a/imagen.jpg"
        return 1
    fi
    local img="$1"
    if command -v dms &>/dev/null; then
        dms ipc call wallpaper set "$img" 2>/dev/null && {
            echo "🖼️ Fondo de pantalla actualizado con DMS: $img"
            return 0
        }
    fi
    if command -v swww &>/dev/null; then
        swww img "$img" --transition-type wipe --transition-step 90 2>/dev/null && {
            echo "🖼️ Fondo de pantalla actualizado con swww: $img"
            return 0
        }
    fi
    echo "❌ No se pudo aplicar el fondo de pantalla (DMS o swww no activos)."
    return 1
}

# -----------------------------------------------------------------------------
# 3. PANELES Y AJUSTES RÁPIDOS DE HARDWARE (GUI)
# -----------------------------------------------------------------------------

# Control de Audio (PipeWire GUI)
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
# 4. CAPTURAS Y GRABACIÓN WAYLAND NATIVO (Grim, Slurp, Satty, wl-screenrec)
# -----------------------------------------------------------------------------

# Captura con DMS IPC nativo
if command -v dms &>/dev/null; then
    alias dms-captura="dms ipc call niri screenshot"
fi

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

    # Captura con editor visual Satty
    if command -v satty &>/dev/null; then
        alias captura-edit='grim -g "$(slurp)" - | satty --filename -'
    fi
fi

# Grabación de pantalla Wayland (wl-screenrec)
if command -v wl-screenrec &>/dev/null && command -v slurp &>/dev/null; then
    grabacion() {
        local target_dir="$HOME/Vídeos/Grabaciones"
        mkdir -p "$target_dir"
        local file="$target_dir/grabacion_$(date +%Y%m%d_%H%M%S).mp4"
        echo "🎥 Selecciona la región a grabar (Presiona Ctrl+C para detener)..."
        local geometry
        geometry=$(slurp) || return 1
        wl-screenrec -g "$geometry" -f "$file"
        echo "✅ Grabación guardada en: $file"
    }
fi

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Integración Niri + Dank Material Shell cargada (IPC, atajos y capturas)"
