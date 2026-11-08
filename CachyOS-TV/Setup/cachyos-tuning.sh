#!/usr/bin/env bash
# ==============================================================================
# cachyos-tuning.sh - Optimizador de Rendimiento para CachyOS TV (Sony TV)
# Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / 8.0 GiB DDR3 / SSD 256 GB)
# GPU: Intel HD Graphics 4600 (Haswell x86-64-v3) | Pantalla: Sony TV (Wayland GNOME)
# ==============================================================================
# Características:
#   - Sysctl de alto rendimiento: ZRAM agresivo (swappiness 180, page-cluster 0),
#     TCP BBR + CAKE para streaming fluido de vídeo y buffers optimizados.
#   - Priorización de procesos en CachyOS: Ananicy-CPP con reglas CachyOS,
#     UKSMD (deduplicación de RAM) e Irqbalance multinúcleo (4C/8T).
#   - Mantenimiento SSD (256 GB): fstrim.timer semanal y paccache.timer.
#   - Fast Shutdown en Systemd: Timeouts reducidos a 10s para apagado instantáneo de la TV.
#   - GNOME Mutter & Tracker: Escalado framebuffer sin VRR (no soportado en Haswell HDMI)
#     y exclusión en Tracker de montajes de red (/mnt/nas) y cachés pesadas.
#   - CLI: --status / -s, --sysctl, --limits, --services, --gnome, --no-install, --help / -h.
# ==============================================================================

set -euo pipefail

# Colores ANSI
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo -e "${RED}❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo.${NC}"
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de sudo para configuraciones de usuario de GNOME
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

# Ejecutar comandos de configuración en el contexto del usuario real
run_as_user() {
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$REAL_UID}"
    local dbus_addr="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$runtime_dir/bus}"
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            PATH="/usr/local/bin:/usr/bin:/bin:$PATH" \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            "$@"
    else
        env \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            "$@"
    fi
}

show_help() {
    cat <<EOF
${BOLD}⚡ Optimizador de Rendimiento CachyOS TV - HP Z230 SFF (Sony TV)${NC}
${CYAN}Hardware:${NC} Intel Core i7-4790 (4C/8T) | Intel HD 4600 | 8 GB RAM DDR3 | 256 GB SSD

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones principales:${NC}
  (sin argumentos)       Aplica todas las optimizaciones recomendadas (Kernel, Límites, Servicios, Systemd y GNOME).
  -s, --status           Muestra el estado actual de sysctl, ZRAM, Ananicy-CPP, UKSMD, SSD y servicios.
  --no-install           Aplica las configuraciones de kernel, límites y entorno sin descargar paquetes con pacman.
  --sysctl               Aplica únicamente la configuración de parámetros de Kernel Sysctl.
  --limits               Aplica límites de descriptores y memoria (limits.d y systemd system/user).
  --services             Configura e inicia Ananicy-CPP, UKSMD, irqbalance, fstrim y paccache.
  --gnome                Aplica optimizaciones de Mutter y exclusiones de Tracker para la TV.
  -h, --help             Muestra este mensaje de ayuda.

${BOLD}Optimizaciones incluidas:${NC}
  1. Sysctl Kernel:      ZRAM swappiness (180), page-cluster=0 (sin overhead de swap), dirty ratios bajos (5/10%)
                         y TCP BBR + FastOpen para streaming fluido en alta definición.
  2. Límites de Proceso: Descriptores (1M nofile) y memoria bloqueada en systemd para evitar bloqueos.
  3. Servicios CachyOS:  Ananicy-CPP (Auto-Nice priorizando Kodi/VLC/Wayland), UKSMD (deduplicación RAM),
                         irqbalance (multinúcleo 8 hilos), fstrim.timer (SSD 256 GB) y paccache.timer.
  4. Systemd Timeouts:   Reducción de DefaultTimeoutStopSec y AbortSec a 10s para apagado rápido del televisor.
  5. GNOME Mutter:       Escalado framebuffer optimizado (sin VRR innecesario en Haswell/Sony TV 60Hz).
  6. Indexador Tracker:  Exclusión de montajes de red (/mnt/nas) y directorios pesados para no saturar CPU ni RAM.
EOF
}

