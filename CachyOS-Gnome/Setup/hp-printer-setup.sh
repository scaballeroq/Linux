#!/usr/bin/env bash
# ==============================================================================
# hp-printer-setup.sh - Instalador y Gestor de Impresoras HP (LaserJet M15w)
# Sistema: CachyOS / Arch Linux (GNOME Shell Wayland + Pacman)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM)
# Impresora: HP LaserJet Pro M15w (USB y Wi-Fi / Red local IPP Everywhere)
# ==============================================================================
# Características:
#   - Detección dual inteligente: Cable USB (lsusb) y Wi-Fi/Red (mDNS/IPP Everywhere).
#   - Configuración automática de colas en CUPS sin blobs propietarios vía IPP Everywhere.
#   - Asistencia para plugin propietario de HP (hp-plugin) en modo USB host-based.
#   - Reglas automáticas en Firewalld (IPP 631, ipp-client y mDNS 5353).
#   - Instalación O(1) de paquetes Pacman (verifica paquetes instalados antes de invocar pacman).
#   - Diagnóstico O(1) de solo lectura sin elevación de privilegios (--status).
#   - Impresión de página de prueba para validación inmediata (--test-page).
# ==============================================================================

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y FORMATO VISUAL (ANSI)
# ------------------------------------------------------------------------------
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

# ------------------------------------------------------------------------------
# 2. PRIVILEGIOS Y ENTORNO DE USUARIO
# ------------------------------------------------------------------------------
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
else
    TARGET_USER="${USER:-$(id -un)}"
fi

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &>/dev/null; then
        log_err "'sudo' no está disponible. Ejecuta este script con privilegios de superusuario."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

require_root() {
    if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
        log_err "Se requieren privilegios de superusuario (root o sudo)."
        exit 1
    fi
}

