#!/usr/bin/env bash
# ==============================================================================
# cachyos-tuning.sh - Optimizador y Ajuste de Rendimiento Extremo para CachyOS
# ==============================================================================
# Hardware:  HP ProBook 455 G10
# CPU:       AMD Ryzen 7 7730U (8 núcleos / 16 hilos Zen 3 / Barcelo-R, boost 4.5 GHz)
# GPU:       AMD Radeon Graphics (Vega 8 / Barcelo, Mesa RADV, VA-API hardware)
# RAM:       32 GB DDR4 3200 MHz con ZRAM Swap (zstd) + UKSMD/KSM
# NVMe:      512 GB SSD NVMe Kioxia KBG50ZNV512G (Kyber I/O Scheduler + fstrim)
# Pantallas: Topología Triple Monitor FHD 1080p (DP-3, DP-4, eDP-1)
# Entorno:   GNOME Shell 51+ (Wayland / Mutter)
# ==============================================================================
# Uso:
#   ./cachyos-tuning.sh                 -> Aplica todas las optimizaciones recomendadas
#   ./cachyos-tuning.sh --status        -> Muestra telemetría completa de rendimiento y estado
#   ./cachyos-tuning.sh --no-install    -> Aplica optimizaciones sin instalar paquetes pacman
#   ./cachyos-tuning.sh --sysctl        -> Aplica únicamente los ajustes de Kernel Sysctl
#   ./cachyos-tuning.sh --network       -> Carga módulos (BBR, CAKE) y optimiza stack de red
#   ./cachyos-tuning.sh --nvme          -> Configura planificador Kyber para NVMe y TRIM
#   ./cachyos-tuning.sh --limits        -> Aplica límites de descriptores (limits.d y systemd)
#   ./cachyos-tuning.sh --services      -> Configura e inicia Ananicy-CPP, irqbalance, fstrim
#   ./cachyos-tuning.sh --gnome         -> Optimiza Mutter Wayland, Triple Pantalla y Tracker
#   ./cachyos-tuning.sh --tracker-fast  -> Excluye carpetas masivas de desarrollo en Tracker 3
#   ./cachyos-tuning.sh --help          -> Muestra la ayuda detallada
# ==============================================================================

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN ESTÉTICA
# ------------------------------------------------------------------------------
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
MAGENTA=$'\033[0;35m'
NC=$'\033[0m'

log_info()    { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()      { echo -e "${GREEN}✅ $1${NC}"; }
log_warn()    { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()     { echo -e "${RED}❌ $1${NC}"; }
log_section() {
    echo ""
    echo -e "${BOLD}${BLUE}=== $1 ===${NC}"
}

# ------------------------------------------------------------------------------
# 2. PRIVILEGIOS Y CONTEXTO DE USUARIO (D-Bus / Wayland Aware)
# ------------------------------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
    if ! command -v sudo &>/dev/null; then
        log_err "'sudo' no está disponible. Ejecuta este script como root o instala sudo."
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

# Ejecuta comandos en el contexto de usuario real garantizando bus D-Bus y Wayland
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
        "$@"
    fi
}

# ------------------------------------------------------------------------------
# 3. AYUDA INTERACTIVA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
${BOLD}⚡ Optimizador de Rendimiento Extremo - CachyOS Workstation (GNOME Wayland)${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / 32 GB RAM / NVMe Kioxia / Triple FHD)

${BOLD}Uso:${NC}
  $0 [OPCION]

${BOLD}Opciones principales:${NC}
  (sin argumentos)       Aplica todas las optimizaciones de sistema, kernel, red, NVMe, GNOME y límites.
  --status, -s           Muestra el diagnóstico exhaustivo de telemetría y estado de parámetros.
  --no-install           Aplica las configuraciones de kernel, límites y entorno sin descargar paquetes pacman.
  --sysctl               Aplica únicamente la configuración de parámetros de Kernel Sysctl (/etc/sysctl.d/).
  --network              Carga módulos de red (tcp_bbr, sch_cake) y optimiza stack TCP / qdisc.
  --nvme                 Configura reglas udev para planificador I/O Kyber en SSD NVMe Kioxia y fstrim.
  --limits               Aplica límites de descriptores y memoria (limits.d y systemd system/user).
  --services             Configura e inicia Ananicy-CPP, irqbalance, fstrim y mantenimiento.
  --gnome                Aplica optimizaciones para Mutter Wayland, triple monitor y exclusiones de Tracker 3.
  --tracker-fast         Configura Tracker 3 para excluir masivamente carpetas pesadas de desarrollo.
  --help, -h             Muestra este mensaje de ayuda.

${BOLD}Optimizaciones incluidas para HP ProBook 455 G10:${NC}
  1. ${CYAN}CPU Zen 3 (16T):${NC}    Alineación con amd-pstate-epp, ananicy-cpp y balanceo multinúcleo con irqbalance.
  2. ${CYAN}Memoria 32 GB:${NC}      Swappiness 180 (ZRAM zstd), page-cluster=0, dirty ratios suaves para evitar tirones.
  3. ${CYAN}NVMe Kioxia 512GB:${NC}  Planificador I/O Kyber de ultra-baja latencia y mantenimiento fstrim.timer.
  4. ${CYAN}Red BBR + CAKE:${NC}     Carga persistente de módulos tcp_bbr y sch_cake con buffers optimizados.
  5. ${CYAN}Límites Proceso:${NC}    1M descriptores nofile, memlock ilimitado y recarga en caliente de systemd user/system.
  6. ${CYAN}GNOME / Mutter:${NC}     Espacios de trabajo en triple pantalla, render nítido XWayland 1.0 y exclusión Tracker.
EOF
}

