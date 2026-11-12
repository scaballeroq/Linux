#!/usr/bin/env bash
# ==============================================================================
# cockpit.sh - Consola Web Cockpit Optimizada para Omarchy Workstation
# Sistema: Arch Linux / Omarchy (Hyprland Wayland + Pacman / Paru)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM DDR4)
# Almacenamiento: SSD NVMe Kioxia KBG50ZNV512G 512 GB / ZRAM Swap
# ==============================================================================
# Características:
#   - Activación bajo demanda por socket systemd (cockpit.socket): 0% CPU y 0 MB RAM en reposo.
#   - Módulos nativos integrados:
#     * cockpit-podman: Contenedores rootless del usuario y Quadlets systemd.
#     * cockpit-machines: Máquinas virtuales KVM/QEMU Libvirt (vía libvirt-dbus).
#     * cockpit-storaged: Almacenamiento, SMART NVMe, Btrfs y compresión zstd.
#     * cockpit-pacman: Gestor nativo Arch/Omarchy en Rust (alpm.rs) sin bloqueos de PackageKit.
#     * cockpit-files: Explorador web de archivos nativo de Cockpit.
#     * NetworkManager y udisks2.
#   - Optimización de batería y memoria para portátil HP ProBook 455 G10:
#     * Desconexión por inactividad (/etc/cockpit/cockpit.conf -> IdleTimeout = 15 min).
#     * Restricción y seguridad de orígenes HTTP/HTTPS (Origins / MaxStartups / LoginTitle).
#   - Integración con Podman Rootless (podman.socket de usuario y persistencia linger).
#   - Reglas automáticas en Firewalld exclusivo (puerto 9090 TCP en zona activa).
#   - Integración Hyprland Wayland: acceso directo .desktop con actualización de caché.
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
    pacman -Q "$1" >/dev/null 2>&1
}

get_aur_helper() {
    if command -v paru &>/dev/null; then
        echo "paru"
    elif command -v yay &>/dev/null; then
        echo "yay"
    else
        echo ""
    fi
}

get_lan_ip() {
    local ip
    ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || true)
    if [ -z "$ip" ]; then
        ip=$(ip -4 addr show scope global 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1 || true)
    fi
    echo "$ip"
}

# ------------------------------------------------------------------------------
# 3. LISTADO DE MÓDULOS Y PAQUETES OPTIMIZADOS PARA OMARCHY
# ------------------------------------------------------------------------------
# cockpit-pacman: Plugin nativo en Rust (alpm.rs) disponible en cachyos-extra-v3 / extra.
# Reemplaza a packagekit evitando bloqueos de /var/lib/pacman/db.lck.
CORE_PACKAGES=(
    "cockpit"
    "cockpit-podman"
    "cockpit-machines"
    "cockpit-storaged"
    "cockpit-pacman"
    "cockpit-files"
    "udisks2"
    "networkmanager"
)

