#!/bin/bash
# ==============================================================================
# cockpit.sh - Instalación, configuración y gestión de la consola web Cockpit
# openSUSE Tumbleweed (KDE Plasma 6)
# ==============================================================================
#
# Uso:
#   ./cockpit.sh                     -> Instala Cockpit, módulos avanzados, activa el socket y configura el firewall
#   ./cockpit.sh --status            -> Muestra el estado del socket, servicio, reglas de firewall y módulos instalados
#   ./cockpit.sh --open              -> Abre la consola web de Cockpit en el navegador predeterminado
#   ./cockpit.sh --start             -> Inicia el socket de Cockpit
#   ./cockpit.sh --stop              -> Detiene el socket y servicio de Cockpit
#   ./cockpit.sh --disable           -> Deshabilita el socket de Cockpit y retira la regla de firewall
#   ./cockpit.sh --no-install        -> Habilita el servicio y firewall omitiendo la descarga de paquetes
#   ./cockpit.sh --help              -> Muestra la ayuda interactiva
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecución con sudo
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="${USER:-$(id -un)}"
fi

show_help() {
    cat <<EOF
🌐 Administrador de Consola Web Cockpit - openSUSE Tumbleweed (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala Cockpit con módulos avanzados, activa cockpit.socket y configura Firewalld.
  --status, -s           Muestra el estado de ejecución, puertos, reglas de firewall y módulos disponibles.
  --open, -o             Abre la interfaz web de Cockpit en el navegador predeterminado (https://localhost:9090).
  --start                Inicia cockpit.socket en systemd.
  --stop                 Detiene cockpit.socket y cockpit.service.
  --disable              Deshabilita el socket y retira el servicio de Firewalld.
  --no-install           Habilita socket y firewall omitiendo la descarga de paquetes Zypper.
  --help, -h             Muestra este mensaje de ayuda.

Módulos integrados:
  • Podman (cockpit-podman):          Gestión visual de contenedores, pods e imágenes.
  • Máquinas Virtuales (machines):    Gestión de VMs en KVM / QEMU y libvirt.
  • Instantáneas Snapper (snapshots): Gestión visual de snapshots y rollbacks Btrfs.
  • Almacenamiento (storaged):        Salud SMART de SSDs/NVMe, particionado y RAID.
  • Redes (networkmanager):           Monitoreo de interfaces de red, IP y tráfico.
  • Cortafuegos (firewalld):          Inspección y gestión de zonas y reglas activas.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE CONSOLA WEB COCKPIT - OPENSUSE TUMBLEWEED"
    echo "================================================================="
    echo "• Socket systemd:    $(systemctl is-active cockpit.socket 2>/dev/null || echo 'inactivo')"
    echo "• Servicio systemd:  $(systemctl is-active cockpit.service 2>/dev/null || echo 'inactivo')"
    echo "• Habilitado en boot: $(systemctl is-enabled cockpit.socket 2>/dev/null || echo 'deshabilitado')"
    echo "• Puerto 9090 (ss):  $(if ss -tulanp 2>/dev/null | grep -q ':9090 '; then echo 'Escuchando'; else echo 'Cerrado'; fi)"
    echo "• Regla Firewalld:   $(if sudo firewall-cmd --list-services 2>/dev/null | grep -q 'cockpit'; then echo 'Habilitada (cockpit)'; else echo 'No presente'; fi)"
    echo "-----------------------------------------------------------------"
    echo "📦 Módulos instalados:"
    echo "  - cockpit-bridge:         $(if rpm -q cockpit-bridge &>/dev/null; then echo '✅ Instalado'; else echo '❌ No'; fi)"
    echo "  - cockpit-podman:         $(if rpm -q cockpit-podman &>/dev/null; then echo '✅ Instalado'; else echo '❌ No'; fi)"
    echo "  - cockpit-machines (KVM): $(if rpm -q cockpit-machines &>/dev/null; then echo '✅ Instalado'; else echo '❌ No'; fi)"
    echo "  - cockpit-snapshots:      $(if rpm -q cockpit-snapshots &>/dev/null; then echo '✅ Instalado'; else echo '❌ No'; fi)"
    echo "  - cockpit-storaged:       $(if rpm -q cockpit-storaged &>/dev/null; then echo '✅ Instalado'; else echo '❌ No'; fi)"
    echo "  - cockpit-networkmanager: $(if rpm -q cockpit-networkmanager &>/dev/null; then echo '✅ Instalado'; else echo '❌ No'; fi)"
    echo "================================================================="
}

open_browser() {
    local target_url="https://localhost:9090"
    echo "🌐 Abriendo $target_url en el navegador..."
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$SUDO_USER" xdg-open "$target_url" &>/dev/null &
    else
        xdg-open "$target_url" &>/dev/null &
    fi
}

start_cockpit() {
    echo "🚀 Iniciando cockpit.socket..."
    $SUDO systemctl enable --now cockpit.socket
    echo "✅ cockpit.socket activo."
}

stop_cockpit() {
    echo "🛑 Deteniendo servicios de Cockpit..."
    $SUDO systemctl stop cockpit.service cockpit.socket 2>/dev/null || true
    echo "✅ Cockpit detenido."
}

disable_cockpit() {
    echo "🔒 Deshabilitando Cockpit y retirando reglas de firewall..."
    $SUDO systemctl disable --now cockpit.socket cockpit.service 2>/dev/null || true
    $SUDO firewall-cmd --permanent --remove-service=cockpit 2>/dev/null || true
    $SUDO firewall-cmd --reload 2>/dev/null || true
    echo "✅ Cockpit deshabilitado."
}

configure_firewall() {
    echo "🛡️ Configurando puerto de Cockpit en Firewalld (9090/tcp)..."
    if $SUDO firewall-cmd --state &>/dev/null; then
        $SUDO firewall-cmd --permanent --add-service=cockpit 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
        echo "  ✅ Regla de firewall aplicada para Cockpit."
    fi
}

install_packages() {
    echo "📦 [1/2] Instalando Cockpit y suite de módulos avanzados vía Zypper..."
    $SUDO zypper --non-interactive install -y \
        cockpit \
        cockpit-bridge \
        cockpit-ws \
        cockpit-system \
        cockpit-podman \
        cockpit-machines \
        cockpit-snapshots \
        cockpit-storaged \
        cockpit-networkmanager \
        cockpit-firewalld 2>/dev/null || true
}

enable_service() {
    echo "⚡ [2/2] Habilitando cockpit.socket y configurando seguridad..."
    $SUDO systemctl daemon-reload
    $SUDO systemctl enable --now cockpit.socket
    configure_firewall
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --open|-o|open)
        open_browser
        exit 0
        ;;
    --start|start)
        start_cockpit
        exit 0
        ;;
    --stop|stop)
        stop_cockpit
        exit 0
        ;;
    --disable|disable)
        disable_cockpit
        exit 0
        ;;
    --no-install)
        enable_service
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🌐 CONFIGURANDO CONSOLA DE ADMINISTRACIÓN WEB COCKPIT"
        echo "================================================================="
        install_packages
        enable_service
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Cockpit configurado con éxito."
        echo "💡 Accede a la consola web en: https://localhost:9090"
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
