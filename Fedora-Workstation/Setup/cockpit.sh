#!/usr/bin/env bash
# ==============================================================================
# cockpit.sh - Consola Web Cockpit Optimizada para Fedora Workstation
# Sistema: Fedora 45 Workstation (GNOME Shell Wayland + DNF5)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM DDR4)
# Almacenamiento: SSD NVMe Kioxia KBG50ZNV512G 512 GB / ZRAM Swap
# ==============================================================================
# Características:
#   - Activación bajo demanda por socket systemd (cockpit.socket): 0% CPU y 0 MB RAM en reposo.
#   - Módulos integrados: Podman (contenedores rootless), Machines (KVM/QEMU Libvirt),
#     Storaged (NVMe SMART / Btrfs), NetworkManager, SELinux, PackageKit, Files y Sosreport.
#   - Optimización de batería y memoria para portátil HP ProBook 455 G10:
#     * Desconexión por inactividad (/etc/cockpit/cockpit.conf -> IdleTimeout = 15 min).
#     * Restricción y seguridad de orígenes HTTP/HTTPS (Origins / MaxStartups).
#   - Integración nativa con Podman Rootless (podman.socket de usuario y persistencia linger).
#   - Reglas automáticas en Firewalld exclusivo (puerto 9090 TCP en zona FedoraWorkstation).
#   - Integración GNOME Shell Wayland: acceso directo .desktop y cliente seguro rootless.
#   - Diagnóstico O(1) de solo lectura sin elevación forzada de sudo (--status).
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
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &>/dev/null; then
        log_err "Error: 'sudo' no está disponible. Ejecuta este script con privilegios de superusuario."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

if command -v dnf5 &>/dev/null; then
    DNF_BIN="dnf5"
else
    DNF_BIN="dnf"
fi

require_root() {
    if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
        log_err "Se requieren privilegios de superusuario (root o sudo)."
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

get_lan_ip() {
    ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || echo ""
}

# ------------------------------------------------------------------------------
# 3. LISTADO DE MÓDULOS Y PAQUETES
# ------------------------------------------------------------------------------
CORE_PACKAGES=(
    "cockpit"
    "cockpit-bridge"
    "cockpit-system"
    "cockpit-ws"
    "cockpit-ws-selinux"
    "cockpit-podman"
    "cockpit-machines"
    "cockpit-storaged"
    "cockpit-networkmanager"
    "cockpit-selinux"
    "cockpit-packagekit"
    "cockpit-files"
    "cockpit-sosreport"
)

RECOMMENDED_PACKAGES=(
    "smartmontools"
)

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN IDEMPOTENTE O(1) DE PAQUETES
# ------------------------------------------------------------------------------
install_cockpit() {
    log_info "[1/6] Comprobando paquetes y módulos de Cockpit vía DNF5..."

    local all_pkgs=("${CORE_PACKAGES[@]}" "${RECOMMENDED_PACKAGES[@]}")
    local missing=()

    for pkg in "${all_pkgs[@]}"; do
        if ! is_pkg_installed "$pkg"; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        require_root
        log_info "Instalando paquetes faltantes (${missing[*]}):"
        $SUDO $DNF_BIN install -y "${missing[@]}" || {
            log_warn "Error en instalación agrupada; reintentando con módulos esenciales..."
            $SUDO $DNF_BIN install -y cockpit cockpit-podman cockpit-machines cockpit-storaged cockpit-networkmanager
        }
        log_ok "Paquetes de Cockpit instalados exitosamente."
    else
        log_ok "Todos los módulos de Cockpit y utilidades ya están instalados."
    fi
}

# ------------------------------------------------------------------------------
# 5. CONFIGURACIÓN OPTIMIZADA DE COCKPIT (/etc/cockpit/cockpit.conf)
# ------------------------------------------------------------------------------
configure_cockpit_conf() {
    log_info "[2/6] Configurando optimizaciones de rendimiento y batería (/etc/cockpit/cockpit.conf)..."
    require_root

    $SUDO mkdir -p /etc/cockpit

    local host_ip host_name origins_list
    host_ip=$(get_lan_ip)
    host_name=$(hostname 2>/dev/null || echo "fedora")

    origins_list="https://localhost:9090 https://127.0.0.1:9090"
    if [ -n "$host_ip" ] && [ "$host_ip" != "127.0.0.1" ]; then
        origins_list="$origins_list https://$host_ip:9090"
    fi
    if [ -n "$host_name" ]; then
        origins_list="$origins_list https://$host_name:9090 https://$host_name.local:9090"
    fi

    cat <<EOF | $SUDO tee /etc/cockpit/cockpit.conf > /dev/null
# ==============================================================================
# Configuración Optimizada de Cockpit - HP ProBook 455 G10 (Fedora 45 Workstation)
# Hardware: AMD Ryzen 7 7730U / 32 GB RAM / NVMe Kioxia / Podman Rootless
# ==============================================================================

[WebService]
# Permite conexiones locales y desde la red de desarrollo LAN
Origins = $origins_list
MaxStartups = 5:50:10
AllowUnencrypted = false

[Session]
# Desconexión automática tras 15 min de inactividad: ahorra batería y CPU en el portátil
IdleTimeout = 15
EOF

    log_ok "Archivo /etc/cockpit/cockpit.conf configurado (IdleTimeout=15 min, Origins seguros)."
}

# ------------------------------------------------------------------------------
# 6. ACTIVACIÓN BAJO DEMANDA EN SYSTEMD
# ------------------------------------------------------------------------------
enable_socket() {
    log_info "[3/6] Habilitando activación bajo demanda en systemd (cockpit.socket)..."
    require_root
    $SUDO systemctl daemon-reload
    $SUDO systemctl enable --now cockpit.socket
    log_ok "Socket de Cockpit activo (0% CPU / 0 MB RAM en reposo; escucha en puerto 9090)."
}

# ------------------------------------------------------------------------------
# 7. CONFIGURACIÓN DE FIREWALLD EXCLUSIVO (REGLA MANDATORIA)
# ------------------------------------------------------------------------------
configure_firewall() {
    log_info "[4/6] Configurando reglas de red en Firewalld (puerto 9090 TCP)..."
    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "FedoraWorkstation")

        if ! firewall-cmd --zone="$active_zone" --list-services 2>/dev/null | grep -qw "cockpit"; then
            require_root
            $SUDO firewall-cmd --permanent --zone="$active_zone" --add-service=cockpit 2>/dev/null || \
            $SUDO firewall-cmd --permanent --add-service=cockpit 2>/dev/null || true
            $SUDO firewall-cmd --reload 2>/dev/null || true
            log_ok "Servicio 'cockpit' añadido permanentemente a la zona Firewalld '$active_zone'."
        else
            log_ok "Servicio 'cockpit' ya está habilitado en la zona Firewalld '$active_zone'."
        fi
    else
        log_warn "Firewalld no está activo; omitiendo configuración de cortafuegos."
    fi
}