# ------------------------------------------------------------------------------
# 4. TELEMETRÍA Y DIAGNÓSTICO DE ESTADO
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}${MAGENTA}=================================================================${NC}"
    echo -e "${BOLD}🔍 DIAGNÓSTICO DE RENDIMIENTO Y ESTADO - CACHYOS WORKSTATION${NC}"
    echo -e "Hardware: HP ProBook 455 G10 | AMD Ryzen 7 7730U (8C/16T) | 32 GB RAM"
    echo -e "${BOLD}${MAGENTA}=================================================================${NC}"

    # 1. CPU & Energía
    local cpu_model governor epp driver pprofile
    cpu_model=$(lscpu 2>/dev/null | grep "Model name:" | sed 's/Model name:[ \t]*//' || echo "AMD Ryzen 7 7730U")
    governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "n/a")
    driver=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo "n/a")
    epp=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo "n/a")
    pprofile=$(powerprofilesctl get 2>/dev/null || echo "n/a")

    echo -e "${BOLD}⚙️  CPU & Energía AMD:${NC}"
    echo -e "  • Procesador:                  ${CYAN}${cpu_model}${NC}"
    echo -e "  • Controlador CPU:             ${CYAN}${driver}${NC}"
    echo -e "  • Governor Activo:             ${CYAN}${governor}${NC}"
    echo -e "  • AMD P-State EPP:             ${CYAN}${epp}${NC}"
    echo -e "  • Perfil de Energía PPD:       ${CYAN}${pprofile}${NC}"

    # 2. Kernel & Planificación
    local kernel_rel sched_ext_state
    kernel_rel=$(uname -r)
    sched_ext_state=$(cat /sys/kernel/sched_ext/state 2>/dev/null || echo "disabled/bore-default")

    echo ""
    echo -e "${BOLD}🐧 Kernel & Planificadores:${NC}"
    echo -e "  • Release Kernel:              ${CYAN}${kernel_rel}${NC}"
    echo -e "  • Estado Sched-ext (scx):      ${CYAN}${sched_ext_state}${NC}"
    echo -e "  • Ananicy-CPP (Auto-Nice):     $(systemctl is-active --quiet ananicy-cpp.service 2>/dev/null && echo -e "${GREEN}Activo (Reglas CachyOS)${NC}" || echo -e "${YELLOW}Inactivo${NC}")"
    echo -e "  • Irqbalance (SMP IRQ 16T):    $(systemctl is-active --quiet irqbalance.service 2>/dev/null && echo -e "${GREEN}Activo${NC}" || echo -e "${YELLOW}Inactivo / No instalado${NC}")"

    # 3. Memoria, ZRAM y Almacenamiento NVMe
    local zram_info nvme_sched
    zram_info=$(if command -v zramctl &>/dev/null && [[ -n "$(zramctl 2>/dev/null)" ]]; then
        zramctl --noheadings -o ALGORITHM,DISKSIZE 2>/dev/null | head -n1
    else
        echo "Inactivo"
    fi)
    nvme_sched=$(cat /sys/block/nvme0n1/queue/scheduler 2>/dev/null || echo "n/a")

    echo ""
    echo -e "${BOLD}💾 Memoria, ZRAM y NVMe (512 GB Kioxia):${NC}"
    echo -e "  • ZRAM Swap en RAM:            ${CYAN}${zram_info}${NC}"
    echo -e "  • Planificador NVMe:           ${CYAN}${nvme_sched}${NC}"
    echo -e "  • Fstrim Timer (SSD TRIM):     $(systemctl is-enabled --quiet fstrim.timer 2>/dev/null && echo -e "${GREEN}Habilitado${NC}" || echo -e "${YELLOW}Inactivo${NC}")"
    echo -e "  • Paccache Timer (Cache):      $(systemctl is-enabled --quiet paccache.timer 2>/dev/null && echo -e "${GREEN}Habilitado${NC}" || echo -e "${YELLOW}Inactivo${NC}")"

    # 4. Parámetros Críticos de Kernel Sysctl
    echo ""
    echo -e "${BOLD}🎛️  Parámetros de Kernel Sysctl:${NC}"
    echo -e "  • inotify max_user_watches:    ${CYAN}$(sysctl -n fs.inotify.max_user_watches 2>/dev/null || echo 'n/a')${NC}"
    echo -e "  • inotify max_user_instances:  ${CYAN}$(sysctl -n fs.inotify.max_user_instances 2>/dev/null || echo 'n/a')${NC}"
    echo -e "  • vm.max_map_count:            ${CYAN}$(sysctl -n vm.max_map_count 2>/dev/null || echo 'n/a')${NC}"
    echo -e "  • vm.swappiness (ZRAM):        ${CYAN}$(sysctl -n vm.swappiness 2>/dev/null || echo 'n/a')${NC}"
    echo -e "  • vm.page-cluster:             ${CYAN}$(sysctl -n vm.page-cluster 2>/dev/null || echo 'n/a')${NC}"
    echo -e "  • vm.vfs_cache_pressure:       ${CYAN}$(sysctl -n vm.vfs_cache_pressure 2>/dev/null || echo 'n/a')${NC}"
    echo -e "  • vm.dirty_ratio / background: ${CYAN}$(sysctl -n vm.dirty_ratio 2>/dev/null || echo 'n/a')% / $(sysctl -n vm.dirty_background_ratio 2>/dev/null || echo 'n/a')%${NC}"
    echo -e "  • net.ipv4.tcp_congestion_ctrl:${CYAN}$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'n/a')${NC}"
    echo -e "  • net.core.default_qdisc:      ${CYAN}$(sysctl -n net.core.default_qdisc 2>/dev/null || echo 'n/a')${NC}"
    echo -e "  • net.ipv4.tcp_fastopen:       ${CYAN}$(sysctl -n net.ipv4.tcp_fastopen 2>/dev/null || echo 'n/a')${NC}"

    # 5. Límites de Proceso y Systemd
    echo ""
    echo -e "${BOLD}📈 Límites de Descriptores y Systemd:${NC}"
    echo -e "  • Límite nofile shell (soft):  ${CYAN}$(ulimit -Sn 2>/dev/null || echo 'n/a')${NC}"
    echo -e "  • Límite nofile shell (hard):  ${CYAN}$(ulimit -Hn 2>/dev/null || echo 'n/a')${NC}"
    echo -e "  • Systemd DefaultLimitNOFILE:  ${CYAN}$(grep -sh "DefaultLimitNOFILE" /etc/systemd/system.conf.d/*.conf /etc/systemd/user.conf.d/*.conf 2>/dev/null | head -n1 || echo 'Por defecto')${NC}"
    echo -e "  • Systemd Stop Timeout:        ${CYAN}$(grep -sh "DefaultTimeoutStopSec" /etc/systemd/system.conf.d/*.conf 2>/dev/null | head -n1 || echo 'Por defecto')${NC}"

    # 6. GNOME Shell, Mutter y Tracker
    local mutter_exp ws_primary xwayland_scale tracker_ignored
    if (run_as_user gsettings list-keys org.gnome.mutter 2>/dev/null || true) | grep -qx "experimental-features"; then
        mutter_exp=$(run_as_user gsettings get org.gnome.mutter experimental-features 2>/dev/null || echo "n/a")
    else
        mutter_exp="No aplicable (GNOME 51+)"
    fi
    ws_primary=$(run_as_user gsettings get org.gnome.mutter workspaces-only-on-primary 2>/dev/null || echo "n/a")
    xwayland_scale=$(run_as_user gsettings get org.gnome.mutter.wayland xwayland-scaling-factor 2>/dev/null || echo "n/a")
    tracker_ignored=$(run_as_user gsettings get org.freedesktop.Tracker3.Miner.Files ignored-directories 2>/dev/null || echo "n/a")

    echo ""
    echo -e "${BOLD}🎨 GNOME Shell 51 (Wayland Mutter Triple Monitor):${NC}"
    echo -e "  • Espacios solo monitor ppal:  ${CYAN}${ws_primary}${NC} (false = triple monitor habilitado)"
    echo -e "  • XWayland Scaling Factor:     ${CYAN}${xwayland_scale}${NC}"
    echo -e "  • Mutter Experimental:         ${CYAN}${mutter_exp}${NC}"
    echo -e "  • Tracker 3 Carpetas Excluidas:${CYAN}${tracker_ignored}${NC}"
    echo -e "${BOLD}${MAGENTA}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 5. MÓDULOS DEL KERNEL Y STACK DE RED (BBR + CAKE)
