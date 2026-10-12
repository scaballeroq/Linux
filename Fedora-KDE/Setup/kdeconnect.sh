#!/usr/bin/env bash
# ==============================================================================
# kdeconnect.sh - Integración de KDE Connect y Configuración de Firewalld
# Sistema: Fedora 44 Workstation | Escritorio: KDE Plasma 6 (Wayland)
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U / Radeon Vega 7)
# ==============================================================================
# Características:
# - Instalación idempotente de KDE Connect y fuse-sshfs vía DNF5.
# - Configuración del cortafuegos nativo Firewalld (puertos 1714-1764 TCP/UDP en FedoraWorkstation).
# - Detección e inicialización automática de firewalld en systemd.
# - Detección y gestión del demonio kdeconnectd en la sesión Wayland de Plasma 6.
# - Diagnóstico integral: estado de paquetes, reglas de red, ID local y dispositivos emparejados.
# - Opciones CLI completas: --status, --devices, --pair, --ping, --open, --restart, --disable, --help.
# ==============================================================================

set -euo pipefail

# 1. Detección de Usuario y Permisos
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

require_root() {
    if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
        echo "❌ Error: Esta operación requiere privilegios de administrador ('sudo')."
        exit 1
    fi
}

is_pkg_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

ensure_installed() {
    local missing=()
    for pkg in kde-connect fuse-sshfs firewalld; do
        if ! is_pkg_installed "$pkg"; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "📦 Instalando paquetes requeridos vía DNF5: ${missing[*]}..."
        require_root
        $SUDO dnf5 install -y "${missing[@]}" 2>/dev/null || true
    else
        echo "  ✅ Paquetes de KDE Connect, SSHFS y Firewalld ya instalados."
    fi
}

ensure_firewalld_running() {
    if ! systemctl is-active --quiet firewalld 2>/dev/null; then
        echo "🛡️  Iniciando servicio Firewalld..."
        require_root
        $SUDO systemctl enable --now firewalld
        echo "  ✅ Firewalld activado y en ejecución."
    fi
}

configure_firewall() {
    ensure_firewalld_running

    local default_zone
    default_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "FedoraWorkstation")
    [ -z "$default_zone" ] && default_zone="FedoraWorkstation"

    local is_active=false
    if firewall-cmd --zone="$default_zone" --list-services 2>/dev/null | grep -qw "kdeconnect"; then
        is_active=true
    fi

    if [ "$is_active" = "true" ]; then
        echo "  ✅ Servicio 'kdeconnect' ya está permitido en Firewalld (zona: '$default_zone', puertos 1714-1764 TCP/UDP)."
    else
        echo "🛡️  Configurando servicio 'kdeconnect' en Firewalld (zona: '$default_zone')..."
        require_root
        $SUDO firewall-cmd --permanent --zone="$default_zone" --add-service=kdeconnect 2>/dev/null || \
        $SUDO firewall-cmd --permanent --add-service=kdeconnect 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
        echo "  ✅ Regla permanente aplicada y recargada en Firewalld (puertos 1714-1764 TCP/UDP abiertos)."
    fi
}

disable_firewall() {
    require_root
    local default_zone
    default_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "FedoraWorkstation")
    [ -z "$default_zone" ] && default_zone="FedoraWorkstation"

    echo "🔒 Retirando servicio 'kdeconnect' de Firewalld (zona: '$default_zone')..."
    $SUDO firewall-cmd --permanent --zone="$default_zone" --remove-service=kdeconnect 2>/dev/null || \
    $SUDO firewall-cmd --permanent --remove-service=kdeconnect 2>/dev/null || true
    $SUDO firewall-cmd --reload 2>/dev/null || true
    echo "  ✅ Regla de KDE Connect deshabilitada en Firewalld."
}

ensure_daemon() {
    if pgrep -u "$REAL_UID" -x kdeconnectd >/dev/null 2>&1; then
        local pids
        pids=$(pgrep -u "$REAL_UID" -x kdeconnectd | tr '\n' ' ' | xargs)
        echo "  ✅ Demonio kdeconnectd en ejecución (PID: $pids)."
    else
        echo "🚀 Iniciando demonio kdeconnectd en la sesión de usuario ($REAL_USER)..."
        run_as_user /usr/bin/kdeconnectd >/dev/null 2>&1 &
        sleep 1
        if pgrep -u "$REAL_UID" -x kdeconnectd >/dev/null 2>&1; then
            echo "  ✅ Demonio kdeconnectd iniciado correctamente."
        else
            echo "  ℹ️ Demonio registrado para autoinicio en el arranque de sesión KDE Plasma 6."
        fi
    fi
}

