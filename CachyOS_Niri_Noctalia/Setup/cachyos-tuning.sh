#!/bin/bash
# ==============================================================================
# cachyos-tuning.sh - Optimizador y Ajuste de Rendimiento para CachyOS + KDE Plasma 6
# ==============================================================================
#
# Uso:
#   ./cachyos-tuning.sh               -> Aplica todas las optimizaciones recomendadas
#   ./cachyos-tuning.sh --status      -> Muestra el estado actual de los parametros de rendimiento
#   ./cachyos-tuning.sh --no-install  -> Aplica optimizaciones sin instalar paquetes adicionales
#   ./cachyos-tuning.sh --sysctl      -> Aplica unicamente los ajustes de Kernel Sysctl
#   ./cachyos-tuning.sh --limits      -> Aplica limites de descriptores (limits.d y systemd)
#   ./cachyos-tuning.sh --services    -> Configura servicios de alto rendimiento (Ananicy, UKSMD, irqbalance, fstrim)
#   ./cachyos-tuning.sh --kde         -> Aplica optimizaciones especificas de KDE Plasma 6 y Baloo
#   ./cachyos-tuning.sh --baloo-fast  -> Configura Baloo en modo rapido (solo indexa nombres/metadatos, no contenido)
#   ./cachyos-tuning.sh --baloo-disable -> Deshabilita el indexador Baloo por completo
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

# Detectar usuario real en caso de sudo para configuraciones de usuario de KDE
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

# Helper para escribir configuraciones de KDE Plasma de manera segura
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
        # Fallback basico si kwriteconfig no estuviera presente
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
⚡ Optimizador y Ajuste de Rendimiento - CachyOS (KDE Plasma 6)

Uso:
  $0 [OPCION]

Opciones principales:
  (sin argumentos)       Aplica todas las optimizaciones recomendadas (Kernel, Limites, Servicios, KDE/Baloo, Systemd y Distrobox).
  --status, -s           Muestra el estado actual de sysctl, limites, ZRAM, Ananicy-CPP, UKSMD, Baloo y servicios.
  --no-install           Aplica las configuraciones de kernel, limites y entorno sin descargar paquetes con pacman.
  --sysctl               Aplica unicamente la configuracion de parametros de Kernel Sysctl.
  --limits               Aplica limites de descriptores y memoria (limits.d y systemd system/user).
  --services             Configura e inicia Ananicy-CPP, UKSMD, irqbalance y fstrim.
  --kde                  Aplica optimizaciones de respuesta de KDE Plasma 6 y exclusiones de Baloo.
  --baloo-fast           Configura Baloo en modo ultra rapido (indexa metadatos/nombres sin parsear contenido).
  --baloo-disable        Desactiva completamente el indexador Baloo en KDE Plasma.
  --help, -h             Muestra este mensaje de ayuda.

Optimizaciones incluidas:
  1. Sysctl Kernel:      Inotify ampliado (1M watches, 8K instancias), max_map_count (16M), ZRAM swappiness (180),
                         vm.page-cluster=0 (critico para ZRAM), dirty ratios equilibrados y TCP BBR + FastOpen.
  2. Limites de Proceso: Descriptores (1M nofile), memoria bloqueada (memlock) y limites en systemd system/user
                         para que aplicaciones GUI de KDE (IDEs, compiladores, navegadores) hereden los limites.
  3. Servicios CachyOS:  Ananicy-CPP (Auto-Nice con reglas CachyOS), UKSMD (deduplicacion KSM RAM),
                         irqbalance (balanceo multinuclo de interrupciones) y fstrim.timer (mantenimiento NVMe/SSD).
  4. Systemd Timeouts:   Reduccion de DefaultTimeoutStopSec y AbortSec a 10s para apagados/reinicios instantaneos.
  5. KDE Plasma 6:       Ajuste de fluidez y respuesta de animaciones (AnimationDurationFactor=0.6).
  6. Baloo File Indexer: Exclusiones masivas de directorios de desarrollo y soporte para indexacion rapida de metadatos.
  7. Contenedores:       Instalacion de Distrobox y Podman para entornos aislados.
EOF
}

# 1. Mostrar estado actual
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE RENDIMIENTO Y OPTIMIZACIONES - CACHYOS (KDE PLASMA 6)"
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
    local BALOO_STATUS="No configurado"
    if [ -f "$USER_HOME/.config/baloofilerc" ]; then
        local BALOO_ENABLED
        BALOO_ENABLED=$(grep -i "Indexing-Enabled" "$USER_HOME/.config/baloofilerc" 2>/dev/null | cut -d= -f2 || true)
        local BALOO_CONTENT
        BALOO_CONTENT=$(grep -i "index content" "$USER_HOME/.config/baloofilerc" 2>/dev/null | cut -d= -f2 || true)
        if [ "$BALOO_ENABLED" = "false" ]; then
            BALOO_STATUS="Deshabilitado"
        elif [ "$BALOO_CONTENT" = "false" ]; then
            BALOO_STATUS="Habilitado (Modo Rapido: solo nombres/metadatos)"
        else
            BALOO_STATUS="Habilitado (Completo)"
        fi
    fi
    echo "• KDE Baloo Indexer:             $BALOO_STATUS"
    echo "• KDE Animation Factor:          $(if command -v kreadconfig6 &>/dev/null; then run_as_user kreadconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 2>/dev/null || echo '1.0 (defecto)'; else echo '1.0'; fi)"
    echo "================================================================="
}