# ------------------------------------------------------------------------------
apply_network_tuning() {
    log_section "Configurando Módulos de Red (TCP BBR y CAKE Qdisc)"

    log_info "Asegurando carga persistente de módulos 'tcp_bbr' y 'sch_cake'..."
    $SUDO mkdir -p /etc/modules-load.d
    $SUDO tee /etc/modules-load.d/99-cachyos-net.conf > /dev/null << 'EOF'
# Módulos de red de alta velocidad y control de congestión de CachyOS
tcp_bbr
sch_cake
EOF

    # Cargar módulos inmediatamente en el kernel
    $SUDO modprobe tcp_bbr 2>/dev/null || log_warn "El módulo tcp_bbr ya está integrado o no pudo cargarse directamente."
    $SUDO modprobe sch_cake 2>/dev/null || log_warn "El módulo sch_cake ya está integrado o no pudo cargarse directamente."

    log_ok "Módulos de red preparados y registrados en /etc/modules-load.d/99-cachyos-net.conf."
}

# ------------------------------------------------------------------------------
# 6. PARÁMETROS DE KERNEL SYSCTL
# ------------------------------------------------------------------------------
apply_sysctl_tuning() {
    log_section "Configurando Parámetros de Kernel Sysctl para CachyOS Workstation"

    # Asegurar módulos antes de sysctl
    apply_network_tuning

    log_info "Desplegando /etc/sysctl.d/99-cachyos-tuning.conf..."
    $SUDO tee /etc/sysctl.d/99-cachyos-tuning.conf > /dev/null << 'EOF'
# =============================================================================
# CACHYOS HIGH-PERFORMANCE SYSCTL TUNING (HP ProBook 455 G10)
# Hardware: AMD Ryzen 7 7730U (16T) | 32 GB RAM DDR4 | NVMe SSD Kioxia 512GB
# =============================================================================

# 1. Monitoreo de Archivos e Inotify (Crítico para IDEs, Git y Vite/Webpack)
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 8192
fs.file-max = 2097152

# 2. Memoria Virtual y Mapas (Gaming Proton, LLVM, Chromium, Java)
vm.max_map_count = 16777216

# 3. ZRAM Swappiness agresivo y ultra-baja latencia
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
vm.vfs_cache_pressure = 50

# 4. Gestión de Memoria Sucia (Dirty Pages) optimizada para 32 GB RAM y NVMe
# Evita pausas y tirones de E/S síncrona al volcar datos masivos a disco
vm.dirty_background_ratio = 3
vm.dirty_ratio = 6
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500

# 5. Compactación proactiva y HugePages suaves
vm.compaction_proactiveness = 20

# 6. Planificación CPU y Latencia
kernel.nmi_watchdog = 0
kernel.sched_cfs_bandwidth_slice_us = 3000

# 7. Stack de Red TCP de Alta Velocidad (BBR + CAKE)
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_notsent_lowat = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_max_syn_backlog = 8192
net.core.netdev_max_backlog = 8192

# Buffers de red optimizados para Gigabit / Wi-Fi 6
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_tw_reuse = 1
EOF

    log_info "Aplicando cambios de sysctl en el kernel en tiempo de ejecución..."
    $SUDO sysctl --system > /dev/null || true
    log_ok "Parámetros de Kernel Sysctl aplicados con éxito."
}

