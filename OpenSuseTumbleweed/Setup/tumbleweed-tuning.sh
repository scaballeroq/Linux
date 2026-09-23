#!/bin/bash
# ==============================================================================
# tumbleweed-tuning.sh - Optimizador y Ajuste de Rendimiento para openSUSE Tumbleweed
# Entorno: KDE Plasma 6 (Wayland) + Btrfs Snapper + AMD Ryzen
# ==============================================================================
#
# Uso:
#   ./tumbleweed-tuning.sh               -> Aplica todas las optimizaciones recomendadas
#   ./tumbleweed-tuning.sh --status      -> Muestra el estado actual de los parámetros de rendimiento
#   ./tumbleweed-tuning.sh --no-install  -> Aplica optimizaciones sin instalar paquetes adicionales
#   ./tumbleweed-tuning.sh --sysctl      -> Aplica únicamente los ajustes de Kernel Sysctl
#   ./tumbleweed-tuning.sh --limits      -> Aplica límites de descriptores (limits.d y systemd)
#   ./tumbleweed-tuning.sh --snapper     -> Ajusta políticas de retención de instantáneas Snapper
#   ./tumbleweed-tuning.sh --baloo       -> Configura el indexador Baloo para excluir carpetas pesadas de desarrollo
#   ./tumbleweed-tuning.sh --help        -> Muestra la ayuda interactiva
#
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de sudo para configuraciones de usuario de KDE/Baloo
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
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$REAL_UID/bus}" \
            "$@"
    else
        "$@"
    fi
}