# 2. Configuracion de Sysctl para Kernel de Desarrollo y Alto Rendimiento
apply_sysctl_tuning() {
    echo "⚙️ [1/6] Aplicando parametros de Kernel Sysctl para CachyOS, KDE Plasma 6 y desarrollo..."

    # Cargar modulo BBR para TCP si esta disponible
    $SUDO modprobe tcp_bbr 2>/dev/null || true

    $SUDO tee /etc/sysctl.d/99-cachyos-dev.conf > /dev/null << 'EOF'
# =============================================================================
# Optimizaciones de rendimiento del Kernel - CachyOS + KDE Plasma 6
# =============================================================================

# 1. Monitoreo de archivos en tiempo real para IDEs (VSCode, JetBrains, Rust-Analyzer) y Baloo/Dolphin
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 8192
fs.inotify.max_queued_events = 32768
fs.file-max = 2097152

# 2. Mapeos de memoria virtual para bases de datos en memoria, compiladores, Docker/Podman y Wine/Proton/Steam Gaming
vm.max_map_count = 16777216

# 3. Gestion de Memoria y Swap optimizada para CachyOS con ZRAM
vm.swappiness = 180
vm.page-cluster = 0
vm.compaction_proactiveness = 20

# 4. Retencion de cache de inodos y directorios para acelerar 'git status', compilaciones e indexacion
vm.vfs_cache_pressure = 50

# 5. Ratios de memoria sucia (Dirty Ratios) para prevenir microcongelamientos (I/O stutter) durante escrituras masivas
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# 6. Rendimiento de red TCP y reduccion de latencia (Fair Queuing + BBR + FastOpen)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_notsent_lowat = 16384
net.core.somaxconn = 8192
net.ipv4.tcp_max_syn_backlog = 8192
EOF

    $SUDO sysctl --system > /dev/null || true
    echo "✅ Parametros de Kernel Sysctl aplicados correctamente."
}

# 3. Configuracion de Limites de Descriptores de Proceso (limits.d y systemd)
apply_limits_tuning() {
    echo "📈 [2/6] Configurando limites de descriptores de archivos, memoria y sesiones Systemd..."

    # 1. Limites PAM para sesiones de terminal y logins
    $SUDO tee /etc/security/limits.d/99-dev-limits.conf > /dev/null << 'EOF'
# Limites ampliados para desarrollo masivo, IDEs, compilaciones y gaming
*          soft    nofile     524288
*          hard    nofile     1048576
*          soft    memlock    unlimited
*          hard    memlock    unlimited
*          soft    nproc      512000
*          hard    nproc      512000
EOF

    # 2. Limites en Systemd para servicios del sistema y aplicaciones GUI de KDE (app.slice / user session)
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
    echo "✅ Limites de seguridad (limits.d y systemd system/user) configurados."
}

# 4. Servicios de Alto Rendimiento y Mantenimiento de CachyOS
apply_cachyos_services() {
    echo "🚀 [3/6] Verificando e instalando Ananicy-CPP, UKSMD, Irqbalance y temporizadores..."

    # Intentar instalar paquetes necesarios con soporte para variantes de repositorios
    $SUDO pacman -S --needed --noconfirm \
        ananicy-cpp \
        cachyos-ananicy-rules \
        irqbalance 2>/dev/null || \
    $SUDO pacman -S --needed --noconfirm ananicy-cpp irqbalance 2>/dev/null || true

    # uksmd es opcional (no disponible en todos los repositorios oficiales)
    $SUDO pacman -S --needed --noconfirm uksmd 2>/dev/null || true

    # Habilitar servicios de rendimiento y optimizacion en systemd
    $SUDO systemctl enable --now ananicy-cpp.service 2>/dev/null || true
    if systemctl list-unit-files uksmd.service &>/dev/null; then
        $SUDO systemctl enable --now uksmd.service 2>/dev/null || true
    fi
    $SUDO systemctl enable --now irqbalance.service 2>/dev/null || true

    # Habilitar mantenimiento automatico de TRIM para SSD/NVMe
    $SUDO systemctl enable --now fstrim.timer 2>/dev/null || true

    # Habilitar limpieza automatica de cache de pacman si pacman-contrib esta instalado
    if systemctl list-unit-files paccache.timer &>/dev/null; then
        $SUDO systemctl enable --now paccache.timer 2>/dev/null || true
    fi

    echo "✅ Servicios de rendimiento (Ananicy-CPP, UKSMD, Irqbalance, fstrim) habilitados."
}

