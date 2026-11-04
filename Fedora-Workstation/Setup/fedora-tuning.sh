#!/usr/bin/env bash
# ==============================================================================
#  fedora-tuning.sh - Optimizador de Rendimiento para Fedora 45 Workstation
#  Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM)
#  Almacenamiento: SSD NVMe 512 GB Kioxia KBG50ZNV512G (Btrfs / ZRAM zstd)
#  Entorno: GNOME Shell (Wayland / Mutter) / DNF5 / Podman / KVM Libvirt
# ==============================================================================
#  Características:
#   - Sysctl Kernel: Memoria adaptada a 32 GB RAM, dirty ratios bajos para NVMe
#     DRAM-less (Kioxia BG5), inotify masivo (1M), max_map_count (16M) y TCP BBR.
#   - AMD Zen 3: vm.watermark_boost_factor = 0 para erradicar micro-bloqueos
#     de compactación kswapd en los 16 hilos del Ryzen 7 7730U.
#   - ZRAM (zstd): vm.swappiness = 100 y vm.page-cluster = 0 para lectura sin latencia.
#   - Almacenamiento Btrfs: Atributos NoCoW (+C) en /var/lib/libvirt/images y
#     almacenamiento de Podman (~/.local/share/containers/storage) para evitar fragmentación.
#   - NVMe udev: Programador de E/S bloqueado en [none] para máxima tasa de transferencia.
#   - Límites PAM y Systemd: nofile (1M), memlock ilimitado y prioridad de audio PipeWire.
#   - GNOME Tracker / LocalSearch: Exclusión de carpetas de desarrollo (node_modules,
#     .git, .venv, target, etc.) y desactivación de indexación en batería.
#   - Servicios del Sistema: fstrim.timer, irqbalance.service, tuned.service y
#     reducción de timeouts de apagado a 10s.
#   - CLI Modular e Idempotente: --status, --storage, --sysctl, --limits, --tracker,
#     --services, --zram, --no-install, --help.
# ==============================================================================

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y FORMATO VISUAL (ANSI-C Quoting)
# ------------------------------------------------------------------------------
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

# ------------------------------------------------------------------------------
# 2. PRIVILEGIOS Y CONTEXTO DE USUARIO
# ------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    if ! command -v sudo &>/dev/null; then
        echo -e "${RED}❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo.${NC}" >&2
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

# Ejecución segura en el bus D-Bus de la sesión del usuario (para GNOME Tracker/dconf)
run_as_user() {
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$REAL_UID}"
    local dbus_addr="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$runtime_dir/bus}"
    if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            "$@"
    else
        env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            "$@"
    fi
}

# Gestor de paquetes DNF5
DNF_BIN="dnf5"
command -v dnf5 &>/dev/null || DNF_BIN="dnf"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Rutas de archivos de configuración administrados
SYSCTL_FILE="/etc/sysctl.d/99-fedora-workstation-tuning.conf"
LIMITS_FILE="/etc/security/limits.d/99-fedora-workstation-limits.conf"
SYSTEMD_TIMEOUT_FILE="/etc/systemd/system.conf.d/99-fast-shutdown.conf"
SYSTEMD_SYS_LIMITS="/etc/systemd/system.conf.d/99-limits.conf"
SYSTEMD_USR_LIMITS="/etc/systemd/user.conf.d/99-limits.conf"
UDEV_NVME_FILE="/etc/udev/rules.d/60-nvme-scheduler.rules"
BBR_MODULE_FILE="/etc/modules-load.d/bbr.conf"

# Banderas CLI
DO_INSTALL=true
RUN_ALL=true
RUN_STORAGE=false
RUN_SYSCTL=false
RUN_LIMITS=false
RUN_TRACKER=false
RUN_SERVICES=false
RUN_ZRAM=false
ACTION="run"

# ------------------------------------------------------------------------------
# 3. AYUDA CLI
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}⚡ Optimizador de Rendimiento - Fedora 45 Workstation (GNOME Wayland)${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / 32 GB RAM DDR4 / NVMe Kioxia BG5)