RECOMMENDED_PACKAGES=(
    "smartmontools"
    "libvirt-dbus"
)

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN IDEMPOTENTE O(1) DE PAQUETES
# ------------------------------------------------------------------------------
install_cockpit() {
    log_info "[1/6] Comprobando paquetes y módulos nativos de Cockpit en Omarchy..."

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
        if ! $SUDO pacman -S --needed --noconfirm "${missing[@]}"; then
            log_warn "Pacman reportó advertencias o faltan paquetes en repositorios oficiales..."
            local aur_helper
            aur_helper=$(get_aur_helper)
            if [ -n "$aur_helper" ]; then
                log_info "Intentando resolver paquetes restantes mediante $aur_helper..."
                run_as_user "$aur_helper" -S --needed --noconfirm "${missing[@]}" || true
            else
                log_warn "Helper AUR (paru/yay) no detectado. Si algún paquete no se instaló, revisa pacman.conf."
            fi
        fi
        log_ok "Paquetes y módulos de Cockpit verificados/instalados exitosamente."
    else
        log_ok "Todos los módulos nativos de Cockpit y utilidades ya están instalados."
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
    host_name=$(hostname 2>/dev/null || uname -n 2>/dev/null || echo "cachyos")

    # Orígenes autorizados para protección contra Cross-Origin WebSocket Hijacking
    origins_list="https://localhost:9090 https://127.0.0.1:9090 https://[::1]:9090"
    if [ -n "$host_ip" ] && [ "$host_ip" != "127.0.0.1" ]; then
        origins_list="$origins_list https://$host_ip:9090"
    fi
    if [ -n "$host_name" ]; then
        origins_list="$origins_list https://$host_name:9090 https://$host_name.local:9090"
    fi

    cat <<EOF | $SUDO tee /etc/cockpit/cockpit.conf > /dev/null
# ==============================================================================
# Configuración Optimizada de Cockpit - HP ProBook 455 G10 (Omarchy Workstation)
# Hardware: AMD Ryzen 7 7730U / 32 GB RAM DDR4 / NVMe Kioxia / Podman Rootless
# ==============================================================================

[WebService]
# Título del portal de acceso en Hyprland Wayland
LoginTitle = Omarchy Workstation (HP ProBook 455 G10)

# Orígenes WebSocket autorizados para desarrollo local y LAN
Origins = $origins_list

# Mitigación y rate-limiting contra ataques de fuerza bruta al socket 9090
MaxStartups = 5:50:10

# Obliga el uso estricto de cifrado TLS/HTTPS
AllowUnencrypted = false

# Habilita administración y monitorización de múltiples hosts remotos
AllowMultiHost = true

# Soporte de cabecera de protocolo para proxies inversos locales
ProtocolHeader = X-Forwarded-Proto

[Session]
# Desconexión automática tras 15 min de inactividad:
# Ahorro térmico y de batería en el portátil AMD Ryzen 7 7730U (0% CPU / 0 MB RAM en reposo)
IdleTimeout = 15
EOF

    $SUDO chmod 644 /etc/cockpit/cockpit.conf
    log_ok "Archivo /etc/cockpit/cockpit.conf configurado (IdleTimeout=15 min, Origins seguros, LoginTitle)."
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
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")

        if ! firewall-cmd --zone="$active_zone" --query-service=cockpit >/dev/null 2>&1; then
            require_root
            $SUDO firewall-cmd --permanent --zone="$active_zone" --add-service=cockpit >/dev/null
            $SUDO firewall-cmd --reload >/dev/null
            log_ok "Servicio 'cockpit' (9090/tcp) añadido permanentemente a la zona Firewalld '$active_zone'."
        else
            log_ok "Servicio 'cockpit' (9090/tcp) ya está autorizado en la zona Firewalld '$active_zone'."
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

    # Persistencia de procesos de fondo y contenedores del usuario (Linger)
    if command -v loginctl &>/dev/null; then
        require_root
        $SUDO loginctl enable-linger "$REAL_USER" 2>/dev/null || true
        log_ok "Persistencia linger habilitada para el usuario '$REAL_USER'."
    fi

    # Socket de Podman a nivel de usuario para cockpit-podman
    if command -v podman &>/dev/null; then
        if [ -d "/run/user/$REAL_UID" ]; then
            run_as_user systemctl --user enable --now podman.socket 2>/dev/null || true
            log_ok "Socket Podman Rootless activo (systemctl --user enable --now podman.socket)."
        else
            log_info "Sesión gráfica de usuario no activa en este instante; el socket se activará al iniciar sesión."
        fi
    else
        log_warn "Podman aún no está instalado en el sistema. Una vez instalado, ejecuta: $0 --enable-podman"
    fi
}

# ------------------------------------------------------------------------------
# 9. ACCESO DIRECTO EN GNOME SHELL WAYLAND
# ------------------------------------------------------------------------------
create_desktop_entry() {
    log_info "[6/6] Creando acceso directo en el tablero de aplicaciones de Hyprland..."
    local desktop_file="/usr/share/applications/cockpit.desktop"

    if [ -d "/usr/share/applications" ]; then
        require_root
        cat <<EOF | $SUDO tee "$desktop_file" > /dev/null
[Desktop Entry]
Name=Consola Web Cockpit
Name[es]=Consola Web Cockpit
GenericName=Administración del Sistema
GenericName[es]=Administración del Sistema
Comment=Consola web para monitorear hardware AMD Ryzen, contenedores Podman, almacenamiento y Libvirt
Comment[es]=Consola web para monitorear hardware AMD Ryzen, contenedores Podman, almacenamiento y Libvirt
Exec=xdg-open https://localhost:9090
Icon=utilities-system-monitor
Terminal=false
Type=Application
Categories=System;Settings;Monitor;HardwareSettings;
Keywords=cockpit;admin;system;monitor;podman;kvm;storage;nvme;hardware;ryzen;cachyos;
StartupNotify=true
EOF
        $SUDO chmod 644 "$desktop_file"
        if command -v update-desktop-database &>/dev/null; then
            $SUDO update-desktop-database /usr/share/applications 2>/dev/null || true
        fi
        log_ok "Acceso directo creado y actualizado en el sistema: $desktop_file"
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
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        if firewall-cmd --zone="$active_zone" --query-service=cockpit >/dev/null 2>&1; then
            $SUDO firewall-cmd --permanent --zone="$active_zone" --remove-service=cockpit >/dev/null 2>&1 || true
            $SUDO firewall-cmd --reload >/dev/null 2>&1 || true
            log_ok "Regla 'cockpit' retirada de la zona Firewalld '$active_zone'."
        fi
    fi
    log_ok "Cockpit deshabilitado completamente."
}