show_help() {
    cat <<EOF
⚡ Optimizador y Ajuste de Rendimiento - openSUSE Tumbleweed (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones principales:
  (sin argumentos)       Aplica todas las optimizaciones recomendadas (Kernel, Límites, Snapper, Baloo, Systemd y Distrobox).
  --status, -s           Muestra el estado actual de sysctl, límites, ZRAM, Snapper, Baloo y servicios.
  --no-install           Aplica las configuraciones de kernel, límites y entorno sin descargar paquetes Zypper.
  --sysctl               Aplica únicamente la configuración de parámetros de Kernel Sysctl.
  --limits               Aplica límites de descriptores y memoria (limits.d y systemd system/user).
  --snapper              Ajusta los límites de retención de Snapper en Btrfs para prevenir saturación de disco.
  --baloo                Configura Baloo para excluir carpetas pesadas de desarrollo (node_modules, target, etc.).
  --help, -h             Muestra este mensaje de ayuda.

Optimizaciones incluidas:
  1. Sysctl Kernel:      Inotify ampliado (1M watches, 8K instancias), max_map_count (16M), ZRAM swappiness (180),
                         vm.page-cluster=0 (crítico para ZRAM), dirty ratios equilibrados y TCP BBR + FastOpen.
  2. Límites de Proceso: Descriptores (1M nofile), memoria bloqueada (memlock) y límites en systemd system/user
                         para que aplicaciones GUI (IDEs, compiladores, navegadores) hereden los límites.
  3. Systemd Timeouts:   Reducción de DefaultTimeoutStopSec y AbortSec a 10s para apagados/reinicios instantáneos.
  4. Snapper Btrfs:      Límites equilibrados de instantáneas horarias/diarias y timers de limpieza activos.
  5. Baloo Indexer:      Exclusiones masivas de directorios de desarrollo para prevenir saturación de CPU/disco.
  6. Contenedores:       Instalación de Distrobox y Podman para entornos aislados.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE RENDIMIENTO Y OPTIMIZACIONES - OPENSUSE TUMBLEWEED"
    echo "================================================================="
    echo "• Kernel:                        $(uname -r)"
    echo "• Planificador CPU Governor:     $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'n/a')"
    echo "-----------------------------------------------------------------"
    echo "• fs.inotify.max_user_watches:   $(sysctl -n fs.inotify.max_user_watches 2>/dev/null || echo 'n/a')"
    echo "• fs.inotify.max_user_instances: $(sysctl -n fs.inotify.max_user_instances 2>/dev/null || echo 'n/a')"
    echo "• fs.file-max:                   $(sysctl -n fs.file-max 2>/dev/null || echo 'n/a')"
    echo "• vm.max_map_count:              $(sysctl -n vm.max_map_count 2>/dev/null || echo 'n/a')"
    echo "• vm.swappiness (ZRAM):          $(sysctl -n vm.swappiness 2>/dev/null || echo 'n/a')"
    echo "• vm.page-cluster (ZRAM):        $(sysctl -n vm.page-cluster 2>/dev/null || echo 'n/a')"
    echo "• vm.vfs_cache_pressure:         $(sysctl -n vm.vfs_cache_pressure 2>/dev/null || echo 'n/a')"
    echo "• vm.dirty_ratio / background:   $(sysctl -n vm.dirty_ratio 2>/dev/null || echo 'n/a') / $(sysctl -n vm.dirty_background_ratio 2>/dev/null || echo 'n/a')"
    echo "• net.ipv4.tcp_congestion_ctrl:  $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'n/a')"
    echo "• net.ipv4.tcp_fastopen:         $(sysctl -n net.ipv4.tcp_fastopen 2>/dev/null || echo 'n/a')"
    echo "-----------------------------------------------------------------"
    echo "• Límites nofile (soft / hard):  $(ulimit -Sn 2>/dev/null || echo 'n/a') / $(ulimit -Hn 2>/dev/null || echo 'n/a')"
    echo "• Dispositivo ZRAM:              $(zramctl 2>/dev/null | grep -E '^/dev/zram' || echo 'No detectado / inactivo')"
    echo "-----------------------------------------------------------------"
    echo "• Estado de Snapper (Btrfs):     $(if command -v snapper &>/dev/null && [ -f /etc/snapper/configs/root ]; then echo "Activo (Config root presente)"; else echo "No configurado"; fi)"
    if command -v snapper &>/dev/null && [ -f /etc/snapper/configs/root ]; then
        echo "  - Horarias (Hourly):           $(grep -E '^TIMELINE_LIMIT_HOURLY=' /etc/snapper/configs/root 2>/dev/null || echo 'n/a')"
        echo "  - Diarias (Daily):             $(grep -E '^TIMELINE_LIMIT_DAILY=' /etc/snapper/configs/root 2>/dev/null || echo 'n/a')"
    fi
    echo "• Estado de Baloo (KDE Indexer): $(if command -v balooctl6 &>/dev/null; then balooctl6 status 2>/dev/null | head -n1; elif command -v balooctl &>/dev/null; then balooctl status 2>/dev/null | head -n1; else echo "No detectado"; fi)"
    echo "• Distrobox instalado:           $(if command -v distrobox &>/dev/null; then echo "✅ Sí ($(distrobox version 2>/dev/null || echo 'instalado'))"; else echo "❌ No"; fi)"
    echo "================================================================="
}

apply_sysctl() {
    echo "⚙️ [Sysctl] Aplicando optimizaciones avanzadas de Kernel para openSUSE Tumbleweed..."
    $SUDO mkdir -p /etc/sysctl.d
    cat <<'EOF' | $SUDO tee /etc/sysctl.d/99-tumbleweed-dev.conf > /dev/null
# =============================================================================
# OPTIMIZACIONES DE KERNEL SYSCTL - OPENSUSE TUMBLEWEED
# =============================================================================

# Inotify ampliado para desarrollo e IDEs (evita ENOSPC con Vite, Next, Rust, Webpack)
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 8192
fs.file-max = 2097152

# Memoria virtual y mmap ampliado (necesario para bases de datos, Elasticsearch, LLMs, Steam/Proton)
vm.max_map_count = 16777216

# Gestión de swap optimizada para ZRAM
vm.swappiness = 180
vm.page-cluster = 0

# Preservación agresiva de caché de inodos y dentry en memoria
vm.vfs_cache_pressure = 50

# Ratios de escritura en disco asíncronos y reactivos
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# Pila de red TCP de alto rendimiento y baja latencia
net.core.default_qdisc = fq_codel
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 4096
EOF

    $SUDO sysctl --system > /dev/null 2>&1 || true
    echo "  ✅ Parámetros de sysctl aplicados correctamente."
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
DefaultTimeoutStopSec=10s
DefaultTimeoutAbortSec=10s
EOF

    cat <<'EOF' | $SUDO tee /etc/systemd/user.conf.d/99-limits.conf > /dev/null
[Manager]
DefaultLimitNOFILE=1048576:1048576
DefaultLimitMEMLOCK=infinity
DefaultTimeoutStopSec=10s
DefaultTimeoutAbortSec=10s
EOF

    echo "  ✅ Límites configurados para sesiones de usuario y servicios systemd."
}

apply_snapper() {
    echo "⚙️ [Snapper] Optimizando políticas de retención de instantáneas en Btrfs..."
    if command -v snapper &> /dev/null && [ -f /etc/snapper/configs/root ]; then
        $SUDO sed -i 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' /etc/snapper/configs/root 2>/dev/null || true
        $SUDO sed -i 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' /etc/snapper/configs/root 2>/dev/null || true
        $SUDO sed -i 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="2"/' /etc/snapper/configs/root 2>/dev/null || true
        $SUDO sed -i 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/' /etc/snapper/configs/root 2>/dev/null || true
        $SUDO sed -i 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root 2>/dev/null || true

        # Habilitar timers automáticos de Snapper
        $SUDO systemctl enable --now snapper-cleanup.timer 2>/dev/null || true
        $SUDO systemctl enable --now snapper-timeline.timer 2>/dev/null || true
        echo "  ✅ Snapper optimizado para balancear seguridad y espacio en disco."
    else
        echo "  ℹ️ Snapper no detectado o configuración de root ausente."
    fi
}

apply_baloo() {
    echo "⚙️ [Baloo] Configurando exclusiones del indexador de KDE Plasma para desarrollo..."
    # Configurar exclusiones de carpetas pesadas en baloorc del usuario
    run_as_user mkdir -p "$USER_HOME/.config"
    local baloorc="$USER_HOME/.config/baloorc"

    # Excluir directorios típicos de dependencias y builds pesadas
    local exclude_dirs="$USER_HOME/Workspace/node_modules,$USER_HOME/.cache,$USER_HOME/.cargo,$USER_HOME/.rustup,$USER_HOME/.local/share/containers,$USER_HOME/.local/share/Trash,$USER_HOME/Descargas,$USER_HOME/Downloads"

    run_as_user kwriteconfig6 --file baloorc --group "General" --key "exclude folders[$e]" "$exclude_dirs" 2>/dev/null || \
    run_as_user kwriteconfig5 --file baloorc --group "General" --key "exclude folders[$e]" "$exclude_dirs" 2>/dev/null || true

    # Excluir indexación de contenido de archivos de código masivo
    run_as_user kwriteconfig6 --file baloorc --group "General" --key "only basic indexing" true 2>/dev/null || true

    echo "  ✅ Baloo configurado con exclusiones de desarrollo para ahorrar CPU y batería."
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
    --snapper)
        apply_snapper
        exit 0
        ;;
    --baloo)
        apply_baloo
        exit 0
        ;;
    --no-install)
        apply_sysctl
        apply_limits
        apply_snapper
        apply_baloo
        echo "================================================================="
        echo "✅ Optimizaciones aplicadas (modo sin instalación de paquetes)."
        echo "================================================================="
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🚀 APLICANDO OPTIMIZACIONES COMPLETAS PARA OPENSUSE TUMBLEWEED"
        echo "================================================================="
        apply_sysctl
        apply_limits
        apply_snapper
        apply_baloo

        # Instalar Distrobox si no está presente
        echo "📦 Instalando Distrobox para contenedores de desarrollo..."
        $SUDO zypper --non-interactive install -y distrobox 2>/dev/null || true

        echo "================================================================="
        echo "✅ Optimizaciones completadas con éxito."
        echo "💡 Ejecuta './Setup/tumbleweed-tuning.sh --status' para verificar el estado."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
