#!/bin/bash
# ==============================================================================
# fedora-tuning.sh - Optimizador y Ajuste de Rendimiento para Fedora 44 (KDE Plasma 6)
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U / Vega 7 / 32 GB RAM / Btrfs)
# ==============================================================================
#
# Uso:
#   ./fedora-tuning.sh               -> Aplica todas las optimizaciones recomendadas
#   ./fedora-tuning.sh --status, -s  -> Muestra el estado actual de los parámetros
#   ./fedora-tuning.sh --btrfs       -> Aplica optimizaciones de Btrfs y NoCoW
#   ./fedora-tuning.sh --sysctl      -> Aplica ajustes de Kernel Sysctl y TCP BBR
#   ./fedora-tuning.sh --limits      -> Aplica límites de descriptores (limits.d)
#   ./fedora-tuning.sh --baloo       -> Configura exclusiones para Baloo (KDE Plasma 6)
#   ./fedora-tuning.sh --zram        -> Verifica y optimiza parámetros para ZRAM
#   ./fedora-tuning.sh --no-install  -> Aplica optimizaciones sin instalar paquetes DNF5
#   ./fedora-tuning.sh --help, -h    -> Muestra la ayuda interactiva
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

# Detectar usuario real en caso de sudo para configuraciones de KDE Plasma 6
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

show_help() {
    cat <<EOF
⚡ Optimizador y Ajuste de Rendimiento - Fedora 44 (KDE Plasma 6 / Btrfs / AMD Ryzen)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Aplica todas las optimizaciones recomendadas (Btrfs, Sysctl, Límites, Baloo, ZRAM, Systemd y Distrobox).
  --status, -s           Muestra los valores actuales de Btrfs, sysctl, ZRAM, límites y Baloo.
  --btrfs                Aplica optimizaciones Btrfs (NoCoW en VMs KVM y Podman, verificación de compresión zstd).
  --sysctl               Aplica parámetros de Kernel Sysctl (Inotify, max_map_count, TCP BBR, ZRAM swappiness).
  --limits               Configura límites de descriptores de archivos (nofile) y memlock.
  --baloo                Configura exclusiones inteligentes para el indexador Baloo de KDE Plasma 6.
  --zram                 Verifica y optimiza parámetros de compresión ZRAM (zstd).
  --no-install           Aplica las configuraciones de kernel y entorno sin descargar paquetes DNF5.
  --help, -h             Muestra este mensaje de ayuda.

Optimizaciones incluidas:
  1. Sistema Btrfs:      NoCoW ('chattr +C') en /var/lib/libvirt/images y Podman para evitar fragmentación de I/O.
  2. Sysctl Kernel:      Inotify elevado (IDEs/KDE), max_map_count (Gaming/VMs), swappiness=150 (ZRAM), vfs_cache_pressure=50 y TCP BBR.
  3. Límites de Usuario: Descriptores de archivos (nofile 524288/1048576) y memoria bloqueada para desarrollo intensivo.
  4. KDE Plasma Baloo:   Exclusión de carpetas pesadas (node_modules, .git, .venv, target, etc.) para evitar picos de CPU/disco.
  5. Systemd Timeouts:   Reducción de DefaultTimeoutStopSec a 10s para apagados y reinicios instantáneos sin bloqueos.
  6. Contenedores:       Instalación de Distrobox y Podman para entornos de desarrollo aislados.
EOF
}