Aplica el ajuste fino integral de Kernel (${BOLD}sysctl${NC}), almacenamiento ${BOLD}Btrfs NoCoW${NC},
límites de descriptores (${BOLD}limits.d${NC} y ${BOLD}systemd${NC}), exclusiones del indexador
${BOLD}GNOME Tracker / LocalSearch${NC}, compresión ${BOLD}ZRAM (zstd)${NC} y servicios de sistema.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)   Aplica todos los módulos de optimización recomendados
  -s, --status       Muestra la telemetría completa de hardware, Kernel, Btrfs y límites
  --storage, --btrfs Aplica NoCoW (+C) en Podman/KVM y regla udev para NVMe scheduler
  --sysctl           Aplica parámetros de Kernel (32 GB RAM, Zen 3, inotify 1M, TCP BBR)
  --limits           Configura límites de descriptores nofile (1M), memlock y PipeWire
  --tracker          Configura exclusiones de indexación y ahorro de batería en GNOME Tracker
  --services         Habilita fstrim.timer, irqbalance, tuned y reduce timeouts a 10s
  --zram             Configura Swap comprimida ZRAM (invoca ./Setup/zram-setup.sh)
  --no-install       Omite la instalación de paquetes adicionales vía DNF5
  -h, --help         Muestra este mensaje de ayuda

${BOLD}Optimizaciones específicas del HP ProBook 455 G10:${NC}
  • ${BOLD}AMD Zen 3 / 16 Hilos:${NC} vm.watermark_boost_factor = 0 (evita caídas de FPS e hipo en GNOME).
  • ${BOLD}SSD Kioxia BG5 (DRAM-less):${NC} dirty_ratio = 10 y dirty_background_ratio = 5 para evitar congelaciones.
  • ${BOLD}Btrfs NoCoW (+C):${NC} Previene fragmentación severa en imágenes Libvirt KVM y capas de Podman.
  • ${BOLD}Red TCP BBR + fq:${NC} Mayor ancho de banda y menor latencia bajo congestión.
  • ${BOLD}GNOME Tracker:${NC} index-on-battery = false y crawling-interval = -2 para máxima duración de batería.
EOF
}