# ------------------------------------------------------------------------------
# 7. NVME STORAGE & PLANIFICADOR I/O (Kyber + fstrim)
# ------------------------------------------------------------------------------
apply_nvme_tuning() {
    log_section "Configurando Planificador I/O para SSD NVMe Kioxia KBG50ZNV512G"

    log_info "Instalando regla udev para planificador Kyber en discos NVMe..."
    $SUDO tee /etc/udev/rules.d/60-cachyos-nvme.rules > /dev/null << 'EOF'
# Planificador I/O Kyber de ultra-baja latencia para dispositivos NVMe de alta velocidad
ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="kyber"

# Dispositivos SATA SSD / no rotacionales
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="bfq"
EOF

    $SUDO udevadm control --reload-rules 2>/dev/null || true
    $SUDO udevadm trigger --subsystem-match=block 2>/dev/null || true

    # Activar temporizador de descarte periódico de bloques (TRIM) para NVMe
    if systemctl list-unit-files fstrim.timer &>/dev/null; then
        $SUDO systemctl enable --now fstrim.timer 2>/dev/null || true
        log_ok "fstrim.timer habilitado para mantenimiento semanal del SSD NVMe Kioxia."
    fi

    log_ok "Reglas de planificador I/O Kyber aplicadas a dispositivos de bloque."
}

