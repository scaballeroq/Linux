#!/usr/bin/env bash
# ==============================================================================
# laptop-setup.sh - Optimización para portátiles de desarrollo en NixOS
# Entorno: KDE Plasma 6 (Wayland) + AMD Ryzen (HP EliteBook 855 G7)
# ==============================================================================

set -euo pipefail

# Detectar usuario real
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
💻 Optimización para Portátiles - NixOS (KDE Plasma 6)
Adaptado para HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica las optimizaciones de touchpad, energía y bluetooth para portátil.
  --status, -s        Muestra el estado actual de los servicios, touchpad y batería.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE CONFIGURACIÓN DE PORTÁTIL - NIXOS (KDE 6)"
    echo "================================================================="
    echo "• Power Profiles Daemon:       $(if systemctl is-active --quiet power-profiles-daemon 2>/dev/null; then echo "✅ Activo (Integrado en Plasma)"; else echo "❌ Inactivo"; fi)"
    echo "• Bluetooth Service:           $(if systemctl is-active --quiet bluetooth 2>/dev/null; then echo "✅ Activo"; else echo "❌ Inactivo"; fi)"
    echo "• Touchpad Natural Scroll:     $(if grep -q "NaturalScroll=true" "$USER_HOME/.config/kcminputrc" 2>/dev/null; then echo "✅ Activo"; else echo "❌ Desactivado"; fi)"
    echo "• PowerDevil Plasma 6:         $(if [ -f "$USER_HOME/.config/powerdevilrc" ]; then echo "✅ Configurado"; else echo "❌ Por defecto"; fi)"
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
echo "🚀 INICIANDO OPTIMIZACIÓN PARA PORTÁTIL - NIXOS (KDE 6)"
echo "================================================================="

# 1. Configurar Touchpad Wayland (Desplazamiento natural)
echo "ℹ️ [1/3] Configurando desplazamiento natural en Touchpad (Plasma 6 Wayland)..."
run_as_user kwriteconfig6 --file "$USER_HOME/.config/kcminputrc" --group "Libinput" --group "1133" --group "50505" --group "SynPS/2 Synaptics TouchPad" --key "NaturalScroll" "true" 2>/dev/null || true
run_as_user kwriteconfig6 --file "$USER_HOME/.config/kcminputrc" --group "Libinput" --key "NaturalScroll" "true" 2>/dev/null || true

# 2. Configurar perfiles de energía PowerDevil en Plasma 6
echo "ℹ️ [2/3] Configurando perfiles de energía (AC vs Batería) en PowerDevil..."
mkdir -p "$USER_HOME/.config"
cat << 'EOF' > "$USER_HOME/.config/powerdevilrc"
[AC][Display]
DimDisplayWhenIdle=false
TurnOffDisplayWhenIdle=true
TurnOffDisplayIdleTimeoutSec=900

[Battery][Display]
DimDisplayWhenIdle=true
DimDisplayIdleTimeoutSec=120
TurnOffDisplayWhenIdle=true
TurnOffDisplayIdleTimeoutSec=300

[Battery][SuspendAndShutdown]
AutoSuspendAction=1
AutoSuspendIdleTimeoutSec=900
EOF
chown "$REAL_USER:" "$USER_HOME/.config/powerdevilrc" 2>/dev/null || true

# 3. Notificación final
echo "ℹ️ [3/3] Optimizaciones de hardware declaradas en NixOS (modules/hardware.nix)."
echo "================================================================="
echo "✅ Entorno de portátil para NixOS configurado."
echo "================================================================="
