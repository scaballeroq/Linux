#!/bin/bash
# ==============================================================================
# kubuntu-tuning.sh - Optimizador de Rendimiento para Kubuntu + KDE Plasma 6
# ==============================================================================
#
# Uso:
#   ./kubuntu-tuning.sh               -> Aplica todas las optimizaciones
#   ./kubuntu-tuning.sh --status      -> Muestra estado actual
#   ./kubuntu-tuning.sh --sysctl      -> Solo ajustes de Kernel Sysctl
#   ./kubuntu-tuning.sh --limits      -> Solo límites de descriptores
#   ./kubuntu-tuning.sh --kde         -> Solo optimizaciones KDE/Baloo
#   ./kubuntu-tuning.sh --baloo-fast  -> Baloo modo rápido (solo metadatos)
#   ./kubuntu-tuning.sh --baloo-disable -> Desactiva Baloo completamente
#   ./kubuntu-tuning.sh --help        -> Muestra ayuda
#
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "Error: 'sudo' no esta disponible. Ejecuta este script como root."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

set_kde_config() {
    local file="$1"
    local group="$2"
    local key="$3"
    local val="$4"

    if command -v kwriteconfig6 &>/dev/null; then
        run_as_user kwriteconfig6 --file "$file" --group "$group" --key "$key" "$val"
    elif command -v kwriteconfig5 &>/dev/null; then
        run_as_user kwriteconfig5 --file "$file" --group "$group" --key "$val"
    else
        local target="$USER_HOME/.config/$file"
        run_as_user mkdir -p "$(dirname "$target")"
        if [ ! -f "$target" ]; then
            run_as_user touch "$target"
        fi
        if grep -q "^\[$group\]" "$target" 2>/dev/null; then
            if grep -A 100 "^\[$group\]" "$target" | grep -q "^$key="; then
                sed -i "/^\[$group\]/,/^\[/ s|^$key=.*|$key=$val|" "$target"
            else
                sed -i "/^\[$group\]/a $key=$val" "$target"
            fi
        else
            printf "\n[%s]\n%s=%s\n" "$group" "$key" "$val" >> "$target"
        fi
    fi
}

show_help() {
    cat <<EOF
Optimizador de Rendimiento - Kubuntu (KDE Plasma 6)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Aplica todas las optimizaciones (Sysctl, Limites, KDE/Baloo, Systemd).
  --status, -s           Muestra el estado actual de sysctl, limites, ZRAM, Baloo.
  --sysctl               Aplica unicamente la configuracion de Kernel Sysctl.
  --limits               Aplica limites de descriptores y memoria (limits.d y systemd).
  --kde                  Aplica optimizaciones de KDE Plasma 6 y Baloo.
  --baloo-fast           Configura Baloo en modo rapido (solo metadatos/nombres).
  --baloo-disable        Desactiva completamente el indexador Baloo.
  --help, -h             Muestra este mensaje de ayuda.

Optimizaciones incluidas:
  1. Sysctl Kernel:      Inotify ampliado (524K watches), max_map_count (16M),
                         swappiness=10, BBR TCP, dirty ratios equilibrados.
  2. Limites de Proceso: Descriptores (524K/1M nofile), memlock unlimited,
                         systemd DefaultTasksMax=infinity.
  3. Systemd Timeouts:   DefaultTimeoutStopSec=10s para apagados rapidos.
  4. KDE Plasma 6:       AnimationDurationFactor=0.6, exclusiones Baloo para dev.
  5. Servicios:          fstrim.timer (mantenimiento SSD/NVMe), irqbalance.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE RENDIMIENTO - KUBUNTU (KDE PLASMA 6)"
    echo "================================================================="
    echo "Kernel:                        $(uname -r)"
    echo "Governor CPU:                  $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'n/a')"
    echo "-----------------------------------------------------------------"
    echo "fs.inotify.max_user_watches:   $(sysctl -n fs.inotify.max_user_watches 2>/dev/null || echo 'n/a')"
    echo "fs.inotify.max_user_instances: $(sysctl -n fs.inotify.max_user_instances 2>/dev/null || echo 'n/a')"
    echo "vm.max_map_count:              $(sysctl -n vm.max_map_count 2>/dev/null || echo 'n/a')"
    echo "vm.swappiness:                 $(sysctl -n vm.swappiness 2>/dev/null || echo 'n/a')"
    echo "vm.vfs_cache_pressure:         $(sysctl -n vm.vfs_cache_pressure 2>/dev/null || echo 'n/a')"
    echo "net.ipv4.tcp_congestion_ctrl:  $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'n/a')"
    echo "-----------------------------------------------------------------"
    echo "Limite nofile (ulimit -n):     $(ulimit -n 2>/dev/null || echo 'n/a')"
    echo "ZRAM Activo:                   $(if command -v zramctl &>/dev/null && [ -n "$(zramctl 2>/dev/null)" ]; then echo 'Si'; else echo 'No'; fi)"
    echo "fstrim.timer:                  $(systemctl is-enabled --quiet fstrim.timer 2>/dev/null && echo 'Habilitado' || echo 'Inactivo')"
    echo "irqbalance:                    $(systemctl is-active --quiet irqbalance.service 2>/dev/null && echo 'Activo' || echo 'Inactivo')"
    echo "-----------------------------------------------------------------"
    if [ -f "$USER_HOME/.config/baloofilerc" ]; then
        BALOO_ENABLED=$(grep -i "Indexing-Enabled" "$USER_HOME/.config/baloofilerc" 2>/dev/null | cut -d= -f2 || echo "true")
        if [ "$BALOO_ENABLED" = "false" ]; then
            echo "Baloo Indexer:                 Deshabilitado"
        else
            echo "Baloo Indexer:                 Habilitado"
        fi
    else
        echo "Baloo Indexer:                 No configurado"
    fi
    echo "KDE Animation Factor:          $(if command -v kreadconfig6 &>/dev/null; then run_as_user kreadconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 2>/dev/null || echo '1.0'; else echo '1.0'; fi)"
    echo "================================================================="
}