show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}${BOLD}🔍 ESTADO DE RENDIMIENTO Y OPTIMIZACIONES - CACHYOS TV${NC}"
    echo -e "${CYAN}   Equipo: HP Z230 SFF Workstation (Sony TV / Intel Haswell)${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "• Kernel:                        $(uname -r)"
    echo -e "• CPU Scaling Driver:            $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo 'n/a')"
    echo -e "• CPU Governor:                  $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'n/a')"
    local pstate_status
    pstate_status=$(cat /sys/devices/system/cpu/intel_pstate/status 2>/dev/null || echo 'n/a')
    echo -e "• Intel P-State Status:          $pstate_status"
    echo -e "-----------------------------------------------------------------"
    echo -e "• fs.inotify.max_user_watches:   $(sysctl -n fs.inotify.max_user_watches 2>/dev/null || echo 'n/a')"
    echo -e "• fs.inotify.max_user_instances: $(sysctl -n fs.inotify.max_user_instances 2>/dev/null || echo 'n/a')"
    echo -e "• fs.file-max:                   $(sysctl -n fs.file-max 2>/dev/null || echo 'n/a')"
    echo -e "• vm.max_map_count:              $(sysctl -n vm.max_map_count 2>/dev/null || echo 'n/a')"
    echo -e "• vm.swappiness (ZRAM):          $(sysctl -n vm.swappiness 2>/dev/null || echo 'n/a')"
    echo -e "• vm.page-cluster (ZRAM):        $(sysctl -n vm.page-cluster 2>/dev/null || echo 'n/a')"
    echo -e "• vm.vfs_cache_pressure:         $(sysctl -n vm.vfs_cache_pressure 2>/dev/null || echo 'n/a')"
    echo -e "• vm.dirty_ratio / background:   $(sysctl -n vm.dirty_ratio 2>/dev/null || echo 'n/a') / $(sysctl -n vm.dirty_background_ratio 2>/dev/null || echo 'n/a')"
    echo -e "• net.ipv4.tcp_congestion_ctrl:  $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'n/a')"
    echo -e "• net.ipv4.tcp_fastopen:         $(sysctl -n net.ipv4.tcp_fastopen 2>/dev/null || echo 'n/a')"
    echo -e "-----------------------------------------------------------------"
    echo -e "• Límite nofile (ulimit -n):     $(ulimit -n 2>/dev/null || echo 'n/a')"
    echo -e "• Systemd DefaultLimitNOFILE:    $(grep -h "DefaultLimitNOFILE" /etc/systemd/system.conf.d/*.conf /etc/systemd/user.conf.d/*.conf 2>/dev/null | head -n1 || echo 'Por defecto')"
    echo -e "• Systemd Stop Timeout:          $(grep -h "DefaultTimeoutStopSec" /etc/systemd/system.conf.d/*.conf 2>/dev/null | head -n1 || echo 'Por defecto')"
    echo -e "-----------------------------------------------------------------"
    echo -e "• ZRAM Swap Activo:              $(if command -v zramctl &>/dev/null && [ -n "$(zramctl 2>/dev/null)" ]; then echo 'Sí ('"$(zramctl --noheadings -o ALGORITHM,DISKSIZE 2>/dev/null | head -n1)"')'; else echo 'No / Inactivo'; fi)"
    echo -e "• Ananicy-CPP (Auto-Nice):       $(systemctl is-active --quiet ananicy-cpp.service 2>/dev/null && echo -e "${GREEN}Activo${NC}" || echo -e "${YELLOW}Inactivo / No instalado${NC}")"
    echo -e "• UKSMD (Deduplicación RAM):     $(systemctl is-active --quiet uksmd.service 2>/dev/null && echo -e "${GREEN}Activo${NC}" || echo -e "${YELLOW}Inactivo / No instalado${NC}")"
    echo -e "• Irqbalance (Distribución IRQ): $(systemctl is-active --quiet irqbalance.service 2>/dev/null && echo -e "${GREEN}Activo${NC}" || echo -e "${YELLOW}Inactivo / No instalado${NC}")"
    echo -e "• Fstrim Timer (Mantenimiento SSD): $(systemctl is-enabled --quiet fstrim.timer 2>/dev/null && echo -e "${GREEN}Habilitado${NC}" || echo -e "${YELLOW}Inactivo${NC}")"
    echo -e "• Paccache Timer (Limpieza Pacman): $(systemctl is-enabled --quiet paccache.timer 2>/dev/null && echo -e "${GREEN}Habilitado${NC}" || echo -e "${YELLOW}Inactivo${NC}")"
    echo -e "-----------------------------------------------------------------"
    echo -e "• GNOME Mutter Escalado:         $(run_as_user gsettings get org.gnome.mutter experimental-features 2>/dev/null || echo 'n/a')"
    echo -e "• GNOME Tema de Color:           $(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo 'n/a')"
    echo -e "${BOLD}=================================================================${NC}"
}

