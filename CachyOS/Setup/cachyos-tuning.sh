#!/bin/bash
# ==============================================================================
# cachyos-tuning.sh - Optimizador y Ajuste de Rendimiento para CachyOS + GNOME
# ==============================================================================
#
# Uso:
#   ./cachyos-tuning.sh               -> Aplica todas las optimizaciones recomendadas
#   ./cachyos-tuning.sh --status      -> Muestra el estado actual de los parámetros de rendimiento
#   ./cachyos-tuning.sh --no-install  -> Aplica optimizaciones sin instalar paquetes adicionales
#   ./cachyos-tuning.sh --sysctl      -> Aplica únicamente los ajustes de Kernel Sysctl
#   ./cachyos-tuning.sh --limits      -> Aplica límites de descriptores (limits.d y systemd)
#   ./cachyos-tuning.sh --services    -> Configura servicios de alto rendimiento (Ananicy, UKSMD, irqbalance, fstrim)
#   ./cachyos-tuning.sh --gnome       -> Aplica optimizaciones específicas de GNOME y exclusiones de Tracker
#   ./cachyos-tuning.sh --tracker-fast -> Configura Tracker para excluir masivamente carpetas de desarrollo
#   ./cachyos-tuning.sh --help        -> Muestra la ayuda interactiva
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

# Detectar usuario real en caso de sudo para configuraciones de usuario de GNOME
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

# Ejecutar comandos de configuración en el contexto del usuario real
run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

show_help() {
    cat <<EOF
⚡ Optimizador y Ajuste de Rendimiento - CachyOS (GNOME Workstation)

Uso:
  $0 [OPCION]

Opciones principales:
  (sin argumentos)       Aplica todas las optimizaciones recomendadas (Kernel, Límites, Servicios, GNOME/Tracker, Systemd y Distrobox).
  --status, -s           Muestra el estado actual de sysctl, límites, ZRAM, Ananicy-CPP, UKSMD, Tracker y servicios.
  --no-install           Aplica las configuraciones de kernel, límites y entorno sin descargar paquetes con pacman.
  --sysctl               Aplica únicamente la configuración de parámetros de Kernel Sysctl.
  --limits               Aplica límites de descriptores y memoria (limits.d y systemd system/user).
  --services             Configura e inicia Ananicy-CPP, UKSMD, irqbalance y fstrim.
  --gnome                Aplica optimizaciones de respuesta de GNOME Mutter (VRR) y exclusiones de Tracker.
  --tracker-fast         Configura Tracker para excluir carpetas pesadas de desarrollo (node_modules, target, etc.).
  --help, -h             Muestra este mensaje de ayuda.

Optimizaciones incluidas:
  1. Sysctl Kernel:      Inotify ampliado (1M watches, 8K instancias), max_map_count (16M), ZRAM swappiness (180),
                         vm.page-cluster=0 (crítico para ZRAM), dirty ratios equilibrados y TCP BBR + FastOpen.
  2. Límites de Proceso: Descriptores (1M nofile), memoria bloqueada (memlock) y límites en systemd system/user
                         para que aplicaciones GUI (IDEs, compiladores, navegadores) hereden los límites.
  3. Servicios CachyOS:  Ananicy-CPP (Auto-Nice con reglas CachyOS), UKSMD (deduplicación KSM RAM),
                         irqbalance (balanceo multinúcleo de interrupciones) y fstrim.timer (mantenimiento NVMe/SSD).
  4. Systemd Timeouts:   Reducción de DefaultTimeoutStopSec y AbortSec a 10s para apagados/reinicios instantáneos.
  5. GNOME / Mutter:     Habilitación de VRR (Variable Refresh Rate) y escalado framebuffer para multi-monitor.
  6. Tracker File Indexer: Exclusiones masivas de directorios de desarrollo para prevenir saturación de CPU/disco.
  7. Contenedores:       Instalación de Distrobox y Podman para entornos aislados.
EOF
}

