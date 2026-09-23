#!/usr/bin/env bash
# ==============================================================================
# cockpit.sh - Consola de Administración Web Cockpit y Cliente de Escritorio
# Sistema: openSUSE Tumbleweed | Escritorio: KDE Plasma 6 (Wayland)
# ==============================================================================
# Características:
# - Detección inteligente de paquetes instalados por defecto en openSUSE.
# - Modo rootless e idempotente: no solicita sudo si Cockpit y el socket ya están listos.
# - Soporte para Cockpit Client Launcher (lanzador nativo de escritorio openSUSE).
# - Diagnóstico detallado del socket, puerto 9090, reglas de Firewalld y módulos.
# - Control granular del ciclo de vida: --start, --stop, --disable, --open, --client.
# - Módulo opcional: --files (cockpit-files, explorador web de archivos).
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
    "cockpit-snapshots"
    "cockpit-storaged"
    "cockpit-networkmanager"
    "cockpit-firewalld"
)

ALL_MODULES=(
    "cockpit-bridge:Puente de comunicación entre navegador y sistema"
    "cockpit-ws:Servidor web y autenticación HTTPS (puerto 9090)"
    "cockpit-system:Métricas de CPU, memoria y servicios systemd"
    "cockpit-podman:Gestión visual de contenedores Podman y pods"
    "cockpit-machines:Gestión de máquinas virtuales KVM / QEMU"
    "cockpit-snapshots:Gestión visual de snapshots Snapper en Btrfs"
    "cockpit-storaged:Salud SMART de SSD/NVMe, particionado y RAID"
    "cockpit-networkmanager:Monitoreo de interfaces y tráfico de red"
    "cockpit-firewalld:Inspección y configuración de Firewalld"
    "cockpit-client-launcher:Lanzador nativo de escritorio de openSUSE"
    "cockpit-packages:Gestión y actualización de paquetes RPM"
    "cockpit-repos:Gestión de repositorios oficiales de openSUSE"
    "cockpit-bootloader:Configuración de arranque y kernel en GRUB2"
    "cockpit-files:Explorador de archivos web (Opcional)"
)

# ------------------------------------------------------------------------------
# 3. VERIFICACIÓN E INSTALACIÓN INTELIGENTE
# ------------------------------------------------------------------------------
ensure_installed() {
    local missing=()
    for pkg in "${CORE_PACKAGES[@]}"; do
        if ! rpm -q "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "📦 Instalando componentes faltantes de Cockpit vía Zypper (${missing[*]})..."
        require_root
        $SUDO zypper --non-interactive install -y "${missing[@]}"
    else
        echo "  ✅ Cockpit y sus módulos principales ya están instalados (proporcionados por openSUSE Tumbleweed)."
    fi
}

install_files_module() {
    if rpm -q cockpit-files &>/dev/null; then
        echo "  ✅ El módulo cockpit-files ya está instalado en el sistema."
        return 0
    fi
    echo "📦 Instalando módulo opcional cockpit-files (explorador de archivos web)..."
    require_root
    $SUDO zypper --non-interactive install -y cockpit-files
    echo "  ✅ cockpit-files instalado correctamente."
}

# ------------------------------------------------------------------------------
# 4. GESTIÓN DE SERVICIOS Y SEGURIDAD (SYSTEMD + FIREWALLD)
# ------------------------------------------------------------------------------
ensure_socket_and_firewall() {
    local need_socket=false
    local need_fw=false

    if [ "$(systemctl is-active cockpit.socket 2>/dev/null)" != "active" ] || [ "$(systemctl is-enabled cockpit.socket 2>/dev/null)" != "enabled" ]; then
        need_socket=true
    fi

    if ! firewall-cmd --list-services 2>/dev/null | grep -q '\bcockpit\b'; then
        need_fw=true
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

    if [ "$need_fw" = "true" ]; then
        echo "🛡️  Configurando servicio 'cockpit' en Firewalld (9090/tcp)..."
        require_root
        $SUDO firewall-cmd --permanent --add-service=cockpit 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
        echo "  ✅ Servicio 'cockpit' habilitado en Firewalld."
    else
        echo "  ✅ Servicio 'cockpit' ya está habilitado en Firewalld (puerto 9090/tcp permitido)."
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
    $SUDO firewall-cmd --permanent --remove-service=cockpit 2>/dev/null || true
    $SUDO firewall-cmd --reload 2>/dev/null || true
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
    if command -v cockpit-client-launcher &>/dev/null; then
        echo "🚀 Lanzando Cockpit Client Launcher (aplicación nativa de escritorio openSUSE)..."
        if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
            sudo -u "$SUDO_USER" cockpit-client-launcher &>/dev/null &
        else
            cockpit-client-launcher &>/dev/null &
        fi
    else
        echo "⚠️ cockpit-client-launcher no encontrado. Abriendo en el navegador web..."
        open_browser
    fi
}