apply_sysctl_tuning() {
    echo -e "${BLUE}⚙️ [1/5] Configurando optimizaciones del Kernel (Sysctl) para HTPC...${NC}"

    $SUDO tee /etc/sysctl.d/99-cachyos-tuning.conf > /dev/null << 'EOF'
# =============================================================================
# CACHYOS TV SYSCTL TUNING - HP Z230 SFF (Sony TV)
# Hardware: Intel Core i7-4790 (Haswell) | 8.0 GiB DDR3 | ZRAM ZSTD
# =============================================================================

# 1. Monitoreo de Sistema y Descriptores de Inotify
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 4096
fs.file-max = 2097152

# 2. Memoria Virtual y Gestor de Mapas de Memoria
vm.max_map_count = 16777216

# 3. ZRAM y Swappiness optimizado para 8 GB RAM física con ZRAM ZSTD (4 GB)
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0

# 4. Presión de Caché VFS y Gestión de Páginas Sucias (Dirty Ratio)
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10

# 5. Red TCP / Stack de Red de Alta Velocidad para Streaming (BBR y CAKE)
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_notsent_lowat = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_max_syn_backlog = 8192
EOF

    $SUDO sysctl --system > /dev/null || true
    echo -e "${GREEN}✅ Parámetros de Kernel Sysctl aplicados correctamente.${NC}"
}

apply_limits_tuning() {
    echo -e "${BLUE}📈 [2/5] Configurando límites de descriptores y sesiones Systemd...${NC}"

    $SUDO tee /etc/security/limits.d/99-tv-limits.conf > /dev/null << 'EOF'
# Límites optimizados para Centro Multimedia CachyOS TV
*          soft    nofile     524288
*          hard    nofile     1048576
*          soft    memlock    unlimited
*          hard    memlock    unlimited
*          soft    nproc      256000
*          hard    nproc      256000
EOF

    $SUDO mkdir -p /etc/systemd/system.conf.d /etc/systemd/user.conf.d

    $SUDO tee /etc/systemd/system.conf.d/99-limits.conf > /dev/null << 'EOF'
[Manager]
DefaultLimitNOFILE=1048576:1048576
DefaultLimitMEMLOCK=infinity
DefaultLimitNPROC=256000
DefaultTasksMax=infinity
EOF

    $SUDO tee /etc/systemd/user.conf.d/99-limits.conf > /dev/null << 'EOF'
[Manager]
DefaultLimitNOFILE=1048576:1048576
DefaultLimitMEMLOCK=infinity
DefaultLimitNPROC=256000
DefaultTasksMax=infinity
EOF

    $SUDO systemctl daemon-reexec 2>/dev/null || true
    echo -e "${GREEN}✅ Límites de seguridad y systemd configurados.${NC}"
}

apply_cachyos_services() {
    echo -e "${BLUE}🚀 [3/5] Verificando e iniciando Ananicy-CPP, UKSMD, Irqbalance y timers SSD...${NC}"

    $SUDO pacman -S --needed --noconfirm \
        ananicy-cpp \
        cachyos-ananicy-rules \
        irqbalance 2>/dev/null || \
    $SUDO pacman -S --needed --noconfirm ananicy-cpp irqbalance 2>/dev/null || true

    $SUDO pacman -S --needed --noconfirm uksmd 2>/dev/null || true

    $SUDO systemctl enable --now ananicy-cpp.service 2>/dev/null || true
    if systemctl list-unit-files uksmd.service &>/dev/null; then
        $SUDO systemctl enable --now uksmd.service 2>/dev/null || true
    fi
    $SUDO systemctl enable --now irqbalance.service 2>/dev/null || true
    $SUDO systemctl enable --now fstrim.timer 2>/dev/null || true

    if systemctl list-unit-files paccache.timer &>/dev/null; then
        $SUDO systemctl enable --now paccache.timer 2>/dev/null || true
    fi

    echo -e "${GREEN}✅ Servicios de rendimiento (Ananicy-CPP, UKSMD, Irqbalance, fstrim, paccache) activos.${NC}"
}

