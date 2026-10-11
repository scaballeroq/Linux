#!/usr/bin/env bash
# ==============================================================================
# cockpit.sh - Consola de Administración Web Cockpit y Cliente de Escritorio
# Sistema: Debian Testing (Trixie/Sid) | Escritorio: KDE Plasma 6 (Wayland)
# ==============================================================================
# Características:
# - Detección inteligente e instalación idempotente de paquetes en Debian vía APT.
# - Modo rootless e idempotente: no solicita sudo si Cockpit y el socket ya están listos.
# - Diagnóstico detallado del socket, puerto 9090, reglas de Firewalld / UFW y módulos.
# - Control granular del ciclo de vida: --start, --stop, --disable, --open, --client.
# - Integración de módulos: Podman, Machines (KVM/QEMU), Storaged, NetworkManager, PackageKit.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO Y PERMISOS
# ------------------------------------------------------------------------------
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

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

# ------------------------------------------------------------------------------
# 2. DEFINICIÓN DE PAQUETES Y MÓDULOS
# ------------------------------------------------------------------------------
CORE_PACKAGES=(
    "cockpit"
    "cockpit-bridge"
    "cockpit-ws"
    "cockpit-system"
    "cockpit-podman"
    "cockpit-machines"
    "cockpit-packagekit"
    "cockpit-storaged"
    "cockpit-networkmanager"
    "cockpit-sosreport"
    "udisks2"
    "network-manager"
    "lm-sensors"
)

ALL_MODULES=(
    "cockpit-bridge:Puente de comunicación entre navegador y sistema"
    "cockpit-ws:Servidor web y autenticación HTTPS (puerto 9090)"
    "cockpit-system:Métricas de CPU, memoria y servicios systemd"
    "cockpit-podman:Gestión visual de contenedores Podman y pods"
    "cockpit-machines:Gestión de máquinas virtuales KVM / QEMU"
    "cockpit-packagekit:Gestión e inspección de actualizaciones de paquetes APT"
    "cockpit-storaged:Salud SMART de SSD/NVMe, particionado y RAID"
    "cockpit-networkmanager:Monitoreo de interfaces y tráfico de red"
    "cockpit-sosreport:Generación de diagnósticos e informes de soporte"
    "cockpit-pcp:Métricas avanzadas de rendimiento con Performance Co-Pilot"
    "cockpit-files:Explorador de archivos web (Opcional)"
)

is_pkg_installed() {
    local pkg="$1"
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
}

# ------------------------------------------------------------------------------
# 3. VERIFICACIÓN E INSTALACIÓN INTELIGENTE
# ------------------------------------------------------------------------------
ensure_installed() {
    local missing=()
    for pkg in "${CORE_PACKAGES[@]}"; do
        if ! is_pkg_installed "$pkg"; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "📦 Instalando componentes faltantes de Cockpit vía APT (${missing[*]})..."
        require_root
        export DEBIAN_FRONTEND=noninteractive
        $SUDO apt-get update -qq
        $SUDO apt-get install -y "${missing[@]}"
        echo "  ✅ Paquetes de Cockpit instalados correctamente."
    else
        echo "  ✅ Cockpit y sus módulos principales ya están instalados."
    fi
}

install_files_module() {
    if is_pkg_installed "cockpit-files"; then
        echo "  ✅ El módulo cockpit-files ya está instalado en el sistema."
        return 0
    fi
    echo "📦 Comprobando disponibilidad del módulo cockpit-files..."
    require_root
    export DEBIAN_FRONTEND=noninteractive
    if $SUDO apt-get install -y cockpit-files 2>/dev/null; then
        echo "  ✅ cockpit-files instalado correctamente vía APT."
    else
        echo "  ⚠️ cockpit-files no está en repositorios APT oficiales. Intentando Flatpak o paquete alternativo..."
        echo "  💡 Puedes instalarlo descargando el paquete oficial .deb desde el repositorio upstream de Cockpit Project."
    fi
}

