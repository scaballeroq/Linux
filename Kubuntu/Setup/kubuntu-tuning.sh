#!/bin/bash
# ==============================================================================
# kubuntu-tuning.sh - Optimizador de Rendimiento para Kubuntu 26.04.1 (Plasma 6)
# ==============================================================================
# Optimizado para:
#   - Kernel Linux 7.x / 6.x y gestión de memoria moderna
#   - ZRAM con compresión ZSTD (vm.page-cluster = 0, swappiness equilibrado)
#   - Monitoreo masivo de archivos (Inotify) para IDEs y compiladores
#   - Límites de descriptores de archivos (1M nofile) y tareas Systemd
#   - KDE Plasma 6 (animaciones ágiles 0.6x, indexación Baloo optimizada para dev)
#   - Servicios de mantenimiento (fstrim.timer para NVMe/SSD, irqbalance)
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "Error: 'sudo' no está disponible. Ejecuta este script como root."
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
        run_as_user kwriteconfig5 --file "$file" --group "$group" --key "$key" "$val"
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
Optimizador de Rendimiento - Kubuntu 26.04 (KDE Plasma 6)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Aplica todas las optimizaciones (Sysctl, Límites, KDE/Baloo, Systemd, Servicios).
  --status, -s           Muestra el estado actual de sysctl, límites, ZRAM, Baloo y servicios.
  --sysctl               Aplica únicamente la configuración de Kernel Sysctl.
  --limits               Aplica límites de descriptores y memoria (limits.d y systemd).
  --kde                  Aplica optimizaciones de KDE Plasma 6 y Baloo.
  --baloo-fast           Configura Baloo en modo rápido (solo nombres de archivo y metadatos).
  --baloo-disable        Desactiva completamente el indexador Baloo.
  --no-install           Aplica ajustes de configuración sin habilitar servicios adicionales.
  --help, -h             Muestra este mensaje de ayuda.

Optimizaciones incluidas:
  1. Sysctl Kernel:      Inotify ampliado (524K watches), max_map_count (16M),
                         vm.page-cluster=0 (optimizado para ZRAM/NVMe), swappiness=10,
                         BBR TCP + FastOpen, dirty ratios equilibrados (10/5).
  2. Límites de Proceso: Descriptores de archivo (524K soft / 1M hard nofile), memlock unlimited,
                         systemd DefaultTasksMax=infinity.
  3. Systemd Timeouts:   DefaultTimeoutStopSec=10s para apagados y reinicios rápidos.
  4. KDE Plasma 6:       AnimationDurationFactor=0.6 (animaciones ultra ágiles),
                         exclusiones Baloo para proyectos de desarrollo (node_modules, .git, .venv, etc.).
  5. Servicios:          fstrim.timer (mantenimiento SSD/NVMe), irqbalance (reparto multi-core).
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE RENDIMIENTO - KUBUNTU 26.04 (KDE PLASMA 6)"
    echo "================================================================="
    echo "Kernel:                        $(uname -r)"
    echo "Governor CPU:                  $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'n/a')"
    echo "-----------------------------------------------------------------"
    echo "fs.inotify.max_user_watches:   $(sysctl -n fs.inotify.max_user_watches 2>/dev/null || echo 'n/a')"
    echo "fs.inotify.max_user_instances: $(sysctl -n fs.inotify.max_user_instances 2>/dev/null || echo 'n/a')"
    echo "vm.max_map_count:              $(sysctl -n vm.max_map_count 2>/dev/null || echo 'n/a')"
    echo "vm.swappiness:                 $(sysctl -n vm.swappiness 2>/dev/null || echo 'n/a')"
    echo "vm.page-cluster (0 para ZRAM): $(sysctl -n vm.page-cluster 2>/dev/null || echo 'n/a')"
    echo "vm.vfs_cache_pressure:         $(sysctl -n vm.vfs_cache_pressure 2>/dev/null || echo 'n/a')"
    echo "net.ipv4.tcp_congestion_ctrl:  $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'n/a')"
    echo "-----------------------------------------------------------------"
    echo "Límite nofile (ulimit -n):     $(ulimit -n 2>/dev/null || echo 'n/a')"
    echo "ZRAM Activo:                   $(if command -v zramctl &>/dev/null && [ -n "$(zramctl 2>/dev/null)" ]; then echo 'Sí'; else echo 'No'; fi)"
    echo "fstrim.timer:                  $(systemctl is-enabled --quiet fstrim.timer 2>/dev/null && echo 'Habilitado' || echo 'Inactivo')"
    echo "irqbalance:                    $(systemctl is-active --quiet irqbalance.service 2>/dev/null && echo 'Activo' || echo 'Inactivo')"
    echo "-----------------------------------------------------------------"
    if [ -f "$USER_HOME/.config/baloofilerc" ]; then
        BALOO_ENABLED=$(grep -i "Indexing-Enabled" "$USER_HOME/.config/baloofilerc" 2>/dev/null | cut -d= -f2 || echo "true")
        if [ "$BALOO_ENABLED" = "false" ]; then
            echo "Baloo Indexer:                 Deshabilitado"
        else
            echo "Baloo Indexer:                 Habilitado (Optimizado)"
        fi
    else
        echo "Baloo Indexer:                 No configurado"
    fi
    echo "KDE Animation Factor:          $(if command -v kreadconfig6 &>/dev/null; then run_as_user kreadconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 2>/dev/null || echo '0.6'; else echo '1.0'; fi)"
    echo "================================================================="
}

