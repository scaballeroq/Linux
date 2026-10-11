#!/bin/bash
# ==============================================================================
# debian-tuning.sh - Optimizador y Ajuste de Rendimiento para Debian Testing
# Entorno: KDE Plasma 6 (Wayland) + ZRAM + AMD Ryzen / Intel
# ==============================================================================
#
# Uso:
#   ./debian-tuning.sh               -> Aplica todas las optimizaciones recomendadas
#   ./debian-tuning.sh --status      -> Muestra el estado actual de los parámetros de rendimiento
#   ./debian-tuning.sh --no-install  -> Aplica optimizaciones sin instalar paquetes APT
#   ./debian-tuning.sh --sysctl      -> Aplica ajustes de Kernel Sysctl y TCP BBR
#   ./debian-tuning.sh --limits      -> Aplica límites de descriptores (limits.d y systemd)
#   ./debian-tuning.sh --baloo       -> Configura Baloo (KDE 6) para excluir carpetas de desarrollo
#   ./debian-tuning.sh --zram        -> Verifica y configura ZRAM (zstd)
#   ./debian-tuning.sh --help        -> Muestra la ayuda interactiva
#
# ==============================================================================

set -euo pipefail

# Asegurar rutas administrativas en PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de sudo para configuraciones de KDE Plasma 6 y Baloo
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
⚡ Optimizador y Ajuste de Rendimiento - Debian Testing (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones principales:
  (sin argumentos)       Aplica todas las optimizaciones recomendadas (Kernel, Límites, Baloo, ZRAM y Distrobox).
  --status, -s           Muestra el estado actual de sysctl, límites, ZRAM, Baloo y servicios.
  --no-install           Aplica las configuraciones de kernel, límites y entorno sin descargar paquetes APT.
  --sysctl               Aplica únicamente la configuración de parámetros de Kernel Sysctl y TCP BBR.
  --limits               Aplica límites de descriptores y memoria (limits.d y systemd system/user con daemon-reexec).
  --baloo                Configura Baloo (KDE Plasma 6) para excluir carpetas pesadas de desarrollo (baloofilerc).
  --zram                 Verifica y aplica la configuración óptima de ZRAM (zstd).
  --help, -h             Muestra este mensaje de ayuda.

Optimizaciones incluidas:
  1. Sysctl Kernel:      Inotify ampliado (1M watches, 8K instancias), max_map_count (16M), ZRAM swappiness (180),
                         vm.page-cluster=0, vm.watermark_boost_factor=0 (elimina microtirones), TCP BBR + FQ
                         con carga automática del módulo tcp_bbr en /etc/modules-load.d/bbr.conf.
  2. Límites de Proceso: Descriptores (1M nofile), memoria bloqueada (memlock infinity), DefaultTasksMax=infinity
                         en systemd system/user para que IDEs y compiladores nunca agoten recursos.
  3. Systemd Timeouts:   Reducción de DefaultTimeoutStopSec y AbortSec a 10s para apagados/reinicios limpios y rápidos.
  4. Baloo Indexer:      Configuración nativa de KDE Plasma 6 (balooctl6) con exclusión de Workspace, .cache,
                         node_modules, .cargo y contenedores, desactivando indexación profunda de contenidos.
  5. Memoria ZRAM:       Compresión ZSTD al 50% de RAM (hasta 8 GB) para mitigar la necesidad de swap en disco.
  6. Contenedores:       Disponibilidad de Distrobox y Podman para entornos aislados de desarrollo.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE RENDIMIENTO Y OPTIMIZACIONES - DEBIAN TESTING"
    echo "================================================================="
    echo "• Kernel:                        $(uname -r)"
    local gov_driver gov_name
    gov_driver=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo 'n/a')
    gov_name=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'n/a')
    echo "• CPU Scaling:                   $gov_name (Driver: $gov_driver)"
    echo "-----------------------------------------------------------------"
    echo "• fs.inotify.max_user_watches:   $(cat /proc/sys/fs/inotify/max_user_watches 2>/dev/null || echo 'n/a')"
    echo "• fs.inotify.max_user_instances: $(cat /proc/sys/fs/inotify/max_user_instances 2>/dev/null || echo 'n/a')"
    echo "• fs.file-max:                   $(cat /proc/sys/fs/file-max 2>/dev/null || echo 'n/a')"
    echo "• vm.max_map_count:              $(cat /proc/sys/vm/max_map_count 2>/dev/null || echo 'n/a')"
    echo "• vm.swappiness (ZRAM):          $(cat /proc/sys/vm/swappiness 2>/dev/null || echo 'n/a')"
    echo "• vm.page-cluster (ZRAM):        $(cat /proc/sys/vm/page-cluster 2>/dev/null || echo 'n/a')"
    echo "• vm.watermark_boost_factor:     $(cat /proc/sys/vm/watermark_boost_factor 2>/dev/null || echo 'n/a')"
    echo "• vm.vfs_cache_pressure:         $(cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null || echo 'n/a')"
    echo "• vm.dirty_ratio / background:   $(cat /proc/sys/vm/dirty_ratio 2>/dev/null || echo 'n/a') / $(cat /proc/sys/vm/dirty_background_ratio 2>/dev/null || echo 'n/a')"
    echo "• net.ipv4.tcp_congestion_ctrl:  $(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo 'n/a')"
    echo "• net.core.default_qdisc:        $(cat /proc/sys/net/core/default_qdisc 2>/dev/null || echo 'n/a')"
    echo "• net.ipv4.tcp_fastopen:         $(cat /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null || echo 'n/a')"
    echo "-----------------------------------------------------------------"
    echo "• Límites nofile (soft / hard):  $(ulimit -Sn 2>/dev/null || echo 'n/a') / $(ulimit -Hn 2>/dev/null || echo 'n/a')"
    local zram_info
    zram_info=$(zramctl 2>/dev/null | grep -E '^/dev/zram' || true)
    if [ -n "$zram_info" ]; then
        echo "• Dispositivo ZRAM:              $zram_info"
    else
        echo "• Dispositivo ZRAM:              No detectado / inactivo"
    fi
    echo "-----------------------------------------------------------------"
    local baloo_status
    if command -v balooctl6 &>/dev/null; then
        baloo_status=$(run_as_user balooctl6 status 2>/dev/null | head -n1 || echo "Instalado")
        echo "• Estado de Baloo (KDE 6):       $baloo_status"
        local baloo_indexing
        baloo_indexing=$(run_as_user balooctl6 config list contentIndexing 2>/dev/null || echo "desconocido")
        echo "  - Indexación de contenido:     $baloo_indexing"
    elif command -v balooctl &>/dev/null; then
        baloo_status=$(run_as_user balooctl status 2>/dev/null | head -n1 || echo "Instalado")
        echo "• Estado de Baloo (KDE 5):       $baloo_status"
    else
        echo "• Estado de Baloo (KDE Indexer): No detectado"
    fi
    echo "• Distrobox instalado:           $(if command -v distrobox &>/dev/null; then echo "✅ Sí ($(distrobox version 2>/dev/null || echo 'instalado'))"; else echo "❌ No"; fi)"
    echo "================================================================="
}