# ------------------------------------------------------------------------------
# 8. LÍMITES DE PROCESO Y SYSTEMD (System & User Sessions)
# ------------------------------------------------------------------------------
apply_limits_tuning() {
    log_section "Configurando Límites de Descriptores, Memoria y Sesiones Systemd"

    log_info "Configurando /etc/security/limits.d/99-dev-limits.conf..."
    $SUDO tee /etc/security/limits.d/99-dev-limits.conf > /dev/null << 'EOF'
# Límites ampliados para compilación masiva, IDEs, bases de datos y gaming
*          soft    nofile     524288
*          hard    nofile     1048576
*          soft    memlock    unlimited
*          hard    memlock    unlimited
*          soft    nproc      512000
*          hard    nproc      512000
EOF

    log_info "Configurando límites en systemd system y user..."
    $SUDO mkdir -p /etc/systemd/system.conf.d /etc/systemd/user.conf.d

    $SUDO tee /etc/systemd/system.conf.d/99-limits.conf > /dev/null << 'EOF'
[Manager]
DefaultLimitNOFILE=1048576:1048576
DefaultLimitMEMLOCK=infinity
DefaultLimitNPROC=512000
DefaultTasksMax=infinity
EOF

    $SUDO tee /etc/systemd/user.conf.d/99-limits.conf > /dev/null << 'EOF'
[Manager]
DefaultLimitNOFILE=1048576:1048576
DefaultLimitMEMLOCK=infinity
DefaultLimitNPROC=512000
DefaultTasksMax=infinity
EOF

    log_info "Configurando timeouts de apagado rápido en Systemd (10s)..."
    $SUDO tee /etc/systemd/system.conf.d/99-fast-shutdown.conf > /dev/null << 'EOF'
[Manager]
DefaultTimeoutStopSec=10s
DefaultTimeoutAbortSec=10s
EOF

    $SUDO tee /etc/systemd/user.conf.d/99-fast-shutdown.conf > /dev/null << 'EOF'
[Manager]
DefaultTimeoutStopSec=10s
DefaultTimeoutAbortSec=10s
EOF

    log_info "Recargando demonio Systemd de sistema y de usuario..."
    $SUDO systemctl daemon-reexec 2>/dev/null || true
    run_as_user systemctl --user daemon-reexec 2>/dev/null || true

    log_ok "Límites de proceso y systemd aplicados y recargados en caliente."
}

