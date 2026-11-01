#!/usr/bin/env bash
# ==============================================================================
# hp-printer-setup.sh - Gestor y Configurador de Impresoras HP (HPLIP / CUPS)
# Sistema: Soplos Linux Boro | Entorno: GNOME Shell (Wayland nativo)
# Compatibilidad: HP LaserJet Pro M15w / M15a / M14-M17 series y multifunciones HP
# Red & Seguridad: Firewalld (mDNS, IPP, SLP, SNMP, JetDirect)
# ==============================================================================
# Características:
#   - Instalación idempotente vía APT: CUPS, HPLIP, librerías Python y helper PolicyKit.
#   - Contexto de usuario limpio (run_as_user): asistentes HPLIP ejecutados bajo el usuario
#     real con variables Wayland y D-Bus correctas, evitando polución en /root.
#   - Detección y coexistencia con ipp-usb (evita bloqueos de descriptor USB en M15w).
#   - Reglas completas de Firewalld para descubrimiento LAN (mDNS, SLP, SNMP, IPP, JetDirect).
#   - Soporte para sockets y servicios bajo demanda en systemd (cups.socket / cups.service).
#   - Opciones CLI: --status, --wifi, --usb, --plugin, --gui, --test, --check, --help.
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

require_root() {
    if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
        echo "❌ Error: Esta operación requiere privilegios de administrador ('sudo')."
        exit 1
    fi
}

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

CORE_PACKAGES=(
    "cups"
    "cups-client"
    "cups-filters"
    "cups-pk-helper"
    "hplip"
    "hplip-gui"
    "printer-driver-hpcups"
    "python3-notify2"
    "python3-pyqt5"
    "snmp"
    "libsane-hpaio"
    "avahi-daemon"
    "system-config-printer"
)

show_help() {
    cat <<EOF
🖨️ Gestor de Impresión HP - Soplos Linux Boro Workstation (GNOME Shell Wayland)
Optimizado para HP LaserJet Pro M15w / M15a y ecosistema HPLIP + CUPS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala dependencias de forma idempotente, habilita servicios y
                         guía la configuración inicial del sistema.
  --status, -s           Diagnóstico completo de CUPS, Avahi, ipp-usb, Firewalld, puertos y colas.
  --plugin               Descarga e instala el plugin propietario oficial de HP (firmware M15w).
  --wifi, --net          Inicia la detección y configuración de impresora por Wi-Fi / Red local.
  --usb                  Inicia la configuración de impresora HP por conexión directa USB.
  --gui, -g              Abre el panel gráfico de impresoras en GNOME (Configuración / system-config-printer).
  --test, -t             Envía un trabajo de página de prueba a la impresora predeterminada.
  --check, -c            Ejecuta el chequeo de salud oficial de HPLIP (hp-check -t).
  --help, -h             Muestra este mensaje de ayuda.

Modelos optimizados:
  • HP LaserJet Pro M15w / M15a (requieren plugin de firmware hp-plugin)
  • Series HP LaserJet Pro M14 / M17 / P1102w / 1020
  • Impresoras multifunción HP DeskJet, Envy, OfficeJet y PageWide
EOF
}

is_plugin_installed() {
    if [ -d "/usr/share/hplip/data/plugins" ] && [ -f "/usr/share/hplip/data/plugins/license.txt" ]; then
        return 0
    elif [ -f "/var/lib/hp/hplip.state" ] && grep -qi "installed=1" "/var/lib/hp/hplip.state" 2>/dev/null; then
        return 0
    fi
    return 1
}

