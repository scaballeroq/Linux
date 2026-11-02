#!/usr/bin/env bash
# ==============================================================================
# laptop-setup.sh - Optimización de Portátil para Debian Workstation (GNOME Shell Wayland)
# Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 Barcelo-R)
# Compatible con Debian 13 Trixie (GNOME Shell 48+ Wayland), Testing y superiores
# ==============================================================================
# Características:
#   - GNOME Shell 48+ Wayland nativo con compositor Mutter
#   - power-profiles-daemon integrado con AMD P-State EPP (energy_performance_preference)
#   - switcheroo-control para gestión y conmutación dinámica de GPUs en Wayland
#   - Touchpad multitáctil Wayland (tap-to-click, natural scroll, two-finger tap, tap-and-drag)
#   - Teclado con bloque numérico integrado (remember-numlock-state activo)
#   - Gestión de tapa y multimonitor en systemd-logind (HandleLidSwitchDocked=ignore)
#   - Detección dinámica de topología de pantallas DRM (eDP-1 integrada + DP-3/DP-4 externas)
#   - Telemetría de batería y salud (Wh de diseño vs actual, ciclos de carga, modo AC)
#   - Bluetooth FastConnectable para emparejamiento inmediato sin latencia
#   - Mutter Wayland: VRR (variable-refresh-rate), escalado fraccional y XWayland native scaling
#   - Opciones CLI: --status / -s, --power / -p, --touchpad / -t, --display / -d,
#                   --logind / -l, --bluetooth / -b, --help / -h
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO, ENTORNO Y PRIVILEGIOS SUDO
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script con privilegios de superusuario."
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
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$REAL_UID}"
    local dbus_addr="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$runtime_dir/bus}"
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            PATH="/usr/local/bin:/usr/bin:/bin:$PATH" \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            "$@"
    else
        env \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            "$@"
    fi
}

get_gnome_version() {
    local ver
    ver=$(gnome-shell --version 2>/dev/null | awk '{print $3}' || true)
    if [ -z "$ver" ]; then
        ver=$(run_as_user gnome-shell --version 2>/dev/null | awk '{print $3}' || true)
    fi
    echo "${ver:-48}"
}

get_os_description() {
    if [ -f /etc/os-release ]; then
        grep "^PRETTY_NAME=" /etc/os-release | cut -d= -f2 | tr -d '"'
    else
        echo "Debian GNU/Linux 13 (trixie)"
    fi
}

# ------------------------------------------------------------------------------
# 2. AYUDA Y DIAGNÓSTICO DEL SISTEMA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
💻 Optimizador de Portátiles - Debian Workstation (GNOME Shell Wayland)
Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Aplica todas las optimizaciones (Energía, Touchpad, Mutter, Logind, Bluetooth).
  --status, -s           Muestra diagnóstico completo: Batería, salud Wh, AMD EPP, pantallas y Mutter.
  --power, -p            Instala y configura power-profiles-daemon, switcheroo y políticas de suspensión.
  --touchpad, -t         Configura gestos Wayland del touchpad (tap, scroll, arrastre) y teclado numérico.
  --display, -d          Aplica características adaptativas de Mutter (VRR, escalado fraccional y XWayland).
  --logind, -l           Configura systemd-logind para evitar suspensión en docked multimonitor al cerrar tapa.
  --bluetooth, -b        Optimiza Bluetooth FastConnectable para reconexión instantánea de periféricos.
  --help, -h             Muestra este mensaje de ayuda.

Características gestionadas en Debian 13 (Trixie):
  • CPU & Energía:       AMD P-State EPP gestionado nativamente por power-profiles-daemon en GNOME Shell.
  • Batería & Salud:     Telemetría en tiempo real (capacidad %, Wh diseño vs actual, ciclos y estado AC).
  • Topología Pantallas: Detección inteligente de eDP-1 interna y monitores externos DP-3 / DP-4.
  • Cierre de Tapa:      HandleLidSwitchDocked=ignore sin suspender si hay pantallas externas conectadas.
  • Mutter Wayland:      VRR (tasa de refresco variable), scale-monitor-framebuffer y xwayland-native-scaling.
  • Entrada & Gestos:    Tap-to-click, natural scroll, two-finger tap, tap-and-drag y numlock persistente.