# ------------------------------------------------------------------------------
# 9. SERVICIOS DE RENDIMIENTO Y MANTENIMIENTO CACHYOS
# ------------------------------------------------------------------------------
apply_cachyos_services() {
    log_section "Verificando y Habilitando Servicios de Rendimiento"

    # 1. Ananicy-CPP y Reglas CachyOS
    if ! pacman -Q ananicy-cpp &>/dev/null; then
        log_info "Instalando ananicy-cpp y cachyos-ananicy-rules..."
        $SUDO pacman -S --needed --noconfirm ananicy-cpp cachyos-ananicy-rules 2>/dev/null || true
    fi

    if systemctl list-unit-files ananicy-cpp.service &>/dev/null; then
        $SUDO systemctl enable --now ananicy-cpp.service 2>/dev/null || true
        log_ok "Servicio ananicy-cpp activo con reglas de auto-nice optimizadas para CachyOS."
    fi

    # 2. Irqbalance para los 16 hilos del AMD Ryzen 7 7730U
    if ! pacman -Q irqbalance &>/dev/null; then
        log_info "Instalando irqbalance para distribución SMP en los 16 hilos Zen 3..."
        $SUDO pacman -S --needed --noconfirm irqbalance 2>/dev/null || true
    fi

    if systemctl list-unit-files irqbalance.service &>/dev/null; then
        $SUDO systemctl enable --now irqbalance.service 2>/dev/null || true
        log_ok "Servicio irqbalance habilitado y activo."
    fi

    # 3. UKSMD si está disponible
    if systemctl list-unit-files uksmd.service &>/dev/null; then
        $SUDO systemctl enable --now uksmd.service 2>/dev/null || true
        log_ok "Servicio uksmd habilitado."
    fi

    # 4. Paccache Timer para limpieza inteligente de caché Pacman
    if systemctl list-unit-files paccache.timer &>/dev/null; then
        $SUDO systemctl enable --now paccache.timer 2>/dev/null || true
        log_ok "paccache.timer habilitado para rotación limpia de paquetes pacman."
    fi

    # 5. Fstrim Timer
    if systemctl list-unit-files fstrim.timer &>/dev/null; then
        $SUDO systemctl enable --now fstrim.timer 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# 10. OPTIMIZACIÓN DE GNOME WAYLAND, TRIPLE MONITOR Y TRACKER 3
# ------------------------------------------------------------------------------
apply_gnome_tuning() {
    log_section "Configurando GNOME Shell 51 (Mutter Wayland y Triple Pantalla)"

    # Comprobar si gsettings está disponible en el entorno
    if ! command -v gsettings &>/dev/null; then
        log_warn "gsettings no encontrado. Omitiendo optimizaciones gráficas de GNOME."
        return 0
    fi

    log_info "Ajustando Mutter para topología triple monitor (DP-3, DP-4, eDP-1)..."
    # Crítico para triple monitor: workspaces independientes en todas las pantallas
    run_as_user gsettings set org.gnome.mutter workspaces-only-on-primary false 2>/dev/null || true
    run_as_user gsettings set org.gnome.shell.app-switcher current-workspace-only false 2>/dev/null || true

    # Ventanas y tiling fluido
    run_as_user gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter edge-tiling true 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter dynamic-workspaces true 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter attach-modal-dialogs true 2>/dev/null || true

    # Renderizado 1:1 nítido en aplicaciones XWayland para 1080p
    run_as_user gsettings set org.gnome.mutter.wayland xwayland-scaling-factor 1.0 2>/dev/null || true

    # Características experimentales de Mutter si el esquema lo soporta (seguridad para GNOME 47/48/51)
    if (run_as_user gsettings list-keys org.gnome.mutter 2>/dev/null || true) | grep -qx "experimental-features"; then
        run_as_user gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'variable-refresh-rate']" 2>/dev/null || true
        log_ok "Mutter experimental-features (VRR + scale framebuffer) activado."
    fi

    # Optimización del indexador Tracker 3 (LocalSearch) para desarrollo
    log_info "Configurando exclusiones inteligentes de Tracker 3 para estaciones de desarrollo..."
    if (run_as_user gsettings list-schemas 2>/dev/null || true) | grep -q "org.freedesktop.Tracker3.Miner.Files"; then
        run_as_user gsettings set org.freedesktop.Tracker3.Miner.Files index-on-battery false 2>/dev/null || true
        run_as_user gsettings set org.freedesktop.Tracker3.Miner.Files ignored-directories \
            "['node_modules', '.git', '.venv', '.cargo', 'target', 'build', 'dist', '.cache', '.npm', '.rustup', '.local/share/Steam', '.local/share/containers', 'vendor', 'bin', 'obj']" 2>/dev/null || true
        log_ok "Tracker 3 configurado: batería protegida y carpetas de dependencias ignoradas."
    fi

    log_ok "Optimizaciones de GNOME Wayland y Mutter aplicadas correctamente."
}