apply_sysctl() {
    echo "⚙️ [Sysctl] Aplicando optimizaciones avanzadas de Kernel y TCP BBR..."

    # Asegurar módulo tcp_bbr en arranque y en caliente
    $SUDO mkdir -p /etc/modules-load.d
    echo "tcp_bbr" | $SUDO tee /etc/modules-load.d/bbr.conf > /dev/null
    $SUDO modprobe tcp_bbr 2>/dev/null || true

    $SUDO mkdir -p /etc/sysctl.d
    cat <<'EOF' | $SUDO tee /etc/sysctl.d/99-debian-dev.conf > /dev/null
# =============================================================================
# OPTIMIZACIONES DE KERNEL SYSCTL - DEBIAN TESTING
# =============================================================================

# Inotify ampliado para desarrollo e IDEs (evita ENOSPC con Vite, Next, Rust, Webpack)
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 8192
fs.file-max = 2097152

# Memoria virtual y mmap ampliado (necesario para bases de datos, Elasticsearch, LLMs, Steam/Proton)
vm.max_map_count = 16777216

# Gestión de swap optimizada para ZRAM (alta swappiness para comprimir páginas inactivas en RAM)
vm.swappiness = 180
vm.page-cluster = 0

# Eliminar microtirones de kswapd en desbordamiento de memoria
vm.watermark_boost_factor = 0

# Preservación equilibrada de caché de inodos y dentry en memoria
vm.vfs_cache_pressure = 50

# Ratios de escritura en disco asíncronos y reactivos para almacenamiento NVMe
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# Pila de red TCP de alto rendimiento y baja latencia (BBR + Fair Queueing)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 4096
EOF

    $SUDO sysctl --system > /dev/null 2>&1 || true
    echo "  ✅ Parámetros de sysctl y módulo BBR aplicados con éxito."
}

