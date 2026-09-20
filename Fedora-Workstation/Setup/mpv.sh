#!/usr/bin/env bash
# ==============================================================================
# mpv.sh - Instalación y Optimización de MPV Video Player para Fedora 44 Workstation
# Aceleración VA-API (AMD/Intel), Wayland nativo (gpu-next), HDR Tone Mapping y PipeWire
# ==============================================================================

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
🎬 Instalador y Optimizador de MPV Player - Fedora 44 Workstation (GNOME / Wayland)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala MPV, drivers VA-API freeworld (RPM Fusion) y despliega
                      la configuración optimizada para Wayland y GPUs AMD/Intel.
  --status, -s        Muestra el estado de instalación de MPV, aceleración VA-API y configuración.
  --help, -h          Muestra este mensaje de ayuda.

Características configuradas:
  • Salida de vídeo:  vo=gpu-next con contexto nativo Wayland (sin desgarro ni capas X11).
  • Aceleración HW:   hwdec=auto-safe aprovechando VA-API (AMD Radeon Vega / Intel UHD/Iris).
  • Color y HDR:      Mapeo de tonos avanzado (spline) para vídeos de smartphones (Google Pixel, iPhone).
  • Drivers:          mesa-va-drivers-freeworld (soporte completo para decodificación H.264/HEVC/VP9).
  • Integración:      Recuerda posición al salir, redimensionado inteligente y PipeWire.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE MPV Y ACELERACIÓN POR HARDWARE - FEDORA 44"
    echo "================================================================="
    echo "• MPV instalado:            $(if command -v mpv &>/dev/null; then echo "✅ $(mpv --version 2>/dev/null | head -n 1)"; else echo "❌ No instalado"; fi)"
    echo "• Mesa VA-API Freeworld:    $(if rpm -q mesa-va-drivers-freeworld &>/dev/null; then echo "✅ $(rpm -q --qf '%{VERSION}-%{RELEASE}' mesa-va-drivers-freeworld)"; else echo "❌ No instalado (requerido para H.264/HEVC)"; fi)"
    echo "• libva-utils (vainfo):     $(if rpm -q libva-utils &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"

    local config_file="$USER_HOME/.config/mpv/mpv.conf"
    echo "• Archivo de configuración: $(if [ -f "$config_file" ]; then echo "✅ Presente ($config_file)"; else echo "⚠️ No existe"; fi)"

    if command -v vainfo &>/dev/null; then
        echo "-----------------------------------------------------------------"
        echo "• Perfiles VA-API detectados:"
        vainfo 2>/dev/null | grep -E "VAProfile(H264|HEVC|VP9|AV1)" | head -n 6 || echo "  (Sin perfiles activos)"
    fi
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

echo "================================================================="
echo "🎬 CONFIGURANDO REPRODUCTOR MPV (WAYLAND + ACELERACIÓN HW)"
echo "================================================================="

# 1. Instalar MPV
echo "📦 [1/3] Instalando MPV desde repositorios oficiales..."
$SUDO dnf5 install -y mpv

# 2. Instalar drivers de aceleración por hardware (VA-API Freeworld)
echo "⚡ [2/3] Verificando e instalando controladores VA-API con soporte freeworld..."
$SUDO dnf5 install -y \
    mesa-va-drivers-freeworld \
    mesa-vdpau-drivers-freeworld \
    libva-utils 2>/dev/null || true

CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo 2>/dev/null | awk '{print $3}' || true)
if [ "$CPU_VENDOR" == "GenuineIntel" ]; then
    echo "ℹ️ CPU Intel detectada: asegurando intel-media-driver..."
    $SUDO dnf5 install -y intel-media-driver 2>/dev/null || true
fi

# 3. Desplegar configuración optimizada en ~/.config/mpv/mpv.conf
echo "⚙️ [3/3] Desplegando archivo de configuración optimizado en $USER_HOME/.config/mpv/mpv.conf..."

MPV_CONF_DIR="$USER_HOME/.config/mpv"
run_as_user mkdir -p "$MPV_CONF_DIR"

CONFIG_TARGET="$MPV_CONF_DIR/mpv.conf"

if [ -f "$CONFIG_TARGET" ]; then
    BACKUP_FILE="${CONFIG_TARGET}.bak.$(date +%Y%m%d%H%M%S)"
    echo "📋 Creando copia de seguridad de la configuración previa en $BACKUP_FILE..."
    run_as_user cp "$CONFIG_TARGET" "$BACKUP_FILE"
fi

cat << 'EOF' | run_as_user tee "$CONFIG_TARGET" > /dev/null
# ==============================================================================
# MPV Configuration - Fedora 44 Workstation (GNOME Wayland / AMD & Intel)
# ==============================================================================

# --- Salida de Vídeo y Rendimiento Wayland ---
vo=gpu-next
gpu-context=wayland

# --- Aceleración por Hardware ---
# Utiliza VA-API nativo sin consumo de CPU para H.264, HEVC (H.265), VP9 y AV1
hwdec=auto-safe

# --- Tratamiento de Color y HDR (Especial para Pixel 6a / Smartphones) ---
# Mapeo de tonos avanzado para adaptar contenido HDR a pantallas SDR con máxima fidelidad
tone-mapping=spline
target-colorspace-hint=yes

# --- Comportamiento de la Ventana e Interfaz ---
keep-open=yes
autofit-larger=80%x80%
autofit-smaller=30%x30%
cursor-autohide=1000

# --- Reproducción y Audio ---
ao=pipewire,pulse
save-position-on-quit=yes

# --- Capturas de Pantalla ---
screenshot-format=png
screenshot-high-bit-depth=yes
screenshot-directory=~~desktop/
screenshot-template="mpv-%F-%P"
EOF

# Asegurar propiedad correcta del archivo y directorio
chown -R "$REAL_USER:$REAL_USER" "$MPV_CONF_DIR"

echo "================================================================="
echo "✅ MPV y aceleración por hardware configurados con éxito."
echo "================================================================="
echo "💡 Para probarlo con un vídeo: mpv ~/Vídeos/tu_video.mp4"
echo "💡 Atajos rápidos: [ . ] frame a frame | [ [ / ] ] velocidad | [ Espacio ] pausa"