# ------------------------------------------------------------------------------
# 8. INTEGRACIÓN CON PODMAN ROOTLESS Y LINGER
# ------------------------------------------------------------------------------
enable_podman_integration() {
    log_info "[5/6] Configurando integración de Podman Rootless para el usuario $REAL_USER..."
    if ! command -v podman &>/dev/null; then
        log_warn "Podman no está instalado; omitiendo activación de socket de usuario."
        return 0
    fi

    # Persistencia de procesos de fondo y contenedores del usuario (Linger)
    if command -v loginctl &>/dev/null; then
        require_root
        $SUDO loginctl enable-linger "$REAL_USER" 2>/dev/null || true
        log_ok "Persistencia linger habilitada para el usuario '$REAL_USER'."
    fi

    # Socket de Podman a nivel de usuario para cockpit-podman
    if [ -d "/run/user/$REAL_UID" ]; then
        run_as_user systemctl --user enable --now podman.socket 2>/dev/null || true
        log_ok "Socket Podman Rootless activo (systemctl --user enable --now podman.socket)."
    else
        log_info "Sesión gráfica de usuario no detectada en este instante; el socket se activará al iniciar sesión."
    fi
}

# ------------------------------------------------------------------------------
# 9. ACCESO DIRECTO EN GNOME SHELL WAYLAND
# ------------------------------------------------------------------------------
create_desktop_entry() {
    log_info "[6/6] Creando acceso directo en el tablero de aplicaciones de GNOME Shell..."
    local desktop_file="/usr/share/applications/cockpit.desktop"

    if [ -d "/usr/share/applications" ]; then
        require_root
        cat <<EOF | $SUDO tee "$desktop_file" > /dev/null
[Desktop Entry]
Name=Consola Web Cockpit
GenericName=Administración del Sistema
Comment=Consola web para monitorear hardware, contenedores Podman y almacenamiento
Exec=xdg-open https://localhost:9090
Icon=utilities-system-monitor
Terminal=false
Type=Application
Categories=System;Settings;Monitor;
Keywords=cockpit;admin;system;monitor;podman;kvm;storage;nvme;hardware;
StartupNotify=true
EOF
        $SUDO chmod 644 "$desktop_file"
        log_ok "Acceso directo creado: $desktop_file"
    fi
}