EOF
}

show_status() {
    local gnome_ver os_name
    gnome_ver=$(get_gnome_version)
    os_name=$(get_os_description)

    echo "================================================================="
    echo "🔍 ESTADO DE CONFIGURACIÓN DE PORTÁTIL - DEBIAN WORKSTATION"
    echo "================================================================="
    echo "• Sistema Operativo:     $os_name (Kernel $(uname -r))"
    echo "• GNOME Shell:           $gnome_ver (${XDG_SESSION_TYPE:-wayland} / Mutter)"
    echo "• Hardware:              HP ProBook 455 G10 (AMD Ryzen 7 7730U / Vega 8)"
    echo "-----------------------------------------------------------------"

    # 1. Batería y Salud
    echo "• Batería y Alimentación:"
    if [ -d /sys/class/power_supply/BAT0 ]; then
        local bat_status bat_cap bat_cycles bat_design_uwh bat_full_uwh bat_health="n/a"
        bat_status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "n/a")
        bat_cap=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "n/a")
        bat_cycles=$(cat /sys/class/power_supply/BAT0/cycle_count 2>/dev/null || echo "n/a")
        bat_design_uwh=$(cat /sys/class/power_supply/BAT0/energy_full_design 2>/dev/null || true)
        bat_full_uwh=$(cat /sys/class/power_supply/BAT0/energy_full 2>/dev/null || true)

        if [ -n "$bat_design_uwh" ] && [ -n "$bat_full_uwh" ] && [ "$bat_design_uwh" -gt 0 ] 2>/dev/null; then
            local design_wh full_wh health_pct
            design_wh=$(awk -v v="$bat_design_uwh" 'BEGIN {printf "%.1f", v/1000000}')
            full_wh=$(awk -v v="$bat_full_uwh" 'BEGIN {printf "%.1f", v/1000000}')
            health_pct=$(( (bat_full_uwh * 100) / bat_design_uwh ))
            bat_health="${full_wh} Wh / ${design_wh} Wh (${health_pct}%)"
        fi

        echo "  - Estado Batería:      BAT0: $bat_status ($bat_cap%)"
        echo "  - Salud de Batería:    $bat_health | Ciclos: $bat_cycles"
    else
        echo "  - Batería:             No se detectó batería BAT0"
    fi

    local ac_online="desconocido"
    if [ -f /sys/class/power_supply/AC/online ]; then
        ac_online=$( [ "$(cat /sys/class/power_supply/AC/online 2>/dev/null)" = "1" ] && echo "🔌 Conectado (AC)" || echo "🔋 En batería" )
    fi
    echo "  - Adaptador de Corriente: $ac_online"

    echo "-----------------------------------------------------------------"
    # 2. CPU AMD P-State EPP & Perfiles de Energía
    echo "• Rendimiento y Perfiles de Energía (AMD P-State EPP):"
    local cpu_driver cpu_gov cpu_epp
    cpu_driver=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo "n/a")
    cpu_gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "n/a")
    cpu_epp=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo "n/a")
    echo "  - Driver CPU / Gov:    $cpu_driver / $cpu_gov"
    echo "  - EPP Hardware:        $cpu_epp"

    local ppd_profile="n/a"
    if command -v powerprofilesctl &>/dev/null; then
        ppd_profile=$(powerprofilesctl get 2>/dev/null || echo "n/a")
    fi
    echo "  - Perfil GNOME Shell:  $ppd_profile (power-profiles-daemon)"

    if run_as_user gsettings list-keys org.gnome.settings-daemon.plugins.power 2>/dev/null | grep -q "^power-saver-profile-on-low-battery$"; then
        local ps_low
        ps_low=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.power power-saver-profile-on-low-battery 2>/dev/null || echo 'n/a')
        echo "  - Ahorro en Baja Bat.: $ps_low"
    fi

    echo "-----------------------------------------------------------------"
    # 3. Topología de Pantallas DRM
    echo "• Topología de Pantallas (DRM Wayland):"
    local drm_connected=()
    for conn in /sys/class/drm/card*-*/status; do
        [ -f "$conn" ] || continue
        if [ "$(cat "$conn" 2>/dev/null)" = "connected" ]; then
            local cname
            cname=$(basename "$(dirname "$conn")" | sed 's/^card[0-9]*-//')
            drm_connected+=("$cname")
        fi
    done
    if [ ${#drm_connected[@]} -gt 0 ]; then
        echo "  - Pantallas Activas:   ${drm_connected[*]}"
        if echo "${drm_connected[*]}" | grep -qE "DP-[34]"; then
            echo "  - Modo Estación:       ✅ Multimonitor Externo detectado (Topología Triple Pantalla)"
        fi
    else
        echo "  - Pantallas Activas:   No se detectaron conectores DRM activos"
    fi

    echo "-----------------------------------------------------------------"
    # 4. Gestión de Tapa y Multimonitor
    echo "• Gestión de Tapa y Multimonitor (systemd-logind):"
    if [ -f /etc/systemd/logind.conf.d/lid-docked.conf ]; then
        local docked_policy
        docked_policy=$(grep "^HandleLidSwitchDocked=" /etc/systemd/logind.conf.d/lid-docked.conf 2>/dev/null | cut -d= -f2 || echo "ignore")
        echo "  - Logind Lid Docked:   ✅ Configurado ($docked_policy - no suspende con pantallas externas)"
    else
        echo "  - Logind Lid Docked:   ❌ Predeterminado (no configurado en logind.conf.d)"
    fi

    echo "-----------------------------------------------------------------"
    # 5. Touchpad y Teclado
    echo "• Touchpad y Teclado (GNOME GSettings):"
    echo "  - Tap-to-click:        $(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad tap-to-click 2>/dev/null || echo 'n/a')"
    echo "  - Natural Scroll:      $(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad natural-scroll 2>/dev/null || echo 'n/a')"
    echo "  - Click Method:        $(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad click-method 2>/dev/null || echo 'n/a')"
    echo "  - Two-Finger Scroll:   $(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled 2>/dev/null || echo 'n/a')"
    echo "  - Tap-and-Drag:        $(run_as_user gsettings get org.gnome.desktop.peripherals.touchpad tap-and-drag 2>/dev/null || echo 'n/a')"
    echo "  - NumLock Persistente: $(run_as_user gsettings get org.gnome.desktop.peripherals.keyboard remember-numlock-state 2>/dev/null || echo 'n/a')"

    echo "-----------------------------------------------------------------"
    # 6. Mutter Wayland Features
    echo "• Mutter Wayland & Características Gráficas:"
    if run_as_user gsettings list-keys org.gnome.mutter 2>/dev/null | grep -q "^experimental-features$"; then
        local cur_feat range_feat
        cur_feat=$(run_as_user gsettings get org.gnome.mutter experimental-features 2>/dev/null || echo '[]')
        range_feat=$(run_as_user gsettings range org.gnome.mutter experimental-features 2>/dev/null | grep -v "^flags$" | tr '\n' ' ' || echo 'n/a')
        echo "  - Features Activas:    $cur_feat"
        echo "  - Features Soportadas: $range_feat"
    else
        echo "  - Features:            ✅ Integrado nativamente en Mutter Wayland"
    fi

    echo "-----------------------------------------------------------------"
    # 7. Bluetooth FastConnectable
    echo "• Bluetooth FastConnectable:"
    if [ -f /etc/bluetooth/main.conf ] && grep -qE "^FastConnectable\s*=\s*true" /etc/bluetooth/main.conf 2>/dev/null; then
        echo "  - Estado:              ✅ Activo (FastConnectable = true)"
    else
        echo "  - Estado:              ❌ Desactivado o comentado en main.conf"
    fi
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. MÓDULO DE ENERGÍA Y HARDWARE (power-profiles-daemon, switcheroo)
# ------------------------------------------------------------------------------
setup_power() {
    echo "⚡ [1/5] Configurando utilidades de energía y perfiles de hardware AMD..."
    $SUDO apt-get update -qq
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        power-profiles-daemon \
        switcheroo-control \
        bluez \
        brightnessctl

    # Si tlp estuviese instalado o activo, desactivarlo para evitar conflictos con power-profiles-daemon
    if systemctl is-active --quiet tlp 2>/dev/null || systemctl is-enabled --quiet tlp 2>/dev/null; then
        echo "⚠️ Desactivando TLP para permitir que power-profiles-daemon gestione la energía y AMD P-State..."
        $SUDO systemctl stop tlp 2>/dev/null || true
        $SUDO systemctl mask tlp 2>/dev/null || true
    fi

    # Habilitar servicios nativos de energía
    $SUDO systemctl enable --now power-profiles-daemon switcheroo-control 2>/dev/null || true

    # Políticas de inactividad y suspensión en GNOME Shell
    echo "  - Configurando temporizadores de suspensión e inactividad en GNOME..."
    # Tiempo de inactividad de pantalla: 15 min (900 seg)
    run_as_user gsettings set org.gnome.desktop.session idle-delay 900 2>/dev/null || true

    # Suspensión: 20 min en batería / nunca en corriente AC
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1200 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend' 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive' 2>/dev/null || true

    # Activar modo de bajo consumo automático cuando la batería esté baja (si soportado)
    if run_as_user gsettings list-keys org.gnome.settings-daemon.plugins.power 2>/dev/null | grep -q "^power-saver-profile-on-low-battery$"; then
        run_as_user gsettings set org.gnome.settings-daemon.plugins.power power-saver-profile-on-low-battery true 2>/dev/null || true
    fi

    echo "  ✅ Módulo de energía y perfiles configurado."
}

# ------------------------------------------------------------------------------
# 4. MÓDULO DE GESTIÓN DE TAPA Y MULTIMONITOR (systemd-logind)
# ------------------------------------------------------------------------------
setup_logind() {
    echo "🖥️ [2/5] Configurando comportamiento de cierre de tapa en estaciones multimonitor..."
    $SUDO mkdir -p /etc/systemd/logind.conf.d
    cat <<'EOF' | $SUDO tee /etc/systemd/logind.conf.d/lid-docked.conf > /dev/null
[Login]
# Comportamiento de tapa en portátil HP ProBook 455 G10
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=ignore
EOF

    # IMPORTANTE: NUNCA usar 'restart systemd-logind' en un entorno gráfico (Wayland/X11).
    # Reiniciar logind destruye las sesiones activas de usuario, revoca los descriptores DRM
    # y de dispositivos de entrada (evdev) a Mutter/GNOME Shell, provocando el cierre abrupto
    # de sesión y el bloqueo completo (deadlock) de la máquina al intentar reingresar.
    # Se utiliza 'reload' (SIGHUP) que recarga la configuración sin terminar procesos ni sesiones.
    $SUDO systemctl reload systemd-logind 2>/dev/null || true
    echo "  ✅ Configuración de tapa en multimonitor aplicada en systemd-logind (HandleLidSwitchDocked=ignore)."
}

# ------------------------------------------------------------------------------
# 5. MÓDULO DE TOUCHPAD Y TECLADO (GNOME Wayland)
# ------------------------------------------------------------------------------
setup_touchpad() {
    echo "🖱️ [3/5] Configurando gestos y comportamiento del Touchpad y Teclado en GNOME..."
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true 2>/dev/null || true

    # Teclado: recordar y mantener activo el teclado numérico del HP ProBook 455 G10
    run_as_user gsettings set org.gnome.desktop.peripherals.keyboard remember-numlock-state true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.peripherals.keyboard numlock-state true 2>/dev/null || true

    echo "  ✅ Touchpad multitáctil y teclado numérico configurados con éxito."
}

# ------------------------------------------------------------------------------
# 6. MÓDULO DE CARACTERÍSTICAS MUTTER WAYLAND (VRR, Escalado, XWayland)
# ------------------------------------------------------------------------------
setup_mutter_features() {
    echo "🖼️ [4/5] Configurando características adaptativas de Mutter Wayland..."
    if run_as_user gsettings list-keys org.gnome.mutter 2>/dev/null | grep -q "^experimental-features$"; then
        local range features=()
        range=$(run_as_user gsettings range org.gnome.mutter experimental-features 2>/dev/null || true)

        # scale-monitor-framebuffer (escalado fraccional en Wayland)
        if echo "$range" | grep -q "scale-monitor-framebuffer"; then
            features+=("'scale-monitor-framebuffer'")
        fi

        # variable-refresh-rate (VRR: Adaptive Sync / FreeSync en paneles compatibles)
        if echo "$range" | grep -q "variable-refresh-rate"; then
            features+=("'variable-refresh-rate'")
        fi

        # xwayland-native-scaling (escalado nítido para apps X11 en GNOME 48+)
        if echo "$range" | grep -q "xwayland-native-scaling"; then
            features+=("'xwayland-native-scaling'")
        fi

        if [ ${#features[@]} -gt 0 ]; then
            local features_str
            features_str="[$(printf "%s, " "${features[@]}" | sed 's/, $//')]"
            run_as_user gsettings set org.gnome.mutter experimental-features "$features_str" 2>/dev/null || true
            echo "  - Mutter experimental-features aplicadas: $features_str"
        else
            echo "  - Mutter no requiere experimental-features adicionales en esta versión."
        fi
    else
        echo "  - Esquema experimental-features no disponible en esta versión de Mutter."
    fi
    echo "  ✅ Características gráficas de Mutter verificadas."
}

# ------------------------------------------------------------------------------
# 7. MÓDULO DE BLUETOOTH FASTCONNECTABLE
# ------------------------------------------------------------------------------
setup_bluetooth() {
    echo "📶 [5/5] Optimizando Bluetooth FastConnectable..."
    if [ -f /etc/bluetooth/main.conf ]; then
        if grep -q "^FastConnectable" /etc/bluetooth/main.conf 2>/dev/null; then
            $SUDO sed -i 's/^FastConnectable.*/FastConnectable = true/' /etc/bluetooth/main.conf
        elif grep -q "^#FastConnectable" /etc/bluetooth/main.conf 2>/dev/null; then
            $SUDO sed -i 's/^#FastConnectable.*/FastConnectable = true/' /etc/bluetooth/main.conf
        else
            echo -e "\n[General]\nFastConnectable = true" | $SUDO tee -a /etc/bluetooth/main.conf > /dev/null
        fi
        $SUDO systemctl restart bluetooth 2>/dev/null || true
        echo "  ✅ Bluetooth FastConnectable activado y reiniciado con éxito."
    else
        echo "  ℹ️ /etc/bluetooth/main.conf no existe aún; asegúrate de instalar bluez."
    fi
}

# ------------------------------------------------------------------------------
# 8. ENTRADA PRINCIPAL
# ------------------------------------------------------------------------------
case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --power|-p)
        setup_power
        exit 0
        ;;
    --logind|-l)
        setup_logind
        exit 0
        ;;
    --touchpad|-t)
        setup_touchpad
        exit 0
        ;;
    --display|-d)
        setup_mutter_features
        exit 0
        ;;
    --bluetooth|-b)
        setup_bluetooth
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        GNOME_CUR_VER=$(get_gnome_version)
        OS_CUR_NAME=$(get_os_description)

        echo "================================================================="
        echo "💻 CONFIGURANDO OPTIMIZACIONES DE PORTÁTIL"
        echo "   $OS_CUR_NAME | GNOME Shell $GNOME_CUR_VER (Wayland)"
        echo "   Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Vega 8)"
        echo "================================================================="
        setup_power
        setup_logind
        setup_touchpad
        setup_mutter_features
        setup_bluetooth
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Optimización de portátil completada con éxito en $OS_CUR_NAME."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