show_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DE IMPRESIÓN HP - SOPLOS LINUX BORO WORKSTATION"
    echo "================================================================="
    echo "• Usuario objetivo:            $REAL_USER (UID: $REAL_UID)"
    echo "• Grupos de impresión:         $(groups "$REAL_USER" 2>/dev/null | grep -E -o '(lp|lpadmin)' | tr '\n' ' ' || echo '❌ Ninguno')"
    echo "-----------------------------------------------------------------"
    echo "• Servicios del Sistema (systemd):"

    local cups_status="❌ Inactivo"
    if systemctl is-active --quiet cups.service 2>/dev/null; then
        cups_status="✅ Activo (cups.service)"
    elif systemctl is-active --quiet cups.socket 2>/dev/null; then
        cups_status="✅ Activo bajo demanda (cups.socket)"
    fi
    echo "  - Servicio CUPS:             $cups_status"

    local avahi_status="❌ Inactivo"
    if systemctl is-active --quiet avahi-daemon.service 2>/dev/null; then
        avahi_status="✅ Activo (mDNS LAN)"
    fi
    echo "  - Servicio Avahi (mDNS):     $avahi_status"

    local ipp_usb_status="ℹ️ No activo / no instalado"
    if systemctl is-active --quiet ipp-usb.service 2>/dev/null; then
        ipp_usb_status="⚠️ Activo (ipp-usb puede capturar el USB antes que HPLIP)"
    fi
    echo "  - Daemon ipp-usb:            $ipp_usb_status"

    echo "-----------------------------------------------------------------"
    echo "• Cortafuegos (Firewalld):"
    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        local allowed_services
        allowed_services=$(firewall-cmd --zone="$active_zone" --list-services 2>/dev/null || echo "")
        echo "  - Estado de Firewalld:       ✅ Activo (Zona: $active_zone)"
        for srv in mdns ipp ipp-client slp snmp; do
            if echo "$allowed_services" | grep -qw "$srv"; then
                printf "    * Servicio %-15s ✅ Permitido\n" "$srv"
            else
                printf "    * Servicio %-15s ⚠️ No habilitado\n" "$srv"
            fi
        done
        if firewall-cmd --zone="$active_zone" --list-ports 2>/dev/null | grep -qw "9100/tcp" || echo "$allowed_services" | grep -qw "jetdirect"; then
            printf "    * Puerto JetDirect (9100)  ✅ Permitido\n"
        else
            printf "    * Puerto JetDirect (9100)  ⚠️ No habilitado\n"
        fi
    else
        echo "  - Estado de Firewalld:       ℹ️ Inactivo o no gestionado"
    fi

    echo "-----------------------------------------------------------------"
    echo "• Paquetes esenciales instalados en Soplos Linux Boro:"
    for pkg in "${CORE_PACKAGES[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            printf "  - %-25s ✅ Instalado\n" "$pkg"
        else
            printf "  - %-25s ❌ No instalado\n" "$pkg"
        fi
    done

    echo "-----------------------------------------------------------------"
    echo "• Plugin propietario de firmware HP (requerido para LaserJet M15w):"
    if is_plugin_installed; then
        echo "  - Estado del Plugin:         ✅ Instalado correctamente"
    else
        echo "  - Estado del Plugin:         ⚠️ No detectado (ejecuta '$0 --plugin' para instalarlo)"
    fi

    echo "-----------------------------------------------------------------"
    echo "• Dispositivos HP detectados por USB:"
    if command -v lsusb &>/dev/null; then
        local hp_usb
        hp_usb=$(lsusb | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17|print" || true)
        if [ -n "$hp_usb" ]; then
            echo "$hp_usb" | sed 's/^/    /'
        else
            echo "    (Ninguna impresora HP detectada en puertos USB)"
        fi
    else
        echo "    (lsusb no disponible)"
    fi

    echo "-----------------------------------------------------------------"
    echo "• Colas de impresión activas en CUPS:"
    if command -v lpstat &>/dev/null; then
        lpstat -p -d 2>/dev/null || echo "    (No hay colas de impresión configuradas actualmente)"
    else
        echo "    (lpstat no disponible)"
    fi

    echo "================================================================="
    echo "💡 Puedes administrar las impresoras visualmente desde GNOME en:"
    echo "   'Configuración del Sistema -> Impresoras' o ejecutando '$0 --gui'"
    echo "================================================================="
}

install_plugin() {
    echo "⬇️ Iniciando instalador del plugin propietario oficial de HP..."
    if ! command -v hp-plugin &>/dev/null; then
        echo "❌ Error: 'hp-plugin' no está disponible. Ejecuta primero '$0' sin argumentos."
        exit 1
    fi

    echo "ℹ️ Ejecutando 'hp-plugin -i' en contexto del usuario '$REAL_USER'..."
    run_as_user hp-plugin -i
}

