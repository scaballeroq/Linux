#!/usr/bin/env bash
# ==============================================================================
# hp-printer-setup.sh - Instalación y Configuración de Impresoras HP (LaserJet M15w)
# Debian Testing (Trixie/Sid) + KDE Plasma 6 (Wayland)
# ==============================================================================
# Soporta conexión USB y Red/Wi-Fi (mDNS/IPP), instalación de CUPS, HPLIP,
# reglas de Firewall, plugin propietario de HP e integración nativa en KDE Plasma.
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

TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"

is_pkg_installed() {
    local pkg="$1"
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
}

show_help() {
    cat <<EOF
🖨️ Instalador y Gestor de Impresoras HP (LaserJet M15w) - Debian Testing (KDE 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala el stack completo (CUPS, HPLIP, Print Manager), configura
                      servicios y Firewall, detecta impresora y ofrece instalar el plugin HP.
  --status, -s        Muestra el estado de CUPS, HPLIP, plugin, USB/Red y colas activas.
  --plugin, -p        Ejecuta el asistente de instalación del plugin propietario de HP.
  --setup             Lanza 'hp-setup' interactivo en terminal para agregar la impresora.
  --help, -h          Muestra este mensaje de ayuda.

Modelos soportados:
  • HP LaserJet Pro M15w / M14 / M17 (por cable USB o por Wi-Fi/Red local).
  • Compatible con cualquier impresora o multifunción HP soportada por HPLIP.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DEL SISTEMA DE IMPRESIÓN - HP LASERJET (KDE 6)"
    echo "================================================================="

    local cups_status hplip_installed plugin_status usb_printer fw_status

    cups_status=$(if systemctl is-active --quiet cups.service 2>/dev/null; then echo "✅ Activo (running)"; else echo "❌ Inactivo"; fi)
    hplip_installed=$(if is_pkg_installed hplip; then echo "✅ HPLIP ($(dpkg-query -W -f='${Version}' hplip 2>/dev/null))"; else echo "❌ No instalado"; fi)

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

    fw_status="ℹ️ Sin cortafuegos activo"
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        local fw_services
        fw_services=$(firewall-cmd --list-services 2>/dev/null || true)
        if echo "$fw_services" | grep -qw "ipp" && echo "$fw_services" | grep -qw "mdns"; then
            fw_status="✅ Firewalld: IPP y mDNS permitidos"
        elif echo "$fw_services" | grep -qw "ipp"; then
            fw_status="✅ Firewalld: IPP permitido (mDNS inactivo)"
        else
            fw_status="ℹ️ Firewalld: Reglas no activas en zona por defecto"
        fi
    elif systemctl is-active --quiet ufw 2>/dev/null; then
        fw_status="✅ UFW activo"
    fi

    echo "• Servicio CUPS:           $cups_status"
    echo "• Suite HPLIP:             $hplip_installed"
    echo "• KDE Print Manager:       $(if is_pkg_installed print-manager; then echo "✅ Instalado (print-manager)"; else echo "❌ No instalado"; fi)"
    echo "• Plugin propietario HP:   $plugin_status"
    echo "• Detección USB:           $usb_printer"
    echo "• Usuario en grupos lp:    $(if id -nG "$TARGET_USER" 2>/dev/null | grep -qw "lpadmin"; then echo "✅ lp y lpadmin ($TARGET_USER)"; elif id -nG "$TARGET_USER" 2>/dev/null | grep -qw "lp"; then echo "⚠️ Sólo lp ($TARGET_USER)"; else echo "❌ Ninguno"; fi)"
    echo "• Reglas Firewall:         $fw_status"
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

run_setup() {
    echo "================================================================="
    echo "🖨️ CONFIGURACIÓN DE COLA DE IMPRESIÓN HP (hp-setup)"
    echo "================================================================="
    if ! command -v hp-setup &>/dev/null; then
        echo "❌ Error: 'hp-setup' no está instalado. Ejecuta primero: $0"
        exit 1
    fi
    $SUDO hp-setup -i
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
    --setup|setup)
        run_setup
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🚀 CONFIGURANDO IMPRESORA HP (LASERJET M15w) EN DEBIAN TESTING"
echo "================================================================="

# 1. Instalación de paquetes de impresión
echo "📦 [1/6] Verificando e instalando suite de impresión vía APT..."
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get update -qq
$SUDO apt-get install -y \
    cups \
    cups-client \
    cups-filters \
    print-manager \
    hplip \
    hplip-gui \
    avahi-daemon \
    usbutils \
    wget 2>/dev/null || true

# 2. Habilitar e iniciar servicio CUPS y Avahi
echo "⚙️ [2/6] Habilitando e iniciando servicios CUPS y Avahi..."
$SUDO systemctl enable --now cups.service 2>/dev/null || true
$SUDO systemctl enable --now avahi-daemon.service 2>/dev/null || true

# 3. Privilegios de impresión para el usuario
echo "👤 [3/6] Asegurando permisos de usuario en grupos 'lp' y 'lpadmin'..."
$SUDO usermod -aG lp,lpadmin "$TARGET_USER" 2>/dev/null || true

# 4. Habilitar servicios de red e impresión en Firewall (para conexión Wi-Fi / IPP)
echo "🛡️ [4/6] Configurando cortafuegos para descubrimiento e impresión (IPP y mDNS)..."
if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
    $SUDO firewall-cmd --permanent --add-service=ipp --add-service=mdns 2>/dev/null || true
    $SUDO firewall-cmd --reload 2>/dev/null || true
    echo "   ✅ Reglas de Firewalld (IPP y mDNS) aplicadas."
elif command -v ufw &>/dev/null && systemctl is-active --quiet ufw 2>/dev/null; then
    $SUDO ufw allow 631/tcp 2>/dev/null || true
    $SUDO ufw allow 5353/udp 2>/dev/null || true
    echo "   ✅ Reglas de UFW (IPP y mDNS) aplicadas."
fi

# 5. Comprobación de detección de la impresora
echo "🔍 [5/6] Verificando conexión de la impresora HP..."
if lsusb 2>/dev/null | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17" >/dev/null; then
    echo "   ✅ Impresora HP detectada en puerto USB:"
    lsusb 2>/dev/null | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17" || true
else
    echo "   ℹ️ No se detectó ninguna HP LaserJet en puertos USB."
    echo "   💡 Si la vas a usar por Wi-Fi/Red, asegúrate de que esté encendida y conectada a tu misma red."
fi

# 6. Asistente para instalar el Plugin Propietario de HP
echo "🔌 [6/6] Comprobación del Plugin Propietario de HP..."
echo "================================================================="
echo "💡 IMPORTANTE: La serie HP LaserJet M15w requiere el PLUGIN PROPIETARIO"
echo "   de HP (hplip-plugin) para poder procesar y enviar trabajos de impresión."
echo "================================================================="

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

echo ""
read -rp "¿Deseas lanzar 'hp-setup' interactivo para agregar la cola de impresión ahora? (s/N): " RUN_HP_SETUP || true
RUN_HP_SETUP="${RUN_HP_SETUP:-n}"

if [[ "$RUN_HP_SETUP" =~ ^[Ss]$ ]]; then
    if command -v hp-setup &>/dev/null; then
        $SUDO hp-setup -i || true
    fi
fi

echo "================================================================="
echo "✅ Configuración base de HP LaserJet Pro M15w completada."
echo "   • Panel Web de CUPS:        http://localhost:631"
echo "   • Gestión gráfica en KDE:   Preferencias del Sistema -> Impresoras"
echo "                               (o ejecutando: kcmshell6 kcm_printer_manager)"
echo "   • Comprobar estado:         $0 --status"
echo "================================================================="