# 1. Mostrar estado actual
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE RENDIMIENTO Y OPTIMIZACIONES - CACHYOS (GNOME)"
    echo "================================================================="
    echo "• Kernel:                        $(uname -r)"
    echo "• Planificador CPU Governor:     $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'n/a')"
    echo "• Energy Performance Pref (EPP): $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo 'n/a')"
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
    echo "• Límite nofile (ulimit -n):     $(ulimit -n 2>/dev/null || echo 'n/a')"
    echo "• Systemd DefaultLimitNOFILE:    $(grep -h "DefaultLimitNOFILE" /etc/systemd/system.conf.d/*.conf /etc/systemd/user.conf.d/*.conf 2>/dev/null | head -n1 || echo 'Por defecto')"
    echo "• Systemd Stop Timeout:          $(grep -h "DefaultTimeoutStopSec" /etc/systemd/system.conf.d/*.conf 2>/dev/null | head -n1 || echo 'Por defecto')"
    echo "-----------------------------------------------------------------"
    echo "• ZRAM Swap Activo:              $(if command -v zramctl &>/dev/null && [ -n "$(zramctl 2>/dev/null)" ]; then echo 'Sí ('"$(zramctl --noheadings -o ALGORITHM,DISKSIZE 2>/dev/null | head -n1)"')'; else echo 'No / Inactivo'; fi)"
    echo "• Ananicy-CPP (Auto-Nice):       $(systemctl is-active --quiet ananicy-cpp.service 2>/dev/null && echo 'Activo' || echo 'Inactivo / No instalado')"
    echo "• UKSMD (Deduplicación RAM):     $(systemctl is-active --quiet uksmd.service 2>/dev/null && echo 'Activo' || echo 'Inactivo / No instalado')"
    echo "• Irqbalance (Distribución IRQ): $(systemctl is-active --quiet irqbalance.service 2>/dev/null && echo 'Activo' || echo 'Inactivo / No instalado')"
    echo "• Fstrim Timer (Mantenimiento SSD): $(systemctl is-enabled --quiet fstrim.timer 2>/dev/null && echo 'Habilitado' || echo 'Inactivo')"
    echo "-----------------------------------------------------------------"
    echo "• GNOME Mutter VRR / Scaling:    $(run_as_user gsettings get org.gnome.mutter experimental-features 2>/dev/null || echo 'n/a')"
    echo "• GNOME Tema de Color:           $(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo 'n/a')"
    echo "================================================================="
}

# 2. Configuración de Parámetros de Kernel Sysctl
apply_sysctl_tuning() {
    echo "⚙️ [1/6] Configurando optimizaciones del Kernel (Sysctl)..."

    $SUDO tee /etc/sysctl.d/99-cachyos-tuning.conf > /dev/null << 'EOF'
# =============================================================================
# CACHYOS HIGH-PERFORMANCE SYSCTL TUNING (GNOME Workstation)
# =============================================================================

# 1. Monitoreo de Sistema y Descriptores de Inotify
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 8192
fs.file-max = 2097152

# 2. Memoria Virtual y Gestor de Mapas de Memoria
vm.max_map_count = 16777216

# 3. ZRAM y Swappiness agresivo optimizado para memoria comprimida
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0

# 4. Presión de Caché VFS y Gestión de Páginas Sucias (Dirty Ratio)
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10

# 5. Red TCP / Stack de Red de Alta Velocidad (BBR y FastOpen)
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_notsent_lowat = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_max_syn_backlog = 8192
EOF

    $SUDO sysctl --system > /dev/null || true
    echo "✅ Parámetros de Kernel Sysctl aplicados correctamente."
}

# 3. Configuración de Límites de Descriptores de Proceso (limits.d y systemd)
apply_limits_tuning() {
    echo "📈 [2/6] Configurando límites de descriptores de archivos, memoria y sesiones Systemd..."

    $SUDO tee /etc/security/limits.d/99-dev-limits.conf > /dev/null << 'EOF'
# Límites ampliados para desarrollo masivo, IDEs, compilaciones y gaming
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
    echo "✅ Límites de seguridad (limits.d y systemd system/user) configurados."
}

# 4. Servicios de Alto Rendimiento y Mantenimiento de CachyOS
apply_cachyos_services() {
    echo "🚀 [3/6] Verificando e instalando Ananicy-CPP, UKSMD, Irqbalance y temporizadores..."

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

    echo "✅ Servicios de rendimiento (Ananicy-CPP, UKSMD, Irqbalance, fstrim) habilitados."
}