show_status() {
    local socket_state srv_state boot_state
    socket_state=$(systemctl is-active cockpit.socket 2>/dev/null || echo 'inactivo')
    srv_state=$(systemctl is-active cockpit.service 2>/dev/null || true)
    boot_state=$(systemctl is-enabled cockpit.socket 2>/dev/null || echo 'deshabilitado')

    echo "================================================================="
    echo "🔍 ESTADO DE CONSOLA WEB COCKPIT - OPENSUSE TUMBLEWEED"
    echo "================================================================="
    echo "• Socket systemd:        ${socket_state:-inactivo}"
    echo "• Servicio systemd:      ${srv_state:-inactivo}"
    echo "• Habilitado en boot:    ${boot_state:-deshabilitado}"
    echo "• Puerto 9090 (ss):      $(if ss -tlpn 2>/dev/null | grep -q ':9090 '; then echo '✅ Escuchando (LISTEN)'; else echo '❌ Cerrado'; fi)"
    
    local fw_status="❌ No presente"
    if firewall-cmd --list-services 2>/dev/null | grep -q '\bcockpit\b'; then
        fw_status="✅ Habilitada (servicio cockpit en zona predeterminada)"
    fi
    echo "• Regla Firewalld:       $fw_status"
    
    local launcher_status="❌ No disponible"
    if command -v cockpit-client-launcher &>/dev/null; then
        launcher_status="✅ Instalado y disponible (/usr/bin/cockpit-client-launcher)"
    fi
    echo "• Cliente de escritorio: $launcher_status"
    echo "-----------------------------------------------------------------"
    echo "📦 Módulos instalados:"
    for mod in "${ALL_MODULES[@]}"; do
        local mod_name="${mod%%:*}"
        local mod_desc="${mod##*:}"
        local mod_status="❌ No"
        if rpm -q "$mod_name" &>/dev/null; then
            mod_status="✅ Instalado"
        fi
        printf "  - %-26s %-14s (%s)\n" "$mod_name:" "$mod_status" "$mod_desc"
    done
    echo "================================================================="
    echo "🌐 Acceso web:       https://localhost:9090"
    if command -v cockpit-client-launcher &>/dev/null; then
        echo "🖥️  Acceso de escritorio: cockpit-client-launcher (o en el menú de aplicaciones de KDE)"
    fi
    echo "================================================================="
}

show_help() {
    cat <<EOF
Uso: $(basename "$0") [OPCIÓN]

Administrador de la Consola Web Cockpit y Cockpit Client Launcher
para openSUSE Tumbleweed y KDE Plasma 6.

OPCIONES:
  (sin argumentos)       Verificación inteligente: asegura componentes, socket y cortafuegos.
  -s, --status           Muestra el estado del socket, puerto, firewall y módulos instalados.
  -o, --open             Abre la interfaz web de Cockpit en el navegador (https://localhost:9090).
  -c, --client           Lanza Cockpit Client Launcher (aplicación nativa de escritorio openSUSE).
  --start                Inicia e instala cockpit.socket en systemd.
  --stop                 Detiene el socket y servicio de Cockpit.
  --disable              Deshabilita el socket y retira el servicio de Firewalld.
  --files                Instala el módulo opcional 'cockpit-files' (explorador web).
  -h, --help             Muestra esta ayuda.

MÓDULOS INTEGRADOS POR OPENSUSE:
  • Podman (cockpit-podman):          Gestión visual de contenedores, pods e imágenes.
  • Máquinas Virtuales (machines):    Gestión de VMs en KVM / QEMU y libvirt.
  • Instantáneas Snapper (snapshots): Gestión visual de snapshots y rollbacks Btrfs.
  • Almacenamiento (storaged):        Salud SMART de SSD/NVMe, particionado y RAID.
  • Redes (networkmanager):           Monitoreo de interfaces de red, IP y tráfico.
  • Cortafuegos (firewalld):          Inspección y gestión de zonas y reglas activas.
  • Actualizaciones (packages):       Inspección de parches y actualización con Zypper.
  • Repositorios (repos):             Gestión de repositorios oficiales de openSUSE.
  • Arranque (bootloader):            Configuración de GRUB2 y opciones de kernel.
  • Escritorio (client-launcher):     Aplicación gráfica nativa para escritorio.
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
        echo "🌐 CONSOLA DE ADMINISTRACIÓN COCKPIT (openSUSE Tumbleweed)"
        echo "================================================================="
        ensure_installed
        ensure_socket_and_firewall
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Cockpit verificado y listo para usar."
        echo "💡 Acceso web:        https://localhost:9090"
        if command -v cockpit-client-launcher &>/dev/null; then
            echo "💡 Acceso escritorio: just cockpit --client (o 'Cockpit Client Launcher')"
        fi
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
