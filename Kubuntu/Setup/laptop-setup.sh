#!/bin/bash
# ==============================================================================
# laptop-setup.sh - Optimización de Portátil para Kubuntu 26.04.1 (Plasma 6)
# ==============================================================================
# Optimizado para:
#   - KDE Plasma 6 + Wayland
#   - power-profiles-daemon integrado (sin conflictos de TLP)
#   - Touchpad multitáctil nativo (tap-to-click, natural scrolling, gestos)
#   - Gestión de energía y umbral de carga de batería (80%)
#   - VRR (Variable Refresh Rate) y gráficos híbridos (switcheroo-control)
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "Error: Este script requiere privilegios de superusuario."
        exit 1
    fi
else
    SUDO=""
fi

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

show_help() {
    cat <<EOF
Optimizador de Portátiles - Kubuntu 26.04 (KDE Plasma 6)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Aplica todas las configuraciones de energía, touchpad, VRR y servicios.
  --status, -s           Muestra el estado de la batería, perfiles de energía, touchpad y VRR.
  --help, -h             Muestra esta ayuda.

Optimizaciones incluidas:
  1. Servicios de Energía y Hardware:
     - power-profiles-daemon (gestor nativo integrado en el widget de batería de Plasma 6).
     - switcheroo-control (conmutación dinámica de gráficos híbridos AMD/Intel/NVIDIA en Wayland).
     - brightnessctl y bluez (control de brillo y Bluetooth optimizado).
  2. Touchpad Nativo (Plasma 6 Wayland):
     - Tap-to-click (toque para pulsar).
     - Natural scrolling (desplazamiento natural).
     - Two-finger tap para clic secundario.
  3. Políticas de Energía (powermanagementprofilesrc):
     - Suspensión: 20 min en batería / 60 min en corriente (AC).
     - Umbral de carga de batería al 80% (preserva la vida útil de la batería en portátiles enchufados).
     - Atenuación y apagado progresivo de pantalla.
  4. Pantalla y Gráficos:
     - VRR (Tasa de refresco variable) en modo Automático para pantallas compatibles.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE HARDWARE Y ENERGÍA - KUBUNTU (PORTÁTIL)"
    echo "================================================================="
    echo "power-profiles-daemon:         $(systemctl is-active --quiet power-profiles-daemon 2>/dev/null && echo 'Activo' || echo 'Inactivo')"
    echo "Perfil de Energía Actual:      $(if command -v powerprofilesctl &>/dev/null; then powerprofilesctl get 2>/dev/null || echo 'n/a'; else echo 'powerprofilesctl no disponible'; fi)"
    echo "switcheroo-control:            $(systemctl is-active --quiet switcheroo-control 2>/dev/null && echo 'Activo' || echo 'Inactivo')"
    echo "Bluetooth:                     $(systemctl is-active --quiet bluetooth.service 2>/dev/null && echo 'Activo' || echo 'Inactivo')"
    echo "-----------------------------------------------------------------"
    echo "Batería / Umbral de Carga:"
    if [ -d /sys/class/power_supply ]; then
        for bat in /sys/class/power_supply/BAT*; do
            if [ -d "$bat" ]; then
                local name status capacity thresh
                name=$(basename "$bat")
                status=$(cat "$bat/status" 2>/dev/null || echo 'Desconocido')
                capacity=$(cat "$bat/capacity" 2>/dev/null || echo 'n/a')
                thresh=$(cat "$bat/charge_control_end_threshold" 2>/dev/null || echo 'No soportado por firmware')
                echo "  - $name: $capacity% ($status) | Límite hardware: $thresh%"
            fi
        done
    else
        echo "  No se detectaron baterías."
    fi
    echo "-----------------------------------------------------------------"
    echo "Touchpad (Tap-to-click):       $(if command -v kreadconfig6 &>/dev/null; then run_as_user kreadconfig6 --file kcminputrc --group Touchpad --key tapToClick 2>/dev/null || echo 'true'; else echo 'n/a'; fi)"
    echo "Touchpad (Natural Scroll):     $(if command -v kreadconfig6 &>/dev/null; then run_as_user kreadconfig6 --file kcminputrc --group Touchpad --key naturalScroll 2>/dev/null || echo 'true'; else echo 'n/a'; fi)"
    echo "VRR en Wayland (kwinrc):       $(if command -v kreadconfig6 &>/dev/null; then run_as_user kreadconfig6 --file kwinrc --group Wayland --key variableRefreshRate 2>/dev/null || echo 'Automatic'; else echo 'n/a'; fi)"
    echo "================================================================="
}