apply_sysctl_tuning() {
    echo "ℹ️ Aplicando parámetros de Kernel Sysctl optimizados..."

    $SUDO modprobe tcp_bbr 2>/dev/null || true

    $SUDO tee /etc/sysctl.d/99-kubuntu-dev.conf > /dev/null << 'EOF'
# ==============================================================================
# Optimizaciones de rendimiento del Kernel - Kubuntu 26.04 + KDE Plasma 6
# ==============================================================================

# Monitoreo de archivos para IDEs (VSCode, JetBrains, Antigravity) y Dolphin
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
fs.file-max = 2097152

# Mapeos de memoria virtual para bases de datos (PostgreSQL, MongoDB), Rust y JVM
vm.max_map_count = 16777216

# Gestión de memoria y ZRAM:
# vm.page-cluster = 0 desactiva la lectura en bloque secuencial para swap,
# leyendo páginas individuales instantáneamente de RAM comprimida (reduce latencia de CPU)
vm.page-cluster = 0
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# Dirty ratios ajustados para prevenir micro-bloqueos de I/O en escrituras pesadas
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# Rendimiento de red TCP (BBR + FastOpen + colas FQ)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.core.somaxconn = 8192
EOF

    $SUDO sysctl --system > /dev/null || true
    echo "✅ Parámetros Sysctl aplicados correctamente."
}

apply_limits_tuning() {
    echo "ℹ️ Configurando límites de descriptores y sesiones Systemd..."

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
    echo "✅ Límites de procesos y descriptores configurados."
}

apply_systemd_tuning() {
    echo "ℹ️ Ajustando timeouts de Systemd para apagado rápido (10s)..."
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

    echo "✅ Timeouts de Systemd configurados a 10 segundos."
}

apply_kde_tuning() {
    local MODE="${1:-smart}"
    echo "ℹ️ Configurando optimizaciones de KDE Plasma 6 y Baloo (Modo: $MODE)..."

    # Excluir directorios típicos de compilación y librerías para evitar saturación del indexador
    local EXCLUDE_PATTERNS="*.o,*.a,*.so,*.pyc,*.class,node_modules,.git,.venv,.cargo,target,vendor,.cache,build,dist,.npm,.rustup,.next,.nuxt,.turbo,.gradle,__pycache__,.local/share/Steam,.var/app"

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
            echo "Baloo configurado en modo rápido (solo metadatos y nombres)."
            ;;
        smart|*)
            set_kde_config "baloofilerc" "Basic Settings" "Indexing-Enabled" "true"
            set_kde_config "baloofilerc" "General" "index content" "false"
            run_as_user balooctl6 check 2>/dev/null || run_as_user balooctl check 2>/dev/null || true
            echo "Baloo optimizado con exclusiones para desarrollo."
            ;;
    esac

    # Animaciones ultra fluidas en Plasma 6 (0.6x de duración para máxima agilidad visual)
    set_kde_config "kdeglobals" "KDE" "AnimationDurationFactor" "0.6"

    # Prevenir que Dolphin intente generar miniaturas de recursos de red lentos
    set_kde_config "dolphinrc" "PreviewSettings" "MaximumRemoteFolderSize" "0"

    echo "✅ Optimizaciones de KDE Plasma 6 aplicadas."
}

apply_services() {
    echo "ℹ️ Habilitando servicios de rendimiento y mantenimiento de almacenamiento..."
    $SUDO systemctl enable --now fstrim.timer 2>/dev/null || true
    $SUDO systemctl enable --now irqbalance.service 2>/dev/null || true
    echo "✅ Servicios fstrim.timer e irqbalance habilitados."
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
        echo "================================================================="
        echo "APLICANDO SYSCTL TUNING - KUBUNTU 26.04"
        echo "================================================================="
        apply_sysctl_tuning
        ;;
    --limits)
        echo "================================================================="
        echo "APLICANDO LÍMITES - KUBUNTU 26.04"
        echo "================================================================="
        apply_limits_tuning
        ;;
    --kde)
        echo "================================================================="
        echo "OPTIMIZANDO KDE PLASMA 6 Y BALOO"
        echo "================================================================="
        apply_kde_tuning "smart"
        ;;
    --baloo-fast)
        echo "================================================================="
        echo "CONFIGURANDO BALOO EN MODO RÁPIDO"
        echo "================================================================="
        apply_kde_tuning "fast"
        ;;
    --baloo-disable)
        echo "================================================================="
        echo "DESHABILITANDO BALOO"
        echo "================================================================="
        apply_kde_tuning "disable"
        ;;
    --no-install)
        echo "================================================================="
        echo "APLICANDO OPTIMIZACIONES (SIN SERVICIOS EXTRA)"
        echo "================================================================="
        apply_sysctl_tuning
        apply_limits_tuning
        apply_systemd_tuning
        apply_kde_tuning "smart"
        ;;
    "")
        echo "================================================================="
        echo "INICIANDO OPTIMIZACIÓN - KUBUNTU 26.04 (KDE PLASMA 6)"
        echo "================================================================="
        apply_sysctl_tuning
        apply_limits_tuning
        apply_systemd_tuning
        apply_kde_tuning "smart"
        apply_services
        echo ""
        echo "================================================================="
        echo "Optimización completa de Kubuntu 26.04 finalizada."
        echo "Verifica el estado con: $0 --status"
        echo "================================================================="
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