# ------------------------------------------------------------------------------
# 4. GESTIÓN DE SERVICIOS Y SEGURIDAD (SYSTEMD + FIREWALL)
# ------------------------------------------------------------------------------
ensure_socket_and_firewall() {
    local need_socket=false

    if [ "$(systemctl is-active cockpit.socket 2>/dev/null)" != "active" ] || [ "$(systemctl is-enabled cockpit.socket 2>/dev/null)" != "enabled" ]; then
        need_socket=true
    fi

    if [ "$need_socket" = "true" ]; then
        echo "⚡ Habilitando e iniciando cockpit.socket en systemd..."
        require_root
        $SUDO systemctl daemon-reload
        $SUDO systemctl enable --now cockpit.socket
        echo "  ✅ cockpit.socket habilitado y en ejecución."
    else
        echo "  ✅ cockpit.socket ya está habilitado y en ejecución (puerto 9090)."
    fi

    # Configuración de Firewall (Firewalld o UFW)
    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        if ! firewall-cmd --list-services 2>/dev/null | grep -q '\bcockpit\b'; then
            echo "🛡️  Configurando servicio 'cockpit' en Firewalld (9090/tcp)..."
            require_root
            $SUDO firewall-cmd --permanent --add-service=cockpit 2>/dev/null || true
            $SUDO firewall-cmd --reload 2>/dev/null || true
            echo "  ✅ Servicio 'cockpit' habilitado en Firewalld."
        else
            echo "  ✅ Servicio 'cockpit' ya está habilitado en Firewalld (puerto 9090/tcp permitido)."
        fi
    elif command -v ufw &>/dev/null && systemctl is-active --quiet ufw 2>/dev/null; then
        echo "🛡️  Verificando regla de Cockpit en UFW..."
        require_root
        $SUDO ufw limit 9090/tcp 2>/dev/null || $SUDO ufw allow 9090/tcp 2>/dev/null || true
        echo "  ✅ Regla para puerto 9090/tcp activa en UFW."
    fi
}

start_cockpit() {
    require_root
    echo "🚀 Iniciando cockpit.socket..."
    $SUDO systemctl enable --now cockpit.socket
    echo "✅ cockpit.socket activo y escuchando."
}

stop_cockpit() {
    require_root
    echo "🛑 Deteniendo servicios de Cockpit..."
    $SUDO systemctl stop cockpit.service cockpit.socket 2>/dev/null || true
    echo "✅ Cockpit detenido."
}

disable_cockpit() {
    require_root
    echo "🔒 Deshabilitando Cockpit y retirando reglas de firewall..."
    $SUDO systemctl disable --now cockpit.socket cockpit.service 2>/dev/null || true
    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        $SUDO firewall-cmd --permanent --remove-service=cockpit 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
    fi
    if command -v ufw &>/dev/null && systemctl is-active --quiet ufw 2>/dev/null; then
        $SUDO ufw delete allow 9090/tcp 2>/dev/null || true
        $SUDO ufw delete limit 9090/tcp 2>/dev/null || true
    fi
    echo "✅ Cockpit deshabilitado."
}

# ------------------------------------------------------------------------------
# 5. LANZADORES Y DIAGNÓSTICO
# ------------------------------------------------------------------------------
open_browser() {
    local target_url="https://localhost:9090"
    echo "🌐 Abriendo $target_url en el navegador web..."
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$SUDO_USER" xdg-open "$target_url" &>/dev/null &
    else
        xdg-open "$target_url" &>/dev/null &
    fi
}

open_client() {
    if command -v cockpit-client &>/dev/null; then
        echo "🚀 Lanzando Cockpit Client..."
        if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
            sudo -u "$SUDO_USER" cockpit-client &>/dev/null &
        else
            cockpit-client &>/dev/null &
        fi
    elif flatpak list 2>/dev/null | grep -qi "org.cockpit_project.CockpitClient"; then
        echo "🚀 Lanzando Cockpit Client vía Flatpak..."
        if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
            sudo -u "$SUDO_USER" flatpak run org.cockpit_project.CockpitClient &>/dev/null &
        else
            flatpak run org.cockpit_project.CockpitClient &>/dev/null &
        fi
    else
        echo "⚠️ cockpit-client no encontrado. Abriendo en el navegador web..."
        open_browser
    fi
}