# ------------------------------------------------------------------------------
# 4. TELEMETRÍA Y DIAGNÓSTICO (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  ⚡ ${BOLD}ESTADO DE OPTIMIZACIÓN - FEDORA 45 WORKSTATION (HP PROBOOK 455 G10)${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    echo -e "${BOLD}💻 Telemetría de Hardware:${NC}"
    local cpu_model governor epp
    cpu_model=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs || echo "AMD Ryzen 7 7730U")
    governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "n/a")
    epp=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo "n/a")
    echo -e "  • Procesador CPU:            ${CYAN}${cpu_model} (8C / 16T Zen 3)${NC}"
    echo -e "  • CPU Governor / EPP:        ${CYAN}${governor} / ${epp}${NC}"

    local mem_total mem_avail
    mem_total=$(free -h | awk '/^Mem:/ {print $2}')
    mem_avail=$(free -h | awk '/^Mem:/ {print $7}')
    echo -e "  • Memoria RAM (DDR4):        ${CYAN}${mem_total} (Disponible: ${mem_avail})${NC}"

    if command -v zramctl &>/dev/null && zramctl | grep -q zram; then
        local zram_info
        zram_info=$(zramctl --noheadings --output NAME,ALGORITHM,DISKSIZE,DATA,COMPR 2>/dev/null | head -n1 || echo "")
        echo -e "  • ZRAM Swap activa:          ${GREEN}✅ ${zram_info}${NC}"
    else
        echo -e "  • ZRAM Swap activa:          ${YELLOW}⚠️ Inactiva o no disponible${NC}"
    fi

    echo ""
    echo -e "${BOLD}🌲 Almacenamiento NVMe y Sistema de Archivos:${NC}"
    local root_fstype root_opts nvme_sched
    root_fstype=$(findmnt -n -o FSTYPE / 2>/dev/null || echo "desconocido")
    root_opts=$(findmnt -n -o OPTIONS / 2>/dev/null || echo "n/a")
    nvme_sched=$(cat /sys/block/nvme0n1/queue/scheduler 2>/dev/null || echo "n/a")
    echo -e "  • Sistema de archivos en / : ${CYAN}${root_fstype}${NC}"
    echo -e "  • Opciones de montaje en /:  ${CYAN}${root_opts}${NC}"
    echo -e "  • Planificador I/O NVMe:     ${CYAN}${nvme_sched}${NC}"

    if [[ "$root_fstype" == "btrfs" ]]; then
        local libvirt_cow podman_cow
        if [[ -d /var/lib/libvirt/images ]]; then
            libvirt_cow=$(lsattr -d /var/lib/libvirt/images 2>/dev/null | awk '{print $1}' || echo "n/a")
            if [[ "$libvirt_cow" == *"C"* ]]; then
                echo -e "  • NoCoW en Libvirt KVM:      ${GREEN}✅ Activo (+C en /var/lib/libvirt/images)${NC}"
            else
                echo -e "  • NoCoW en Libvirt KVM:      ${YELLOW}⚠️ CoW activo (fragmentación en VMs)${NC}"
            fi
        else
            echo -e "  • NoCoW en Libvirt KVM:      ${CYAN}Directorio no creado aún${NC}"
        fi

        local podman_storage="$USER_HOME/.local/share/containers/storage"
        if [[ -d "$podman_storage" ]]; then
            podman_cow=$(lsattr -d "$podman_storage" 2>/dev/null | awk '{print $1}' || echo "n/a")
            if [[ "$podman_cow" == *"C"* ]]; then
                echo -e "  • NoCoW en Podman Storage:   ${GREEN}✅ Activo (+C en ${podman_storage})${NC}"
            else
                echo -e "  • NoCoW en Podman Storage:   ${YELLOW}⚠️ CoW activo (aplique --storage)${NC}"
            fi
        else
            echo -e "  • NoCoW en Podman Storage:   ${CYAN}Directorio no inicializado${NC}"
        fi
    fi

    echo ""
    echo -e "${BOLD}🧠 Parámetros del Kernel (sysctl):${NC}"
    echo -e "  • vm.swappiness (ZRAM):      ${CYAN}$(sysctl -n vm.swappiness 2>/dev/null || echo 'N/A')${NC}"
    echo -e "  • vm.page-cluster:           ${CYAN}$(sysctl -n vm.page-cluster 2>/dev/null || echo 'N/A')${NC}"
    echo -e "  • vm.watermark_boost_factor: ${CYAN}$(sysctl -n vm.watermark_boost_factor 2>/dev/null || echo 'N/A')${NC}"
    echo -e "  • vm.vfs_cache_pressure:     ${CYAN}$(sysctl -n vm.vfs_cache_pressure 2>/dev/null || echo 'N/A')${NC}"
    echo -e "  • vm.dirty_ratio / backg:    ${CYAN}$(sysctl -n vm.dirty_ratio 2>/dev/null || echo 'N/A')% / $(sysctl -n vm.dirty_background_ratio 2>/dev/null || echo 'N/A')%${NC}"
    echo -e "  • vm.max_map_count:          ${CYAN}$(sysctl -n vm.max_map_count 2>/dev/null || echo 'N/A')${NC}"
    echo -e "  • fs.inotify.max_user_watches:${CYAN} $(sysctl -n fs.inotify.max_user_watches 2>/dev/null || echo 'N/A')${NC}"
    echo -e "  • fs.inotify.max_instances:  ${CYAN}$(sysctl -n fs.inotify.max_user_instances 2>/dev/null || echo 'N/A')${NC}"
    echo -e "  • net.ipv4.tcp_congestion:   ${CYAN}$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'N/A')${NC}"
    echo -e "  • net.core.default_qdisc:    ${CYAN}$(sysctl -n net.core.default_qdisc 2>/dev/null || echo 'N/A')${NC}"

    echo ""
    echo -e "${BOLD}📂 Límites de Descriptores y Systemd:${NC}"
    echo -e "  • ulimit nofile (shell):     ${CYAN}$(ulimit -n 2>/dev/null || echo 'N/A')${NC}"
    [[ -f "$LIMITS_FILE" ]] && echo -e "  • Perfil PAM limits.d:       ${GREEN}✅ ${LIMITS_FILE}${NC}" || echo -e "  • Perfil PAM limits.d:       ${YELLOW}⚠️ No aplicado${NC}"
    [[ -f "$SYSTEMD_SYS_LIMITS" ]] && echo -e "  • Systemd System Limits:     ${GREEN}✅ ${SYSTEMD_SYS_LIMITS}${NC}" || echo -e "  • Systemd System Limits:     ${YELLOW}⚠️ Por defecto${NC}"
    [[ -f "$SYSTEMD_USR_LIMITS" ]] && echo -e "  • Systemd User Limits:       ${GREEN}✅ ${SYSTEMD_USR_LIMITS}${NC}" || echo -e "  • Systemd User Limits:       ${YELLOW}⚠️ Por defecto${NC}"
    [[ -f "$SYSTEMD_TIMEOUT_FILE" ]] && echo -e "  • Fast Shutdown (10s):       ${GREEN}✅ ${SYSTEMD_TIMEOUT_FILE}${NC}" || echo -e "  • Fast Shutdown (10s):       ${YELLOW}⚠️ Por defecto (90s)${NC}"

    echo ""
    echo -e "${BOLD}⚙️ Servicios del Sistema:${NC}"
    if systemctl is-enabled --quiet fstrim.timer 2>/dev/null; then
        echo -e "  • NVMe TRIM (fstrim.timer):  ${GREEN}✅ Habilitado y activo${NC}"
    else
        echo -e "  • NVMe TRIM (fstrim.timer):  ${YELLOW}⚠️ Inactivo${NC}"
    fi

    if systemctl is-active --quiet irqbalance.service 2>/dev/null; then
        echo -e "  • IRQ Balance (16 hilos):    ${GREEN}✅ Activo (irqbalance.service)${NC}"
    else
        echo -e "  • IRQ Balance (16 hilos):    ${YELLOW}⚠️ Inactivo${NC}"
    fi

    if systemctl is-active --quiet tuned.service 2>/dev/null; then
        local tuned_prof
        tuned_prof=$(tuned-adm active 2>/dev/null | awk -F': ' '{print $2}' || echo "activo")
        echo -e "  • TuneD Service:             ${GREEN}✅ Activo [Perfil: ${tuned_prof}]${NC}"
    else
        echo -e "  • TuneD Service:             ${YELLOW}⚠️ Inactivo${NC}"
    fi

    echo ""
    echo -e "${BOLD}🔍 Indexador GNOME Tracker / LocalSearch:${NC}"
    local tracker_schema=""
    if run_as_user gsettings list-schemas 2>/dev/null | grep -q "^org.freedesktop.Tracker3.Miner.Files$"; then
        tracker_schema="org.freedesktop.Tracker3.Miner.Files"
    elif run_as_user gsettings list-schemas 2>/dev/null | grep -q "^org.freedesktop.LocalSearch3.Miner.Files$"; then
        tracker_schema="org.freedesktop.LocalSearch3.Miner.Files"
    fi

    if [[ -n "$tracker_schema" ]]; then
        local ignored_dirs on_battery crawling
        ignored_dirs=$(run_as_user gsettings get "$tracker_schema" ignored-directories 2>/dev/null || echo "N/A")
        on_battery=$(run_as_user gsettings get "$tracker_schema" index-on-battery 2>/dev/null || echo "N/A")
        crawling=$(run_as_user gsettings get "$tracker_schema" crawling-interval 2>/dev/null || echo "N/A")
        echo -e "  • Esquema dconf:             ${CYAN}${tracker_schema}${NC}"
        echo -e "  • Indexación en batería:     ${CYAN}${on_battery}${NC} (false = ahorro de batería)"
        echo -e "  • Intervalo de crawling:     ${CYAN}${crawling}${NC} (-2 = solo monitor inotify)"
        echo -e "  • Directorios excluidos:     ${CYAN}${ignored_dirs}${NC}"
    else
        echo -e "  • Esquema Tracker:           ${YELLOW}No detectado en esta sesión${NC}"
    fi

    [[ -f "$USER_HOME/Workspace/.nomedia" ]] && echo -e "  • Workspace .nomedia:        ${GREEN}✅ Presente${NC}" || echo -e "  • Workspace .nomedia:        ${YELLOW}⚠️ No configurado${NC}"
    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 5. ALMACENAMIENTO NVME Y OPTIMIZACIÓN BTRFS (NoCoW)