# 1. Mostrar estado actual
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE RENDIMIENTO Y OPTIMIZACIONES - FEDORA 44 (KDE PLASMA)"
    echo "================================================================="
    
    # Comprobación de Btrfs
    echo "--- [1] SISTEMA DE ARCHIVOS (Btrfs) ---"
    local root_fstype
    root_fstype=$(findmnt -n -o FSTYPE / 2>/dev/null || echo "desconocido")
    echo "• Sistema de archivos en / :     $root_fstype"
    if [ "$root_fstype" = "btrfs" ]; then
        echo "• Compresión y opciones montadas:"
        findmnt -n -o OPTIONS / 2>/dev/null | tr ',' '\n' | sed 's/^/    - /' || true
        echo "• NoCoW en /var/lib/libvirt/images:"
        if [ -d /var/lib/libvirt/images ]; then
            local nocow_attr
            nocow_attr=$(lsattr -d /var/lib/libvirt/images 2>/dev/null | awk '{print $1}' || echo "n/a")
            if echo "$nocow_attr" | grep -q "C"; then
                echo "    ✅ NoCoW activo (+C) (óptimo para evitar fragmentación en VMs)"
            else
                echo "    ⚠️ CoW activo (se recomienda aplicar --btrfs para habilitar +C)"
            fi
        else
            echo "    ℹ️ Directorio no existe aún (/var/lib/libvirt/images)"
        fi
    fi

    echo "--- [2] KERNEL SYSCTL & RED ---"
    echo "• fs.inotify.max_user_watches:   $(sysctl -n fs.inotify.max_user_watches 2>/dev/null || echo 'n/a')"
    echo "• fs.inotify.max_user_instances: $(sysctl -n fs.inotify.max_user_instances 2>/dev/null || echo 'n/a')"
    echo "• fs.file-max:                   $(sysctl -n fs.file-max 2>/dev/null || echo 'n/a')"
    echo "• vm.max_map_count:              $(sysctl -n vm.max_map_count 2>/dev/null || echo 'n/a')"
    echo "• vm.swappiness:                 $(sysctl -n vm.swappiness 2>/dev/null || echo 'n/a')"
    echo "• vm.vfs_cache_pressure:         $(sysctl -n vm.vfs_cache_pressure 2>/dev/null || echo 'n/a')"
    echo "• vm.page-cluster:               $(sysctl -n vm.page-cluster 2>/dev/null || echo 'n/a')"
    echo "• net.ipv4.tcp_congestion_control: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'n/a')"
    echo "• net.core.default_qdisc:        $(sysctl -n net.core.default_qdisc 2>/dev/null || echo 'n/a')"

    echo "--- [3] MEMORIA Y ZRAM ---"
    if command -v zramctl &>/dev/null; then
        zramctl 2>/dev/null || echo "Sin dispositivos ZRAM activos"
    else
        echo "zramctl no disponible"
    fi

    echo "--- [4] LÍMITES Y SERVICIOS ---"
    echo "• Límite nofile (ulimit -n):     $(ulimit -n 2>/dev/null || echo 'n/a')"
    echo "• Distrobox instalado:           $(command -v distrobox &>/dev/null && echo 'Sí' || echo 'No')"
    echo "• Podman instalado:              $(command -v podman &>/dev/null && echo 'Sí' || echo 'No')"
    echo "• Baloo Indexer (KDE):           $(if [ -f "$USER_HOME/.config/baloofilerc" ]; then grep -i "exclude patterns" "$USER_HOME/.config/baloofilerc" 2>/dev/null || echo 'Configurado (por defecto)'; else echo 'No configurado'; fi)"
    echo "================================================================="
}

# 2. Optimizaciones Btrfs y desactivación de CoW para Virtualización y Podman
apply_btrfs_tuning() {
    echo "🌲 [Btrfs] Comprobando optimizaciones para sistema de archivos Btrfs..."
    local root_fstype
    root_fstype=$(findmnt -n -o FSTYPE / 2>/dev/null || echo "desconocido")
    
    if [ "$root_fstype" = "btrfs" ]; then
        echo "⚡ Btrfs detectado en raíz. Configurando directivas NoCoW (+C) para almacenamiento de alto I/O..."
        
        # 1. Directorio de imágenes de KVM / Libvirt (crítico para rendimiento de VMs)
        if [ ! -d /var/lib/libvirt/images ]; then
            $SUDO mkdir -p /var/lib/libvirt/images
        fi
        $SUDO chattr +C /var/lib/libvirt/images 2>/dev/null || true
        echo "✅ Atributo NoCoW (+C) aplicado a /var/lib/libvirt/images."

        # 2. Directorio de contenedores Podman de usuario (si existe)
        local podman_storage="$USER_HOME/.local/share/containers/storage"
        if [ -d "$podman_storage" ]; then
            chattr +C "$podman_storage" 2>/dev/null || true
            echo "✅ Atributo NoCoW (+C) verificado en almacenamiento de Podman ($podman_storage)."
        fi

        # 3. Comprobar timer de fstrim para SSD NVMe
        if systemctl is-enabled fstrim.timer &>/dev/null; then
            echo "✅ fstrim.timer está activo para mantenimiento periódico del SSD NVMe."
        else
            $SUDO systemctl enable --now fstrim.timer 2>/dev/null || true
            echo "✅ fstrim.timer habilitado e iniciado."
        fi
    else
        echo "ℹ️ El sistema de archivos raíz no es Btrfs ($root_fstype). Omitiendo NoCoW."
    fi
}

# 3. Configuración de Sysctl para Kernel de Desarrollo y Alto Rendimiento
apply_sysctl_tuning() {
    echo "⚙️ [Sysctl] Aplicando parámetros de Kernel Sysctl para desarrollo, KDE Plasma y gaming..."
    
    # Habilitar módulo BBR si está disponible
    $SUDO modprobe tcp_bbr 2>/dev/null || true
    
    $SUDO tee /etc/sysctl.d/99-fedora-dev.conf > /dev/null << 'EOF'
# ==============================================================================
# Optimizaciones de Kernel Sysctl - Fedora 44 (KDE Plasma 6 / Btrfs / ZRAM / AMD)
# ==============================================================================

# 1. Monitoreo de archivos en tiempo real para IDEs (VSCode, JetBrains, Rust-Analyzer) y Baloo/Dolphin
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
fs.file-max = 2097152

# 2. Mapeos de memoria virtual para bases de datos en memoria, compiladores, Docker/Podman y Wine/Proton/Steam Gaming
vm.max_map_count = 16777216

# 3. Gestión de Memoria y ZRAM (valor óptimo para Fedora con ZRAM y compresión ZSTD)
# Un swappiness de 150 favorece el uso de ZRAM comprimida frente a descartar páginas de código activas
vm.swappiness = 150
# Desactivar readahead en swap cuando se usa ZRAM (elimina lecturas innecesarias en RAM)
vm.page-cluster = 0

# 4. Retención de caché de inodos y directorios para acelerar 'git status', compilaciones e indexación
vm.vfs_cache_pressure = 50

# 5. Rendimiento de red TCP y reducción de latencia (Fair Queuing + BBR)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF

    $SUDO sysctl --system > /dev/null || true
    echo "✅ Parámetros de Kernel Sysctl aplicados correctamente."
}