setup_wifi() {
    echo "📶 Buscando e instalando impresora HP en la red local (Wi-Fi / LAN)..."
    if ! command -v hp-setup &>/dev/null; then
        echo "❌ Error: 'hp-setup' no está disponible. Ejecuta primero '$0' sin argumentos."
        exit 1
    fi

    if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
        echo "▶️ Lanzando asistente interactivo de red..."
        run_as_user hp-setup -b net
    else
        echo "▶️ Lanzando asistente en terminal (modo texto)..."
        run_as_user hp-setup -i -b net
    fi
}

setup_usb() {
    echo "🔌 Configurando impresora HP por conexión USB directa..."
    if ! command -v hp-setup &>/dev/null; then
        echo "❌ Error: 'hp-setup' no está disponible. Ejecuta primero '$0' sin argumentos."
        exit 1
    fi

    if systemctl is-active --quiet ipp-usb.service 2>/dev/null; then
        echo "⚠️ Nota: 'ipp-usb' está activo. Si el asistente no encuentra la impresora,"
        echo "   es posible que ipp-usb haya reservado el puerto USB. En ese caso,"
        echo "   puedes detener temporalmente ipp-usb con: 'sudo systemctl stop ipp-usb'."
    fi

    if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
        echo "▶️ Lanzando asistente de configuración USB..."
        run_as_user hp-setup -b usb
    else
        echo "▶️ Lanzando asistente en terminal (modo texto)..."
        run_as_user hp-setup -i -b usb
    fi
}

open_gui() {
    echo "🖥️ Abriendo panel gráfico de impresoras en GNOME Shell..."
    if command -v gnome-control-center &>/dev/null; then
        run_as_user gnome-control-center printers &>/dev/null &
        echo "✅ Panel de Impresoras de GNOME abierto."
    elif command -v system-config-printer &>/dev/null; then
        run_as_user system-config-printer &>/dev/null &
        echo "✅ system-config-printer abierto."
    else
        echo "❌ No se encontró ninguna utilidad gráfica de impresoras instalada."
        exit 1
    fi
}

test_print() {
    echo "📄 Enviando página de prueba a la impresora predeterminada..."
    if ! command -v lp &>/dev/null; then
        echo "❌ Error: 'lp' no está disponible. CUPS no está instalado."
        exit 1
    fi

    local default_dest
    default_dest=$(lpstat -d 2>/dev/null | awk -F': ' '{print $2}' || true)
    if [ -z "$default_dest" ] || [ "$default_dest" = "no system default destination" ]; then
        echo "❌ Error: No hay ninguna impresora configurada como predeterminada."
        echo "💡 Usa '$0 --wifi' o '$0 --usb' para añadir una impresora."
        exit 1
    fi

    echo "• Impresora destino: $default_dest"
    local test_page="/usr/share/cups/data/testprint"
    if [ -f "$test_page" ]; then
        run_as_user lp -d "$default_dest" "$test_page"
        echo "✅ Página de prueba de CUPS enviada a '$default_dest'."
    else
        echo -e "Prueba de impresion exitosa desde Soplos Linux Boro Workstation\nFecha: $(date)\nUsuario: $REAL_USER\nHost: $(hostname)" | run_as_user lp -d "$default_dest"
        echo "✅ Documento de prueba enviado a '$default_dest'."
    fi
}

check_hplip() {
    echo "🩺 Ejecutando diagnóstico de salud oficial de HPLIP (hp-check -t)..."
    if command -v hp-check &>/dev/null; then
        run_as_user hp-check -t || true
    else
        echo "❌ Error: 'hp-check' no está disponible. Ejecuta primero '$0' sin argumentos."
        exit 1
    fi
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
    --plugin)
        install_plugin
        exit 0
        ;;
    --wifi|--net)
        setup_wifi
        exit 0
        ;;
    --usb)
        setup_usb
        exit 0
        ;;
    --gui|-g)
        open_gui
        exit 0
        ;;
    --test|-t)
        test_print
        exit 0
        ;;
    --check|-c)
        check_hplip
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