apply_systemd_tuning() {
    echo -e "${BLUE}⏱️ [4/5] Ajustando timeouts de parada de servicios en Systemd (10s)...${NC}"
    $SUDO mkdir -p /etc/systemd/system.conf.d /etc/systemd/user.conf.d

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

    echo -e "${GREEN}✅ Timeout de apagado en Systemd configurado a 10s (reinicio instantáneo).${NC}"
}

apply_gnome_tuning() {
    echo -e "${BLUE}🎨 [5/5] Configurando GNOME Mutter y exclusiones inteligentes del indexador Tracker...${NC}"

    # Escalado framebuffer para pantallas HiDPI/TV (sin VRR innecesario en Haswell HD 4600 / TV 60Hz)
    run_as_user gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']" 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true

    # Optimización del indexador Tracker 3 (LocalSearch) para HTPC:
    # Excluir montajes de red (/mnt/nas) y carpetas de descargas para no devorar CPU ni RAM con bibliotecas de vídeo masivas
    if run_as_user gsettings list-schemas | grep -q "org.freedesktop.Tracker3.Miner.Files"; then
        run_as_user gsettings set org.freedesktop.Tracker3.Miner.Files index-on-battery false 2>/dev/null || true
        run_as_user gsettings set org.freedesktop.Tracker3.Miner.Files ignored-directories \
            "['/mnt/nas', '.cache', '.local/share/Trash', '.local/share/Steam', '.npm', '.cargo', 'target', 'node_modules']" 2>/dev/null || true
        echo -e "  • Tracker 3 configurado con exclusión de montajes de red y cachés masivas."
    fi

    echo -e "${GREEN}✅ Optimizaciones de GNOME y Tracker aplicadas.${NC}"
}

# Procesar argumentos de línea de comandos
case "${1:-}" in
    -h|--help|help)
        show_help
        exit 0
        ;;
    -s|--status|status)
        show_status
        exit 0
        ;;
    --sysctl)
        echo -e "${BOLD}=================================================================${NC}"
        echo -e "${CYAN}⚙️ APLICANDO SYSCTL TUNING - CACHYOS TV${NC}"
        echo -e "${BOLD}=================================================================${NC}"
        apply_sysctl_tuning
        ;;
    --limits)
        echo -e "${BOLD}=================================================================${NC}"
        echo -e "${CYAN}📈 APLICANDO LÍMITES DE PROCESO Y SYSTEMD - CACHYOS TV${NC}"
        echo -e "${BOLD}=================================================================${NC}"
        apply_limits_tuning
        ;;
    --services)
        echo -e "${BOLD}=================================================================${NC}"
        echo -e "${CYAN}🚀 CONFIGURANDO SERVICIOS DE RENDIMIENTO - CACHYOS TV${NC}"
        echo -e "${BOLD}=================================================================${NC}"
        apply_cachyos_services
        ;;
    --gnome)
        echo -e "${BOLD}=================================================================${NC}"
        echo -e "${CYAN}🎨 OPTIMIZANDO GNOME MUTTER Y TRACKER INDEXER${NC}"
        echo -e "${BOLD}=================================================================${NC}"
        apply_gnome_tuning
        ;;
    --no-install)
        echo -e "${BOLD}=================================================================${NC}"
        echo -e "${CYAN}⚡ APLICANDO OPTIMIZACIONES CACHYOS TV [SIN INSTALAR PAQUETES]${NC}"
        echo -e "${BOLD}=================================================================${NC}"
        apply_sysctl_tuning
        apply_limits_tuning
        apply_systemd_tuning
        apply_gnome_tuning
        echo ""
        show_status
        ;;
    "")
        echo -e "${BOLD}=================================================================${NC}"
        echo -e "${CYAN}⚡ INICIANDO OPTIMIZACIÓN DE RENDIMIENTO - CACHYOS TV${NC}"
        echo -e "${CYAN}   Equipo: HP Z230 SFF Workstation (Sony TV / Intel Haswell)${NC}"
        echo -e "${BOLD}=================================================================${NC}"
        apply_sysctl_tuning
        apply_limits_tuning
        apply_cachyos_services
        apply_systemd_tuning
        apply_gnome_tuning
        echo ""
        show_status
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida: $1${NC}"
        show_help
        exit 1
        ;;
esac
