#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  fedora-tuning.sh - Optimización de Kernel, Límites, ZRAM y GNOME Tracker
#  Sistema: Fedora 45 Workstation (GNOME Wayland / 32 GB RAM / AMD Ryzen)
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

if [[ $EUID -eq 0 ]]; then
    REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER:-root}")}"
else
    REAL_USER="${USER:-$(whoami)}"
fi
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
REAL_UID=$(id -u "$REAL_USER")

run_as_user() {
    if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
        sudo -u "$REAL_USER" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${REAL_UID}/bus" \
            XDG_RUNTIME_DIR="/run/user/${REAL_UID}" \
            "$@"
    else
        "$@"
    fi
}

DNF_BIN="dnf5"
command -v dnf5 &>/dev/null || DNF_BIN="dnf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SYSCTL_FILE="/etc/sysctl.d/99-fedora-workstation-tuning.conf"
LIMITS_FILE="/etc/security/limits.d/99-fedora-workstation-limits.conf"
SYSTEMD_TIMEOUT_FILE="/etc/systemd/system.conf.d/99-fast-shutdown.conf"

DO_INSTALL=true
RUN_ALL=true
RUN_SYSCTL=false
RUN_LIMITS=false
RUN_TRACKER=false
RUN_ZRAM=false
RUN_SERVICES=false
ACTION="run"

show_help() {
    cat << EOF
${BOLD}⚡ Optimizador de Rendimiento del Sistema - Fedora 45 Workstation (GNOME Wayland)${NC}

Aplica ajustes de Kernel (${BOLD}sysctl${NC}: inotify 1M, max_map_count 16M, TCP BBR, swappiness),
límites de descriptores (${BOLD}limits.d${NC}), timeouts rápidos de systemd, exclusión de
directorios de desarrollo en ${BOLD}GNOME Tracker / LocalSearch${NC} y compresión ${BOLD}ZRAM (zstd)${NC}.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)   Ejecuta todos los módulos de optimización en Fedora 45
  -s, --status       Muestra el diagnóstico completo de sysctl, límites, ZRAM y Tracker
  --no-install       Omite la instalación de paquetes adicionales vía DNF5
  --sysctl           Aplica solo optimizaciones de Kernel en $SYSCTL_FILE
  --limits           Aplica solo límites ulimit/nofile/memlock en $LIMITS_FILE
  --tracker          Aplica solo exclusiones de indexación en GNOME Tracker / LocalSearch
  --zram             Configura solo ZRAM Swap (invoca ./Setup/zram-setup.sh)
  --services         Habilita fstrim.timer, irqbalance y reduce timeouts de apagado
  -h, --help         Muestra esta ayuda
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  ⚡ ${BOLD}ESTADO DE OPTIMIZACIÓN DEL SISTEMA - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    echo -e "${BOLD}🧠 Parámetros del Kernel (sysctl):${NC}"
    echo -e "  • vm.swappiness:             ${CYAN}$(sysctl -n vm.swappiness 2>/dev/null || echo 'N/A')${NC}"
    echo -e "  • vm.vfs_cache_pressure:     ${CYAN}$(sysctl -n vm.vfs_cache_pressure 2>/dev/null || echo 'N/A')${NC}"
    echo -e "  • vm.max_map_count:          ${CYAN}$(sysctl -n vm.max_map_count 2>/dev/null || echo 'N/A')${NC}"
    echo -e "  • fs.inotify.max_user_watches:${CYAN} $(sysctl -n fs.inotify.max_user_watches 2>/dev/null || echo 'N/A')${NC}"
    echo -e "  • net.ipv4.tcp_congestion:   ${CYAN}$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'N/A')${NC}"

    echo ""
    echo -e "${BOLD}📂 Archivos de Ajuste y Servicios:${NC}"
    [[ -f "$SYSCTL_FILE" ]] && echo -e "  • Perfil sysctl:             ${GREEN}${SYSCTL_FILE}${NC}" || echo -e "  • Perfil sysctl:             ${YELLOW}No aplicado${NC}"
    [[ -f "$LIMITS_FILE" ]] && echo -e "  • Perfil limits.d:           ${GREEN}${LIMITS_FILE}${NC}" || echo -e "  • Perfil limits.d:           ${YELLOW}No aplicado${NC}"
    [[ -f "$SYSTEMD_TIMEOUT_FILE" ]] && echo -e "  • Systemd Fast Shutdown:     ${GREEN}${SYSTEMD_TIMEOUT_FILE}${NC}" || echo -e "  • Systemd Fast Shutdown:     ${YELLOW}Por defecto${NC}"

    if systemctl is-enabled --quiet fstrim.timer 2>/dev/null; then
        echo -e "  • NVMe TRIM (fstrim.timer):  ${GREEN}Habilitado${NC}"
    else
        echo -e "  • NVMe TRIM (fstrim.timer):  ${YELLOW}No habilitado${NC}"
    fi

    echo ""
    echo -e "${BOLD}🔍 Indexador GNOME Tracker / LocalSearch:${NC}"
    local ignored_dirs
    ignored_dirs=$(run_as_user gsettings get org.freedesktop.Tracker3.Miner.Files ignored-directories 2>/dev/null || echo "N/A")
    echo -e "  • Directorios excluidos:     ${CYAN}${ignored_dirs}${NC}"
    echo -e "${BOLD}======================================================================${NC}"
}