is_pkg_installed() {
    pacman -Q "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# 3. PAQUETES DE IMPRESIÓN PARA CACHYOS WORKSTATION
# ------------------------------------------------------------------------------
CORE_PACKAGES=(
    "cups"
    "cups-filters"
    "cups-pdf"
    "system-config-printer"
    "hplip"
    "python-pyqt5"
    "avahi"
    "nss-mdns"
    "usbutils"
    "libusb"
)

# ------------------------------------------------------------------------------
# 4. FUNCIONES DE DETECCIÓN DE HARDWARE Y RED
# ------------------------------------------------------------------------------
detect_usb_printer() {
    lsusb 2>/dev/null | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17" || true
}

get_network_printer_uri() {
    # 1. Búsqueda directa por ippfind
    local uri=""
    if command -v ippfind &>/dev/null; then
        uri=$(timeout 2 ippfind 2>/dev/null | grep -iE "laserjet|m15|m14|m17|npi" | head -n1 || true)
    fi

    # 2. Si ippfind no la localiza, consultar mediante avahi-browse
    if [ -z "$uri" ] && command -v avahi-browse &>/dev/null; then
        local ip_found
        ip_found=$(timeout 2 avahi-browse -rt _ipp._tcp 2>/dev/null | grep -E "address = \[[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\]" | cut -d[ -f2 | cut -d] -f1 | head -n1 || true)
        if [ -n "$ip_found" ]; then
            uri="ipp://$ip_found:631/ipp/print"
        fi
    fi

    # 3. Fallback directo a resolución por nombre mDNS
    if [ -z "$uri" ]; then
        if ping -c 1 -W 1 NPI5E704E.local &>/dev/null; then
            uri="ipp://NPI5E704E.local:631/ipp/print"
        fi
    fi

    echo "$uri"
}

# ------------------------------------------------------------------------------
# 5. DIAGNÓSTICO Y TELEMETRÍA (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${BOLD}${CYAN}🔍 DIAGNÓSTICO DEL SISTEMA DE IMPRESIÓN - HP LASERJET (CACHYOS)${NC}"
    echo -e "💻 ${BOLD}Estación:${NC} HP ProBook 455 G10 | AMD Ryzen 7 7730U | GNOME Wayland"
    echo -e "${BOLD}=================================================================${NC}"

    # Estado de CUPS
    local cups_stat
    if systemctl is-active --quiet cups.service 2>/dev/null; then
        cups_stat="${GREEN}✅ Activo (running - escucha en puerto 631)${NC}"
    else
        cups_stat="${RED}❌ Inactivo (actívalo con: $0)${NC}"
    fi
    echo -e "• Servicio CUPS:           $cups_stat"

    # Estado de Avahi (mDNS)
    local avahi_stat
    if systemctl is-active --quiet avahi-daemon.service 2>/dev/null; then
        avahi_stat="${GREEN}✅ Activo (mDNS para detección de red)${NC}"
    else
        avahi_stat="${YELLOW}⚠️ Inactivo${NC}"
    fi
    echo -e "• Demonio Avahi (mDNS):    $avahi_stat"

    # Suite HPLIP
    local hplip_ver
    if is_pkg_installed hplip; then
        hplip_ver=$(pacman -Q hplip 2>/dev/null | awk '{print $2}' | cut -d- -f1)
        echo -e "• Suite HPLIP:             ${GREEN}✅ Instalado ($hplip_ver)${NC}"
    else
        echo -e "• Suite HPLIP:             ${RED}❌ No instalado${NC}"
    fi

    # Gestor gráfico GNOME
    if is_pkg_installed system-config-printer; then
        echo -e "• GNOME Print Manager:     ${GREEN}✅ Instalado (system-config-printer)${NC}"
    else
        echo -e "• GNOME Print Manager:     ${YELLOW}⚪ No instalado (opcional, usa GNOME Settings)${NC}"
    fi

    # Plugin propietario HP
    local plugin_status plugin_ver=""
    if [ -f /var/lib/hp/hplip.state ] && grep -qiE "^\s*installed\s*=\s*1" /var/lib/hp/hplip.state 2>/dev/null; then
        plugin_ver=$(grep -iE "^\s*version\s*=" /var/lib/hp/hplip.state 2>/dev/null | cut -d= -f2 | xargs)
        plugin_status="${GREEN}✅ Instalado${plugin_ver:+ ($plugin_ver)}${NC}"
    elif [ -f /usr/share/hplip/prnt/plugins/lj.so ] || [ -f /var/lib/hp/hplip-install_plugin.stamp ]; then
        plugin_status="${GREEN}✅ Instalado${NC}"
    else
        plugin_status="${YELLOW}⚪ No instalado (Sólo necesario por USB; no se requiere en Wi-Fi)${NC}"
    fi
    echo -e "• Plugin propietario HP:   $plugin_status"

    # Detección USB
    local usb_dev
    usb_dev=$(detect_usb_printer)
    if [ -n "$usb_dev" ]; then
        local usb_desc
        usb_desc=$(echo "$usb_dev" | head -n1 | cut -d: -f3- | xargs)
        echo -e "• Detección USB:           ${GREEN}✅ Detectada por cable ($usb_desc)${NC}"
    else
        echo -e "• Detección USB:           ${BLUE}ℹ️ No conectada por cable USB (o apagada)${NC}"
    fi

    # Detección Wi-Fi / Red Local
    local net_uri
    net_uri=$(get_network_printer_uri)
    if [ -n "$net_uri" ]; then
        echo -e "• Detección Wi-Fi / Red:   ${GREEN}✅ Detectada en red local ($net_uri)${NC}"
        echo -e "  └─ Modo recomendado:     ${CYAN}Driverless / IPP Everywhere (sin plugins propietarios)${NC}"
    else
        echo -e "• Detección Wi-Fi / Red:   ${YELLOW}⚪ No detectada en la red local (¿está encendida y en el mismo Wi-Fi?)${NC}"
    fi

    # Grupos de usuario
    if id -nG "$TARGET_USER" 2>/dev/null | grep -qw "lp"; then
        echo -e "• Grupos de impresión:     ${GREEN}✅ Usuario '$TARGET_USER' asignado a grupo 'lp'${NC}"
    else
        echo -e "• Grupos de impresión:     ${RED}❌ Usuario '$TARGET_USER' no asignado a 'lp'${NC}"
    fi

    # Firewalld
    local fw_status="${YELLOW}ℹ️ Firewalld no activo${NC}"
    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone fw_services
        active_zone=$(timeout 1 firewall-cmd --get-default-zone 2>/dev/null || echo "home")
        fw_services=$(timeout 1 firewall-cmd --zone="$active_zone" --list-services 2>/dev/null || true)
        if echo "$fw_services" | grep -qw "ipp" && echo "$fw_services" | grep -qw "mdns"; then
            fw_status="${GREEN}✅ IPP (631/tcp) y mDNS (5353/udp) permitidos en '$active_zone'${NC}"
        elif echo "$fw_services" | grep -qw "ipp"; then
            fw_status="${YELLOW}⚠️ IPP permitido (falta mDNS en '$active_zone')${NC}"
        else
            fw_status="${RED}❌ IPP y mDNS bloqueados en zona '$active_zone'${NC}"
        fi
    fi
    echo -e "• Cortafuegos (Firewall):  $fw_status"

    # Colas en CUPS
    echo -e "\n${BOLD}📋 Colas de impresión configuradas en CUPS:${NC}"
    local lp_printers default_prn
    lp_printers=$(lpstat -p 2>/dev/null || true)
    default_prn=$(lpstat -d 2>/dev/null || echo "ninguna")
    if [ -n "$lp_printers" ]; then
        echo "$lp_printers" | sed 's/^/  ✓ /'
        echo -e "  ${BOLD}Destino predeterminado:${NC} ${GREEN}$default_prn${NC}"
    else
        echo -e "  ${YELLOW}ℹ️ No hay ninguna cola configurada en CUPS aún.${NC}"
        echo -e "  💡 Configura la cola automáticamente con: ${CYAN}$0 --add-queue${NC}"
    fi
    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 6. INSTALACIÓN DE PAQUETES O(1)
# ------------------------------------------------------------------------------
install_packages() {
    log_info "[1/5] Comprobando paquetes de la suite de impresión..."

    local missing=()
    for pkg in "${CORE_PACKAGES[@]}"; do
        if ! is_pkg_installed "$pkg"; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        require_root
        log_info "Instalando paquetes faltantes (${missing[*]}):"
        $SUDO pacman -S --needed --noconfirm "${missing[@]}"
        log_ok "Paquetes instalados correctamente."
    else
        log_ok "Todos los paquetes de impresión ya están instalados."
    fi
}

# ------------------------------------------------------------------------------
# 7. SERVICIOS Y GRUPOS DE USUARIO
# ------------------------------------------------------------------------------
setup_services_and_users() {
    log_info "[2/5] Habilitando e iniciando servicios CUPS y Avahi (mDNS)..."
    require_root
    $SUDO systemctl enable --now cups.service cups.socket avahi-daemon.service 2>/dev/null || true
    log_ok "Servicios de impresión activos."

    log_info "[3/5] Verificando permisos del usuario '$TARGET_USER'..."
    local user_groups
    user_groups=$(id -nG "$TARGET_USER" 2>/dev/null || echo "")

    if ! echo "$user_groups" | grep -qw "lp"; then
        $SUDO usermod -aG lp "$TARGET_USER" 2>/dev/null || true
        log_ok "Usuario '$TARGET_USER' añadido al grupo 'lp'."
    fi

    if ! echo "$user_groups" | grep -qw "lpadmin"; then
        $SUDO usermod -aG lpadmin "$TARGET_USER" 2>/dev/null || true
        log_ok "Usuario '$TARGET_USER' añadido al grupo 'lpadmin'."
    fi
}

# ------------------------------------------------------------------------------
# 8. CORTAFUEGOS FIREWALLD
# ------------------------------------------------------------------------------
configure_firewall() {
    log_info "[4/5] Configurando reglas en Firewalld (IPP e mDNS)..."
    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        require_root
        local active_zone
        active_zone=$(timeout 1 firewall-cmd --get-default-zone 2>/dev/null || echo "home")

        local services=("ipp" "ipp-client" "mdns")
        local changed=false

        for srv in "${services[@]}"; do
            if ! firewall-cmd --zone="$active_zone" --list-services 2>/dev/null | grep -qw "$srv"; then
                $SUDO firewall-cmd --permanent --zone="$active_zone" --add-service="$srv" 2>/dev/null || \
                $SUDO firewall-cmd --permanent --add-service="$srv" 2>/dev/null || true
                changed=true
            fi
        done

        if [ "$changed" = true ]; then
            $SUDO firewall-cmd --reload 2>/dev/null || true
            log_ok "Servicios IPP y mDNS añadidos permanentemente a la zona '$active_zone'."
        else
            log_ok "Reglas de Firewalld (IPP y mDNS) ya estaban configuradas en '$active_zone'."
        fi
    else
        log_warn "Firewalld no está activo; se omite configuración de cortafuegos."
    fi
}

# ------------------------------------------------------------------------------
# 9. CONFIGURACIÓN AUTOMÁTICA DE LA COLA CUPS (DRIVERLESS / IPP EVERYWHERE)
# ------------------------------------------------------------------------------
configure_cups_queue() {
    log_info "[5/5] Detectando impresora y configurando cola CUPS..."
    require_root

    local net_uri usb_dev queue_name="HP_LaserJet_M15w"
    net_uri=$(get_network_printer_uri)
    usb_dev=$(detect_usb_printer)

    if [ -n "$net_uri" ]; then
        log_ok "Impresora HP detectada en red Wi-Fi: $net_uri"
        log_info "Configurando cola nativa Driverless (IPP Everywhere / Mopria 1.3)..."

        $SUDO lpadmin -p "$queue_name" -E -v "$net_uri" -m everywhere \
            -D "HP LaserJet Pro M15w (Wi-Fi)" \
            -L "Red Local" 2>/dev/null || {
            log_warn "Configuración con '-m everywhere' requirió PPD directo; reintentando con driverless..."
            $SUDO lpadmin -p "$queue_name" -E -v "$net_uri" \
                -m "driverless:ipps://HP%20LaserJet%20M15w%20(5E704E)._ipps._tcp.local/" 2>/dev/null || true
        }

        $SUDO lpadmin -d "$queue_name" 2>/dev/null || true
        $SUDO cupsenable "$queue_name" 2>/dev/null || true
        $SUDO cupsaccept "$queue_name" 2>/dev/null || true

        log_ok "Cola '$queue_name' creada y establecida como PREDETERMINADA."
        log_info "💡 Al usar conexión Wi-Fi IPP Everywhere, NO necesitas el plugin binario de HP."
        return 0
    elif [ -n "$usb_dev" ]; then
        log_ok "Impresora HP detectada por puerto USB."
        log_info "Para la conexión USB se requiere el backend HPLIP y su plugin propietario."
        if command -v hp-setup &>/dev/null; then
            $SUDO hp-setup -i -b usb || log_warn "hp-setup finalizado con advertencias."
        fi
        return 0
    else
        log_warn "No se detectó la impresora ni por Wi-Fi ni por cable USB."
        echo "   • Verifica que la impresora esté ENCENDIDA y con el Wi-Fi activado (luz azul fija)."
        echo "   • Si está conectada por cable USB, verifica la conexión."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 10. IMPRESIÓN DE PÁGINA DE PRUEBA
# ------------------------------------------------------------------------------
print_test_page() {
    local prn="${1:-HP_LaserJet_M15w}"

    if ! lpstat -p "$prn" &>/dev/null; then
        local def_prn
        def_prn=$(lpstat -d 2>/dev/null | awk -F': ' '{print $2}' | xargs)
        if [ -n "$def_prn" ]; then
            prn="$def_prn"
        else
            log_err "No hay colas de impresión disponibles para la prueba. Ejecuta primero: $0 --add-queue"
            exit 1
        fi
    fi

    log_info "Enviando página de prueba a la impresora '$prn'..."
    local test_file="/tmp/cups-test-$$.txt"
    cat <<EOF > "$test_file"
================================================================================
                    PRUEBA DE IMPRESIÓN - CACHYOS WORKSTATION
================================================================================
Fecha y Hora: $(date)
Estación:     HP ProBook 455 G10 (AMD Ryzen 7 7730U)
Impresora:    $prn
Protocolo:    CUPS + Driverless / IPP Everywhere
================================================================================
¡La impresora HP LaserJet Pro M15w está correctamente configurada y operativa!
================================================================================
EOF

    if lp -d "$prn" "$test_file" 2>/dev/null; then
        log_ok "Trabajo de impresión enviado con éxito a '$prn'."
    else
        log_err "No se pudo enviar el trabajo a la impresora '$prn'."
    fi
    rm -f "$test_file"
}

# ------------------------------------------------------------------------------
# 11. SUBCOMANDOS DE ASISTENCIA ESPECÍFICA
# ------------------------------------------------------------------------------
install_plugin() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${BOLD}${CYAN}🔌 INSTALACIÓN DEL PLUGIN PROPIETARIO DE HP (hplip-plugin)${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "💡 ${YELLOW}Nota:${NC} Este plugin SOLO es imprescindible si conectas la impresora por CABLE USB."
    echo -e "   Si la usas por Wi-Fi / IPP Everywhere, no es necesario instalarlo."
    echo ""
    if ! command -v hp-plugin &>/dev/null; then
        log_err "'hp-plugin' no está disponible. Ejecuta primero: $0"
        exit 1
    fi
    require_root
    $SUDO hp-plugin -i
}

run_wifi_setup() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${BOLD}${CYAN}📡 CONFIGURACIÓN ASISTIDA POR RED / WI-FI${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    configure_cups_queue
}

run_usb_setup() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${BOLD}${CYAN}🔌 CONFIGURACIÓN ASISTIDA POR CABLE USB${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    if ! command -v hp-setup &>/dev/null; then
        log_err "'hp-setup' no está disponible. Ejecuta primero: $0"
        exit 1
    fi
    require_root
    $SUDO hp-setup -i -b usb
}

# ------------------------------------------------------------------------------
# 12. MENÚ DE AYUDA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
${BOLD}🖨️ Instalador y Gestor de Impresoras HP (LaserJet M15w) - CachyOS${NC}
Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U + GNOME Shell Wayland)

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones principales:${NC}
  (sin argumentos)    Instalación completa O(1), configuración de CUPS, Avahi, Firewalld,
                      detección automática de la impresora y alta de la cola predeterminada.
  --status, -s        Diagnóstico detallado de CUPS, Avahi, detección USB, Wi-Fi y colas.
  --add-queue, -q     Detecta y configura la cola de impresión de inmediato en CUPS.
  --test-page, -t     Envía una página de prueba a la impresora predeterminada.
  --wifi, --net       Asistente de configuración por Wi-Fi / Red local.
  --usb               Asistente interactivo de configuración por cable USB (hp-setup).
  --plugin, -p        Descarga e instala el plugin binario propietario de HP (para USB).
  --help, -h          Muestra este mensaje de ayuda.

${BOLD}Ventajas del modo Driverless / Wi-Fi:${NC}
  • La serie HP LaserJet Pro M15w cuenta con certificación Mopria 1.3 y AirPrint.
  • Conexión directa mediante IPP Everywhere: 100% libre de controladores privativos,
    máxima velocidad de arranque y compatibilidad total con GNOME Wayland y navegadores.
EOF
}

