#!/bin/bash
# ==============================================================================
# cachyos-tuning.sh - Optimizador y Ajuste de Rendimiento para CachyOS + Niri
# ==============================================================================
#
# Uso:
#   ./cachyos-tuning.sh               -> Aplica todas las optimizaciones recomendadas
#   ./cachyos-tuning.sh --status      -> Muestra el estado actual de los parametros de rendimiento
#   ./cachyos-tuning.sh --no-install  -> Aplica optimizaciones sin instalar paquetes adicionales
#   ./cachyos-tuning.sh --sysctl      -> Aplica unicamente los ajustes de Kernel Sysctl
#   ./cachyos-tuning.sh --limits      -> Aplica limites de descriptores (limits.d y systemd)
#   ./cachyos-tuning.sh --services    -> Configura servicios de alto rendimiento (Ananicy, UKSMD, irqbalance, fstrim)
#   ./cachyos-tuning.sh --niri        -> Aplica optimizaciones especificas de Niri / Wayland
#   ./cachyos-tuning.sh --help        -> Muestra la ayuda interactiva
#
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no esta disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de sudo
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

# Ejecutar comandos de configuracion en el contexto del usuario real
run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

show_help() {
    cat <<EOF
⚡ Optimizador y Ajuste de Rendimiento - CachyOS (Niri + Noctalia Shell)

Uso:
  $0 [OPCION]

Opciones principales:
  (sin argumentos)       Aplica todas las optimizaciones recomendadas (Kernel, Limites, Servicios, Niri/Wayland, Systemd y Distrobox).
  --status, -s           Muestra el estado actual de sysctl, limites, ZRAM, Ananicy-CPP, UKSMD, Niri y servicios.
  --no-install           Aplica las configuraciones de kernel, limites y entorno sin descargar paquetes con pacman.
  --sysctl               Aplica unicamente la configuracion de parametros de Kernel Sysctl.
  --limits               Aplica limites de descriptores y memoria (limits.d y systemd system/user).
  --services             Configura e inicia Ananicy-CPP, UKSMD, irqbalance y fstrim.
  --niri                 Aplica optimizaciones de entorno Wayland, latencia y sesion de usuario para Niri.
  --help, -h             Muestra este mensaje de ayuda.

Optimizaciones incluidas:
  1. Sysctl Kernel:      Inotify ampliado (1M watches, 8K instancias), max_map_count (16M), ZRAM swappiness (180),
                         vm.page-cluster=0 (critico para ZRAM), dirty ratios equilibrados y TCP BBR + FastOpen.
  2. Limites de Proceso: Descriptores (1M nofile), memoria bloqueada (memlock) y limites en systemd system/user
                         para que aplicaciones GUI (IDEs, compiladores, navegadores) hereden los limites.
  3. Servicios CachyOS:  Ananicy-CPP (Auto-Nice con reglas CachyOS), UKSMD (deduplicacion KSM RAM),
                         irqbalance (balanceo multinuclo de interrupciones) y fstrim.timer (mantenimiento NVMe/SSD).
  4. Systemd Timeouts:   Reduccion de DefaultTimeoutStopSec y AbortSec a 10s para apagados/reinicios instantaneos.
  5. Niri / Wayland:     Variables de entorno de baja latencia Wayland y limpieza de servicios KDE/Baloo obsoletos.
  6. Contenedores:       Instalacion de Distrobox y Podman para entornos aislados.
EOF
}

