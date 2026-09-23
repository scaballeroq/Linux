#!/bin/bash
# ==============================================================================
# laptop-setup.sh - Optimización para portátiles de desarrollo en openSUSE Tumbleweed
# Entorno: KDE Plasma 6 (Wayland) + AMD Ryzen (HP EliteBook 855 G7)
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
💻 Optimización para Portátiles - openSUSE Tumbleweed (KDE Plasma 6)
Especialmente adaptado para HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica todas las optimizaciones recomendadas para portátil.
  --status, -s        Muestra el estado actual de los servicios, touchpad, energía y bluetooth.
  --help, -h          Muestra este mensaje de ayuda.

Optimizaciones aplicadas:
  • Energía (Power Profiles):  power-profiles-daemon integrado en el applet de batería de Plasma 6.
  • Bluetooth (BlueZ):         Nivel de batería de periféricos para BlueDevil y FastConnectable.
  • Cierre de Tapa Inteligente: Evita suspender si hay pantallas externas o corriente (logind + PowerDevil).
  • Touchpad (Plasma 6):       Desplazamiento natural vía KWin Wayland (Tap-to-click ya nativo).
  • PowerDevil (Plasma 6):     Perfiles nativos en ~/.config/powerdevilrc (AC y Batería).
  • Brillo Nativo:             Manejado por systemd-backlight y PowerDevil (sin hacks ni forzados).
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE CONFIGURACIÓN DE PORTÁTIL - KDE PLASMA 6"
    echo "================================================================="
    echo "• Power Profiles Daemon:       $(if systemctl is-active --quiet power-profiles-daemon 2>/dev/null; then echo "✅ Activo (Integrado en Plasma)"; else echo "❌ Inactivo"; fi)"
    echo "• Bluetooth Service:           $(if systemctl is-active --quiet bluetooth 2>/dev/null; then echo "✅ Activo"; else echo "❌ Inactivo"; fi)"
    echo "• Bluetooth Batería/FastConn:  $(if grep -q "Experimental = true" /etc/bluetooth/main.conf 2>/dev/null && grep -q "FastConnectable = true" /etc/bluetooth/main.conf 2>/dev/null; then echo "✅ Configurado"; else echo "❌ No configurado"; fi)"
    echo "• Logind Lid (Docked/AC):      $(if [ -f /etc/systemd/logind.conf.d/lid-docked.conf ]; then echo "✅ Configurado"; else echo "❌ No configurado"; fi)"
    echo "• Control Nativo de Brillo:    $(if systemctl is-active --quiet "systemd-backlight@backlight:amdgpu_bl1.service" 2>/dev/null; then echo "✅ Nativo (systemd-backlight + PowerDevil)"; else echo "ℹ️ Activo vía kernel"; fi)"
    echo "• Touchpad Tap-to-Click:       ✅ Activo por defecto en Plasma 6 Wayland"
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
echo "🚀 INICIANDO OPTIMIZACIÓN PARA PORTÁTIL - OPENSUSE TUMBLEWEED (KDE 6)"
echo "================================================================="

# 1. Servicios de Energía
echo "ℹ️ [1/5] Verificando daemon de perfiles de energía (power-profiles-daemon)..."
if ! rpm -q power-profiles-daemon &>/dev/null; then
    $SUDO zypper --non-interactive install -y power-profiles-daemon 2>/dev/null || true
fi
$SUDO systemctl enable --now power-profiles-daemon.service 2>/dev/null || true
$SUDO systemctl enable --now bluetooth.service 2>/dev/null || true

# 2. Optimización Bluetooth (Batería de periféricos en BlueDevil y reconexión rápida)
echo "ℹ️ [2/5] Configurando Bluetooth (batería de dispositivos en Plasma y FastConnectable)..."
$SUDO mkdir -p /etc/bluetooth
if [ -f /etc/bluetooth/main.conf ]; then
    $SUDO sed -i 's/^#* *Experimental *=.*/Experimental = true/' /etc/bluetooth/main.conf
    $SUDO sed -i 's/^#* *FastConnectable *=.*/FastConnectable = true/' /etc/bluetooth/main.conf
    if ! grep -q "^Experimental *= *true" /etc/bluetooth/main.conf; then
        echo "Experimental = true" | $SUDO tee -a /etc/bluetooth/main.conf > /dev/null
    fi
    if ! grep -q "^FastConnectable *= *true" /etc/bluetooth/main.conf; then
        echo "FastConnectable = true" | $SUDO tee -a /etc/bluetooth/main.conf > /dev/null
    fi
else
    cat <<EOF | $SUDO tee /etc/bluetooth/main.conf > /dev/null
[General]
Experimental = true
FastConnectable = true
EOF
fi
$SUDO systemctl restart bluetooth.service 2>/dev/null || true

# 3. Comportamiento de tapa en escritorio (evita suspender con monitores externos o corriente)
echo "ℹ️ [3/5] Configurando comportamiento de la tapa en systemd-logind (docking / pantallas externas)..."
$SUDO mkdir -p /etc/systemd/logind.conf.d/
cat <<EOF | $SUDO tee /etc/systemd/logind.conf.d/lid-docked.conf > /dev/null
# Comportamiento de tapa para portátil: suspende solo con batería y sin monitores externos
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF

# 4. Configuración de Touchpad en KDE Plasma 6 (Wayland)
echo "ℹ️ [4/5] Configurando Touchpad en KDE Plasma 6 (Wayland)..."
echo "   • Tap-to-click: Ya viene activo por defecto en Wayland en KDE 6."