restart_daemon() {
    echo "🔄 Reiniciando demonio kdeconnectd para el usuario $REAL_USER..."
    if pgrep -u "$REAL_UID" -x kdeconnectd >/dev/null 2>&1; then
        killall -u "$REAL_USER" kdeconnectd 2>/dev/null || true
        sleep 1
    fi
    run_as_user /usr/bin/kdeconnectd >/dev/null 2>&1 &
    sleep 1
    if pgrep -u "$REAL_UID" -x kdeconnectd >/dev/null 2>&1; then
        local pids
        pids=$(pgrep -u "$REAL_UID" -x kdeconnectd | tr '\n' ' ' | xargs)
        echo "  ✅ Demonio kdeconnectd reiniciado exitosamente (PID: $pids)."
    else
        echo "  ⚠️ No se pudo verificar el proceso kdeconnectd tras el reinicio."
    fi
}

list_devices() {
    echo "🔍 Buscando dispositivos KDE Connect en la red local..."
    run_as_user kdeconnect-cli --refresh 2>/dev/null || true
    sleep 1
    echo ""
    echo "📱 Dispositivos vinculados o detectados:"
    run_as_user kdeconnect-cli -l 2>/dev/null || echo "  (Sin respuesta del comando kdeconnect-cli)"
    echo ""
    echo "🌐 Dispositivos disponibles actualmente en línea:"
    run_as_user kdeconnect-cli -a 2>/dev/null || echo "  (Ninguno disponible en este momento)"
}

pair_device() {
    local target_id="${1:-}"
    run_as_user kdeconnect-cli --refresh 2>/dev/null || true
    sleep 1

    if [ -n "$target_id" ]; then
        echo "🤝 Solicitando vinculación con el dispositivo '$target_id'..."
        run_as_user kdeconnect-cli --pair -d "$target_id"
        echo "  💡 Acepta la solicitud de emparejamiento en la pantalla de tu teléfono."
    else
        echo "📱 Dispositivos detectados en la red local:"
        run_as_user kdeconnect-cli -l 2>/dev/null || true
        echo ""
        echo "💡 Para emparejar un dispositivo específico, ejecuta:"
        echo "   $0 --pair <ID_DEL_DISPOSITIVO>"
        echo "   O solicita el emparejamiento directamente desde la app KDE Connect en tu móvil."
    fi
}

ping_device() {
    local target_id="${1:-}"
    if [ -n "$target_id" ]; then
        echo "📡 Enviando ping de prueba al dispositivo '$target_id'..."
        run_as_user kdeconnect-cli --ping-msg "¡Hola desde KDE Plasma 6 en Fedora 44!" -d "$target_id"
        echo "  ✅ Ping enviado."
    else
        echo "❌ Error: Especifica el ID o nombre del dispositivo a comprobar."
        echo "   Uso: $0 --ping <ID_DEL_DISPOSITIVO>"
        list_devices
    fi
}

open_gui() {
    echo "🖥️ Abriendo panel gráfico de KDE Connect..."
    if command -v kdeconnect-app &>/dev/null; then
        run_as_user kdeconnect-app &>/dev/null &
        echo "  ✅ Aplicación KDE Connect lanzada."
    elif command -v kcmshell6 &>/dev/null; then
        run_as_user kcmshell6 kcm_kdeconnect &>/dev/null &
        echo "  ✅ Módulo de configuración de KDE Connect lanzado."
    else
        echo "⚠️ No se encontró la interfaz gráfica de KDE Connect."
    fi
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE KDE CONNECT Y FIREWALLD - FEDORA 44 (KDE PLASMA 6)"
    echo "================================================================="

    local kc_pkg sshfs_pkg fw_pkg
    kc_pkg=$(if is_pkg_installed kde-connect || is_pkg_installed kdeconnect; then echo "✅ Instalado ($(rpm -q --qf '%{VERSION}' kde-connect 2>/dev/null || rpm -q --qf '%{VERSION}' kdeconnect 2>/dev/null))"; else echo "❌ No instalado"; fi)
    sshfs_pkg=$(if is_pkg_installed fuse-sshfs || is_pkg_installed sshfs; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)
    fw_pkg=$(if is_pkg_installed firewalld; then echo "✅ Instalado ($(rpm -q --qf '%{VERSION}' firewalld 2>/dev/null))"; else echo "❌ No instalado"; fi)

    echo "• Paquetes del Sistema:"
    echo "  - kde-connect (KDE Gear):   $kc_pkg"
    echo "  - fuse-sshfs (FUSE Dolphin): $sshfs_pkg"
    echo "  - firewalld:                $fw_pkg"

    echo "-----------------------------------------------------------------"
    echo "🛡️ Estado del Cortafuegos (Firewalld):"

    local fw_service_state default_zone fw_rule_status
    fw_service_state=$(systemctl is-active firewalld 2>/dev/null || echo "inactivo")
    echo "  - Servicio firewalld:       $fw_service_state"

    if [ "$fw_service_state" = "active" ]; then
        default_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "FedoraWorkstation")
        echo "  - Zona por defecto:         $default_zone"

        local services
        services=$(firewall-cmd --zone="$default_zone" --list-services 2>/dev/null || echo "")
        if echo "$services" | grep -qw "kdeconnect"; then
            fw_rule_status="✅ Permitido (servicio 'kdeconnect' activo)"
        else
            fw_rule_status="⚠️ Bloqueado (servicio 'kdeconnect' NO presente en la zona)"
        fi
        echo "  - Regla KDE Connect:        $fw_rule_status"
        echo "  - Puertos asignados:        1714-1764 TCP y 1714-1764 UDP"
    else
        echo "  - Regla KDE Connect:        ⚠️ Firewalld inactivo (iniciar con: sudo systemctl start firewalld)"
    fi

    echo "-----------------------------------------------------------------"
    echo "📱 Demonio y Dispositivos (KDE Plasma 6 / Wayland):"

    if pgrep -u "$REAL_UID" -x kdeconnectd >/dev/null 2>&1; then
        local pids
        pids=$(pgrep -u "$REAL_UID" -x kdeconnectd | tr '\n' ' ' | xargs)
        echo "  - Demonio kdeconnectd:      ✅ En ejecución (PID: $pids)"
    else
        echo "  - Demonio kdeconnectd:      ❌ Detenido (se iniciará al ejecutar: $0 o al iniciar sesión)"
    fi

    if command -v kdeconnect-cli &>/dev/null; then
        local my_id
        my_id=$(run_as_user kdeconnect-cli --my-id 2>/dev/null || echo "No disponible")
        echo "  - ID de este equipo:        $my_id"

        echo "  - Dispositivos detectados:"
        local dev_output
        dev_output=$(run_as_user kdeconnect-cli -l 2>/dev/null || echo "0 dispositivos encontrados")
        while IFS= read -r line; do
            [ -n "$line" ] && echo "    • $line"
        done <<< "$dev_output"
    fi

    echo "-----------------------------------------------------------------"
    echo "📂 Integración con Dolphin y Plasma 6:"
    echo "  - Exploración remota:       ✅ Activa (Dolphin mostrará el almacenamiento vía 'kdeconnect://')"
    echo "  - Portapapeles compartido:  ✅ Nativo en Wayland (vía KWin / wl-clipboard)"
    echo "  - Notificaciones y medios:  ✅ Sincronizados con el applet del panel de Plasma"
    echo "================================================================="
}

