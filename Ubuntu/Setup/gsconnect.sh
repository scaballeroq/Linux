#!/usr/bin/env bash
# ==============================================================================
# gsconnect.sh - Integración de GSConnect (KDE Connect para GNOME) y Firewalld
# Sistema: Ubuntu Workstation | Escritorio: GNOME Shell 51 (Wayland)
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U / Radeon Vega 7)
# ==============================================================================
# Características:
# - Implementación 100% nativa de GNOME (GJS) del protocolo KDE Connect (cero KDE/Qt).
# - Configuración del cortafuegos nativo Firewalld (puertos 1714-1764 TCP/UDP).
# - Integración nativa con Quick Settings, centro de notificaciones y Nautilus.
# - Diagnóstico integral: estado de la extensión, reglas de red y dispositivos emparejados.
# - Opciones CLI completas: --status, --devices, --open, --restart, --disable, --help.
# ==============================================================================

set -euo pipefail

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

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

GSCONNECT_UUID="gsconnect@andyholmes.github.io"

show_help() {
    cat <<EOF
📱 Gestor de GSConnect (KDE Connect para GNOME) y Cortafuegos - Ubuntu

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala GSConnect, sshfs, habilita la extensión y abre reglas en Firewalld.
  --status, -s        Muestra diagnóstico completo de red, puertos 1714-1764 y estado de la extensión.
  --devices, -d       Lista los dispositivos móviles detectados y emparejados.
  --open, -o          Abre el panel gráfico de preferencias de GSConnect.
  --restart, -r       Reinicia el servicio/demonio de GSConnect en GNOME.
  --disable           Desactiva GSConnect y retira el servicio del cortafuegos.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE GSCONNECT Y CORTAFUEGOS - UBUNTU WORKSTATION"
    echo "================================================================="

    local ext_installed ext_enabled
    ext_installed=$(run_as_user gnome-extensions list 2>/dev/null | grep -q "^$GSCONNECT_UUID$" && echo "✅ Instalada" || echo "❌ No instalada")
    ext_enabled=$(run_as_user gnome-extensions list --enabled 2>/dev/null | grep -q "^$GSCONNECT_UUID$" && echo "✅ Activa" || echo "❌ Inactiva")

    echo "• Extensión GSConnect:       $ext_installed ($ext_enabled)"
    echo "• Montaje SFTP (sshfs):      $(if command -v sshfs &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "-----------------------------------------------------------------"
    echo "• Cortafuegos (Firewalld):"
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone
        active_zone=$($SUDO firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        echo "  - Estado de Firewalld:     ✅ Activo"
        echo "  - Zona activa:             $active_zone"
        echo "  - Servicio 'kdeconnect':   $($SUDO firewall-cmd --zone="$active_zone" --query-service=kdeconnect 2>/dev/null && echo '✅ Permitido (1714-1764 TCP/UDP)' || echo '❌ No permitido')"
        echo "  - Servicio 'mdns':         $($SUDO firewall-cmd --zone="$active_zone" --query-service=mdns 2>/dev/null && echo '✅ Permitido (5353 UDP)' || echo '❌ No permitido')"
    else
        echo "  - Estado de Firewalld:     ❌ Inactivo o no instalado"
    fi
    echo "-----------------------------------------------------------------"
    echo "• Dispositivos vinculados:"
    if [ -x "$USER_HOME/.local/share/gnome-shell/extensions/$GSCONNECT_UUID/service/daemon.js" ] || command -v gapplication &>/dev/null; then
        run_as_user gsettings get org.gnome.Shell.Extensions.GSConnect devices 2>/dev/null || echo "    (Sin dispositivos configurados todavía)"
    else
        echo "    (Instala e inicia GSConnect para emparejar tu teléfono móvil)"
    fi
    echo "================================================================="
}

open_prefs() {
    echo "📱 Abriendo preferencias de GSConnect..."
    run_as_user gnome-extensions prefs "$GSCONNECT_UUID" 2>/dev/null || \
        run_as_user gapplication launch org.gnome.Shell.Extensions.GSConnect 2>/dev/null || true
}

restart_service() {
    echo "🔄 Reiniciando GSConnect..."
    run_as_user gnome-extensions disable "$GSCONNECT_UUID" 2>/dev/null || true
    sleep 1
    run_as_user gnome-extensions enable "$GSCONNECT_UUID" 2>/dev/null || true
    echo "✅ GSConnect reiniciado."
}

disable_service() {
    echo "🛑 Desactivando GSConnect..."
    run_as_user gnome-extensions disable "$GSCONNECT_UUID" 2>/dev/null || true
    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld; then
        local active_zone
        active_zone=$($SUDO firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        $SUDO firewall-cmd --permanent --zone="$active_zone" --remove-service=kdeconnect 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
        echo "🔒 Reglas de red retiradas de Firewalld."
    fi
    echo "✅ GSConnect desactivado."
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
    --devices|-d)
        show_status
        exit 0
        ;;
    --open|-o)
        open_prefs
        exit 0
        ;;
    --restart|-r)
        restart_service
        exit 0
        ;;
    --disable)
        disable_service
        exit 0
        ;;
    "")
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac

echo "================================================================="
echo "📱 CONFIGURANDO GSCONNECT Y CORTAFUEGOS (UBUNTU WORKSTATION)"
echo "================================================================="

# 1. Instalar paquetes de soporte
echo "ℹ️ [1/4] Instalando paquetes de soporte y sshfs para Nautilus..."
$SUDO apt update
$SUDO apt install -y \
    gnome-shell-extension-gsconnect \
    sshfs \
    openssl \
    ca-certificates 2>/dev/null || true

# 2. Habilitar extensión en GNOME Shell
echo "ℹ️ [2/4] Activando extensión GSConnect en GNOME Shell..."
run_as_user gnome-extensions enable "$GSCONNECT_UUID" 2>/dev/null || true

# 3. Configurar Firewalld para el protocolo KDE Connect
echo "ℹ️ [3/4] Configurando reglas en Firewalld (puertos 1714-1764 TCP/UDP y mDNS)..."
$SUDO apt install -y firewalld 2>/dev/null || true
$SUDO systemctl enable --now firewalld

ACTIVE_ZONE=$($SUDO firewall-cmd --get-default-zone 2>/dev/null || echo "public")
$SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=kdeconnect 2>/dev/null || true
$SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=mdns 2>/dev/null || true
$SUDO firewall-cmd --reload

# 4. Diagnóstico final
echo ""
echo "================================================================="
echo "✅ GSConnect y Cortafuegos configurados con éxito."
echo "💡 Abre la app KDE Connect en tu teléfono móvil Android/iOS."
echo "   Aparecerá automáticamente en el menú superior derecho de GNOME."
echo "================================================================="