# ------------------------------------------------------------------------------
# 11. ENTORNO DE CONTENEDORES Y DESARROLLO (Podman Rootless + Distrobox)
# ------------------------------------------------------------------------------
install_dev_tools() {
    log_section "Verificando Herramientas de Desarrollo y Contenedores"

    log_info "Comprobando Podman y Distrobox en Pacman..."
    $SUDO pacman -S --needed --noconfirm distrobox podman 2>/dev/null || true

    # Verificar que el usuario real tenga rangos en /etc/subuid y /etc/subgid
    if [[ -f /etc/subuid && -f /etc/subgid ]]; then
        if ! grep -q "^${REAL_USER}:" /etc/subuid 2>/dev/null; then
            log_info "Registrando subuid para usuario $REAL_USER (Podman Rootless)..."
            echo "${REAL_USER}:100000:65536" | $SUDO tee -a /etc/subuid >/dev/null
        fi
        if ! grep -q "^${REAL_USER}:" /etc/subgid 2>/dev/null; then
            log_info "Registrando subgid para usuario $REAL_USER (Podman Rootless)..."
            echo "${REAL_USER}:100000:65536" | $SUDO tee -a /etc/subgid >/dev/null
        fi
    fi

    log_ok "Podman Rootless y Distrobox listos para el usuario ${REAL_USER}."
}

# ------------------------------------------------------------------------------
# 12. DESPACHO DE COMANDOS CLI
# ------------------------------------------------------------------------------
case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --sysctl)
        apply_sysctl_tuning
        log_ok "Módulo Sysctl finalizado con éxito."
        ;;
    --network)
        apply_network_tuning
        $SUDO sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null || true
        $SUDO sysctl -w net.core.default_qdisc=cake 2>/dev/null || true
        log_ok "Módulo Network finalizado con éxito."
        ;;
    --nvme)
        apply_nvme_tuning
        log_ok "Módulo NVMe finalizado con éxito."
        ;;
    --limits)
        apply_limits_tuning
        log_ok "Módulo Límites y Systemd finalizado con éxito."
        ;;
    --services)
        apply_cachyos_services
        log_ok "Módulo Servicios de Rendimiento finalizado con éxito."
        ;;
    --gnome)
        apply_gnome_tuning
        log_ok "Módulo GNOME y Tracker finalizado con éxito."
        ;;
    --tracker-fast)
        apply_gnome_tuning
        log_ok "Exclusiones de Tracker 3 aplicadas con éxito."
        ;;
    --no-install)
        log_section "Aplicando Optimizaciones CachyOS [Modo Sin Descargas Pacman]"
        apply_network_tuning
        apply_sysctl_tuning
        apply_nvme_tuning
        apply_limits_tuning
        apply_gnome_tuning
        echo ""
        log_ok "Optimizaciones sin instalación de paquetes completadas."
        ;;
    "")
        log_section "Iniciando Optimización Integral - CachyOS Workstation (HP ProBook 455 G10)"
        apply_network_tuning
        apply_sysctl_tuning
        apply_nvme_tuning
        apply_limits_tuning
        apply_cachyos_services
        apply_gnome_tuning
        install_dev_tools
        echo ""
        echo -e "${BOLD}${GREEN}=================================================================${NC}"
        echo -e "${BOLD}✅ OPTIMIZACIÓN INTEGRAL DE CACHYOS WORKSTATION FINALIZADA CON ÉXITO${NC}"
        echo -e "${BOLD}${GREEN}=================================================================${NC}"
        ;;
    *)
        log_err "Opción no reconocida: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