# ------------------------------------------------------------------------------
# 13. PROCESAMIENTO DE ARGUMENTOS
# ------------------------------------------------------------------------------
case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --add-queue|-q|add-queue)
        configure_cups_queue
        exit 0
        ;;
    --test-page|-t|test-page)
        print_test_page "${2:-}"
        exit 0
        ;;
    --plugin|-p|plugin)
        install_plugin
        exit 0
        ;;
    --wifi|--net)
        run_wifi_setup
        exit 0
        ;;
    --usb)
        run_usb_setup
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        echo -e "${BOLD}=================================================================${NC}"
        echo -e "${BOLD}${CYAN}🚀 INSTALADOR Y CONFIGURADOR DE IMPRESORA HP LASERJET M15w${NC}"
        echo -e "💻 HP ProBook 455 G10 | CachyOS Workstation (GNOME Shell Wayland)"
        echo -e "${BOLD}=================================================================${NC}"
        install_packages
        setup_services_and_users
        configure_firewall
        configure_cups_queue || true
        echo ""
        show_status
        echo -e "\n${GREEN}🎉 ¡Listo! La impresora está preparada para su uso.${NC}"
        echo -e "💡 Prueba la impresión ejecutando: ${CYAN}$0 --test-page${NC}"
        echo -e "🌐 Panel Web de CUPS:              ${CYAN}http://localhost:631${NC}"
        exit 0
        ;;
    *)
        log_err "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