show_logs() {
    echo -e "${BOLD}📋 Últimos 35 registros de eventos de Cockpit (journalctl):${NC}"
    journalctl -u cockpit.service -u cockpit.socket -u 'cockpit-wsinstance*' -u 'cockpit-session*' -n 35 --no-pager || true
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
    echo -e "${BOLD}${CYAN}🔍 DIAGNÓSTICO DE CONSOLA WEB COCKPIT - OMARCHY WORKSTATION${NC}"
    echo -e "💻 ${BOLD}Hardware:${NC} HP ProBook 455 G10 | AMD Ryzen 7 7730U (8C/16T) | 32 GB RAM"
    echo -e "${BOLD}=================================================================${NC}"

    echo -e "• Socket Systemd:        $([ "$sock_stat" = "active" ] && echo -e "${GREEN}✅ Activo (bajo demanda / 0% CPU)${NC}" || echo -e "${RED}❌ Inactivo${NC}")"
    echo -e "• Servicio Web (Daemon): $([ "$serv_stat" = "active" ] && echo -e "${GREEN}🟢 En ejecución${NC}" || echo -e "${YELLOW}⚪ Inactivo en reposo (despierta al conectar)${NC}")"
    echo -e "• Habilitado al inicio:  $([ "$enab_stat" = "enabled" ] && echo -e "${GREEN}✅ Habilitado${NC}" || echo -e "${RED}❌ Deshabilitado${NC}")"
    echo -e "• Puerto de escucha:     $port_stat"

    # Cortafuegos Firewalld (Consulta rápida O(1))
    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        if firewall-cmd --zone="$active_zone" --query-service=cockpit >/dev/null 2>&1; then
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
    elif command -v podman &>/dev/null; then
        podman_stat="${YELLOW}⚪ Instalado pero inactivo (actívalo con: $0 --enable-podman)${NC}"
    else
        podman_stat="${YELLOW}⚪ Podman no instalado${NC}"
    fi
    echo -e "  - Socket Podman Rootless: $podman_stat"

    local linger_stat="${RED}❌ Deshabilitado${NC}"
    if command -v loginctl &>/dev/null && loginctl show-user "$REAL_USER" -p Linger 2>/dev/null | grep -q "Linger=yes"; then
        linger_stat="${GREEN}✅ Habilitado (contenedores persistentes tras logout)${NC}"
    fi
    echo -e "  - Persistencia Linger:    $linger_stat"

    local libvirt_stat="${RED}❌ Inactivo${NC}"
    if systemctl is-active --quiet virtqemud 2>/dev/null || systemctl is-active --quiet libvirtd 2>/dev/null || systemctl is-active --quiet virtqemud.socket 2>/dev/null; then
        libvirt_stat="${GREEN}✅ Activo (KVM / QEMU)${NC}"
    elif command -v virsh &>/dev/null; then
        libvirt_stat="${YELLOW}⚪ Instalado pero inactivo${NC}"
    fi
    echo -e "  - Hipervisor Libvirt:     $libvirt_stat"

    local libvirt_dbus_stat="${RED}❌ No instalado (recomendado para cockpit-machines)${NC}"
    if is_pkg_installed "libvirt-dbus"; then
        libvirt_dbus_stat="${GREEN}✅ Instalado (comunicación D-Bus con Libvirt activa)${NC}"
    fi
    echo -e "  - Conector libvirt-dbus:  $libvirt_dbus_stat"

    # Almacenamiento NVMe, SMART y Telemetría Térmica
    echo -e "\n${BOLD}💾 Telemetría de Almacenamiento, Memoria y Batería:${NC}"
    local nvme_stat="${YELLOW}⚪ No detectado${NC}"
    if [ -b "/dev/nvme0n1" ]; then
        if is_pkg_installed "smartmontools"; then
            nvme_stat="${GREEN}✅ SSD NVMe Kioxia KBG50ZNV512G detectado (smartmontools activo para cockpit-storaged)${NC}"
        else
            nvme_stat="${YELLOW}⚠️ SSD NVMe Kioxia detectado (instala smartmontools para telemetría SMART)${NC}"
        fi
    fi
    echo -e "  - Unidad NVMe Kioxia:     $nvme_stat"

    # Telemetría de sensores si están disponibles
    if command -v sensors &>/dev/null; then
        local cpu_t nvme_t
        cpu_t=$(sensors 2>/dev/null | awk '/k10temp/{flag=1; next} flag && /Tctl/{print $2; exit}' || echo "")
        nvme_t=$(sensors 2>/dev/null | awk '/nvme-pci/{flag=1; next} flag && /Composite/{print $2; exit}' || echo "")
        if [ -n "$cpu_t" ] || [ -n "$nvme_t" ]; then
            echo -e "  - Sensores Térmicos:      CPU AMD Ryzen: ${CYAN}${cpu_t:-N/A}${NC} | SSD NVMe: ${CYAN}${nvme_t:-N/A}${NC}"
        fi
    fi

    # ZRAM Swap y Batería
    local zram_info bat_info
    zram_info=$(swapon --show 2>/dev/null | grep -i zram | awk '{print $1 " (" $3 " total, " $4 " usado)"}' || echo "")
    if [ -n "$zram_info" ]; then
        echo -e "  - ZRAM Swap:              ${GREEN}✅ $zram_info${NC}"
    fi

    if [ -d "/sys/class/power_supply/BAT0" ]; then
        local bat_pct bat_st
        bat_pct=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "N/A")
        bat_st=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "N/A")
        echo -e "  - Estado de Batería:      ${CYAN}$bat_pct% ($bat_st)${NC}"
    fi

    # Configuración /etc/cockpit/cockpit.conf
    if [ -f /etc/cockpit/cockpit.conf ]; then
        local idle_to
        idle_to=$(grep -E '^[[:space:]]*IdleTimeout' /etc/cockpit/cockpit.conf 2>/dev/null | cut -d= -f2 | tr -d ' ' || echo "no configurado")
        echo -e "  - Perfil de Energía:      ${GREEN}✅ IdleTimeout = ${idle_to} min (ahorro térmico y batería en reposo)${NC}"
    else
        echo -e "  - Perfil de Energía:      ${YELLOW}⚠️ Sin archivo /etc/cockpit/cockpit.conf${NC}"
    fi

    # Módulos instalados
    echo -e "\n${BOLD}📦 Módulos y Extensiones de Cockpit instalados:${NC}"
    local installed_mods
    installed_mods=$(pacman -Q 2>/dev/null | grep -E "cockpit|udisks2|libvirt-dbus|smartmontools" | awk '{print "  ✓ " $1 " (" $2 ")"}' || true)
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
    echo -e "💡 Inicia sesión con tus credenciales de usuario de Omarchy (${BOLD}$REAL_USER${NC})."
    echo -e "🔒 Nota: El primer acceso mostrará aviso de certificado TLS autofirmado seguro."
    echo -e "🚀 Abrir en navegador:      ${CYAN}$0 --open${NC}"
    echo -e "🖥️  Abrir en cliente:        ${CYAN}$0 --client${NC}"
    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 12. AYUDA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
