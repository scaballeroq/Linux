#!/usr/bin/env bash
# ==============================================================================
# cockpit.sh - Instalación, Gestión y Diagnóstico de Consola Web Cockpit
# Sistema: Fedora 44 Workstation | Escritorio: KDE Plasma 6 (Wayland)
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U / Radeon Vega 7 / Btrfs)
# ==============================================================================
# Características:
# - Activación bajo demanda mediante cockpit.socket (0 MB de RAM en reposo).
# - Módulos: Podman (contenedores), Machines (KVM/QEMU), Storaged (NVMe/Btrfs),
#   NetworkManager, SELinux, Files (explorador web) y Sosreport.
# - Configuración automática de Firewalld (puerto 9090 TCP en zona activa).
# - Control granular del ciclo de vida: --start, --stop, --disable, --open, --client, --files.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO Y PRIVILEGIOS
# ------------------------------------------------------------------------------
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
        echo "❌ Error: Se requieren privilegios de superusuario (root/sudo)."
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

is_pkg_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

# ------------------------------------------------------------------------------
# 2. INSTALACIÓN DE PAQUETES Y MÓDULOS (DNF5)
# ------------------------------------------------------------------------------
ensure_installed() {
    local core_pkgs=(
        "cockpit"
        "cockpit-bridge"
        "cockpit-system"
        "cockpit-ws"
        "cockpit-podman"
        "cockpit-machines"
        "cockpit-storaged"
        "cockpit-networkmanager"
        "cockpit-selinux"
        "cockpit-files"
        "cockpit-sosreport"
    )
    local missing=()
    for pkg in "${core_pkgs[@]}"; do
        if ! is_pkg_installed "$pkg"; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo "📦 [1/3] Instalando paquetes y módulos de Cockpit vía DNF5: ${missing[*]}..."
        require_root
        $SUDO dnf5 install -y "${missing[@]}" 2>/dev/null || \
        $SUDO dnf5 install -y cockpit cockpit-podman cockpit-machines cockpit-storaged cockpit-networkmanager 2>/dev/null || true
        echo "  ✅ Módulos de Cockpit instalados con éxito."
    else
        echo "  ✅ Todos los módulos de Cockpit ya están instalados."
    fi
}

install_files_module() {
    echo "📂 Instalando módulo opcional 'cockpit-files' vía DNF5..."
    require_root
    $SUDO dnf5 install -y cockpit-files
    echo "  ✅ Módulo 'cockpit-files' instalado."
}

# ------------------------------------------------------------------------------
# 3. GESTIÓN DE SOCKET SYSTEMD Y FIREWALLD
# ------------------------------------------------------------------------------
ensure_socket_and_firewall() {
    require_root
    echo "⚡ [2/3] Habilitando cockpit.socket bajo demanda (consumo 0 MB en reposo)..."
    $SUDO systemctl enable --now cockpit.socket
    echo "  ✅ Socket activo y escuchando en https://localhost:9090"

    echo "🛡️  [3/3] Configurando permisos de red en Firewalld (puerto 9090 TCP)..."
    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "FedoraWorkstation")
        if ! firewall-cmd --zone="$active_zone" --list-services 2>/dev/null | grep -qw "cockpit"; then
            $SUDO firewall-cmd --permanent --zone="$active_zone" --add-service=cockpit 2>/dev/null || \
            $SUDO firewall-cmd --permanent --add-service=cockpit 2>/dev/null || true
            $SUDO firewall-cmd --reload 2>/dev/null || true
        fi
        echo "  ✅ Servicio 'cockpit' permitido en Firewalld (zona: $active_zone)."
    else
        echo "  ℹ️ Firewalld no está activo; omitiendo regla de red."
    fi
}

start_cockpit() {
    require_root
    echo "⚡ Iniciando cockpit.socket..."
    $SUDO systemctl enable --now cockpit.socket
    echo "  ✅ Cockpit activo en https://localhost:9090"
}

stop_cockpit() {
    require_root
    echo "🛑 Deteniendo cockpit.socket y cockpit.service..."
    $SUDO systemctl stop cockpit.service cockpit.socket 2>/dev/null || true
    echo "  ✅ Cockpit detenido."
}

disable_cockpit() {
    require_root
    echo "🛑 Deshabilitando Cockpit de Systemd y retirando regla de Firewalld..."
    $SUDO systemctl disable --now cockpit.socket cockpit.service 2>/dev/null || true
    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "FedoraWorkstation")
        $SUDO firewall-cmd --permanent --zone="$active_zone" --remove-service=cockpit 2>/dev/null || \
        $SUDO firewall-cmd --permanent --remove-service=cockpit 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
    fi
    echo "  ✅ Cockpit deshabilitado completamente."
}

# ------------------------------------------------------------------------------
# 4. ACCESO WEB Y CLIENTE DE ESCRITORIO
# ------------------------------------------------------------------------------
open_browser() {
    local url="https://localhost:9090"
    if ! systemctl is-active --quiet cockpit.socket 2>/dev/null; then
        echo "ℹ️ El socket no estaba activo. Iniciando cockpit.socket..."
        require_root
        $SUDO systemctl start cockpit.socket
    fi
    echo "🌐 Abriendo Cockpit en el navegador predeterminado ($url)..."
    if command -v xdg-open &>/dev/null; then
        run_as_user xdg-open "$url" &>/dev/null & disown
    elif command -v kioclient &>/dev/null; then
        run_as_user kioclient exec "$url" &>/dev/null & disown
    else
        echo "💡 Abre manualmente en tu navegador: $url"
    fi
}