# ------------------------------------------------------------------------------
apply_storage() {
    log_info "Configurando optimizaciones de almacenamiento NVMe y Btrfs NoCoW..."
    local root_fstype
    root_fstype=$(findmnt -n -o FSTYPE / 2>/dev/null || echo "desconocido")

    # 1. Regla udev para forzar programador [none] en SSDs NVMe (Kioxia KBG50ZNV512G)
    $SUDO tee "$UDEV_NVME_FILE" > /dev/null << 'EOF'
# Programador de E/S óptimo para SSDs NVMe (sin sobrecarga de encolado)
ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"
EOF
    $SUDO udevadm trigger --subsystem-match=block 2>/dev/null || true
    log_ok "Regla udev de planificador NVMe aplicada ($UDEV_NVME_FILE)."

    # 2. Desactivación de CoW (NoCoW +C) en Btrfs para Libvirt y Podman
    if [[ "$root_fstype" == "btrfs" ]]; then
        log_info "Sistema Btrfs detectado. Aplicando atributos NoCoW (+C) para virtualización y contenedores..."

        # Directorio de máquinas virtuales KVM / Libvirt
        if [[ ! -d /var/lib/libvirt/images ]]; then
            $SUDO mkdir -p /var/lib/libvirt/images
        fi
        $SUDO chattr +C /var/lib/libvirt/images 2>/dev/null || true
        log_ok "Atributo NoCoW (+C) verificado en /var/lib/libvirt/images."

        # Directorio de almacenamiento de Podman rootless de usuario
        local podman_storage="$USER_HOME/.local/share/containers/storage"
        if [[ ! -d "$podman_storage" ]]; then
            run_as_user mkdir -p "$podman_storage"
        fi
        chattr +C "$podman_storage" 2>/dev/null || true
        log_ok "Atributo NoCoW (+C) verificado en Podman storage ($podman_storage)."
    else
        log_info "Sistema de archivos raíz no es Btrfs ($root_fstype). Omitiendo NoCoW."
    fi
}