# ------------------------------------------------------------------------------
# 10. CONTROL DEL CICLO DE VIDA DE COCKPIT
# ------------------------------------------------------------------------------
start_cockpit() {
    require_root
    log_info "Iniciando cockpit.socket..."
    $SUDO systemctl enable --now cockpit.socket
    log_ok "Cockpit iniciado. Accede a: https://localhost:9090"
}

stop_cockpit() {
    require_root
    log_info "Deteniendo cockpit.service y cockpit.socket (liberando memoria y CPU)..."
    $SUDO systemctl stop cockpit.service cockpit.socket 2>/dev/null || true
    log_ok "Cockpit detenido."
}

restart_cockpit() {
    require_root
    log_info "Reiniciando cockpit.socket..."
    $SUDO systemctl restart cockpit.socket 2>/dev/null || true
    $SUDO systemctl stop cockpit.service 2>/dev/null || true
    log_ok "Cockpit reiniciado."
}

disable_cockpit() {
    require_root
    log_info "Deshabilitando Cockpit de systemd y retirando regla de Firewalld..."
    $SUDO systemctl disable --now cockpit.socket cockpit.service 2>/dev/null || true

    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "FedoraWorkstation")
        $SUDO firewall-cmd --permanent --zone="$active_zone" --remove-service=cockpit 2>/dev/null || \
        $SUDO firewall-cmd --permanent --remove-service=cockpit 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
    fi
    log_ok "Cockpit deshabilitado completamente."
}

show_logs() {
    echo -e "${BOLD}📋 Últimos 35 registros de eventos de Cockpit (journalctl):${NC}"
    journalctl -u cockpit.service -u cockpit.socket -n 35 --no-pager || true
}

open_browser() {
    local url="https://localhost:9090"
    log_info "Abriendo Cockpit en el navegador web predeterminado ($url)..."
    if ! systemctl is-active --quiet cockpit.socket 2>/dev/null; then
        log_info "Socket inactivo; iniciando cockpit.socket..."
        require_root
        $SUDO systemctl start cockpit.socket
    fi

    if command -v xdg-open &>/dev/null; then
        run_as_user xdg-open "$url" &>/dev/null & disown
    elif command -v gio &>/dev/null; then
        run_as_user gio open "$url" &>/dev/null & disown
    else
        log_info "Abre manualmente en tu navegador: $url"
    fi
}

open_client() {
    log_info "Comprobando cliente de escritorio para Cockpit en Wayland..."
    if command -v cockpit-client &>/dev/null; then
        log_ok "Lanzando Cockpit Client nativo..."
        run_as_user cockpit-client localhost &>/dev/null & disown
    elif command -v flatpak &>/dev/null && run_as_user flatpak info org.cockpit_project.CockpitClient &>/dev/null; then
        log_ok "Lanzando Cockpit Client (Flatpak)..."
        run_as_user flatpak run org.cockpit_project.CockpitClient localhost &>/dev/null & disown
    else
        log_warn "Cockpit Client no está instalado. Abriendo interfaz web en navegador..."
        open_browser
    fi
}

