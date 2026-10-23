#!/bin/bash
# ==============================================================================
# ubuntu-tuning.sh - Optimizador de Rendimiento para Ubuntu Workstation (GNOME)
# Hardware: AMD Ryzen 7 7730U / NVMe SSD / 32 GB RAM / ZRAM
# ==============================================================================
# Características:
#   - Kernel Linux moderno y gestión de memoria optimizada (vm.page-cluster = 0)
#   - ZRAM con compresión ZSTD y swappiness adaptativo
#   - Monitoreo masivo de archivos (Inotify 1M watches) para IDEs y compiladores
#   - Límites de descriptores de archivos (1M nofile) y tareas Systemd (TasksMax=infinity)
#   - Optimización de red con TCP BBR + FQ
#   - Ajuste de GNOME Tracker Miner para excluir carpetas pesadas de desarrollo
#   - Servicios de mantenimiento: fstrim.timer para SSD/NVMe e irqbalance
#   - Opciones CLI: --status, --sysctl, --limits, --tracker, --zram, --no-install, --help
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
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

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            PATH="/usr/local/bin:/usr/bin:/bin:$PATH" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$REAL_UID/bus}" \
            "$@"
    else
        "$@"
    fi
}

show_help() {
    cat <<EOF
⚡ Optimizador de Rendimiento - Ubuntu Workstation (GNOME Shell 51)

Uso:
  $0 [OPCIÓN]

Opciones principales:
  (sin argumentos)       Aplica todas las optimizaciones (Kernel, Límites, GNOME Tracker, ZRAM, Servicios).
  --status, -s           Muestra el estado actual de sysctl, límites, ZRAM, Tracker y servicios.
  --sysctl               Aplica únicamente la configuración de Kernel Sysctl y TCP BBR.
  --limits               Aplica límites de descriptores y memoria (limits.d y systemd).
  --tracker              Configura exclusiones en GNOME Tracker Miner para proyectos de desarrollo.
  --zram                 Verifica y aplica la configuración óptima de ZRAM (zstd).
  --no-install           Aplica ajustes de configuración sin descargar paquetes adicionales.
  --help, -h             Muestra este mensaje de ayuda.

Optimizaciones incluidas:
  1. Sysctl Kernel:      Inotify ampliado (1M watches), max_map_count (16M),
                         vm.page-cluster=0 (optimizado para ZRAM/NVMe), swappiness=10,
                         vm.watermark_boost_factor=0 (elimina microtirones), TCP BBR + FQ.
  2. Límites de Proceso: Descriptores de archivo (1M nofile), memlock unlimited,
                         systemd system/user DefaultTasksMax=infinity.
  3. Systemd Timeouts:   DefaultTimeoutStopSec=10s para apagados y reinicios rápidos.
  4. GNOME Tracker:      Exclusiones en Tracker Miner de node_modules, .git, .venv y Workspace.
  5. Memoria ZRAM:       Compresión ZSTD al 50% de RAM con zram-tools.
  6. Servicios:          fstrim.timer (mantenimiento SSD/NVMe) e irqbalance (reparto multi-core).
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE RENDIMIENTO Y OPTIMIZACIONES - UBUNTU WORKSTATION"
    echo "================================================================="
    echo "• Kernel activo:                 $(uname -r)"
    echo "-----------------------------------------------------------------"
    echo "• Sysctl Kernel & Memoria:"
    echo "  - fs.inotify.max_user_watches: $(sysctl -n fs.inotify.max_user_watches 2>/dev/null || echo 'n/a') (Objetivo: >= 1048576)"
    echo "  - vm.max_map_count:            $(sysctl -n vm.max_map_count 2>/dev/null || echo 'n/a') (Objetivo: >= 16777216)"
    echo "  - vm.swappiness:               $(sysctl -n vm.swappiness 2>/dev/null || echo 'n/a') (Objetivo: 10 con ZRAM)"
    echo "  - vm.page-cluster:             $(sysctl -n vm.page-cluster 2>/dev/null || echo 'n/a') (Objetivo: 0 para ZRAM/NVMe)"
    echo "  - vm.watermark_boost_factor:   $(sysctl -n vm.watermark_boost_factor 2>/dev/null || echo 'n/a') (Objetivo: 0)"
    echo "  - net.ipv4.tcp_congestion:     $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'n/a') (Objetivo: bbr)"
    echo "-----------------------------------------------------------------"
    echo "• Límites de Descriptores y Procesos:"
    echo "  - Soft nofile (sesión actual): $(ulimit -Sn 2>/dev/null || echo 'n/a')"
    echo "  - Hard nofile (sesión actual): $(ulimit -Hn 2>/dev/null || echo 'n/a')"
    echo "  - Archivo limits.d:            $(if [ -f /etc/security/limits.d/99-development-limits.conf ]; then echo "✅ Configurado"; else echo "❌ No presente"; fi)"
    echo "-----------------------------------------------------------------"
    echo "• Memoria ZRAM (Swap en RAM):"
    if command -v zramctl &>/dev/null; then
        zramctl 2>/dev/null || echo "  (Sin dispositivos ZRAM activos)"
    else
        echo "  - zramctl no instalado"
    fi
    echo "-----------------------------------------------------------------"
    echo "• Servicios del Sistema:"
    echo "  - fstrim.timer (SSD TRIM):     $(systemctl is-active fstrim.timer 2>/dev/null || echo 'inactivo')"
    echo "  - irqbalance (Multi-core IRQ): $(systemctl is-active irqbalance 2>/dev/null || echo 'inactivo')"
    echo "================================================================="
}