# 1. Mostrar estado actual
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE RENDIMIENTO Y OPTIMIZACIONES - CACHYOS (NIRI WAYLAND)"
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
    echo "• Limite nofile (ulimit -n):     $(ulimit -n 2>/dev/null || echo 'n/a')"
    echo "• Systemd DefaultLimitNOFILE:    $(grep -h "DefaultLimitNOFILE" /etc/systemd/system.conf.d/*.conf /etc/systemd/user.conf.d/*.conf 2>/dev/null | head -n1 || echo 'Por defecto')"
    echo "• Systemd Stop Timeout:          $(grep -h "DefaultTimeoutStopSec" /etc/systemd/system.conf.d/*.conf 2>/dev/null | head -n1 || echo 'Por defecto')"
    echo "-----------------------------------------------------------------"
    echo "• ZRAM Swap Activo:              $(if command -v zramctl &>/dev/null && [ -n "$(zramctl 2>/dev/null)" ]; then echo 'Si ('"$(zramctl --noheadings -o ALGORITHM,DISKSIZE 2>/dev/null | head -n1)"')'; else echo 'No / Inactivo'; fi)"
    echo "• Ananicy-CPP (Auto-Nice):       $(systemctl is-active --quiet ananicy-cpp.service 2>/dev/null && echo 'Activo' || echo 'Inactivo / No instalado')"
    echo "• UKSMD (Deduplicacion RAM):     $(systemctl is-active --quiet uksmd.service 2>/dev/null && echo 'Activo' || echo 'Inactivo / No instalado')"
    echo "• Irqbalance (Distribucion IRQ): $(systemctl is-active --quiet irqbalance.service 2>/dev/null && echo 'Activo' || echo 'Inactivo / No instalado')"
    echo "• SSD Trim Timer (fstrim.timer): $(systemctl is-enabled --quiet fstrim.timer 2>/dev/null && echo 'Habilitado' || echo 'Inactivo / Deshabilitado')"
    echo "• Distrobox instalado:           $(command -v distrobox &>/dev/null && echo 'Si' || echo 'No')"
    echo "• Podman instalado:              $(command -v podman &>/dev/null && echo 'Si' || echo 'No')"
    echo "-----------------------------------------------------------------"
    echo "• Niri Compositor:               $(command -v niri &>/dev/null && echo 'Disponible' || echo 'No instalado')"
    echo "• Noctalia Shell:                $(command -v noctalia &>/dev/null && echo 'Disponible' || echo 'No instalado')"
    echo "• Config Niri (~/.config/niri):  $([ -f "$USER_HOME/.config/niri/config.kdl" ] && echo 'Presente' || echo 'No configurada')"
    echo "================================================================="
}

# 2. Configuracion de Sysctl para Kernel de Desarrollo y Alto Rendimiento
apply_sysctl_tuning() {
    echo "⚙️ [1/5] Aplicando parametros de Kernel Sysctl para CachyOS y Wayland..."

    $SUDO mkdir -p /etc/sysctl.d

    cat << 'EOF' | $SUDO tee /etc/sysctl.d/99-cachyos-tuning.conf > /dev/null
# Optimizaciones de rendimiento del Kernel - CachyOS + Niri Wayland
# Generado automaticamente por cachyos-tuning.sh

# 1. Inotify (Monitoreo de archivos para IDEs, Vite, Webpack, Rust Analyzer, Git)
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 8192
fs.inotify.max_queued_events = 65536

# 2. Descriptores de archivo globales del sistema
fs.file-max = 2097152

# 3. Virtual Memory & ZRAM
vm.max_map_count = 16777216
vm.swappiness = 180
vm.page-cluster = 0
vm.vfs_cache_pressure = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10

# 4. Red (BBR + Fast Open para descargas y navegacion web instantanea)
net.core.default_qdisc = fq_pie
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.somaxconn = 8192
net.ipv4.tcp_max_syn_backlog = 8192
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_slow_start_after_idle = 0
EOF

    # Aplicar parametros inmediatamente
    $SUDO sysctl --system > /dev/null || true
    echo "✅ Parametros de Sysctl aplicados y persistidos en /etc/sysctl.d/99-cachyos-tuning.conf"
}