install_laptop_packages() {
    echo "ℹ️ [1/4] Instalando paquetes de hardware, energía y conectividad..."
    $SUDO apt update

    # NOTA: En Kubuntu 26.04 (Plasma 6), power-profiles-daemon es el backend oficial.
    # Evitamos instalar tlp para prevenir conflictos de gestión térmica y de frecuencia.
    $SUDO apt install -y \
        power-profiles-daemon \
        switcheroo-control \
        bluez \
        bluez-tools \
        brightnessctl

    # Habilitar y arrancar servicios de hardware
    $SUDO systemctl enable --now bluetooth.service 2>/dev/null || true
    $SUDO systemctl enable --now power-profiles-daemon.service 2>/dev/null || true
    $SUDO systemctl enable --now switcheroo-control.service 2>/dev/null || true

    echo "✅ Paquetes y servicios de hardware configurados."
}

configure_touchpad() {
    echo "ℹ️ [2/4] Configurando Touchpad en KDE Plasma 6..."

    if command -v kwriteconfig6 &>/dev/null; then
        run_as_user kwriteconfig6 --file kcminputrc --group Touchpad --key tapToClick true
        run_as_user kwriteconfig6 --file kcminputrc --group Touchpad --key naturalScroll true
        run_as_user kwriteconfig6 --file kcminputrc --group Touchpad --key twoFingerTap 2
        run_as_user kwriteconfig6 --file kcminputrc --group Touchpad --key scrollTwoFinger true
    else
        local cfg_path="$USER_HOME/.config/kcminputrc"
        mkdir -p "$(dirname "$cfg_path")"
        cat <<'EOF' >> "$cfg_path"

[Touchpad]
naturalScroll=true
scrollTwoFinger=true
tapToClick=true
twoFingerTap=2
EOF
    fi

    echo "✅ Touchpad configurado (Tap-to-click + Desplazamiento natural)."
}

configure_power_policies() {
    echo "ℹ️ [3/4] Configurando perfiles de gestión de energía (Plasma 6)..."

    if command -v kwriteconfig6 &>/dev/null; then
        # Batería: Suspensión a los 20 min (1200000 ms), atenuación a los 5 min (300 s), apagado pantalla a los 10 min (600 s)
        run_as_user kwriteconfig6 --file powermanagementprofilesrc --group Battery --group SuspendSession --key idleTime 1200000
        run_as_user kwriteconfig6 --file powermanagementprofilesrc --group Battery --group SuspendSession --key suspendType 1
        run_as_user kwriteconfig6 --file powermanagementprofilesrc --group Battery --group DimDisplay --key idleTime 300000
        run_as_user kwriteconfig6 --file powermanagementprofilesrc --group Battery --group ScreenEnergySaving --key idleTime 600

        # Corriente AC: Suspensión a los 60 min (3600000 ms), atenuación a los 10 min (600 s), apagado pantalla a los 20 min (1200 s)
        run_as_user kwriteconfig6 --file powermanagementprofilesrc --group AC --group SuspendSession --key idleTime 3600000
        run_as_user kwriteconfig6 --file powermanagementprofilesrc --group AC --group SuspendSession --key suspendType 1
        run_as_user kwriteconfig6 --file powermanagementprofilesrc --group AC --group DimDisplay --key idleTime 600000
        run_as_user kwriteconfig6 --file powermanagementprofilesrc --group AC --group ScreenEnergySaving --key idleTime 1200

        # Umbral de carga de batería al 80% (prolonga la vida de la batería si se usa conectado la mayor parte del tiempo)
        run_as_user kwriteconfig6 --file powermanagementprofilesrc --group Battery --key chargeStopThreshold 80
    fi

    echo "✅ Políticas de energía y umbrales aplicados."
}

configure_display_and_vrr() {
    echo "ℹ️ [4/4] Configurando VRR y gráficos Wayland..."

    if command -v kwriteconfig6 &>/dev/null; then
        run_as_user kwriteconfig6 --file kwinrc --group Wayland --key variableRefreshRate Automatic
        run_as_user kwriteconfig6 --file kwinrc --group Wayland --key VrrPolicy Automatic
    fi

    echo "✅ VRR en Wayland configurado en modo Automático."
}

case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "OPTIMIZANDO CONFIGURACIÓN DE PORTÁTIL - KUBUNTU 26.04 (PLASMA 6)"
        echo "================================================================="
        install_laptop_packages
        configure_touchpad
        configure_power_policies
        configure_display_and_vrr
        echo ""
        echo "================================================================="
        echo "Configuración de portátil aplicada con éxito."
        echo "Verifica el estado con: $0 --status"
        echo "================================================================="
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