# 4. Configuración de Límites de Descriptores de Proceso (limits.d)
apply_limits_tuning() {
    echo "📈 [Límites] Configurando límites de descriptores de archivos y memoria bloqueada..."
    $SUDO tee /etc/security/limits.d/99-dev-limits.conf > /dev/null << 'EOF'
# Límites ampliados para desarrollo masivo, IDEs y compilaciones en paralelo
*          soft    nofile     524288
*          hard    nofile     1048576
*          soft    memlock    unlimited
*          hard    memlock    unlimited
EOF
    echo "✅ Límites de seguridad (limits.d) configurados."
}

# 5. Optimización de Timeouts de Apagado de Systemd
apply_systemd_tuning() {
    echo "⏱️ [Systemd] Ajustando timeouts de parada de servicios en Systemd (evita esperas de 90s al apagar)..."
    $SUDO mkdir -p /etc/systemd/system.conf.d
    $SUDO tee /etc/systemd/system.conf.d/99-fast-shutdown.conf > /dev/null << 'EOF'
[Manager]
DefaultTimeoutStopSec=10s
EOF
    echo "✅ Timeout de apagado en Systemd configurado a 10 segundos."
}

# 6. Optimización del Indexador de Archivos de KDE Plasma (Baloo)
apply_baloo_tuning() {
    echo "🗂️ [Baloo] Configurando exclusiones inteligentes para el indexador Baloo de KDE Plasma 6..."
    local BALOO_CONF="$USER_HOME/.config/baloofilerc"
    mkdir -p "$(dirname "$BALOO_CONF")"
    
    # Exclusiones de directorios pesados de desarrollo para no sobrecargar CPU ni disco
    local EXCLUDE_PATTERNS="*.o,*.a,*.so,*.pyc,*.class,node_modules,.git,.venv,.cargo,target,vendor,.cache,build,dist,.npm,.rustup"
    
    if [ -f "$BALOO_CONF" ]; then
        if grep -q "exclude patterns" "$BALOO_CONF"; then
            sed -i "s|^exclude patterns=.*|exclude patterns=$EXCLUDE_PATTERNS|" "$BALOO_CONF"
        else
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

# 7. Verificación de ZRAM
apply_zram_tuning() {
    echo "⚡ [ZRAM] Verificando compresión y estado de ZRAM..."
    if command -v zramctl &>/dev/null; then
        zramctl || true
    fi
    echo "✅ Parámetros vm.swappiness=150 y vm.page-cluster=0 activos para ZRAM."
}

# 8. Herramientas de Desarrollo y Contenedores (Distrobox + Podman)
install_dev_tools() {
    echo "📦 [Contenedores] Verificando e instalando Distrobox y Podman para entornos aislados..."
    $SUDO dnf5 install -y distrobox podman 2>/dev/null || true
    echo "✅ Distrobox y Podman verificados."
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
    --btrfs)
        apply_btrfs_tuning
        ;;
    --sysctl)
        apply_sysctl_tuning
        ;;
    --limits)
        apply_limits_tuning
        ;;
    --baloo)
        apply_baloo_tuning
        ;;
    --zram)
        apply_zram_tuning
        ;;
    --no-install)
        echo "================================================================="
        echo "⚡ APLICANDO OPTIMIZACIONES FEDORA 44 (KDE PLASMA 6) [SIN PAQUETES]"
        echo "================================================================="
        apply_btrfs_tuning
        apply_sysctl_tuning
        apply_limits_tuning
        apply_systemd_tuning
        apply_baloo_tuning
        apply_zram_tuning
        echo ""
        echo "✅ Optimizaciones de sistema aplicadas con éxito."
        ;;
    "")
        echo "================================================================="
        echo "⚡ INICIANDO OPTIMIZACIÓN AVANZADA - FEDORA 44 (KDE PLASMA 6)"
        echo "================================================================="
        apply_btrfs_tuning
        apply_sysctl_tuning
        apply_limits_tuning
        apply_systemd_tuning
        apply_baloo_tuning
        apply_zram_tuning
        install_dev_tools
        echo ""
        echo "================================================================="
        echo "✅ Optimización completa de Fedora 44 (KDE Plasma 6 / Btrfs) finalizada."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