apply_limits() {
    echo "⚙️ [Límites] Configurando límites de descriptores y memoria (limits.d y systemd)..."
    $SUDO mkdir -p /etc/security/limits.d
    cat <<'EOF' | $SUDO tee /etc/security/limits.d/99-developer-limits.conf > /dev/null
# Límites ampliados para compilación intensiva, servidores e IDEs
*          soft    nofile     1048576
*          hard    nofile     1048576
*          soft    nproc      unlimited
*          hard    nproc      unlimited
*          soft    memlock    unlimited
*          hard    memlock    unlimited
root       soft    nofile     1048576
root       hard    nofile     1048576
EOF

    $SUDO mkdir -p /etc/systemd/system.conf.d /etc/systemd/user.conf.d
    cat <<'EOF' | $SUDO tee /etc/systemd/system.conf.d/99-limits.conf > /dev/null
[Manager]
DefaultLimitNOFILE=1048576:1048576
DefaultLimitMEMLOCK=infinity
DefaultTasksMax=infinity
DefaultTimeoutStopSec=10s
DefaultTimeoutAbortSec=10s
EOF

    cat <<'EOF' | $SUDO tee /etc/systemd/user.conf.d/99-limits.conf > /dev/null
[Manager]
DefaultLimitNOFILE=1048576:1048576
DefaultLimitMEMLOCK=infinity
DefaultTasksMax=infinity
DefaultTimeoutStopSec=10s
DefaultTimeoutAbortSec=10s
EOF

    # Aplicar inmediatamente la configuración a systemd
    $SUDO systemctl daemon-reexec 2>/dev/null || true
    run_as_user systemctl --user daemon-reexec 2>/dev/null || true

    echo "  ✅ Límites configurados y daemon-reexec ejecutado para system y user."
}

apply_baloo() {
    echo "⚙️ [Baloo] Configurando exclusiones del indexador de KDE Plasma 6 para desarrollo..."
    run_as_user mkdir -p "$USER_HOME/.config"

    # Lista de directorios pesados de desarrollo y caché para excluir
    local dev_dirs=(
        "$USER_HOME/Workspace"
        "$USER_HOME/.cache"
        "$USER_HOME/.cargo"
        "$USER_HOME/.rustup"
        "$USER_HOME/.local/share/containers"
        "$USER_HOME/.local/share/Trash"
        "$USER_HOME/.var/app"
        "$USER_HOME/Descargas"
        "$USER_HOME/Downloads"
    )

    if command -v balooctl6 &>/dev/null; then
        for dir in "${dev_dirs[@]}"; do
            if [ -d "$dir" ] || [ "$dir" = "$USER_HOME/Workspace" ]; then
                run_as_user balooctl6 config add excludeFolders "$dir" 2>/dev/null || true
            fi
        done
        run_as_user balooctl6 config set contentIndexing no 2>/dev/null || true
    fi

    # Respaldo directo en baloofilerc (archivo nativo de KDE Plasma 6)
    if command -v kwriteconfig6 &>/dev/null; then
        run_as_user kwriteconfig6 --file baloofilerc --group "General" --key "only basic indexing" true 2>/dev/null || true
    fi

    echo "  ✅ Baloo configurado con exclusiones de desarrollo para ahorrar CPU, disco y batería."
}

apply_zram() {
    echo "⚙️ [ZRAM] Verificando compresión de memoria RAM..."
    if [ -f /etc/default/zramswap ]; then
        $SUDO sed -i 's/^#*ALGORITHM=.*/ALGORITHM=zstd/' /etc/default/zramswap
        $SUDO sed -i 's/^#*PERCENT=.*/PERCENT=50/' /etc/default/zramswap
        $SUDO systemctl restart zramswap.service 2>/dev/null || true
    fi

    $SUDO mkdir -p /etc/systemd
    if [ ! -f /etc/systemd/zram-generator.conf ]; then
        echo "  • Creando configuración de zram-generator (zstd al 50% de RAM, máx 8GB)..."
        cat <<'EOF' | $SUDO tee /etc/systemd/zram-generator.conf > /dev/null
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
EOF
    fi

    if systemctl list-unit-files systemd-zram-setup@zram0.service &>/dev/null; then
        $SUDO systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true
    fi
    echo "  ✅ ZRAM operativo y configurado."
}

# Procesar opciones CLI
case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
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
    --baloo)
        apply_baloo
        exit 0
        ;;
    --zram)
        apply_zram
        exit 0
        ;;
    --no-install)
        apply_sysctl
        apply_limits
        apply_baloo
        apply_zram
        echo "================================================================="
        echo "✅ Optimizaciones aplicadas (modo sin instalación de paquetes)."
        echo "================================================================="
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🚀 APLICANDO OPTIMIZACIONES COMPLETAS PARA DEBIAN TESTING"
        echo "================================================================="
        apply_sysctl
        apply_limits
        apply_baloo
        apply_zram

        # Instalar Distrobox si no está presente
        if ! command -v distrobox &>/dev/null; then
            echo "📦 Instalando Distrobox para contenedores de desarrollo..."
            export DEBIAN_FRONTEND=noninteractive
            $SUDO apt-get update -qq
            $SUDO apt-get install -y distrobox 2>/dev/null || true
        else
            echo "📦 Distrobox ya está instalado."
        fi

        echo "================================================================="
        echo "✅ Optimizaciones completadas con éxito."
        echo "💡 Ejecuta './Setup/debian-tuning.sh --status' para verificar el estado."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