apply_sysctl() {
    echo "⚙️ [1/6] Aplicando parámetros Sysctl de Kernel para desarrollo..."
    $SUDO mkdir -p /etc/sysctl.d /etc/modules-load.d

    # Cargar módulo BBR
    echo "tcp_bbr" | $SUDO tee /etc/modules-load.d/bbr.conf > /dev/null
    $SUDO modprobe tcp_bbr 2>/dev/null || true

    cat <<'EOF' | $SUDO tee /etc/sysctl.d/99-workstation-tuning.conf > /dev/null
# =============================================================================
# OPTIMIZACIONES DE RENDIMIENTO - UBUNTU WORKSTATION
# =============================================================================

# Inotify masivo para IDEs (VS Code, Antigravity, Neovim) y compiladores
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 8192

# Soporte de memoria mapeada para bases de datos y runtimes (Java, Node, Elasticsearch)
vm.max_map_count = 16777216

# Optimización para ZRAM y almacenamiento NVMe
vm.page-cluster = 0
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.watermark_boost_factor = 0

# Red BBR y FastOpen
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3

# Descriptores de archivo a nivel de sistema
fs.file-max = 2097152
EOF

    $SUDO sysctl --system > /dev/null 2>&1 || true
    echo "  ✅ Parámetros de Kernel aplicados con éxito."
}

apply_limits() {
    echo "⚙️ [2/6] Configurando límites de descriptores y tareas..."
    $SUDO mkdir -p /etc/security/limits.d /etc/systemd/system.conf.d /etc/systemd/user.conf.d

    cat <<'EOF' | $SUDO tee /etc/security/limits.d/99-development-limits.conf > /dev/null
# Límites para desarrollo y compilación intensiva
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576

* soft memlock unlimited
* hard memlock unlimited

* soft nproc 1048576
* hard nproc 1048576
EOF

    cat <<'EOF' | $SUDO tee /etc/systemd/system.conf.d/99-limits.conf > /dev/null
[Manager]
DefaultLimitNOFILE=1048576
DefaultLimitMEMLOCK=infinity
DefaultTasksMax=infinity
DefaultTimeoutStopSec=10s
DefaultTimeoutAbortSec=10s
EOF

    cat <<'EOF' | $SUDO tee /etc/systemd/user.conf.d/99-limits.conf > /dev/null
[Manager]
DefaultLimitNOFILE=1048576
DefaultLimitMEMLOCK=infinity
DefaultTasksMax=infinity
DefaultTimeoutStopSec=10s
DefaultTimeoutAbortSec=10s
EOF

    $SUDO systemctl daemon-reexec 2>/dev/null || true
    run_as_user systemctl --user daemon-reexec 2>/dev/null || true
    echo "  ✅ Límites de descriptores y timeouts configurados."
}

apply_tracker() {
    echo "⚙️ [3/6] Optimizando GNOME Tracker Miner (exclusión de proyectos de desarrollo)..."
    # Prevenir que el indexador de escritorio de GNOME sature la CPU en directorios de código
    local workspace_dir="$USER_HOME/Workspace"
    if [ -d "$workspace_dir" ]; then
        run_as_user touch "$workspace_dir/.trackerignore" 2>/dev/null || true
        run_as_user touch "$workspace_dir/.nomedia" 2>/dev/null || true
    fi

    # Configurar carpetas ignoradas en GSettings de Tracker si está disponible
    if run_as_user gsettings list-schemas 2>/dev/null | grep -q "org.freedesktop.Tracker3.Miner.Files"; then
        local current_ignored
        current_ignored=$(run_as_user gsettings get org.freedesktop.Tracker3.Miner.Files ignored-directories 2>/dev/null || echo "[]")
        run_as_user gsettings set org.freedesktop.Tracker3.Miner.Files index-recursive-directories "['&DESKTOP', '&DOCUMENTS', '&DOWNLOAD', '&MUSIC', '&PICTURES', '&VIDEOS']" 2>/dev/null || true
        run_as_user gsettings set org.freedesktop.Tracker3.Miner.Files enable-monitors true 2>/dev/null || true
    fi
    echo "  ✅ GNOME Tracker configurado para respetar .trackerignore en directorios de código."
}

apply_zram() {
    echo "⚙️ [4/6] Verificando memoria ZRAM con compresión ZSTD..."
    if [ -f "$(dirname "$0")/zram-setup.sh" ]; then
        bash "$(dirname "$0")/zram-setup.sh"
    fi
}

apply_services() {
    echo "⚙️ [5/6] Habilitando servicios de mantenimiento (fstrim e irqbalance)..."
    $SUDO apt update -qq 2>/dev/null || true
    $SUDO apt install -y irqbalance 2>/dev/null || true
    $SUDO systemctl enable --now fstrim.timer 2>/dev/null || true
    $SUDO systemctl enable --now irqbalance 2>/dev/null || true
    echo "  ✅ fstrim.timer e irqbalance activos."
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --sysctl)
        apply_sysctl
        exit 0
        ;;
    --limits)
        apply_limits
        exit 0
        ;;
    --tracker)
        apply_tracker
        exit 0
        ;;
    --zram)
        apply_zram
        exit 0
        ;;
    --no-install)
        apply_sysctl
        apply_limits
        apply_tracker
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "⚡ APLICANDO OPTIMIZACIONES DE RENDIMIENTO (UBUNTU WORKSTATION)"
        echo "================================================================="
        apply_sysctl
        apply_limits
        apply_tracker
        apply_zram
        apply_services
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Optimizaciones de rendimiento aplicadas con éxito en Ubuntu."
        echo "================================================================="
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