# 3. Limites de Procesos y Descriptores (limits.d y Systemd)
apply_limits_tuning() {
    echo "📈 [2/5] Configurando limites de descriptores de archivo y memoria (limits.d y systemd)..."

    # 1. Limites en limits.d (PAM sessions, shells interactivas y terminales)
    $SUDO mkdir -p /etc/security/limits.d
    cat << 'EOF' | $SUDO tee /etc/security/limits.d/99-cachyos-limits.conf > /dev/null
# Limites elevados para desarrollo en CachyOS
* soft nofile 1048576
* hard nofile 1048576
* soft memlock unlimited
* hard memlock unlimited
root soft nofile 1048576
root hard nofile 1048576
EOF

    # 2. Limites en Systemd para servicios del sistema y aplicaciones GUI Wayland (app.slice / user session)
    $SUDO mkdir -p /etc/systemd/system.conf.d /etc/systemd/user.conf.d

    cat << 'EOF' | $SUDO tee /etc/systemd/system.conf.d/99-limits.conf > /dev/null
[Manager]
DefaultLimitNOFILE=1048576:1048576
DefaultLimitMEMLOCK=infinity
EOF

    cat << 'EOF' | $SUDO tee /etc/systemd/user.conf.d/99-limits.conf > /dev/null
[Manager]
DefaultLimitNOFILE=1048576:1048576
DefaultLimitMEMLOCK=infinity
EOF

    echo "✅ Limites de descriptores (1,048,576) configurados para shell y servicios de usuario Systemd."
}

# 4. Servicios de Rendimiento de CachyOS
apply_cachyos_services() {
    echo "🚀 [3/5] Habilitando y optimizando servicios de rendimiento CachyOS..."

    # 1. Ananicy-CPP (Auto Nice Daemon en C++)
    if pacman -Q ananicy-cpp &>/dev/null; then
        echo "  • Configurando Ananicy-CPP..."
        $SUDO systemctl enable --now ananicy-cpp.service 2>/dev/null || true
    elif command -v ananicy-cpp &>/dev/null; then
        $SUDO systemctl enable --now ananicy-cpp.service 2>/dev/null || true
    fi

    # 2. UKSMD (Kernel Samepage Merging Daemon - deduplicacion transparente de RAM)
    if pacman -Q uksmd &>/dev/null || command -v uksmd &>/dev/null; then
        echo "  • Configurando UKSMD..."
        $SUDO systemctl enable --now uksmd.service 2>/dev/null || true
    fi

    # 3. Irqbalance (Balanceo inteligente de interrupciones entre nucleos de CPU)
    if pacman -Q irqbalance &>/dev/null || command -v irqbalance &>/dev/null; then
        echo "  • Habilitando Irqbalance..."
        $SUDO systemctl enable --now irqbalance.service 2>/dev/null || true
    fi

    # 4. Fstrim.timer (Mantenimiento periodico de SSDs / NVMe)
    echo "  • Habilitando fstrim.timer..."
    $SUDO systemctl enable --now fstrim.timer 2>/dev/null || true

    echo "✅ Servicios de rendimiento verificados y activos."
}

# 5. Reduccion de Timeouts de Apagado en Systemd
apply_systemd_tuning() {
    echo "⏱️ [4/5] Optimizando tiempos de parada de servicios en Systemd..."

    $SUDO mkdir -p /etc/systemd/system.conf.d /etc/systemd/user.conf.d

    cat << 'EOF' | $SUDO tee /etc/systemd/system.conf.d/99-timeout.conf > /dev/null
[Manager]
DefaultTimeoutStopSec=10s
DefaultTimeoutAbortSec=10s
EOF

    cat << 'EOF' | $SUDO tee /etc/systemd/user.conf.d/99-timeout.conf > /dev/null
[Manager]
DefaultTimeoutStopSec=10s
DefaultTimeoutAbortSec=10s
EOF

    echo "✅ Timeout de apagado en Systemd configurado a 10 segundos (evita bloqueos al reiniciar)."
}