# =============================================================================
# APROVISIONAMIENTO Y CONFIGURACIÓN DEL SISTEMA
# =============================================================================
echo "================================================================="
echo "🖨️ CONFIGURACIÓN DE IMPRESIÓN HP - SOPLOS LINUX BORO WORKSTATION"
echo "================================================================="

require_root

# 1. Comprobar e instalar paquetes faltantes de forma idempotente
MISSING_PKGS=()
for pkg in "${CORE_PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "ℹ️ [1/5] Instalando ${#MISSING_PKGS[@]} paquete(s) de impresión faltante(s) vía APT..."
    $SUDO apt-get update -qq
    $SUDO apt-get install -y "${MISSING_PKGS[@]}"
else
    echo "ℹ️ [1/5] Todos los paquetes de CUPS, Avahi y HPLIP ya se encuentran instalados."
fi

# 2. Habilitar y arrancar sockets y servicios de systemd
echo "ℹ️ [2/5] Habilitando sockets y servicios de impresión en systemd..."
$SUDO systemctl enable --now cups.socket 2>/dev/null || true
$SUDO systemctl enable --now cups.service 2>/dev/null || true
$SUDO systemctl enable --now avahi-daemon.service 2>/dev/null || true

# 3. Asegurar pertenencia del usuario a grupos lp y lpadmin
echo "ℹ️ [3/5] Asegurando permisos de usuario '$REAL_USER' en grupos 'lp' y 'lpadmin'..."
$SUDO usermod -aG lp,lpadmin "$REAL_USER"

# 4. Configurar reglas completas en Firewalld (mDNS, IPP, SLP, SNMP, JetDirect)
if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
    echo "ℹ️ [4/5] Configurando reglas de cortafuegos en Firewalld para descubrimiento y colas HP..."
    ACTIVE_ZONE=$($SUDO firewall-cmd --get-default-zone 2>/dev/null || echo "public")
    
    SERVICES_TO_ADD=("mdns" "ipp" "ipp-client" "slp" "snmp")
    for srv in "${SERVICES_TO_ADD[@]}"; do
        if $SUDO firewall-cmd --get-services 2>/dev/null | grep -qw "$srv"; then
            $SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service="$srv" &>/dev/null || true
        fi
    done
    
    # Puerto JetDirect (RAW 9100 TCP)
    if $SUDO firewall-cmd --get-services 2>/dev/null | grep -qw "jetdirect"; then
        $SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=jetdirect &>/dev/null || true
    else
        $SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-port=9100/tcp &>/dev/null || true
    fi
    
    $SUDO firewall-cmd --reload &>/dev/null || true
    echo "✅ Reglas de Firewalld aplicadas y recargadas en zona '$ACTIVE_ZONE'."
else
    echo "ℹ️ [4/5] Firewalld no está activo; omitiendo configuración de red."
fi

# 5. Comprobar e instalar el plugin propietario oficial de HP
echo "ℹ️ [5/5] Comprobando plugin de firmware requerido (HP LaserJet M15w / series afines)..."
if is_plugin_installed; then
    echo "✅ Plugin propietario oficial de HP ya instalado y operativo."
else
    echo "💡 El plugin de firmware no está instalado. Se iniciará el asistente 'hp-plugin'..."
    if command -v hp-plugin &>/dev/null; then
        run_as_user hp-plugin -i || echo "⚠️ Puedes ejecutar '$0 --plugin' en cualquier momento si decides posponerlo."
    fi
fi

echo ""
echo "================================================================="
echo "✅ Entorno de impresión HP configurado con éxito en Soplos Linux Boro."
echo "💡 Siguientes pasos recomendados para vincular tu impresora:"
echo "   • Configurar por Wi-Fi / Red:   $0 --wifi"
echo "   • Configurar por cable USB:     $0 --usb"
echo "   • Ver estado y diagnóstico:     $0 --status"
echo "   • Abrir panel visual en GNOME:  $0 --gui"
echo "================================================================="