apply_sysctl() {
    log_info "Aplicando optimizaciones de Kernel en $SYSCTL_FILE..."
    sudo tee "$SYSCTL_FILE" > /dev/null << 'EOF'
# ==============================================================================
#  Optimización de Kernel para Fedora 45 Workstation (32 GB RAM / ZRAM / NVMe)
# ==============================================================================

# Gestión de memoria virtual y ZRAM (con 32 GB RAM y ZRAM zstd)
vm.swappiness = 100
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.page-cluster = 0

# Mapas de memoria (requerido para IDEs pesados, contenedores, compiladores y Proton/Steam)
vm.max_map_count = 16777216

# Observadores de archivos inotify (Antigravity, VS Code, Vite, Next.js, Cargo, Podman)
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 8192
fs.inotify.max_queued_events = 65536
fs.file-max = 2097152

# Red de baja latencia y alto rendimiento (TCP BBR + fq)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.somaxconn = 8192
EOF

    sudo sysctl --system >/dev/null 2>&1 || true
    log_ok "Parámetros sysctl aplicados."
}

apply_limits() {
    log_info "Configurando límites de descriptores y memoria en $LIMITS_FILE..."
    sudo tee "$LIMITS_FILE" > /dev/null << 'EOF'
# Límites extendidos para desarrollo, contenedores Podman, KVM y audio PipeWire
* soft nofile 524288
* hard nofile 1048576
root soft nofile 524288
root hard nofile 1048576
* soft memlock unlimited
* hard memlock unlimited
EOF
    log_ok "Límites de sistema configurados."
}

apply_tracker() {
    log_info "Optimizando GNOME Tracker / LocalSearch para excluir directorios de código y build..."
    mkdir -p "$USER_HOME/Workspace"
    touch "$USER_HOME/Workspace/.nomedia"
    [[ $EUID -eq 0 && "$REAL_USER" != "root" ]] && chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/Workspace"

    if run_as_user gsettings list-schemas 2>/dev/null | grep -q "^org.freedesktop.Tracker3.Miner.Files$"; then
        run_as_user gsettings set org.freedesktop.Tracker3.Miner.Files ignored-directories \
            "['po', 'CVS', 'core-dumps', 'lost+found', 'node_modules', '.git', '.hg', '.svn', '.venv', 'venv', '__pycache__', 'target', 'build', 'dist', '.next', '.nuxt', '.angular', '.gradle', '.m2', '.cargo', '.rustup', 'vendor', '.cache', 'tmp']"
        run_as_user gsettings set org.freedesktop.Tracker3.Miner.Files enable-monitors true
        run_as_user gsettings set org.freedesktop.Tracker3.Miner.Files crawling-interval -2 2>/dev/null || true
    fi
    log_ok "Exclusiones de GNOME Tracker configuradas."
}

apply_services() {
    log_info "Configurando servicios de mantenimiento NVMe, IRQ y timeouts de Systemd..."
    if [[ "$DO_INSTALL" == true ]]; then
        local pkgs=()
        rpm -q irqbalance &>/dev/null || pkgs+=(irqbalance)
        rpm -q distrobox &>/dev/null || pkgs+=(distrobox)
        if [[ ${#pkgs[@]} -gt 0 ]]; then
            sudo "$DNF_BIN" install -y "${pkgs[@]}"
        fi
    fi

    sudo systemctl enable --now fstrim.timer 2>/dev/null || true
    sudo systemctl enable --now irqbalance.service 2>/dev/null || true

    sudo mkdir -p "$(dirname "$SYSTEMD_TIMEOUT_FILE")"
    sudo tee "$SYSTEMD_TIMEOUT_FILE" > /dev/null << 'EOF'
[Manager]
DefaultTimeoutStopSec=15s
DefaultTimeoutStartSec=30s
EOF
    sudo systemctl daemon-reload
    log_ok "Servicios NVMe fstrim.timer, irqbalance y timeouts configurados."
}

apply_zram() {
    if [[ -x "$SCRIPT_DIR/zram-setup.sh" ]]; then
        "$SCRIPT_DIR/zram-setup.sh"
    else
        log_warn "No se encontró $SCRIPT_DIR/zram-setup.sh."
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)   ACTION="status"; shift ;;
        --no-install)  DO_INSTALL=false; shift ;;
        --sysctl)      RUN_ALL=false; RUN_SYSCTL=true; shift ;;
        --limits)      RUN_ALL=false; RUN_LIMITS=true; shift ;;
        --tracker)     RUN_ALL=false; RUN_TRACKER=true; shift ;;
        --zram)        RUN_ALL=false; RUN_ZRAM=true; shift ;;
        --services)    RUN_ALL=false; RUN_SERVICES=true; shift ;;
        -h|--help)     show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

if [[ "$ACTION" == "status" ]]; then
    show_status
    exit 0
fi

if [[ "$RUN_ALL" == true ]]; then
    apply_sysctl
    apply_limits
    apply_tracker
    apply_services
    apply_zram
else
    [[ "$RUN_SYSCTL" == true ]]   && apply_sysctl
    [[ "$RUN_LIMITS" == true ]]   && apply_limits
    [[ "$RUN_TRACKER" == true ]]  && apply_tracker
    [[ "$RUN_SERVICES" == true ]] && apply_services
    [[ "$RUN_ZRAM" == true ]]     && apply_zram
fi

log_ok "Optimización completa de Fedora 45 Workstation finalizada."
show_status