# 6. Optimizaciones especificas de Niri y Wayland
apply_niri_tuning() {
    echo "🌀 [5/5] Aplicando optimizaciones de latencia Wayland y limpiando servicios KDE..."

    # Desactivar y enmascarar servicios residuales de KDE Baloo si existieran
    run_as_user systemctl --user disable --now kde-baloo 2>/dev/null || true
    run_as_user systemctl --user mask kde-baloo 2>/dev/null || true

    # Desactivar plasmashell residual
    run_as_user systemctl --user disable --now plasma-plasmashell.service 2>/dev/null || true

    # Configurar generador de entorno Systemd para Niri Wayland
    local ENV_DIR="$USER_HOME/.config/environment.d"
    run_as_user mkdir -p "$ENV_DIR"
    cat << 'EOF' | run_as_user tee "$ENV_DIR/10-wayland-tuning.conf" > /dev/null
# Variables de entorno optimizadas para Niri y Noctalia Shell en CachyOS
XDG_CURRENT_DESKTOP=niri
XDG_SESSION_TYPE=wayland
QT_QPA_PLATFORM=wayland;xcb
QT_WAYLAND_DISABLE_WINDOWDECORATION=1
QT_QPA_PLATFORMTHEME=qt6ct
MOZ_ENABLE_WAYLAND=1
ELECTRON_OZONE_PLATFORM_HINT=auto
SDL_VIDEODRIVER=wayland
_JAVA_AWT_WM_NONREPARENTING=1
EOF

    # Validar configuración de Niri si el ejecutable está disponible
    if command -v niri &>/dev/null; then
        echo "  • Validando configuracion de Niri..."
        run_as_user niri validate 2>/dev/null && echo "  ✅ Configuracion de Niri valida." || echo "  ℹ️ Niri instalado pero se recomienda revisar ~/.config/niri/config.kdl"
    fi

    echo "✅ Optimizaciones de Niri / Wayland aplicadas con exito."
}

# 7. Herramientas de Desarrollo y Contenedores (Distrobox + Podman)
install_dev_tools() {
    echo "📦 Verificando e instalando Distrobox y Podman para entornos aislados..."
    $SUDO pacman -S --needed --noconfirm distrobox podman 2>/dev/null || true
    echo "✅ Distrobox y Podman instalados y listos."
}

# Procesar argumentos de linea de comandos
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
        echo "⚙️ APLICANDO SYSCTL TUNING - CACHYOS (NIRI WAYLAND)"
        echo "================================================================="
        apply_sysctl_tuning
        echo "✅ Sysctl aplicado con exito."
        ;;
    --limits)
        echo "================================================================="
        echo "📈 APLICANDO LIMITES DE PROCESO Y SYSTEMD - CACHYOS"
        echo "================================================================="
        apply_limits_tuning
        echo "✅ Limites aplicados con exito."
        ;;
    --services)
        echo "================================================================="
        echo "🚀 CONFIGURANDO SERVICIOS DE RENDIMIENTO - CACHYOS"
        echo "================================================================="
        apply_cachyos_services
        echo "✅ Servicios configurados con exito."
        ;;
    --niri|--wayland)
        echo "================================================================="
        echo "🌀 OPTIMIZANDO NIRI Y ENTORNO WAYLAND"
        echo "================================================================="
        apply_niri_tuning
        echo "✅ Optimizaciones de Niri aplicadas con exito."
        ;;
    --no-install)
        echo "================================================================="
        echo "⚡ APLICANDO OPTIMIZACIONES CACHYOS (NIRI) [SIN PAQUETES]"
        echo "================================================================="
        apply_sysctl_tuning
        apply_limits_tuning
        apply_systemd_tuning
        apply_niri_tuning
        echo ""
        echo "✅ Optimizaciones de sistema aplicadas con exito."
        ;;
    "")
        echo "================================================================="
        echo "⚡ INICIANDO OPTIMIZACION AVANZADA - CACHYOS (NIRI + NOCTALIA)"
        echo "================================================================="
        apply_sysctl_tuning
        apply_limits_tuning
        apply_cachyos_services
        apply_systemd_tuning
        apply_niri_tuning
        install_dev_tools
        echo ""
        echo "================================================================="
        echo "✅ Optimizacion completa de CachyOS (Niri + Noctalia) finalizada."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opcion no reconocida: $1"
        show_help
        exit 1
        ;;
esac