${BOLD}🌐 Administrador de Consola Web Cockpit - Omarchy Workstation${NC}
Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U + Hyprland Wayland)

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones de Diagnóstico e Interfaz:${NC}
  (sin argumentos)       Instala Cockpit y módulos nativos, optimiza cockpit.conf, activa socket y Firewalld.
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
  --no-install           Aplica configuración, socket y firewall omitiendo la descarga de paquetes Pacman.
  --help, -h             Muestra este mensaje de ayuda.

${BOLD}Optimizaciones de Hardware para HP ProBook 455 G10:${NC}
  • Activación bajo demanda: cockpit.socket mantiene cockpit-ws inactivo hasta que se contacta el puerto 9090.
  • Ahorro de batería: Cierre de sesión automático por inactividad tras 15 min (IdleTimeout = 15).
  • cockpit-pacman nativo: Gestión de paquetes Arch/Omarchy en Rust (alpm.rs), sustituyendo packagekit.
  • cockpit-files nativo: Explorador web de archivos integrado directamente en Cockpit.
  • Podman Rootless: Soporte directo con cockpit-podman vía socket /run/user/$REAL_UID/podman/podman.sock.
  • KVM / Libvirt: Soporte de máquinas virtuales con cockpit-machines y libvirt-dbus.
  • NVMe SMART: Monitoreo de salud y temperatura del SSD NVMe Kioxia KBG50ZNV512G con smartmontools.
  • Cortafuegos Firewalld: Regla de red exclusiva y permanente en la zona activa (puerto 9090/tcp).
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
        echo -e "${BOLD}${CYAN}🌐 ACTIVANDO COCKPIT EN OMARCHY WORKSTATION [SIN INSTALACIÓN]${NC}"
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
        echo -e "${BOLD}${CYAN}🌐 CONFIGURADOR DE CONSOLA WEB COCKPIT - OMARCHY WORKSTATION${NC}"
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