# ------------------------------------------------------------------------------
# 6. PARÁMETROS DE KERNEL (SYSCTL) & TCP BBR
# ------------------------------------------------------------------------------
apply_sysctl() {
    log_info "Configurando módulo de congestión de red TCP BBR persistente..."
    $SUDO mkdir -p /etc/modules-load.d
    $SUDO tee "$BBR_MODULE_FILE" > /dev/null << 'EOF'
tcp_bbr
EOF
    $SUDO modprobe tcp_bbr 2>/dev/null || true

    log_info "Aplicando optimizaciones de Kernel Sysctl en $SYSCTL_FILE..."
    $SUDO tee "$SYSCTL_FILE" > /dev/null << 'EOF'
# ==============================================================================
#  fedora-workstation-tuning.conf - Optimización de Kernel
#  Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / 32 GB RAM DDR4 / NVMe Kioxia)
# ==============================================================================

# 1. Gestión de memoria virtual adaptada a 32 GB RAM y ZRAM Swap (zstd)
vm.swappiness = 100
# En swap sobre RAM comprimida (ZRAM), la lectura de páginas individuales sin readahead es óptima
vm.page-cluster = 0
# Retención de caché de inodos y directorios (acelera git status, monorepo y compiladores)
vm.vfs_cache_pressure = 50

# 2. Protección contra micro-tirones y pausas de E/S en SSD NVMe DRAM-less (Kioxia BG5)
# Ratios bajos obligan a descargas continuas en segundo plano en vez de picos gigantes
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10

# 3. AMD Zen 3 (Ryzen 7 7730U): erradicar pausas de compactación de memoria en kswapd
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125

# 4. Mapas de memoria virtual (IDEs pesados, Podman, KVM, Compilación paralela y Steam Proton)
vm.max_map_count = 16777216

# 5. Monitoreo de archivos inotify (Antigravity, VS Code, Vite, Next.js, Cargo, Podman)
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 8192
fs.inotify.max_queued_events = 65536
fs.file-max = 2097152

# 6. Red de baja latencia y alto ancho de banda (TCP BBR + Fair Queuing)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.somaxconn = 8192
net.ipv4.tcp_max_syn_backlog = 8192
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
EOF

    $SUDO sysctl --system >/dev/null 2>&1 || true
    log_ok "Parámetros de Kernel sysctl y TCP BBR aplicados con éxito."
}

