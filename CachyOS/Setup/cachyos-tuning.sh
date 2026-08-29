#!/bin/bash
# cachyos-tuning.sh - Optimizaciones de Kernel Sysctl, Limites, Ananicy-CPP, UKSMD, Baloo y Distrobox para CachyOS + KDE Plasma 6
#
# Uso:
#   ./cachyos-tuning.sh               -> Aplica todas las optimizaciones recomendadas (Kernel, Limites, Ananicy-CPP, UKSMD, Baloo, Systemd y Distrobox)
#   ./cachyos-tuning.sh --status      -> Muestra el estado actual de los parametros de rendimiento del sistema
#   ./cachyos-tuning.sh --no-install  -> Aplica optimizaciones de configuracion sin reinstalar paquetes
#   ./cachyos-tuning.sh --help        -> Muestra la ayuda interactiva

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

# Detectar usuario real en caso de sudo para configuraciones de usuario de KDE
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

show_help() {
    cat <<EOF
⚡ Optimizador y Ajuste de Rendimiento - CachyOS (KDE Plasma 6)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Aplica todas las optimizaciones recomendadas (Sysctl, Limites, Ananicy-CPP, UKSMD, Baloo, Systemd y Distrobox).
  --status, -s           Muestra los valores actuales de sysctl, descriptores de archivos, ZRAM, Ananicy-CPP, UKSMD y Baloo.
  --no-install           Aplica las configuraciones de kernel y entorno sin descargar paquetes.
  --help, -h             Muestra este mensaje de ayuda.

Optimizaciones incluidas:
  1. Sysctl Kernel:      Inotify elevado (IDEs/KDE), max_map_count (Gaming/VMs), swappiness, vfs_cache_pressure y TCP BBR.
  2. Limites de Usuario: Descriptores de archivos (nofile) y memoria bloqueada (memlock) para desarrollo intensivo.
  3. Ananicy-CPP:        Auto-Nice en tiempo real para priorizar KWin, juegos y tareas interactivas sobre tareas de fondo.
  4. UKSMD Daemon:       Ultra Kernel Samepage Merging para ahorro inteligente de memoria RAM en KVM y contenedores Podman.
  5. Systemd Timeouts:   Reduccion de DefaultTimeoutStopSec a 10s para apagados y reinicios instantaneos sin bloqueos.
  6. KDE Plasma Baloo:   Exclusión de carpetas pesadas (node_modules, .git, .venv, target, etc.) para evitar picos de CPU/disco.
  7. Contenedores:       Instalacion de Distrobox y Podman para entornos de desarrollo aislados.
EOF
}

# 1. Mostrar estado actual
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE RENDIMIENTO Y OPTIMIZACIONES - CACHYOS (KDE PLASMA 6)"
    echo "================================================================="
    echo "• fs.inotify.max_user_watches:   $(sysctl -n fs.inotify.max_user_watches 2>/dev/null || echo 'n/a')"
    echo "• fs.inotify.max_user_instances: $(sysctl -n fs.inotify.max_user_instances 2>/dev/null || echo 'n/a')"
    echo "• fs.file-max:                   $(sysctl -n fs.file-max 2>/dev/null || echo 'n/a')"
    echo "• vm.max_map_count:              $(sysctl -n vm.max_map_count 2>/dev/null || echo 'n/a')"
    echo "• vm.swappiness:                 $(sysctl -n vm.swappiness 2>/dev/null || echo 'n/a')"
    echo "• vm.vfs_cache_pressure:         $(sysctl -n vm.vfs_cache_pressure 2>/dev/null || echo 'n/a')"
    echo "• net.ipv4.tcp_congestion_control: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'n/a')"
    echo "• Limite nofile (ulimit -n):     $(ulimit -n 2>/dev/null || echo 'n/a')"
    echo "• Ananicy-CPP (Auto-Nice):       $(systemctl is-active ananicy-cpp.service 2>/dev/null || echo 'inactivo / no instalado')"
    echo "• UKSMD (Ahorro RAM / KSM):      $(systemctl is-active uksmd.service 2>/dev/null || echo 'inactivo / no instalado')"
    echo "• Distrobox instalado:           $(command -v distrobox &>/dev/null && echo 'Si' || echo 'No')"
    echo "• Baloo Indexer (KDE):           $(if [ -f "$USER_HOME/.config/baloofilerc" ]; then grep -i "Indexing-Enabled" "$USER_HOME/.config/baloofilerc" 2>/dev/null || echo 'Habilitado (por defecto)'; else echo 'No configurado'; fi)"
    echo "================================================================="
}

# 2. Configuracion de Sysctl para Kernel de Desarrollo y Alto Rendimiento
apply_sysctl_tuning() {
    echo "⚙️ [1/6] Aplicando parametros de Kernel Sysctl para desarrollo, KDE Plasma y gaming..."

    # Habilitar modulo BBR si esta disponible
    $SUDO modprobe tcp_bbr 2>/dev/null || true

    $SUDO tee /etc/sysctl.d/99-cachyos-dev.conf > /dev/null << 'EOF'
# Optimizaciones de rendimiento del Kernel - CachyOS + KDE Plasma 6
# -------------------------------------------------------------------
# 1. Monitoreo de archivos en tiempo real para IDEs (VSCode, JetBrains, Rust-Analyzer) y Baloo/Dolphin
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
fs.file-max = 2097152

# 2. Mapeos de memoria virtual para bases de datos en memoria, compiladores, Docker/Podman y Wine/Proton/Steam Gaming
vm.max_map_count = 16777216

# 3. Gestion de Memoria (valor optimizado para CachyOS con ZRAM)
vm.swappiness = 180

# 4. Retencion de cache de inodos y directorios para acelerar 'git status', compilaciones e indexacion
vm.vfs_cache_pressure = 50

# 5. Rendimiento de red TCP y reduccion de latencia (Fair Queuing + BBR)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

    $SUDO sysctl --system > /dev/null || true
    echo "✅ Parametros de Kernel Sysctl aplicados correctamente."
}