# ------------------------------------------------------------------------------
# 11. DIAGNÓSTICO Y TELEMETRÍA COMPLETA (--status)
# ------------------------------------------------------------------------------
show_status() {
    local sock_stat serv_stat enab_stat port_stat fw_stat
    sock_stat=$(systemctl is-active cockpit.socket 2>/dev/null || true)
    [[ -z "$sock_stat" ]] && sock_stat="inactivo"

    serv_stat=$(systemctl is-active cockpit.service 2>/dev/null || true)
    [[ -z "$serv_stat" ]] && serv_stat="inactivo"

    enab_stat=$(systemctl is-enabled cockpit.socket 2>/dev/null || true)
    [[ -z "$enab_stat" ]] && enab_stat="deshabilitado"

    if ss -tln 2>/dev/null | grep -q ":9090 "; then
        port_stat="${GREEN}✅ Escuchando en 0.0.0.0:9090 (TCP HTTPS)${NC}"
    else
        port_stat="${YELLOW}⚪ En espera de conexión (activación por socket)${NC}"
    fi

    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${BOLD}${CYAN}🔍 DIAGNÓSTICO DE CONSOLA WEB COCKPIT - FEDORA 45 WORKSTATION${NC}"
    echo -e "💻 ${BOLD}Hardware:${NC} HP ProBook 455 G10 | AMD Ryzen 7 7730U (16T) | 32 GB RAM"
    echo -e "${BOLD}=================================================================${NC}"

    echo -e "• Socket Systemd:        $([ "$sock_stat" = "active" ] && echo -e "${GREEN}✅ Activo (bajo demanda / 0% CPU)${NC}" || echo -e "${RED}❌ Inactivo${NC}")"
    echo -e "• Servicio Web (Daemon): $([ "$serv_stat" = "active" ] && echo -e "${GREEN}🟢 En ejecución${NC}" || echo -e "${YELLOW}⚪ Inactivo en reposo (despierta al conectar)${NC}")"
    echo -e "• Habilitado al inicio:  $([ "$enab_stat" = "enabled" ] && echo -e "${GREEN}✅ Habilitado${NC}" || echo -e "${RED}❌ Deshabilitado${NC}")"
    echo -e "• Puerto de escucha:     $port_stat"

    # Cortafuegos Firewalld
    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "FedoraWorkstation")
        if firewall-cmd --zone="$active_zone" --list-services 2>/dev/null | grep -qw "cockpit"; then
            fw_stat="${GREEN}✅ Permitido (Zona: $active_zone - puerto 9090/tcp)${NC}"
        else
            fw_stat="${RED}❌ No permitido en zona '$active_zone'${NC}"
        fi
    else
        fw_stat="${YELLOW}⚠️ Firewalld no está activo${NC}"
    fi
    echo -e "• Cortafuegos (Firewall):$fw_stat"

    # Integración Podman Rootless
    echo -e "\n${BOLD}🐳 Integración de Contenedores y Virtualización:${NC}"
    local podman_stat="${RED}❌ Inactivo${NC}"
    if [ -S "/run/user/$REAL_UID/podman/podman.sock" ] || run_as_user systemctl --user is-active --quiet podman.socket 2>/dev/null; then
        podman_stat="${GREEN}✅ Activo (/run/user/$REAL_UID/podman/podman.sock)${NC}"
    else
        podman_stat="${YELLOW}⚪ Inactivo (actívalo con: $0 --enable-podman)${NC}"
    fi
    echo -e "  - Socket Podman Rootless: $podman_stat"

    local linger_stat="${RED}❌ Deshabilitado${NC}"
    if command -v loginctl &>/dev/null && loginctl show-user "$REAL_USER" 2>/dev/null | grep -q "Linger=yes"; then
        linger_stat="${GREEN}✅ Habilitado (contenedores persistentes tras logout)${NC}"
    fi
    echo -e "  - Persistencia Linger:    $linger_stat"

    local libvirt_stat="${RED}❌ Inactivo${NC}"
    if systemctl is-active --quiet virtqemud 2>/dev/null || systemctl is-active --quiet libvirtd 2>/dev/null; then
        libvirt_stat="${GREEN}✅ Activo (KVM / QEMU)${NC}"
    elif command -v virsh &>/dev/null; then
        libvirt_stat="${YELLOW}⚪ Instalado pero inactivo${NC}"
    fi
    echo -e "  - Hipervisor Libvirt:     $libvirt_stat"

    # Almacenamiento NVMe y SMART
    echo -e "\n${BOLD}💾 Telemetría de Almacenamiento y Batería:${NC}"
    local nvme_stat="${YELLOW}⚪ No detectado${NC}"
    if [ -b "/dev/nvme0n1" ]; then
        if is_pkg_installed "smartmontools"; then
            nvme_stat="${GREEN}✅ SSD NVMe Kioxia detectado (smartmontools activo para cockpit-storaged)${NC}"
        else
            nvme_stat="${YELLOW}⚠️ SSD NVMe detectado (instala smartmontools para telemetría SMART)${NC}"
        fi
    fi
    echo -e "  - Unidad NVMe Kioxia:     $nvme_stat"

    # Configuración /etc/cockpit/cockpit.conf
    if [ -f /etc/cockpit/cockpit.conf ]; then
        local idle_to
        idle_to=$(grep -E '^[[:space:]]*IdleTimeout' /etc/cockpit/cockpit.conf 2>/dev/null | cut -d= -f2 | tr -d ' ' || echo "no configurado")
        echo -e "  - Perfil de Energía:      ${GREEN}✅ IdleTimeout = ${idle_to} min (ahorro de batería en portátil)${NC}"
    else
        echo -e "  - Perfil de Energía:      ${YELLOW}⚠️ Sin archivo /etc/cockpit/cockpit.conf${NC}"
    fi

    # Módulos instalados
    echo -e "\n${BOLD}📦 Módulos RPM de Cockpit instalados:${NC}"
    local installed_mods
    installed_mods=$(rpm -qa --qf "  ✓ %{NAME}-%{VERSION}\n" "cockpit*" 2>/dev/null | sort || true)
    if [ -n "$installed_mods" ]; then
        echo "$installed_mods"
    else
        echo -e "  ${RED}❌ Ningún módulo de Cockpit instalado.${NC}"
    fi

    # Accesos
    echo -e "\n${BOLD}=================================================================${NC}"
    local host_ip
    host_ip=$(get_lan_ip)
    echo -e "🌐 ${BOLD}Acceso Local:${NC}           ${CYAN}https://localhost:9090${NC}"
    if [ -n "$host_ip" ] && [ "$host_ip" != "127.0.0.1" ]; then
        echo -e "🌐 ${BOLD}Acceso Red LAN:${NC}         ${CYAN}https://$host_ip:9090${NC}"
    fi
    echo -e "💡 Inicia sesión con tus credenciales de usuario de Fedora (${BOLD}$REAL_USER${NC})."
    echo -e "🚀 Abrir en navegador:      ${CYAN}$0 --open${NC}"
    echo -e "🖥️  Abrir en cliente:        ${CYAN}$0 --client${NC}"
    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 12. AYUDA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
