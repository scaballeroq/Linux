#!/bin/bash
# cockpit.sh - Instalación, configuración y gestión de la consola web Cockpit en Fedora 44 + KDE Plasma
#
# Uso:
#   ./cockpit.sh                     -> Instala Cockpit, módulos avanzados, activa el socket y configura el firewall
#   ./cockpit.sh --status            -> Muestra el estado del socket, servicio, reglas de firewall y módulos instalados
#   ./cockpit.sh --open              -> Abre la consola web de Cockpit en el navegador predeterminado
#   ./cockpit.sh --start             -> Inicia el socket de Cockpit
#   ./cockpit.sh --stop              -> Detiene el socket y servicio de Cockpit
#   ./cockpit.sh --disable           -> Deshabilita el socket de Cockpit y retira la regla de firewall
#   ./cockpit.sh --no-install        -> Habilita el servicio y firewall omitiendo la descarga de paquetes DNF5
#   ./cockpit.sh --help              -> Muestra la ayuda interactiva

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

show_help() {
    cat <<EOF
🌐 Administrador de Consola Web Cockpit - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala Cockpit con módulos avanzados, activa cockpit.socket y configura Firewalld.
  --status, -s           Muestra el estado de ejecución, puertos, reglas de firewall y módulos disponibles.
  --open, -o             Abre la interfaz web de Cockpit en el navegador predeterminado (https://localhost:9090).
  --start                Inicia cockpit.socket en systemd.
  --stop                 Detiene cockpit.socket y cockpit.service.
  --disable              Deshabilita el socket y retira el servicio de Firewalld.
  --no-install           Habilita socket y firewall omitiendo la descarga de paquetes DNF5.
  --help, -h             Muestra este mensaje de ayuda.

Módulos integrados:
  • Podman (cockpit-podman):          Gestión visual de contenedores, pods e imágenes.
  • Máquinas Virtuales (machines):    Gestión de VMs en KVM / QEMU y libvirt.
  • Almacenamiento (storaged):        Salud SMART de SSDs/NVMe, particionado, LVM y RAID.
  • Redes (networkmanager):           Monitoreo de interfaces de red, IP y tráfico.
  • Seguridad (selinux):              Análisis de políticas y solución guiada de alertas SELinux.
  • Archivos (files):                 Explorador y gestor de archivos web.
  • Diagnóstico (sosreport):          Generación de reportes técnicos del sistema.
EOF
}

# 1. Mostrar estado de Cockpit
show_status() {
    local SOCK_STAT SERV_STAT ENAB_STAT
    SOCK_STAT=$(systemctl is-active cockpit.socket 2>/dev/null || true)
    [ -z "$SOCK_STAT" ] && SOCK_STAT="inactivo"
    SERV_STAT=$(systemctl is-active cockpit.service 2>/dev/null || true)
    [ -z "$SERV_STAT" ] && SERV_STAT="inactivo"
    ENAB_STAT=$(systemctl is-enabled cockpit.socket 2>/dev/null || true)
    [ -z "$ENAB_STAT" ] && ENAB_STAT="deshabilitado"

    echo "================================================================="
    echo "🔍 ESTADO DE CONSOLA WEB COCKPIT - FEDORA 44 (KDE PLASMA)"
    echo "================================================================="
    echo "• Socket de Systemd:    $SOCK_STAT"
    echo "• Servicio Web:         $SERV_STAT"
    echo "• Habilitado al inicio: $ENAB_STAT"
    echo "• Puerto de escucha:    9090 (HTTPS)"
    echo "• URL de acceso:        https://localhost:9090"
    
    if command -v firewall-cmd &>/dev/null && systemctl is-active firewalld &>/dev/null; then
        local FW_STATUS="No"
        if firewall-cmd --list-services 2>/dev/null | grep -qw "cockpit"; then
            FW_STATUS="Habilitado (Zona activa)"
        elif firewall-cmd --zone=FedoraWorkstation --list-services 2>/dev/null | grep -qw "cockpit"; then
            FW_STATUS="Habilitado (FedoraWorkstation)"
        fi
        echo "• Regla en Firewalld:  $FW_STATUS"
    else
        echo "• Regla en Firewalld:  Firewalld no está activo"
    fi

    echo ""
    echo "📦 Módulos de Cockpit instalados:"
    rpm -qa "cockpit*" 2>/dev/null | sort | sed 's/^/  ✓ /' || echo "  Ningún módulo instalado."
    echo "================================================================="
}

# 2. Instalación de paquetes de Cockpit y módulos avanzados
install_cockpit() {
    echo "📦 [1/3] Instalando Cockpit y módulos avanzados vía DNF5..."
    $SUDO dnf5 install -y \
        cockpit \
        cockpit-bridge \
        cockpit-system \
        cockpit-ws \
        cockpit-podman \
        cockpit-machines \
        cockpit-storaged \
        cockpit-networkmanager \
        cockpit-selinux \
        cockpit-files \
        cockpit-sosreport 2>/dev/null || $SUDO dnf5 install -y cockpit cockpit-podman cockpit-machines cockpit-storaged
    echo "✅ Paquetes y módulos de Cockpit instalados con éxito."
}

# 3. Habilitar socket bajo demanda en Systemd
enable_socket() {
    echo "⚡ [2/3] Habilitando cockpit.socket bajo demanda (consumo 0 en reposo)..."
    $SUDO systemctl enable --now cockpit.socket
    echo "✅ Socket de Cockpit habilitado y escuchando en el puerto 9090."
}

# 4. Configurar reglas de firewall
configure_firewall() {
    echo "🛡️ [3/3] Configurando permisos de red en Firewalld para el puerto 9090..."
    if command -v firewall-cmd &>/dev/null && systemctl is-active firewalld &>/dev/null; then
        $SUDO firewall-cmd --permanent --zone=FedoraWorkstation --add-service=cockpit 2>/dev/null || \
        $SUDO firewall-cmd --permanent --add-service=cockpit 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
        echo "✅ Reglas de Firewalld aplicadas."
    else
        echo "ℹ️ Firewalld no está activo; omitiendo configuración de reglas de red."
    fi
}

# 5. Abrir Cockpit en el navegador
open_cockpit() {
    local URL="https://localhost:9090"
    echo "🌐 Abriendo Cockpit en tu navegador predeterminado ($URL)..."
    if ! systemctl is-active cockpit.socket &>/dev/null; then
        echo "ℹ️ El socket no estaba activo. Iniciando cockpit.socket..."
        $SUDO systemctl start cockpit.socket
    fi
    if command -v xdg-open &>/dev/null; then
        xdg-open "$URL" &>/dev/null &
    elif command -v kioexec &>/dev/null; then
        kioexec "$URL" &>/dev/null &
    else
        echo "💡 Abre manualmente en tu navegador: $URL"
    fi
}

# 6. Detener servicio y socket
stop_cockpit() {
    echo "🛑 Deteniendo cockpit.socket y cockpit.service..."
    $SUDO systemctl stop cockpit.service cockpit.socket 2>/dev/null || true
    echo "✅ Cockpit detenido."
}

# 7. Deshabilitar por completo
disable_cockpit() {
    echo "🛑 Deshabilitando Cockpit de Systemd y Firewalld..."
    $SUDO systemctl disable --now cockpit.socket cockpit.service 2>/dev/null || true
    if command -v firewall-cmd &>/dev/null && systemctl is-active firewalld &>/dev/null; then
        $SUDO firewall-cmd --permanent --zone=FedoraWorkstation --remove-service=cockpit 2>/dev/null || \
        $SUDO firewall-cmd --permanent --remove-service=cockpit 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
    fi
    echo "✅ Cockpit deshabilitado."
}

# Procesar argumentos
case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --open|-o|open)
        open_cockpit
        exit 0
        ;;
    --start|start)
        echo "⚡ Iniciando cockpit.socket..."
        $SUDO systemctl start cockpit.socket
        echo "✅ Cockpit iniciado. Accede a: https://localhost:9090"
        ;;
    --stop|stop)
        stop_cockpit
        ;;
    --disable|disable)
        disable_cockpit
        ;;
    --no-install)
        echo "================================================================="
        echo "🌐 ACTIVANDO COCKPIT EN FEDORA 44 [SIN DESCARGA DE PAQUETES]"
        echo "================================================================="
        enable_socket
        configure_firewall
        echo ""
        show_status
        ;;
    "")
        echo "================================================================="
        echo "🌐 CONFIGURADOR DE CONSOLA WEB COCKPIT - FEDORA 44 (KDE PLASMA)"
        echo "================================================================="
        install_cockpit
        enable_socket
        configure_firewall
        echo ""
        echo "================================================================="
        echo "✅ Cockpit instalado y configurado correctamente."
        echo "🌐 Accede desde tu navegador en: https://localhost:9090"
        echo "💡 Inicia sesión con tu usuario de Fedora ($USER) y contraseña."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