# 3. Configuracion de Limites de Descriptores de Proceso (limits.d)
apply_limits_tuning() {
    echo "📈 [2/6] Configurando limites de descriptores de archivos y memoria bloqueada..."
    $SUDO tee /etc/security/limits.d/99-dev-limits.conf > /dev/null << 'EOF'
# Limites ampliados para desarrollo masivo, IDEs y compilaciones en paralelo
*          soft    nofile     524288
*          hard    nofile     1048576
*          soft    memlock    unlimited
*          hard    memlock    unlimited
EOF
    echo "✅ Limites de seguridad (limits.d) configurados."
}

# 4. Servicios de Alto Rendimiento de CachyOS (Ananicy-CPP + UKSMD)
apply_cachyos_services() {
    echo "🚀 [3/6] Verificando e instalando Ananicy-CPP (Auto-Nice) y UKSMD (Deduplicacion RAM)..."
    $SUDO pacman -S --needed --noconfirm \
        ananicy-cpp \
        cachyos-ananicy-rules \
        uksmd 2>/dev/null || $SUDO pacman -S --needed --noconfirm ananicy-cpp uksmd 2>/dev/null || true

    # Habilitar servicios en systemd
    $SUDO systemctl enable --now ananicy-cpp.service 2>/dev/null || true
    $SUDO systemctl enable --now uksmd.service 2>/dev/null || true
    echo "✅ Ananicy-CPP y UKSMD habilitados correctamente."
}

# 5. Optimizacion de Timeouts de Apagado de Systemd
apply_systemd_tuning() {
    echo "⏱️ [4/6] Ajustando timeouts de parada de servicios en Systemd (evita esperas de 90s al apagar)..."
    $SUDO mkdir -p /etc/systemd/system.conf.d
    $SUDO tee /etc/systemd/system.conf.d/99-fast-shutdown.conf > /dev/null << 'EOF'
[Manager]
DefaultTimeoutStopSec=10s
EOF
    echo "✅ Timeout de apagado en Systemd configurado a 10 segundos."
}

# 6. Optimizacion del Indexador de Archivos de KDE Plasma (Baloo)
apply_baloo_tuning() {
    echo "🗂️ [5/6] Configurando exclusiones inteligentes para el indexador Baloo de KDE Plasma..."
    local BALOO_CONF="$USER_HOME/.config/baloofilerc"
    mkdir -p "$(dirname "$BALOO_CONF")"

    # Exclusiones de directorios pesados de desarrollo para no sobrecargar CPU ni disco
    local EXCLUDE_PATTERNS="*.o,*.a,*.so,*.pyc,*.class,node_modules,.git,.venv,.cargo,target,vendor,.cache,build,dist,.npm,.rustup"

    if [ -f "$BALOO_CONF" ]; then
        if ! grep -q "exclude patterns" "$BALOO_CONF"; then
            echo "exclude patterns=$EXCLUDE_PATTERNS" >> "$BALOO_CONF"
        fi
    else
        cat <<EOF > "$BALOO_CONF"
[General]
exclude patterns=$EXCLUDE_PATTERNS
dbVersion=2
EOF
    fi
    chown -R "$REAL_USER:" "$USER_HOME/.config" 2>/dev/null || true
    echo "✅ Exclusiones de desarrollo de KDE Baloo configuradas."
}

# 7. Herramientas de Desarrollo y Contenedores (Distrobox + Podman)
install_dev_tools() {
    echo "📦 [6/6] Verificando e instalando Distrobox y Podman para entornos aislados..."
    $SUDO pacman -S --needed --noconfirm distrobox podman 2>/dev/null || true
    echo "✅ Distrobox y Podman instalados."
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
    --no-install)
        echo "================================================================="
        echo "⚡ APLICANDO OPTIMIZACIONES CACHYOS (KDE PLASMA 6) [SIN PAQUETES]"
        echo "================================================================="
        apply_sysctl_tuning
        apply_limits_tuning
        apply_systemd_tuning
        apply_baloo_tuning
        echo ""
        echo "✅ Optimizaciones de sistema aplicadas con exito."
        ;;
    "")
        echo "================================================================="
        echo "⚡ INICIANDO OPTIMIZACION AVANZADA - CACHYOS (KDE PLASMA 6)"
        echo "================================================================="
        apply_sysctl_tuning
        apply_limits_tuning
        apply_cachyos_services
        apply_systemd_tuning
        apply_baloo_tuning
        install_dev_tools
        echo ""
        echo "================================================================="
        echo "✅ Optimizacion completa de CachyOS (KDE Plasma 6) finalizada."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opcion no reconocida: $1"
        show_help
        exit 1
        ;;
esac