# 5. Optimización de Timeouts de Apagado de Systemd
apply_systemd_tuning() {
    echo "⏱️ [4/6] Ajustando timeouts de parada de servicios en Systemd (10s)..."
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

    echo "✅ Timeout de apagado en Systemd configurado a 10 segundos (evita bloqueos al reiniciar)."
}

# 6. Optimización de GNOME (Mutter VRR y exclusiones de Tracker)
apply_gnome_tuning() {
    echo "🎨 [5/6] Configurando optimizaciones de fluidez de GNOME y exclusiones del indexador Tracker..."

    # Características avanzadas de Mutter (VRR y soporte multi-pantalla fractional)
    run_as_user gsettings set org.gnome.mutter experimental-features "['variable-refresh-rate', 'scale-monitor-framebuffer']" 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true

    # Optimización del indexador Tracker 3 (LocalSearch) para estaciones de desarrollo:
    # Excluir carpetas masivas de dependencias y compilación para no saturar I/O
    if run_as_user gsettings list-schemas | grep -q "org.freedesktop.Tracker3.Miner.Files"; then
        run_as_user gsettings set org.freedesktop.Tracker3.Miner.Files index-on-battery false 2>/dev/null || true
        run_as_user gsettings set org.freedesktop.Tracker3.Miner.Files ignored-directories \
            "['node_modules', '.git', '.venv', '.cargo', 'target', 'build', 'dist', '.cache', '.npm', '.rustup', '.local/share/Steam']" 2>/dev/null || true
        echo "ℹ️ Tracker 3 configurado con exclusiones inteligentes para desarrollo."
    fi

    echo "✅ Optimizaciones de GNOME y Tracker aplicadas."
}

# 7. Herramientas de Desarrollo y Contenedores (Distrobox + Podman)
install_dev_tools() {
    echo "📦 [6/6] Verificando e instalando Distrobox y Podman para entornos aislados..."
    $SUDO pacman -S --needed --noconfirm distrobox podman 2>/dev/null || true
    echo "✅ Distrobox y Podman instalados y listos."
}

# Procesar argumentos de línea de comandos
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
        echo "⚙️ APLICANDO SYSCTL TUNING - CACHYOS (GNOME)"
        echo "================================================================="
        apply_sysctl_tuning
        echo "✅ Sysctl aplicado con éxito."
        ;;
    --limits)
        echo "================================================================="
        echo "📈 APLICANDO LÍMITES DE PROCESO Y SYSTEMD - CACHYOS"
        echo "================================================================="
        apply_limits_tuning
        echo "✅ Límites aplicados con éxito."
        ;;
    --services)
        echo "================================================================="
        echo "🚀 CONFIGURANDO SERVICIOS DE RENDIMIENTO - CACHYOS"
        echo "================================================================="
        apply_cachyos_services
        echo "✅ Servicios configurados con éxito."
        ;;
    --gnome)
        echo "================================================================="
        echo "🎨 OPTIMIZANDO GNOME Y TRACKER INDEXER"
        echo "================================================================="
        apply_gnome_tuning
        echo "✅ Optimizaciones de GNOME aplicadas con éxito."
        ;;
    --tracker-fast)
        echo "================================================================="
        echo "🗂️ CONFIGURANDO EXCLUSIONES DE TRACKER 3 PARA DESARROLLO"
        echo "================================================================="
        apply_gnome_tuning
        echo "✅ Exclusiones de Tracker aplicadas."
        ;;
    --no-install)
        echo "================================================================="
        echo "⚡ APLICANDO OPTIMIZACIONES CACHYOS (GNOME) [SIN PAQUETES]"
        echo "================================================================="
        apply_sysctl_tuning
        apply_limits_tuning
        apply_systemd_tuning
        apply_gnome_tuning
        echo ""
        echo "✅ Optimizaciones de sistema aplicadas con éxito."
        ;;
    "")
        echo "================================================================="
        echo "⚡ INICIANDO OPTIMIZACIÓN AVANZADA - CACHYOS (GNOME)"
        echo "================================================================="
        apply_sysctl_tuning
        apply_limits_tuning
        apply_cachyos_services
        apply_systemd_tuning
        apply_gnome_tuning
        install_dev_tools
        echo ""
        echo "================================================================="
        echo "✅ Optimización completa de CachyOS (GNOME Workstation) finalizada."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