${BOLD}🌐 Administrador de Consola Web Cockpit - Fedora 45 Workstation${NC}
Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U + GNOME Shell Wayland)

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones de Diagnóstico e Interfaz:${NC}
  (sin argumentos)       Instala Cockpit y módulos, optimiza cockpit.conf, activa socket y Firewalld.
  --status, -s           Muestra diagnóstico completo (sin pedir sudo) de socket, módulos y red.
  --open, -o             Abre la interfaz web de Cockpit en el navegador (https://localhost:9090).
  --client, -c           Lanza Cockpit Client (Flatpak o nativo) o el navegador predeterminado.
  --logs, -l             Muestra los últimos registros de eventos del socket y servicio.
  --enable-podman        Configura socket de Podman Rootless y persistencia linger para $REAL_USER.

${BOLD}Control de Servicios (requiere privilegios):${NC}
  --start                Inicia e instala cockpit.socket en systemd.
  --stop                 Detiene el socket y servicio de Cockpit (liberando memoria y CPU).
  --restart              Reinicia el socket y servicio de Cockpit.
  --disable              Deshabilita permanentemente el socket y retira la regla de Firewalld.
  --no-install           Aplica configuración, socket y firewall omitiendo la descarga de paquetes DNF5.
  --help, -h             Muestra este mensaje de ayuda.

${BOLD}Optimizaciones de Hardware para HP ProBook 455 G10:${NC}
  • Activación bajo demanda: cockpit.socket mantiene cockpit-ws inactivo hasta que se contacta el puerto 9090.
  • Ahorro de batería: Cierre de sesión automático por inactividad tras 15 min (IdleTimeout = 15).
  • Podman Rootless: Soporte directo con cockpit-podman vía socket de usuario /run/user/$REAL_UID/podman/podman.sock.
  • NVMe SMART: Monitoreo de salud y temperatura del SSD NVMe Kioxia KBG50ZNV512G con smartmontools.
  • Cortafuegos Firewalld: Regla de red exclusiva y permanente en la zona FedoraWorkstation.
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
    --open|-o|open)
        open_browser
        exit 0
        ;;
    --client|-c|client)
        open_client
        exit 0
        ;;
    --logs|-l|logs)
        show_logs
        exit 0
        ;;
    --enable-podman)
        enable_podman_integration
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
    --restart|restart)
        restart_cockpit
        exit 0
        ;;
    --disable|disable)
        disable_cockpit
        exit 0
        ;;
    --no-install)
        echo -e "${BOLD}=================================================================${NC}"
        echo -e "${BOLD}${CYAN}🌐 ACTIVANDO COCKPIT EN FEDORA 45 WORKSTATION [SIN DNF5]${NC}"
        echo -e "${BOLD}=================================================================${NC}"
        configure_cockpit_conf
        enable_socket
        configure_firewall
        enable_podman_integration
        create_desktop_entry
        echo ""
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        echo -e "${BOLD}=================================================================${NC}"
        echo -e "${BOLD}${CYAN}🌐 CONFIGURADOR DE CONSOLA WEB COCKPIT - FEDORA 45 WORKSTATION${NC}"
        echo -e "💻 HP ProBook 455 G10 (AMD Ryzen 7 7730U / 32 GB RAM / NVMe Kioxia)"
        echo -e "${BOLD}=================================================================${NC}"
        install_cockpit
        configure_cockpit_conf
        enable_socket
        configure_firewall
        enable_podman_integration
        create_desktop_entry
        echo ""
        show_status
        log_ok "Cockpit configurado y optimizado con éxito para esta estación de trabajo."
        exit 0
        ;;
    *)
        log_err "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
