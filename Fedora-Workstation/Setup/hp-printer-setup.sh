#!/usr/bin/env bash
# ==============================================================================
# hp-printer-setup.sh - Instalación y Configuración de Impresoras HP (LaserJet M15w)
# Fedora Workstation + GNOME Shell (Wayland)
# ==============================================================================
# Soporta conexión USB y Red/Wi-Fi (mDNS/IPP), instalación de CUPS, HPLIP,
# reglas de Firewalld, plugin propietario de HP e integración en GNOME.
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"

if command -v dnf5 &>/dev/null; then
    DNF_CMD="dnf5"
else
    DNF_CMD="dnf"
fi

is_pkg_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

show_help() {
    cat <<EOF
🖨️ Instalador y Gestor de Impresoras HP (LaserJet M15w) - Fedora Workstation (GNOME)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala el stack completo (CUPS, HPLIP, system-config-printer), configura
                      servicios y Firewalld, detecta impresora y asiste con el plugin HP.
  --status, -s        Muestra el estado de CUPS, HPLIP, plugin, USB/Red y colas activas.
  --plugin, -p        Ejecuta el asistente de instalación del plugin propietario de HP.
  --wifi, --net       Inicia configuración interactiva para impresora por red local / Wi-Fi.
  --usb               Inicia configuración interactiva para impresora por cable USB.
  --help, -h          Muestra este mensaje de ayuda.

Modelos soportados:
  • HP LaserJet Pro M15w / M14 / M17 (por cable USB o por Wi-Fi/Red local).
  • Compatible con cualquier impresora o multifunción HP soportada por HPLIP.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DEL SISTEMA DE IMPRESIÓN - HP LASERJET (FEDORA WORKSTATION)"
    echo "================================================================="

    local cups_status hplip_installed plugin_status usb_printer fw_status

    cups_status=$(if systemctl is-active --quiet cups.service 2>/dev/null; then echo "✅ Activo (running)"; else echo "❌ Inactivo"; fi)
    hplip_installed=$(if is_pkg_installed hplip; then echo "✅ HPLIP ($(rpm -q --qf '%{VERSION}' hplip 2>/dev/null))"; else echo "❌ No instalado"; fi)

    local plugin_ver=""
    if [ -f /var/lib/hp/hplip.state ] && grep -qiE "^\s*installed\s*=\s*1" /var/lib/hp/hplip.state 2>/dev/null; then
        plugin_ver=$(grep -iE "^\s*version\s*=" /var/lib/hp/hplip.state 2>/dev/null | cut -d= -f2 | xargs)
        plugin_status="✅ Instalado${plugin_ver:+ ($plugin_ver)}"
    elif [ -f /usr/share/hplip/prnt/plugins/lj.so ] || [ -f /var/lib/hp/hplip-install_plugin.stamp ]; then
        plugin_status="✅ Instalado"
    elif command -v python3 &>/dev/null && python3 -c "import sys; sys.path.append('/usr/share/hplip'); from installer.pluginhandler import PluginHandle; sys.exit(0 if str(PluginHandle().getStatus()) in ('1', 'PLUGIN_INSTALLED') else 1)" 2>/dev/null; then
        plugin_status="✅ Instalado"
    else
        plugin_status="⚠️ No detectado (requerido para la serie LaserJet M15w)"
    fi

    if lsusb 2>/dev/null | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17" >/dev/null; then
        local usb_dev
        usb_dev=$(lsusb 2>/dev/null | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17" | head -n1 | cut -d: -f3- | xargs)
        usb_printer="✅ Detectada en puerto USB ($usb_dev)"
    else
        usb_printer="ℹ️ No conectada por USB (o apagada)"
    fi

    fw_status="ℹ️ Firewalld no activo"
    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone fw_services
        active_zone=$(timeout 1 firewall-cmd --get-default-zone 2>/dev/null || echo "FedoraWorkstation")
        fw_services=$(timeout 1 firewall-cmd --zone="$active_zone" --list-services 2>/dev/null || true)
        if echo "$fw_services" | grep -qw "ipp" && echo "$fw_services" | grep -qw "mdns"; then
            fw_status="✅ Firewalld: IPP y mDNS permitidos en zona '$active_zone'"
        elif echo "$fw_services" | grep -qw "ipp"; then
            fw_status="✅ Firewalld: IPP permitido (mDNS no activo en zona '$active_zone')"
        else
            fw_status="ℹ️ Firewalld: IPP/mDNS no activos en zona '$active_zone'"
        fi
    fi

    echo "• Servicio CUPS:           $cups_status"
    echo "• Suite HPLIP:             $hplip_installed"
    echo "• GNOME Print Manager:     $(if is_pkg_installed system-config-printer; then echo "✅ Instalado (system-config-printer)"; else echo "❌ No instalado"; fi)"
    echo "• Plugin propietario HP:   $plugin_status"
    echo "• Detección USB:           $usb_printer"
    echo "• Usuario en grupos lp:    $(if id -nG "$TARGET_USER" 2>/dev/null | grep -qw "lp"; then echo "✅ lp ($TARGET_USER)"; else echo "❌ No asignado"; fi)"
    echo "• Reglas Firewalld:        $fw_status"
    echo "-----------------------------------------------------------------"
    echo "📋 Colas de impresión en CUPS:"
    local lp_printers
    lp_printers=$(lpstat -p 2>/dev/null || true)
    if [ -n "$lp_printers" ]; then
        lpstat -p -d 2>/dev/null || true
    else
        echo "   ℹ️ No hay impresoras configuradas aún en CUPS."
    fi
    echo "================================================================="
}

install_plugin() {
    echo "================================================================="
    echo "🔌 INSTALACIÓN DEL PLUGIN PROPIETARIO DE HP (hplip-plugin)"
    echo "================================================================="
    echo "💡 La serie HP LaserJet M15w necesita este plugin binario para renderizar."
    if ! command -v hp-plugin &>/dev/null; then
        echo "❌ Error: 'hp-plugin' no está instalado. Ejecuta primero: $0"
        exit 1
    fi
    $SUDO hp-plugin -i
}

run_wifi_setup() {
    echo "================================================================="
    echo "📡 CONFIGURANDO IMPRESORA HP POR RED / WI-FI"
    echo "================================================================="
    if ! command -v hp-setup &>/dev/null; then
        echo "❌ Error: 'hp-setup' no disponible. Ejecuta primero sin argumentos."
        exit 1
    fi
    $SUDO hp-setup -i -b net
}

run_usb_setup() {
    echo "================================================================="
    echo "🔌 CONFIGURANDO IMPRESORA HP POR CABLE USB"
    echo "================================================================="
    if ! command -v hp-setup &>/dev/null; then
        echo "❌ Error: 'hp-setup' no disponible. Ejecuta primero sin argumentos."
        exit 1
    fi
    $SUDO hp-setup -i -b usb
}

case "${1:-}" in
    --status|-s|status)
        show_status
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
esac

