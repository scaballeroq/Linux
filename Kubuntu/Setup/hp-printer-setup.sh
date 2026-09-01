#!/bin/bash
# =============================================================================
# hp-printer-setup.sh - Configuración de Impresora HP (LaserJet Pro M15w)
# =============================================================================
# Optimizado para Kubuntu / KDE Plasma:
#   - Soporte para conexión USB y Red inalámbrica (Wi-Fi / Red local)
#   - Servicios CUPS, Avahi (mDNS) y Print Manager de KDE Plasma
#   - Instalación guiada del plugin propietario requerido (hp-plugin)
#   - Permisos y pertenencia a grupos lp y lpadmin
# =============================================================================

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
    TARGET_USER="$SUDO_USER"
else
    TARGET_USER="${USER:-$(id -un)}"
fi

show_help() {
    cat <<EOF
Instalador y Configurador de Impresoras HP - Kubuntu (KDE Plasma)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Instala dependencias, servicios y lanza configuración interactiva.
  --status, -s           Muestra el estado de CUPS, Avahi, impresoras detectadas y colas activas.
  --plugin               Descarga e instala únicamente el plugin propietario de HP (hp-plugin).
  --wifi, --net          Inicia directamente la búsqueda y configuración de impresora por Wi-Fi/Red.
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
    echo "ESTADO DEL SERVICIO DE IMPRESIÓN - KUBUNTU"
    echo "================================================================="
    echo "Servicio CUPS:                 $(systemctl is-active --quiet cups.service 2>/dev/null && echo 'Activo' || echo 'Inactivo')"
    echo "Servicio Avahi (mDNS/Wi-Fi):   $(systemctl is-active --quiet avahi-daemon.service 2>/dev/null && echo 'Activo' || echo 'Inactivo')"
    echo "Usuario en grupos:             $(groups "$TARGET_USER" 2>/dev/null || echo 'n/a')"
    echo "-----------------------------------------------------------------"
    echo "Impresoras detectadas por USB:"
    if lsusb 2>/dev/null | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17|print" >/dev/null 2>&1; then
        lsusb | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17|print"
    else
        echo "  (Ninguna impresora HP detectada en puertos USB)"
    fi
    echo "-----------------------------------------------------------------"
    echo "Colas de impresión activas en CUPS (lpstat):"
    lpstat -p -d 2>/dev/null || echo "  (No hay impresoras configuradas actualmente)"
    echo "================================================================="
    echo "💡 Panel de administración Web CUPS: http://localhost:631"
}

install_packages() {
    echo "ℹ️ [1/4] Instalando paquetes de impresión (CUPS, HPLIP, KDE Print Manager, Avahi)..."
    $SUDO apt update
    $SUDO apt install -y \
        cups \
        cups-client \
        cups-filters \
        cups-daemon \
        hplip \
        hplip-gui \
        printer-driver-hpcups \
        system-config-printer \
        print-manager \
        avahi-daemon \
        avahi-utils \
        usbutils \
        wget

    # Habilitar e iniciar CUPS y Avahi (para descubrimiento mDNS en red local)
    $SUDO systemctl enable --now cups.service 2>/dev/null || true
    $SUDO systemctl enable --now cups.socket 2>/dev/null || true
    $SUDO systemctl enable --now avahi-daemon.service 2>/dev/null || true

    # Asignar grupos lp y lpadmin al usuario
    if ! id -nG "$TARGET_USER" | grep -qw "lpadmin"; then
        echo "Añadiendo a '$TARGET_USER' al grupo lpadmin..."
        $SUDO usermod -aG lp,lpadmin "$TARGET_USER" 2>/dev/null || true
    fi
    echo "✅ Paquetes y servicios de impresión listos."
}

install_plugin() {
    echo ""
    echo "================================================================="
    echo "💡 INSTALACIÓN DEL PLUGIN PROPIETARIO HP (hp-plugin)"
    echo "================================================================="
    echo "La serie HP LaserJet Pro M15w requiere el plugin binario oficial de HP"
    echo "para procesar el rasterizado y ejecutar trabajos de impresión."
    echo "================================================================="
    echo ""

    if command -v hp-plugin &>/dev/null; then
        echo "Iniciando instalador hp-plugin..."
        $SUDO hp-plugin -i || {
            echo "⚠️ hp-plugin terminó con código no cero. Si es necesario, ejecútalo manualmente con: sudo hp-plugin -i"
        }
    else
        echo "❌ Comando hp-plugin no encontrado. Asegúrate de que hplip esté instalado."
    fi
}

configure_printer() {
    local MODE="${1:-auto}"
    echo ""
    echo "================================================================="
    echo "CONFIGURACIÓN DE LA COLA DE IMPRESIÓN (hp-setup)"
    echo "================================================================="

    case "$MODE" in
        usb)
            echo "ℹ️ Configurando impresora por cable USB..."
            $SUDO hp-setup -b usb -i || true
            ;;
        wifi|net)
            echo "ℹ️ Buscando y configurando impresora en la Red Local (Wi-Fi / Ethernet)..."
            $SUDO hp-setup -b net -i || true
            ;;
        auto|*)
            echo "¿Cómo está conectada tu impresora HP LaserJet M15w?"
            echo "1) Por cable USB"
            echo "2) Por Red Local / Wi-Fi inalámbrica"
            echo "3) Omitir configuración de cola por ahora (configurar más tarde)"
            read -rp "Selecciona una opción (1, 2 o 3): " OPT_CONN || true
            case "${OPT_CONN:-1}" in
                1)
                    $SUDO hp-setup -b usb -i || true
                    ;;
                2)
                    $SUDO hp-setup -b net -i || true
                    ;;
                *)
                    echo "ℹ️ Configuración de cola omitida."
                    ;;
            esac
            ;;
    esac
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
    --usb)
        install_packages
        install_plugin
        configure_printer "usb"
        ;;
    --wifi|--net)
        install_packages
        install_plugin
        configure_printer "net"
        ;;
    "")
        echo "================================================================="
        echo "CONFIGURADOR DE IMPRESORA HP (LASERJET M15w) - KUBUNTU"
        echo "================================================================="
        install_packages
        
        echo ""
        read -rp "¿Deseas instalar/actualizar el plugin propietario HP ahora? (S/n): " RUN_PLUGIN || true
        RUN_PLUGIN="${RUN_PLUGIN:-s}"
        if [[ "$RUN_PLUGIN" =~ ^[Ss]$ ]]; then
            install_plugin
        fi

        configure_printer "auto"
        echo ""
        show_status
        echo ""
        echo "================================================================="
        echo "✅ Configuración finalizada."
        echo "💡 Puedes gestionar tus impresoras desde:"
        echo "   - KDE Plasma: 'Preferencias del Sistema -> Impresoras'"
        echo "   - Panel Web CUPS: http://localhost:631"
        echo "   - Página de prueba: hp-testpage"
        echo "================================================================="
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
