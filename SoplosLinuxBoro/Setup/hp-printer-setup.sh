#!/bin/bash
# =============================================================================
# hp-printer-setup.sh - Configuración de Impresora HP (LaserJet Pro M15w)
# =============================================================================
# Optimizado para Soplos Linux Boro Workstation (GNOME Shell):
#   - Conexión por cable USB y Red inalámbrica (Wi-Fi / mDNS)
#   - Servicios CUPS, Avahi y soporte nativo de impresión en GNOME
#   - Instalación guiada del plugin propietario requerido (hp-plugin)
#   - Pertenencia a grupos 'lp' y 'lpadmin'
#   - Reglas de Firewalld para descubrimiento y colas de impresión
#   - Opciones CLI: --status, --plugin, --wifi, --usb, --help
# =============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "❌ Error: Este script requiere privilegios de superusuario."
        exit 1
    fi
else
    SUDO=""
fi

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    TARGET_USER="$SUDO_USER"
else
    TARGET_USER="${USER:-$(id -un)}"
fi

show_help() {
    cat <<EOF
🖨️ Instalador y Configurador de Impresoras HP - Soplos Linux Boro Workstation (GNOME)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala dependencias, servicios y lanza configuración interactiva.
  --status, -s           Muestra el estado de CUPS, Avahi, impresoras detectadas y colas.
  --plugin               Descarga e instala únicamente el plugin propietario de HP (hp-plugin).
  --wifi, --net          Inicia directamente la búsqueda y configuración de impresora por Wi-Fi.
  --usb                  Inicia directamente la configuración de impresora por cable USB.
  --help, -h             Muestra esta ayuda.

Modelos compatibles:
  - HP LaserJet Pro M15w / M15a
  - HP LaserJet Pro M14 / M17 series
  - Cualquier impresora HP compatible con HPLIP y CUPS
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DEL SERVICIO DE IMPRESIÓN - SOPLOS LINUX BORO WORKSTATION"
    echo "================================================================="
    echo "• Servicio CUPS:               $(systemctl is-active --quiet cups.service 2>/dev/null && echo '✅ Activo' || echo '❌ Inactivo')"
    echo "• Servicio Avahi (mDNS/Wi-Fi): $(systemctl is-active --quiet avahi-daemon.service 2>/dev/null && echo '✅ Activo' || echo '❌ Inactivo')"
    echo "• Usuario en grupos:           $(groups "$TARGET_USER" 2>/dev/null || echo 'n/a')"
    echo "-----------------------------------------------------------------"
    echo "• Impresoras HP detectadas por USB:"
    if lsusb 2>/dev/null | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17|print" >/dev/null 2>&1; then
        lsusb | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17|print" | sed 's/^/    /'
    else
        echo "    (Ninguna impresora HP detectada en puertos USB)"
    fi
    echo "-----------------------------------------------------------------"
    echo "• Colas de impresión activas en CUPS (lpstat):"
    lpstat -p -d 2>/dev/null || echo "    (No hay impresoras configuradas actualmente)"
    echo "================================================================="
    echo "💡 Puedes administrar tus impresoras también desde GNOME en:"
    echo "   'Configuración -> Impresoras' o ejecutando 'system-config-printer'"
}

install_plugin() {
    echo "⬇️ Instalando plugin propietario oficial de HP (hp-plugin)..."
    if command -v hp-plugin &>/dev/null; then
        hp-plugin -i
    else
        echo "❌ Error: 'hp-plugin' no está disponible. Ejecuta primero $0 sin argumentos."
        exit 1
    fi
}

setup_wifi() {
    echo "📶 Buscando impresoras HP en la red local..."
    if command -v hp-setup &>/dev/null; then
        hp-setup -i -b net
    else
        echo "❌ Error: 'hp-setup' no está disponible. Ejecuta primero $0 sin argumentos."
        exit 1
    fi
}

setup_usb() {
    echo "🔌 Configurando impresora HP por conexión USB..."
    if command -v hp-setup &>/dev/null; then
        hp-setup -i -b usb
    else
        echo "❌ Error: 'hp-setup' no está disponible. Ejecuta primero $0 sin argumentos."
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
    "")
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac

echo "================================================================="
echo "🖨️ INSTALANDO Y CONFIGURANDO IMPRESIÓN HP - SOPLOS LINUX BORO WORKSTATION"
echo "================================================================="

# 1. Instalar paquetes de CUPS y HPLIP
echo "ℹ️ [1/5] Instalando CUPS, Avahi y suite HPLIP..."
$SUDO apt update
$SUDO apt install -y \
    cups \
    cups-client \
    cups-filters \
    hplip \
    hplip-gui \
    printer-driver-hpcups \
    avahi-daemon \
    system-config-printer

# 2. Habilitar servicios
echo "ℹ️ [2/5] Habilitando servicios de impresión en systemd..."
$SUDO systemctl enable --now cups.service
$SUDO systemctl enable --now avahi-daemon.service

# 3. Añadir usuario a grupos lp y lpadmin
echo "ℹ️ [3/5] Añadiendo usuario '$TARGET_USER' a grupos 'lp' y 'lpadmin'..."
$SUDO usermod -aG lp,lpadmin "$TARGET_USER"

# 4. Configurar Firewalld para CUPS e IPP
if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld; then
    echo "ℹ️ [4/5] Configurando reglas de cortafuegos en Firewalld (mdns, ipp)..."
    ACTIVE_ZONE=$($SUDO firewall-cmd --get-default-zone 2>/dev/null || echo "public")
    $SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=mdns 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=ipp 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=ipp-client 2>/dev/null || true
    $SUDO firewall-cmd --reload 2>/dev/null || true
fi

# 5. Descargar e instalar plugin propietario de HP
echo "ℹ️ [5/5] Comprobando plugin propietario requerido para LaserJet M15w..."
if command -v hp-plugin &>/dev/null; then
    echo "💡 Se abrirá el asistente para instalar el firmware/plugin de HP:"
    hp-plugin -i || echo "⚠️ Puedes ejecutar './Setup/hp-printer-setup.sh --plugin' más tarde si lo omites."
fi

echo ""
echo "================================================================="
echo "✅ Pila de impresión HP configurada correctamente en Soplos Linux Boro."
echo "💡 Para añadir tu impresora, ejecuta:"
echo "   ./Setup/hp-printer-setup.sh --wifi    (Si está conectada por Wi-Fi)"
echo "   ./Setup/hp-printer-setup.sh --usb     (Si está conectada por cable USB)"
echo "================================================================="