show_status() {
    local socket_state srv_state boot_state
    socket_state=$(systemctl is-active cockpit.socket 2>/dev/null || echo 'inactivo')
    srv_state=$(systemctl is-active cockpit.service 2>/dev/null || true)
    boot_state=$(systemctl is-enabled cockpit.socket 2>/dev/null || echo 'deshabilitado')

    echo "================================================================="
    echo "🔍 ESTADO DE CONSOLA WEB COCKPIT - DEBIAN TESTING"
    echo "================================================================="
    echo "• Socket systemd:        ${socket_state:-inactivo}"
    echo "• Servicio systemd:      ${srv_state:-inactivo}"
    echo "• Habilitado en boot:    ${boot_state:-deshabilitado}"
    echo "• Puerto 9090 (ss):      $(if ss -tlpn 2>/dev/null | grep -q ':9090 '; then echo '✅ Escuchando (LISTEN)'; else echo '❌ Cerrado'; fi)"
    
    local fw_status="❌ Sin cortafuegos activo"
    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        if firewall-cmd --list-services 2>/dev/null | grep -q '\bcockpit\b'; then
            fw_status="✅ Habilitada (servicio cockpit en Firewalld)"
        else
            fw_status="⚠️ Firewalld activo pero regla 'cockpit' no permitida"
        fi
    elif command -v ufw &>/dev/null && systemctl is-active --quiet ufw 2>/dev/null; then
        if ufw status 2>/dev/null | grep -q '9090'; then
            fw_status="✅ Habilitada (puerto 9090 en UFW)"
        else
            fw_status="⚠️ UFW activo pero regla 9090 no permitida"
        fi
    fi
    echo "• Regla de Firewall:     $fw_status"
    
    local launcher_status="❌ No instalado"
    if command -v cockpit-client &>/dev/null; then
        launcher_status="✅ Instalado nativo (/usr/bin/cockpit-client)"
    elif flatpak list 2>/dev/null | grep -qi "org.cockpit_project.CockpitClient"; then
        launcher_status="✅ Instalado vía Flatpak (org.cockpit_project.CockpitClient)"
    fi
    echo "• Cliente de escritorio: $launcher_status"
    echo "-----------------------------------------------------------------"
    echo "📦 Módulos instalados:"
    for mod in "${ALL_MODULES[@]}"; do
        local mod_name="${mod%%:*}"
        local mod_desc="${mod##*:}"
        local mod_status="❌ No"
        if is_pkg_installed "$mod_name"; then
            mod_status="✅ Instalado"
        fi
        printf "  - %-26s %-14s (%s)\n" "$mod_name:" "$mod_status" "$mod_desc"
    done
    echo "================================================================="
    local local_ip
    local_ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || echo "127.0.0.1")
    echo "🌐 Acceso web local:   https://localhost:9090"
    echo "🌐 Acceso en tu red:   https://${local_ip}:9090"
    if command -v cockpit-client &>/dev/null || flatpak list 2>/dev/null | grep -qi "org.cockpit_project.CockpitClient"; then
        echo "🖥️  Acceso escritorio: cockpit.sh --client"
    fi
    echo "================================================================="
}

show_help() {
    cat <<EOF
Uso: $(basename "$0") [OPCIÓN]

Administrador de la Consola Web Cockpit y Cliente de Escritorio
para Debian Testing (Trixie/Sid) y KDE Plasma 6.

OPCIONES:
  (sin argumentos)       Verificación inteligente: asegura componentes, socket y cortafuegos.
  -s, --status           Muestra el estado del socket, puerto, firewall y módulos instalados.
  -o, --open             Abre la interfaz web de Cockpit en el navegador (https://localhost:9090).
  -c, --client           Lanza Cockpit Client (escritorio nativo o Flatpak).
  --start                Inicia e instala cockpit.socket en systemd.
  --stop                 Detiene el socket y servicio de Cockpit.
  --disable              Deshabilita el socket y retira reglas de firewall.
  --files                Instala el módulo opcional 'cockpit-files' (explorador web).
  -h, --help             Muestra esta ayuda.

MÓDULOS INTEGRADOS:
  • Podman (cockpit-podman):          Gestión visual de contenedores, pods e imágenes.
  • Máquinas Virtuales (machines):    Gestión de VMs en KVM / QEMU y libvirt.
  • Almacenamiento (storaged):        Salud SMART de SSD/NVMe, particionado y RAID.
  • Redes (networkmanager):           Monitoreo de interfaces de red, IP y tráfico.
  • Actualizaciones (packagekit):     Inspección y actualización de paquetes APT.
  • Diagnósticos (sosreport):         Generación de informes para soporte y resolución de fallos.
EOF
}

# ------------------------------------------------------------------------------
# 6. PARSEO DE ARGUMENTOS Y FLUJO PRINCIPAL
# ------------------------------------------------------------------------------
case "${1:-}" in
    -s|--status|status)
        show_status
        exit 0
        ;;
    -o|--open|open)
        open_browser
        exit 0
        ;;
    -c|--client|client)
        open_client
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
    --files)
        install_files_module
        exit 0
        ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🌐 CONSOLA DE ADMINISTRACIÓN COCKPIT (Debian Testing)"
        echo "================================================================="
        ensure_installed
        ensure_socket_and_firewall
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Cockpit verificado y listo para usar."
        echo "💡 Acceso web:        https://localhost:9090"
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