apply_sysctl_tuning() {
    echo "Aplicando parametros de Kernel Sysctl..."

    $SUDO modprobe tcp_bbr 2>/dev/null || true

    $SUDO tee /etc/sysctl.d/99-kubuntu-dev.conf > /dev/null << 'EOF'
# Optimizaciones de rendimiento del Kernel - Kubuntu + KDE Plasma 6

# Monitoreo de archivos para IDEs (VSCode, JetBrains) y Dolphin
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
fs.file-max = 2097152

# Mapeos de memoria para bases de datos, compiladores y contenedores
vm.max_map_count = 16777216

# Gestion de memoria optimizada para Kubuntu
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# Dirty ratios para prevenir microcongelamientos en escrituras masivas
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# Rendimiento de red TCP (BBR + FastOpen)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.core.somaxconn = 8192
EOF

    $SUDO sysctl --system > /dev/null || true
    echo "Sysctl aplicado correctamente."
}

apply_limits_tuning() {
    echo "Configurando limites de descriptores y sesiones Systemd..."

    $SUDO tee /etc/security/limits.d/99-dev-limits.conf > /dev/null << 'EOF'
*          soft    nofile     524288
*          hard    nofile     1048576
*          soft    memlock    unlimited
*          hard    memlock    unlimited
*          soft    nproc      512000
*          hard    nproc      512000
EOF

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

    $SUDO systemctl daemon-reexec 2>/dev/null || true
    echo "Limites configurados correctamente."
}

apply_systemd_tuning() {
    echo "Ajustando timeouts de Systemd (10s)..."
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

    echo "Timeouts de Systemd configurados a 10 segundos."
}

apply_kde_tuning() {
    local MODE="${1:-smart}"
    echo "Configurando optimizaciones de KDE Plasma 6 y Baloo (Modo: $MODE)..."

    local EXCLUDE_PATTERNS="*.o,*.a,*.so,*.pyc,*.class,node_modules,.git,.venv,.cargo,target,vendor,.cache,build,dist,.npm,.rustup,.local/share/Steam,.var/app"

    set_kde_config "baloofilerc" "General" "exclude patterns" "$EXCLUDE_PATTERNS"
    set_kde_config "baloofilerc" "General" "dbVersion" "2"

    case "$MODE" in
        disable)
            set_kde_config "baloofilerc" "Basic Settings" "Indexing-Enabled" "false"
            run_as_user balooctl6 disable 2>/dev/null || run_as_user balooctl disable 2>/dev/null || true
            echo "Baloo deshabilitado."
            ;;
        fast)
            set_kde_config "baloofilerc" "Basic Settings" "Indexing-Enabled" "true"
            set_kde_config "baloofilerc" "General" "index content" "false"
            run_as_user balooctl6 enable 2>/dev/null || run_as_user balooctl enable 2>/dev/null || true
            echo "Baloo configurado en modo rapido (solo metadatos)."
            ;;
        smart|*)
            set_kde_config "baloofilerc" "Basic Settings" "Indexing-Enabled" "true"
            set_kde_config "baloofilerc" "General" "index content" "false"
            run_as_user balooctl6 check 2>/dev/null || run_as_user balooctl check 2>/dev/null || true
            echo "Baloo optimizado con exclusiones para desarrollo."
            ;;
    esac

    set_kde_config "kdeglobals" "KDE" "AnimationDurationFactor" "0.6"
    set_kde_config "dolphinrc" "PreviewSettings" "MaximumRemoteFolderSize" "0"

    echo "Optimizaciones de KDE Plasma 6 aplicadas."
}

apply_services() {
    echo "Habilitando servicios de rendimiento..."
    $SUDO systemctl enable --now fstrim.timer 2>/dev/null || true
    $SUDO systemctl enable --now irqbalance.service 2>/dev/null || true
    echo "Servicios habilitados (fstrim.timer, irqbalance)."
}

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
        echo "APLICANDO SYSCTL TUNING - KUBUNTU"
        apply_sysctl_tuning
        ;;
    --limits)
        echo "APLICANDO LIMITES - KUBUNTU"
        apply_limits_tuning
        ;;
    --kde)
        echo "OPTIMIZANDO KDE PLASMA 6 Y BALOO"
        apply_kde_tuning "smart"
        ;;
    --baloo-fast)
        echo "CONFIGURANDO BALOO EN MODO RAPIDO"
        apply_kde_tuning "fast"
        ;;
    --baloo-disable)
        echo "DESHABILITANDO BALOO"
        apply_kde_tuning "disable"
        ;;
    --no-install)
        echo "APLICANDO OPTIMIZACIONES (SIN PAQUETES)"
        apply_sysctl_tuning
        apply_limits_tuning
        apply_systemd_tuning
        apply_kde_tuning "smart"
        ;;
    "")
        echo "================================================================="
        echo "INICIANDO OPTIMIZACION - KUBUNTU (KDE PLASMA 6)"
        echo "================================================================="
        apply_sysctl_tuning
        apply_limits_tuning
        apply_systemd_tuning
        apply_kde_tuning "smart"
        apply_services
        echo ""
        echo "================================================================="
        echo "Optimizacion completa de Kubuntu finalizada."
        echo "================================================================="
        ;;
    *)
        echo "Opcion no reconocida: $1"
        show_help
        exit 1
        ;;
esac