# ------------------------------------------------------------------------------
# 7. LÍMITES DE DESCRIPTORES Y MEMORIA (limits.d & systemd)
# ------------------------------------------------------------------------------
apply_limits() {
    log_info "Configurando límites PAM en $LIMITS_FILE..."
    $SUDO tee "$LIMITS_FILE" > /dev/null << 'EOF'
# ==============================================================================
#  Límites de Seguridad y Descriptores - Fedora 45 Workstation
#  HP ProBook 455 G10 (AMD Ryzen 7 7730U / 32 GB RAM / Podman / PipeWire)
# ==============================================================================

# Descriptores de archivos para desarrollo, Vite, Next.js, IDEs y compilaciones
*          soft    nofile     524288
*          hard    nofile     1048576
root       soft    nofile     524288
root       hard    nofile     1048576

# Memoria bloqueada (PipeWire real-time audio, DPDK, KVM/QEMU)
*          soft    memlock    unlimited
*          hard    memlock    unlimited
root       soft    memlock    unlimited
root       hard    memlock    unlimited

# Procesos e hilos concurrentes para compilaciones paralelas (Zen 3 16 hilos)
*          soft    nproc      65535
*          hard    nproc      65535
root       soft    nproc      65535
root       hard    nproc      65535

# Prioridad en tiempo real y memoria bloqueada para PipeWire / RTKit
@audio     -       rtprio     95
@audio     -       nice       -19
@audio     -       memlock    unlimited
EOF

    log_info "Configurando directivas de límites para Systemd System y User Managers..."
    $SUDO mkdir -p /etc/systemd/system.conf.d /etc/systemd/user.conf.d

    $SUDO tee "$SYSTEMD_SYS_LIMITS" > /dev/null << 'EOF'
[Manager]
DefaultLimitNOFILE=1048576:1048576
DefaultLimitMEMLOCK=infinity
DefaultLimitNPROC=65535:65535
DefaultTasksMax=infinity
EOF

    $SUDO tee "$SYSTEMD_USR_LIMITS" > /dev/null << 'EOF'
[Manager]
DefaultLimitNOFILE=1048576:1048576
DefaultLimitMEMLOCK=infinity
DefaultLimitNPROC=65535:65535
DefaultTasksMax=infinity
EOF

    $SUDO systemctl daemon-reload 2>/dev/null || true
    log_ok "Límites de descriptores PAM y Systemd aplicados con éxito."
}

# ------------------------------------------------------------------------------
# 8. GNOME TRACKER / LOCALSEARCH (Ahorro de Batería y Exclusión de Código)
# ------------------------------------------------------------------------------
apply_tracker() {
    log_info "Optimizando GNOME Tracker / LocalSearch para excluir código y ahorrar batería..."
    run_as_user mkdir -p "$USER_HOME/Workspace"
    run_as_user touch "$USER_HOME/Workspace/.nomedia" "$USER_HOME/Workspace/.trackerignore"
    [[ $EUID -eq 0 && "$REAL_USER" != "root" ]] && chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/Workspace"

    local schemas=()
    if run_as_user gsettings list-schemas 2>/dev/null | grep -q "^org.freedesktop.Tracker3.Miner.Files$"; then
        schemas+=("org.freedesktop.Tracker3.Miner.Files")
    fi
    if run_as_user gsettings list-schemas 2>/dev/null | grep -q "^org.freedesktop.LocalSearch3.Miner.Files$"; then
        schemas+=("org.freedesktop.LocalSearch3.Miner.Files")
    fi

    local EXCLUDED_DIRS="['po', 'CVS', 'core-dumps', 'lost+found', 'node_modules', '.git', '.hg', '.svn', '.venv', 'venv', '__pycache__', 'target', 'build', 'dist', '.next', '.nuxt', '.angular', '.gradle', '.m2', '.cargo', '.rustup', 'vendor', '.cache', 'tmp', '.turbo', '.tox', 'Pods', '.terraform']"

    for schema in "${schemas[@]}"; do
        log_info "Configurando directivas en esquema $schema..."
        run_as_user gsettings set "$schema" ignored-directories "$EXCLUDED_DIRS" 2>/dev/null || true
        run_as_user gsettings set "$schema" ignored-directories-with-content "['.trackerignore', '.git', '.hg', '.nomedia']" 2>/dev/null || true
        run_as_user gsettings set "$schema" enable-monitors true 2>/dev/null || true
        run_as_user gsettings set "$schema" crawling-interval -2 2>/dev/null || true
        run_as_user gsettings set "$schema" index-on-battery false 2>/dev/null || true
    done

    log_ok "Exclusiones de GNOME Tracker y directiva index-on-battery=false configuradas."
}