echo "================================================================="
echo "🚀 CONFIGURANDO IMPRESORA HP (LASERJET M15w) EN FEDORA WORKSTATION"
echo "================================================================="

# 1. Instalación de paquetes de impresión vía DNF
echo "📦 [1/6] Verificando e instalando suite de impresión vía $DNF_CMD..."
$SUDO $DNF_CMD install -y \
    cups \
    cups-filters \
    cups-ipp-utils \
    system-config-printer \
    hplip \
    hplip-gui \
    avahi \
    usbutils \
    libusb1 2>/dev/null || true

# 2. Habilitar e iniciar servicio CUPS y Avahi
echo "⚙️ [2/6] Habilitando e iniciando servicios CUPS y Avahi..."
$SUDO systemctl enable --now cups.service cups.socket 2>/dev/null || true
$SUDO systemctl enable --now avahi-daemon.service 2>/dev/null || true

# 3. Privilegios de impresión para el usuario
echo "👤 [3/6] Asegurando permisos de usuario en grupos 'lp' y 'lpadmin'..."
$SUDO usermod -aG lp "$TARGET_USER" 2>/dev/null || true
$SUDO usermod -aG lpadmin "$TARGET_USER" 2>/dev/null || true

# 4. Habilitar servicios en Firewalld
echo "🛡️ [4/6] Configurando Firewalld para descubrimiento e impresión (IPP y mDNS)..."
if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
    ACTIVE_ZONE=$(timeout 1 firewall-cmd --get-default-zone 2>/dev/null || echo "FedoraWorkstation")
    $SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=ipp --add-service=ipp-client --add-service=mdns 2>/dev/null || \
    $SUDO firewall-cmd --permanent --add-service=ipp --add-service=ipp-client --add-service=mdns 2>/dev/null || true
    $SUDO firewall-cmd --reload 2>/dev/null || true
    echo "   ✅ Reglas de Firewalld (IPP y mDNS) aplicadas en zona '$ACTIVE_ZONE'."
fi

# 5. Comprobación de detección de la impresora
echo "🔍 [5/6] Verificando conexión de la impresora HP..."
if lsusb 2>/dev/null | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17" >/dev/null; then
    echo "   ✅ Impresora HP detectada en puerto USB:"
    lsusb 2>/dev/null | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17" || true
else
    echo "   ℹ️ No se detectó ninguna HP LaserJet en puertos USB."
    echo "   💡 Si la vas a usar por Wi-Fi/Red, asegúrate de que esté encendida y conectada a tu misma red local."
fi

# 6. Asistente para instalar el Plugin Propietario de HP
echo "🔌 [6/6] Comprobación del Plugin Propietario de HP..."
if [ -t 0 ]; then
    read -rp "¿Deseas ejecutar 'hp-plugin' ahora para descargar e instalar el plugin? (S/n): " INSTALL_PLUGIN || true
    INSTALL_PLUGIN="${INSTALL_PLUGIN:-s}"

    if [[ "$INSTALL_PLUGIN" =~ ^[Ss]$ ]]; then
        echo "ℹ️ Ejecutando instalador del plugin HP en modo interactivo..."
        if command -v hp-plugin &>/dev/null; then
            $SUDO hp-plugin -i || echo "⚠️ hp-plugin terminó con advertencias o requiere interacción manual."
        fi
    else
        echo "ℹ️ Puedes instalar el plugin en cualquier momento ejecutando: $0 --plugin"
    fi
else
    echo "ℹ️ Modo no interactivo detectado. Puedes instalar el plugin con: $0 --plugin"
fi

echo "================================================================="
echo "✅ Configuración base de HP LaserJet Pro M15w completada."
echo "   • Panel Web de CUPS:        http://localhost:631"
echo "   • Gestión gráfica en GNOME: Configuración -> Impresoras"
echo "   • Comprobar estado:         $0 --status"
echo "================================================================="