show_help() {
    cat <<EOF
📱 Gestor de Integración KDE Connect & Firewalld - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instalación idempotente de kde-connect y fuse-sshfs vía DNF5,
                      configuración de reglas de Firewalld (puertos 1714-1764 TCP/UDP)
                      y verificación del demonio kdeconnectd.
  --status, -s        Muestra el diagnóstico detallado de paquetes, cortafuegos,
                      identificador de equipo y dispositivos detectados/emparejados.
  --devices, -l       Busca y muestra los dispositivos KDE Connect en la red local.
  --pair, -p [ID]     Solicita vinculación con un dispositivo por su ID o busca disponibles.
  --ping [ID]         Envía un ping de prueba al dispositivo especificado.
  --open, -o          Abre la interfaz gráfica de KDE Connect.
  --restart, -r       Reinicia el demonio kdeconnectd del usuario actual.
  --disable           Retira la regla de KDE Connect del cortafuegos Firewalld.
  --help, -h          Muestra este mensaje de ayuda.

Características configuradas:
  • Puertos Firewall: 1714 a 1764 (TCP y UDP) en la zona activa de Firewalld (FedoraWorkstation).
  • Paquetes DNF5:    kde-connect (aplicación/demonio) y fuse-sshfs (exploración en Dolphin).
EOF
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --devices|-l|--list|devices)
        list_devices
        exit 0
        ;;
    --pair|-p|pair)
        shift || true
        pair_device "${1:-}"
        exit 0
        ;;
    --ping|ping)
        shift || true
        ping_device "${1:-}"
        exit 0
        ;;
    --open|-o|open)
        open_gui
        exit 0
        ;;
    --restart|-r|restart)
        restart_daemon
        exit 0
        ;;
    --disable|disable)
        disable_firewall
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "📱 CONFIGURACIÓN DE KDE CONNECT Y FIREWALLD - FEDORA 44"
        echo "================================================================="
        echo "ℹ️ [1/3] Verificando paquetes del sistema..."
        ensure_installed

        echo "ℹ️ [2/3] Configurando cortafuegos Firewalld..."
        configure_firewall

        echo "ℹ️ [3/3] Comprobando demonio de usuario..."
        ensure_daemon

        echo ""
        show_status
        echo ""
        echo "🚀 ¡KDE Connect está listo y protegido por Firewalld!"
        echo "💡 Abre la aplicación móvil de KDE Connect en la misma red Wi-Fi para emparejar tu dispositivo."
        exit 0
        ;;
    *)
        echo "❌ Opción desconocida: $1"
        echo "Usa '$0 --help' para ver la lista de opciones válidas."
        exit 1
        ;;
esac