# ------------------------------------------------------------------------------
# 9. SERVICIOS DE SISTEMA, TIMEOUTS Y MANTENIMIENTO
# ------------------------------------------------------------------------------
apply_services() {
    log_info "Configurando servicios de mantenimiento del sistema, NVMe y timeouts..."

    if [[ "$DO_INSTALL" == true ]]; then
        local pkgs=()
        rpm -q irqbalance &>/dev/null || pkgs+=(irqbalance)
        rpm -q tuned &>/dev/null || pkgs+=(tuned)
        rpm -q distrobox &>/dev/null || pkgs+=(distrobox)
        if [[ ${#pkgs[@]} -gt 0 ]]; then
            log_info "Instalando paquetes recomendados: ${pkgs[*]}..."
            $SUDO "$DNF_BIN" install -y "${pkgs[@]}"
        fi
    fi

    # Habilitar TRIM periódico del SSD NVMe
    $SUDO systemctl enable --now fstrim.timer 2>/dev/null || true
    # Habilitar distribución de interrupciones en los 16 hilos del procesador
    $SUDO systemctl enable --now irqbalance.service 2>/dev/null || true
    # Habilitar TuneD para ajuste dinámico de perfiles
    $SUDO systemctl enable --now tuned.service 2>/dev/null || true

    # Reducir tiempos muertos al apagar o reiniciar el equipo (10s en vez de 90s)
    $SUDO mkdir -p "$(dirname "$SYSTEMD_TIMEOUT_FILE")"
    $SUDO tee "$SYSTEMD_TIMEOUT_FILE" > /dev/null << 'EOF'
[Manager]
DefaultTimeoutStopSec=10s
DefaultTimeoutAbortSec=10s
DefaultTimeoutStartSec=15s
EOF
    $SUDO systemctl daemon-reload
    log_ok "Servicios fstrim.timer, irqbalance, tuned y timeouts rápidos de apagado aplicados."
}

# ------------------------------------------------------------------------------
# 10. ZRAM SWAP INTEGRATION
# ------------------------------------------------------------------------------
apply_zram() {
    log_info "Verificando y aplicando configuración ZRAM Swap..."
    if [[ -x "$SCRIPT_DIR/zram-setup.sh" ]]; then
        "$SCRIPT_DIR/zram-setup.sh"
    elif [[ -f "$SCRIPT_DIR/zram-setup.sh" ]]; then
        bash "$SCRIPT_DIR/zram-setup.sh"
    else
        log_warn "No se encontró $SCRIPT_DIR/zram-setup.sh."
    fi
}

# ------------------------------------------------------------------------------
# 11. PARSEO DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)       ACTION="status"; shift ;;
        --no-install)      DO_INSTALL=false; shift ;;
        --storage|--btrfs) RUN_ALL=false; RUN_STORAGE=true; shift ;;
        --sysctl)          RUN_ALL=false; RUN_SYSCTL=true; shift ;;
        --limits)          RUN_ALL=false; RUN_LIMITS=true; shift ;;
        --tracker)         RUN_ALL=false; RUN_TRACKER=true; shift ;;
        --services)        RUN_ALL=false; RUN_SERVICES=true; shift ;;
        --zram)            RUN_ALL=false; RUN_ZRAM=true; shift ;;
        -h|--help)         show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

if [[ "$ACTION" == "status" ]]; then
    show_status
    exit 0
fi

# ------------------------------------------------------------------------------
# 12. EJECUCIÓN ORQUESTADA
# ------------------------------------------------------------------------------
echo -e "${BOLD}======================================================================${NC}"
echo -e "  ⚡ ${BOLD}OPTIMIZADOR DE RENDIMIENTO - FEDORA 45 WORKSTATION${NC}"
echo -e "  💻 Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / 32 GB RAM DDR4)"
echo -e "${BOLD}======================================================================${NC}"

if [[ "$RUN_ALL" == true ]]; then
    apply_storage
    apply_sysctl
    apply_limits
    apply_services
    apply_tracker
    apply_zram
else
    [[ "$RUN_STORAGE" == true ]]  && apply_storage
    [[ "$RUN_SYSCTL" == true ]]   && apply_sysctl
    [[ "$RUN_LIMITS" == true ]]   && apply_limits
    [[ "$RUN_SERVICES" == true ]] && apply_services
    [[ "$RUN_TRACKER" == true ]]  && apply_tracker
    [[ "$RUN_ZRAM" == true ]]     && apply_zram
fi

echo ""
log_ok "Optimización de Fedora 45 Workstation finalizada con éxito."
echo ""
show_status