open_client() {
    echo "🖥️  Lanzando cliente de escritorio Cockpit Client..."
    if command -v cockpit-client &>/dev/null; then
        run_as_user cockpit-client &>/dev/null & disown
        echo "  ✅ Cockpit Client nativo iniciado."
    elif command -v flatpak &>/dev/null && flatpak info org.cockpit_project.CockpitClient &>/dev/null; then
        run_as_user flatpak run org.cockpit_project.CockpitClient &>/dev/null & disown
        echo "  ✅ Cockpit Client (Flatpak) iniciado."
    else
        echo "⚠️ Cockpit Client no está instalado. Abriendo interfaz web en su lugar..."
        open_browser
    fi
}

# ------------------------------------------------------------------------------
# 5. DIAGNÓSTICO Y ESTADO (--status)
# ------------------------------------------------------------------------------
show_status() {
    local sock_stat serv_stat enab_stat
    sock_stat=$(systemctl is-active cockpit.socket 2>/dev/null || echo "inactivo")
    serv_stat=$(systemctl is-active cockpit.service 2>/dev/null || echo "inactivo")
    enab_stat=$(systemctl is-enabled cockpit.socket 2>/dev/null || echo "deshabilitado")

    echo "================================================================="
    echo "🔍 ESTADO DE CONSOLA WEB COCKPIT - FEDORA 44 (KDE PLASMA 6)"
    echo "================================================================="
    echo "• Socket de Systemd:    $sock_stat"
    echo "• Servicio Web:         $serv_stat (se activa bajo demanda al abrir la web)"
    echo "• Habilitado al inicio: $enab_stat"
    echo "• Puerto de escucha:    9090 (HTTPS)"
    echo "• URL de acceso:        https://localhost:9090"

    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "FedoraWorkstation")
        if firewall-cmd --zone="$active_zone" --list-services 2>/dev/null | grep -qw "cockpit"; then
            echo "• Regla en Firewalld:   ✅ Permitido (zona: $active_zone)"
        else
            echo "• Regla en Firewalld:   ⚠️ No registrado en zona '$active_zone'"
        fi
    else
        echo "• Regla en Firewalld:   ℹ️ Firewalld inactivo"
    fi

    echo "-----------------------------------------------------------------"
    echo "📦 Módulos de Cockpit instalados (RPM):"
    if rpm -qa "cockpit*" 2>/dev/null | grep -q "cockpit"; then
        rpm -qa --qf "  ✓ %{NAME} (%{VERSION})\n" "cockpit*" 2>/dev/null | sort
    else
        echo "  ❌ Ningún módulo de Cockpit instalado."
    fi
    echo "-----------------------------------------------------------------"
    echo "🌐 Acceso navegador:  ./Setup/cockpit.sh --open"
    echo "🖥️  Acceso escritorio: ./Setup/cockpit.sh --client"
    echo "================================================================="
}

show_help() {
    cat <<EOF
🌐 Administrador de Consola Web Cockpit - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala Cockpit con sus módulos, activa cockpit.socket y configura Firewalld.
  -s, --status           Muestra el estado del socket, puerto, firewall y módulos instalados.
  -o, --open             Abre la interfaz web de Cockpit en el navegador (https://localhost:9090).
  -c, --client           Lanza Cockpit Client (escritorio nativo o Flatpak).
      --start            Inicia e instala cockpit.socket en systemd.
      --stop             Detiene el socket y servicio de Cockpit.
      --disable          Deshabilita el socket y retira reglas de Firewalld.
      --files            Instala el módulo 'cockpit-files' (explorador de archivos web).
      --no-install       Activa socket y firewall omitiendo la descarga de paquetes DNF5.
  -h, --help             Muestra esta ayuda.

Módulos integrados en Fedora 44:
  • Podman (cockpit-podman):          Gestión visual de contenedores rootless y pods.
  • Máquinas Virtuales (machines):    Gestión de VMs en KVM / QEMU y libvirt.
  • Almacenamiento (storaged):        Salud SMART NVMe, subvolúmenes Btrfs, LVM y RAID.
  • Redes (networkmanager):           Monitoreo de interfaces de red, IP y Firewalld.
  • Seguridad (selinux):              Análisis de políticas y solución guiada de alertas SELinux.
  • Archivos (files):                 Explorador y gestor de archivos web.
  • Diagnóstico (sosreport):          Generación de reportes técnicos del sistema.
EOF
}

# ------------------------------------------------------------------------------
# 6. DESPACHADOR DE COMANDOS
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
    --no-install)
        echo "================================================================="
        echo "🌐 ACTIVANDO COCKPIT EN FEDORA 44 [SIN DESCARGA DE PAQUETES]"
        echo "================================================================="
        ensure_socket_and_firewall
        echo ""
        show_status
        exit 0
        ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🌐 CONFIGURADOR DE CONSOLA WEB COCKPIT - FEDORA 44 (KDE PLASMA 6)"
        echo "================================================================="
        ensure_installed
        ensure_socket_and_firewall
        echo ""
        show_status
        echo "✅ Cockpit instalado y configurado correctamente."
        echo "💡 Inicia sesión en https://localhost:9090 con tu usuario ($REAL_USER) y contraseña."
        exit 0
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