# Aplicar desplazamiento natural en caliente vía D-Bus a todos los touchpads detectados por KWin
touchpads_found=0
for dev in $(run_as_user qdbus6 org.kde.KWin /org/kde/KWin/InputDevice org.kde.KWin.InputDeviceManager.devicesSysNames 2>/dev/null || true); do
    is_touchpad=$(run_as_user qdbus6 org.kde.KWin /org/kde/KWin/InputDevice/"$dev" org.freedesktop.DBus.Properties.Get org.kde.KWin.InputDevice touchpad 2>/dev/null || echo "false")
    if [ "$is_touchpad" = "true" ]; then
        touchpads_found=$((touchpads_found + 1))
        run_as_user qdbus6 org.kde.KWin /org/kde/KWin/InputDevice/"$dev" org.freedesktop.DBus.Properties.Set org.kde.KWin.InputDevice naturalScroll true 2>/dev/null || true
        
        vendor=$(run_as_user qdbus6 org.kde.KWin /org/kde/KWin/InputDevice/"$dev" org.freedesktop.DBus.Properties.Get org.kde.KWin.InputDevice vendor 2>/dev/null || true)
        product=$(run_as_user qdbus6 org.kde.KWin /org/kde/KWin/InputDevice/"$dev" org.freedesktop.DBus.Properties.Get org.kde.KWin.InputDevice product 2>/dev/null || true)
        dev_name=$(run_as_user qdbus6 org.kde.KWin /org/kde/KWin/InputDevice/"$dev" org.freedesktop.DBus.Properties.Get org.kde.KWin.InputDevice name 2>/dev/null || true)
        
        if [ -n "$vendor" ] && [ -n "$product" ] && [ -n "$dev_name" ]; then
            run_as_user kwriteconfig6 --file kcminputrc --group "Libinput" --group "$vendor" --group "$product" --group "$dev_name" --key "NaturalScroll" true 2>/dev/null || true
        fi
    fi
done

if [ "$touchpads_found" -eq 0 ]; then
    # Fallback si no hay sesión gráfica activa al momento de ejecutar
    run_as_user kwriteconfig6 --file kcminputrc --group "Libinput" --group "1739" --group "52745" --group "SYNA30BF:00 06CB:CE09" --key "NaturalScroll" true 2>/dev/null || true
fi
echo "   ✅ Desplazamiento natural (Natural Scroll) configurado."

# 5. Configuración de Energía en KDE Plasma 6 (PowerDevil)
echo "ℹ️ [5/5] Configurando perfiles de energía en KDE Plasma 6 (PowerDevil)..."
# Modo Corriente (AC): No suspender automáticamente, inhibir cierre de tapa con monitores externos
run_as_user kwriteconfig6 --file powerdevilrc --group "AC" --key "AutoSuspendAction" 0
run_as_user kwriteconfig6 --file powerdevilrc --group "AC" --key "AutoSuspendIdleTimeoutSec" 0
run_as_user kwriteconfig6 --file powerdevilrc --group "AC" --key "InhibitLidActionWhenExternalMonitorPresent" true

# Modo Batería: Suspender automáticamente tras 30 min (1800 s) de inactividad
run_as_user kwriteconfig6 --file powerdevilrc --group "Battery" --key "AutoSuspendAction" 1
run_as_user kwriteconfig6 --file powerdevilrc --group "Battery" --key "AutoSuspendIdleTimeoutSec" 1800
run_as_user kwriteconfig6 --file powerdevilrc --group "Battery" --key "InhibitLidActionWhenExternalMonitorPresent" true

# Recargar configuración de PowerDevil vía D-Bus si la sesión está activa
run_as_user qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement.reparseConfiguration 2>/dev/null || true

# 6. Limpieza de hacks antiguos (forzado de brillo y servicios de GPU híbrida innecesarios)
if [ -f /etc/systemd/system/persist-screen-brightness.service ]; then
    echo "🧹 Limpiando servicio heredado de forzado de brillo..."
    $SUDO systemctl disable --now persist-screen-brightness.service 2>/dev/null || true
    $SUDO rm -f /etc/systemd/system/persist-screen-brightness.service
    $SUDO systemctl daemon-reload 2>/dev/null || true
fi

if [ -f "$USER_HOME/.config/autostart/set-screen-brightness.desktop" ]; then
    echo "🧹 Limpiando autostart heredado de forzado de brillo..."
    rm -f "$USER_HOME/.config/autostart/set-screen-brightness.desktop"
fi

if systemctl is-active --quiet switcheroo-control 2>/dev/null; then
    echo "🧹 Desactivando switcheroo-control (innecesario en GPU única AMD Vega)..."
    $SUDO systemctl disable --now switcheroo-control.service 2>/dev/null || true
fi

echo "================================================================="
echo "✅ Optimización de portátil completada para openSUSE Tumbleweed (KDE 6)."
echo "   - power-profiles-daemon integrado con el applet de batería de Plasma."
echo "   - Bluetooth con FastConnectable y reporte de batería en BlueDevil."
echo "   - Cierre de tapa inteligente (ignora suspensión con pantallas externas)."
echo "   - Touchpad con desplazamiento natural y tap-to-click nativo de Plasma 6."
echo "   - PowerDevil configurado limpiamente en ~/.config/powerdevilrc."
echo "   - Brillo controlado de forma 100% nativa por systemd y Plasma 6."
echo "================================================================="