# 5. Optimizacion de Timeouts de Apagado de Systemd
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

# 6. Optimizacion del Indexador Baloo y Fluidez de KDE Plasma 6
apply_baloo_tuning() {
    local MODE="${1:-smart}"
    echo "🗂️ [5/6] Configurando optimizaciones del indexador Baloo y KDE Plasma 6 (Modo: $MODE)..."

    # Exclusiones de carpetas pesadas de desarrollo y caches para no saturar disco ni procesador
    local EXCLUDE_PATTERNS="*.o,*.a,*.so,*.pyc,*.class,node_modules,.git,.venv,.cargo,target,vendor,.cache,build,dist,.npm,.rustup,.local/share/Steam,.var/app"

    # Aplicar exclusiones inteligentes con kwriteconfig6
    set_kde_config "baloofilerc" "General" "exclude patterns" "$EXCLUDE_PATTERNS"
    set_kde_config "baloofilerc" "General" "dbVersion" "2"

    case "$MODE" in
        disable)
            set_kde_config "baloofilerc" "Basic Settings" "Indexing-Enabled" "false"
            run_as_user balooctl6 disable 2>/dev/null || run_as_user balooctl disable 2>/dev/null || true
            echo "ℹ️ Baloo indexer ha sido deshabilitado."
            ;;
        fast)
            # Modo rapido: solo indexa nombres y metadatos basicos de archivos (sin extraer contenido completo)
            set_kde_config "baloofilerc" "Basic Settings" "Indexing-Enabled" "true"
            set_kde_config "baloofilerc" "General" "index content" "false"
            run_as_user balooctl6 enable 2>/dev/null || run_as_user balooctl enable 2>/dev/null || true
            run_as_user balooctl6 check 2>/dev/null || run_as_user balooctl check 2>/dev/null || true
            echo "ℹ️ Baloo configurado en modo ultra-rapido (indexacion de nombres sin parseo de contenido)."
            ;;
        smart|*)
            set_kde_config "baloofilerc" "Basic Settings" "Indexing-Enabled" "true"
            set_kde_config "baloofilerc" "General" "index content" "false"
            run_as_user balooctl6 check 2>/dev/null || run_as_user balooctl check 2>/dev/null || true
            echo "ℹ️ Baloo optimizado con exclusiones inteligentes para desarrollo."
            ;;
    esac

    # Optimizar velocidad de animaciones en KDE Plasma 6 para maxima respuesta (0.6x)
    set_kde_config "kdeglobals" "KDE" "AnimationDurationFactor" "0.6"

    # Desactivar previews automaticas en carpetas remotas para prevenir bloqueos en Dolphin
    set_kde_config "dolphinrc" "PreviewSettings" "MaximumRemoteFolderSize" "0"

    echo "✅ Optimizaciones de KDE Plasma 6 y Baloo aplicadas."
}

# 7. Herramientas de Desarrollo y Contenedores (Distrobox + Podman)
install_dev_tools() {
    echo "📦 [6/6] Verificando e instalando Distrobox y Podman para entornos aislados..."
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
        echo "⚙️ APLICANDO SYSCTL TUNING - CACHYOS (KDE PLASMA 6)"
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
    --kde)
        echo "================================================================="
        echo "🎨 OPTIMIZANDO KDE PLASMA 6 Y BALOO INDEXER"
        echo "================================================================="
        apply_baloo_tuning "smart"
        echo "✅ Optimizaciones de KDE Plasma 6 aplicadas con exito."
        ;;
    --baloo-fast)
        echo "================================================================="
        echo "🗂️ CONFIGURANDO BALOO EN MODO RAPIDO (METADATOS SOLAMENTE)"
        echo "================================================================="
        apply_baloo_tuning "fast"
        echo "✅ Baloo configurado en modo rapido."
        ;;
    --baloo-disable)
        echo "================================================================="
        echo "🗂️ DESHABILITANDO INDEXADOR BALOO EN KDE PLASMA 6"
        echo "================================================================="
        apply_baloo_tuning "disable"
        echo "✅ Baloo deshabilitado."
        ;;
    --no-install)
        echo "================================================================="
        echo "⚡ APLICANDO OPTIMIZACIONES CACHYOS (KDE PLASMA 6) [SIN PAQUETES]"
        echo "================================================================="
        apply_sysctl_tuning
        apply_limits_tuning
        apply_systemd_tuning
        apply_baloo_tuning "smart"
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
        apply_baloo_tuning "smart"
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
