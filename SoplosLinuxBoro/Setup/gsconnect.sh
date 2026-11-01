#!/usr/bin/env bash
# ==============================================================================
# gsconnect.sh - Integración de GSConnect (KDE Connect para GNOME) y Firewalld
# Sistema: Soplos Linux Boro Workstation | Escritorio: GNOME Shell (Wayland / Mutter)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics (Vega 8))
# ==============================================================================
# Características y Optimizaciones:
# - Implementación 100% nativa de GNOME (GJS) del protocolo KDE Connect (sin dependencias KDE/Qt).
# - Configuración exhaustiva y resiliente en Firewalld (puertos 1714-1764 TCP/UDP y mDNS 5353/UDP)
#   en la zona por defecto y en todas las zonas activas.
# - Integración completa con el escritorio:
#   * Nautilus: soporte de montaje SFTP de almacenamiento remoto (sshfs) y menús contextuales (python3-nautilus).
#   * Centro de Notificaciones y Quick Settings nativos de GNOME.
#   * Integración de sonido (gir1.2-gsound) para alertas y localización del teléfono.
#   * Monitoreo de batería y estado de carga (gir1.2-upowerglib).
# - Acciones CLI completas: diagnóstico de estado, listado de dispositivos vinculados, conexión
#   directa por IP, localización sonora (--ring), apertura de preferencias y reinicio del demonio.
# - Ejecución idempotente: no solicita sudo innecesario en operaciones de consulta o modo usuario.
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO Y PRIVILEGIOS SUDO
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible en este sistema."
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
            WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}" \
            DISPLAY="${DISPLAY:-:0}" \
            "$@"
    else
        "$@"
    fi
}

GSCONNECT_UUID="gsconnect@andyholmes.github.io"
SYSTEM_EXT_DIR="/usr/share/gnome-shell/extensions/$GSCONNECT_UUID"
USER_EXT_DIR="$USER_HOME/.local/share/gnome-shell/extensions/$GSCONNECT_UUID"

# ------------------------------------------------------------------------------
# 2. AYUDA Y ESTADO DEL SISTEMA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
📱 Gestor de GSConnect (KDE Connect para GNOME) y Cortafuegos - Soplos Linux Boro

Uso:
  $0 [OPCIÓN]

Opciones principales:
  (sin argumentos)           Instala GSConnect y dependencias, activa la extensión y configura Firewalld.
  --status, -s, status       Muestra diagnóstico detallado de paquetes, extensión, puertos, IP y Firewalld.
  --devices, -d, devices     Lista los dispositivos móviles vinculados y emparejados.
  --connect, -c [IP]         Fuerza la conexión directa por IP con el móvil (evita bloqueos de router/mDNS).
  --ring [DEVICE_ID]         Hace sonar el teléfono móvil emparejado para localizarlo (Find My Phone).
  --refresh                  Emite paquetes de descubrimiento UDP en la red local.
  --open, -o, --prefs, -p    Abre el panel gráfico de preferencias de GSConnect.
  --firewall, --setup-firewall  Aplica y recarga únicamente las reglas de red en Firewalld.
  --restart, -r              Reinicia el demonio GJS y la extensión en GNOME Shell.
  --daemon                   Verifica el estado del proceso en segundo plano de GSConnect.
  --disable                  Desactiva la extensión GSConnect y retira el servicio de Firewalld.
  --install, -i              Instala únicamente los paquetes de soporte sin modificar la red.
  --help, -h, help           Muestra este mensaje de ayuda.

Servicios y puertos gestionados en Firewalld:
  • kdeconnect:              Puertos 1714-1764 (TCP y UDP) para enlace, archivos, multimedia y portapapeles.
  • mdns:                    Puerto 5353 (UDP) para detección automática de dispositivos en la LAN.
EOF
}

get_local_network_info() {
    local ip iface
    ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' || true)
    if [ -z "$ip" ]; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
    fi
    if [ -z "$ip" ]; then
        ip=$(ip -o -4 addr show up scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1 || true)
    fi
    if [ -z "$ip" ]; then
        ip=$(ip -o -4 addr show up 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1 || echo "127.0.0.1")
    fi

    iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' || true)
    if [ -z "$iface" ]; then
        iface=$(ip -o -4 route show to default 2>/dev/null | awk '{print $5}' || true)
    fi
    if [ -z "$iface" ]; then
        iface=$(ip -o -4 addr show up scope global 2>/dev/null | awk '{print $2}' | head -n1 || true)
    fi
    if [ -z "$iface" ]; then
        iface=$(ip -o -4 addr show up 2>/dev/null | awk '{print $2}' | head -n1 || echo "lo")
    fi

    echo "$ip $iface"
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE GSCONNECT Y CORTAFUEGOS - SOPLOS LINUX BORO WORKSTATION"
    echo "================================================================="

    local gnome_ver
    gnome_ver=$(run_as_user gnome-shell --version 2>/dev/null || echo "GNOME Shell (Wayland)")
    echo "• Entorno de escritorio:     $gnome_ver"
    echo "• Hardware / Gráficos:       HP ProBook 455 G10 (AMD Ryzen 7 7730U / Vega 8)"
    echo "-----------------------------------------------------------------"

    # 1. Inspección de instalación y activación
    local ext_installed="❌ No instalada (ejecuta '$0' para instalar)"
    local is_installed=false
    if [ -d "$SYSTEM_EXT_DIR" ]; then
        ext_installed="✅ Instalada en sistema (/usr/share)"
        is_installed=true
    elif [ -d "$USER_EXT_DIR" ]; then
        ext_installed="✅ Instalada en usuario (~/.local/share)"
        is_installed=true
    elif dpkg -s gnome-shell-extension-gsconnect &>/dev/null; then
        ext_installed="✅ Instalada vía paquete APT"
        is_installed=true
    fi

    local ext_enabled="⏸️ Deshabilitada"
    local user_ext_disabled
    user_ext_disabled=$(run_as_user gsettings get org.gnome.shell disable-user-extensions 2>/dev/null || echo "false")
    
    if [ "$user_ext_disabled" = "true" ]; then
        ext_enabled="⚠️ Bloqueada (disable-user-extensions = true)"
    elif [ "$is_installed" = true ]; then
        if run_as_user gnome-extensions list --enabled 2>/dev/null | grep -q "^$GSCONNECT_UUID$"; then
            ext_enabled="✅ Habilitada y activa"
        elif run_as_user gsettings get org.gnome.shell enabled-extensions 2>/dev/null | grep -q "$GSCONNECT_UUID"; then
            ext_enabled="✅ Registrada en GSettings"
        fi
    fi

    echo "• Extensión GSConnect:       $ext_installed"
    echo "• Estado en GNOME Shell:     $ext_enabled"

    # 2. Soporte y paquetes del ecosistema
    echo "-----------------------------------------------------------------"
    echo "• Integración del Ecosistema:"
    echo "  - Montaje SFTP (sshfs):    $(if command -v sshfs &>/dev/null; then echo "✅ Disponible"; else echo "❌ No instalado"; fi)"
    echo "  - Enviar desde Nautilus:   $(if dpkg -s python3-nautilus &>/dev/null; then echo "✅ Disponible (python3-nautilus)"; else echo "⚠️ No instalado"; fi)"
    echo "  - Efectos y Alarma Sonora: $(if dpkg -s gir1.2-gsound-1.0 &>/dev/null; then echo "✅ Disponible (gir1.2-gsound)"; else echo "⚠️ No instalado"; fi)"
    echo "  - Sincronización Batería:  $(if dpkg -s gir1.2-upowerglib-1.0 &>/dev/null; then echo "✅ Disponible (gir1.2-upowerglib)"; else echo "⚠️ No instalado"; fi)"

    # 3. Demonio en ejecución y sockets
    local daemon_pids
    daemon_pids=$(pgrep -u "$REAL_UID" -f "gsconnect.*daemon.js" 2>/dev/null || pgrep -f "gsconnect.*daemon.js" 2>/dev/null || true)
    if [ -n "$daemon_pids" ]; then
        echo "• Demonio GSConnect:         ✅ En ejecución (PID: $(echo "$daemon_pids" | tr '\n' ' '))"
    else
        echo "• Demonio GSConnect:         ❌ Inactivo (se inicia al activar la extensión)"
    fi

    # 4. Red Local y Cortafuegos
    read -r local_ip active_iface <<< "$(get_local_network_info)"
    echo "• Dirección IP del Equipo:   $local_ip (interfaz: $active_iface)"
    echo "-----------------------------------------------------------------"
    echo "• Cortafuegos (Firewalld):"
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        local def_zone active_zones
        def_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        active_zones=$(firewall-cmd --get-active-zones 2>/dev/null | awk '/^[a-zA-Z0-9_-]+$/ {print $1}' || echo "$def_zone")
        
        echo "  - Servicio Firewalld:      ✅ Activo y en ejecución"
        echo "  - Zona por defecto:        $def_zone"
        echo "  - Zonas de red activas:    $(echo "$active_zones" | tr '\n' ' ')"

        for z in $(echo "$def_zone $active_zones" | tr ' ' '\n' | sort -u); do
            local has_kdeconnect="❌ No" has_mdns="❌ No"
            if firewall-cmd --zone="$z" --query-service=kdeconnect &>/dev/null || firewall-cmd --zone="$z" --query-port=1714-1764/tcp &>/dev/null; then
                has_kdeconnect="✅ Sí (1714-1764 TCP/UDP)"
            fi
            if firewall-cmd --zone="$z" --query-service=mdns &>/dev/null || firewall-cmd --zone="$z" --query-port=5353/udp &>/dev/null; then
                has_mdns="✅ Sí (5353 UDP)"
            fi
            echo "  - Zona '$z':             kdeconnect: $has_kdeconnect | mdns: $has_mdns"
        done
    else
        echo "  - Servicio Firewalld:      ❌ Inactivo o no instalado"
    fi

    # 5. Resumen de Dispositivos Vinculados
    echo "-----------------------------------------------------------------"
    local devices_raw device_ids
    devices_raw=$(run_as_user gsettings get org.gnome.Shell.Extensions.GSConnect devices 2>/dev/null || echo "@as []")
    device_ids=$(python3 -c "
import sys, ast
try:
    val = sys.argv[1].replace('@as ', '')
    arr = ast.literal_eval(val)
    print('\n'.join(arr))
except Exception:
    pass
" "$devices_raw" 2>/dev/null || true)

    if [ -z "$device_ids" ]; then
        echo "• Dispositivos vinculados:   📱 Ninguno emparejado todavía"
        echo ""
        echo "💡 GUÍA DE CONEXIÓN RÁPIDA CON EL MÓVIL:"
        echo "   1. Abre la app KDE Connect en tu teléfono (Android o iOS)."
        echo "   2. Si no aparece este portátil automáticamente, toca (⋮) ➔ 'Añadir dispositivo por IP'."
        echo "   3. Introduce la IP de este equipo: $local_ip"
        echo "   4. O fuerza la solicitud hacia tu móvil con: $0 --connect <IP_DEL_MOVIL>"
    else
        local count=0
        for dev_id in $device_ids; do
            count=$((count + 1))
            local dev_name dev_type dev_paired
            dev_name=$(run_as_user gsettings get "org.gnome.Shell.Extensions.GSConnect.Device:/org/gnome/shell/extensions/gsconnect/device/$dev_id/" name 2>/dev/null | tr -d "'" || echo "$dev_id")
            dev_type=$(run_as_user gsettings get "org.gnome.Shell.Extensions.GSConnect.Device:/org/gnome/shell/extensions/gsconnect/device/$dev_id/" type 2>/dev/null | tr -d "'" || echo "phone")
            dev_paired=$(run_as_user gsettings get "org.gnome.Shell.Extensions.GSConnect.Device:/org/gnome/shell/extensions/gsconnect/device/$dev_id/" paired 2>/dev/null || echo "false")
            
            local status_icon="⚠️ No emparejado"
            [ "$dev_paired" = "true" ] && status_icon="✅ Emparejado"
            echo "• Dispositivo [$count]:        📱 $dev_name ($dev_type) - $status_icon"
        done
    fi
    echo "================================================================="
}

show_devices() {
    echo "================================================================="
    echo "📱 DISPOSITIVOS VINCULADOS EN GSCONNECT / KDE CONNECT"
    echo "================================================================="

    local devices_raw device_ids
    devices_raw=$(run_as_user gsettings get org.gnome.Shell.Extensions.GSConnect devices 2>/dev/null || echo "@as []")
    device_ids=$(python3 -c "
import sys, ast
try:
    val = sys.argv[1].replace('@as ', '')
    arr = ast.literal_eval(val)
    print('\n'.join(arr))
except Exception:
    pass
" "$devices_raw" 2>/dev/null || true)

    if [ -z "$device_ids" ]; then
        echo "📱 No hay dispositivos registrados."
        echo ""
        read -r local_ip _ <<< "$(get_local_network_info)"
        echo "💡 Para vincular un teléfono móvil:"
        echo "   1. Instala la app KDE Connect en tu móvil (F-Droid, Google Play o App Store)."
        echo "   2. Asegúrate de conectar tu teléfono a la misma red Wi-Fi."
        echo "   3. En la app del móvil toca 'Añadir dispositivo por IP' e introduce: $local_ip"
        echo "   4. O envía una solicitud directa desde aquí: $0 --connect <IP_DEL_MOVIL>"
        echo "================================================================="
        return 0
    fi

    local index=0
    for dev_id in $device_ids; do
        index=$((index + 1))
        local dev_name dev_type dev_paired
        dev_name=$(run_as_user gsettings get "org.gnome.Shell.Extensions.GSConnect.Device:/org/gnome/shell/extensions/gsconnect/device/$dev_id/" name 2>/dev/null | tr -d "'" || echo "$dev_id")
        dev_type=$(run_as_user gsettings get "org.gnome.Shell.Extensions.GSConnect.Device:/org/gnome/shell/extensions/gsconnect/device/$dev_id/" type 2>/dev/null | tr -d "'" || echo "phone")
        dev_paired=$(run_as_user gsettings get "org.gnome.Shell.Extensions.GSConnect.Device:/org/gnome/shell/extensions/gsconnect/device/$dev_id/" paired 2>/dev/null || echo "false")
        
        local icon="📱"
        [ "$dev_type" = "tablet" ] && icon="📟"

        local paired_tag="⚠️ No emparejado (solicitud pendiente o revocada)"
        [ "$dev_paired" = "true" ] && paired_tag="✅ Emparejado y autorizado"

        echo "[$index] $icon $dev_name"
        echo "    • ID del dispositivo: $dev_id"
        echo "    • Tipo:               $dev_type"
        echo "    • Estado de enlace:   $paired_tag"
        echo "    • Acción de alarma:   $0 --ring $dev_id"
    done
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. ACCIONES DE RED Y CONTROL DE GSCONNECT
# ------------------------------------------------------------------------------
connect_device() {
    local ip="${1:-}"
    if [ -z "$ip" ]; then
        read -rp "Introduce la IP de tu teléfono móvil (ej: 192.168.1.X): " ip
    fi
    if [ -z "$ip" ]; then
        echo "❌ Error: Dirección IP vacía o no válida."
        exit 1
    fi

    echo "📡 Enviando solicitud de conexión directa a $ip:1716..."
    if run_as_user gdbus call --session \
        --dest org.gnome.Shell.Extensions.GSConnect \
        --object-path /org/gnome/Shell/Extensions/GSConnect \
        --method org.gtk.Actions.Activate "connect" "[<string '$ip'>]" "{}" >/dev/null 2>&1; then
        echo "✅ Solicitud enviada a $ip. Abre la app KDE Connect en tu teléfono para confirmar la vinculación."
    else
        echo "⚠️ No se pudo comunicar con el demonio de GSConnect vía DBus."
        echo "   Comprueba que la extensión esté habilitada ejecutando: $0 --restart"
    fi
}

ring_device() {
    local target_id="${1:-}"
    local devices_raw device_ids
    devices_raw=$(run_as_user gsettings get org.gnome.Shell.Extensions.GSConnect devices 2>/dev/null || echo "@as []")
    device_ids=$(python3 -c "
import sys, ast
try:
    val = sys.argv[1].replace('@as ', '')
    arr = ast.literal_eval(val)
    print('\n'.join(arr))
except Exception:
    pass
" "$devices_raw" 2>/dev/null || true)

    if [ -z "$device_ids" ]; then
        echo "❌ No hay dispositivos vinculados para hacer sonar."
        echo "   Vincula primero tu teléfono ejecutando: $0"
        return 1
    fi

    if [ -z "$target_id" ]; then
        target_id=$(echo "$device_ids" | head -n1)
    fi

    local dev_name
    dev_name=$(run_as_user gsettings get "org.gnome.Shell.Extensions.GSConnect.Device:/org/gnome/shell/extensions/gsconnect/device/$target_id/" name 2>/dev/null | tr -d "'" || echo "$target_id")

    echo "🔔 Enviando señal de alarma sonora a '$dev_name' ($target_id)..."
    if run_as_user gdbus call --session \
        --dest org.gnome.Shell.Extensions.GSConnect \
        --object-path "/org/gnome/Shell/Extensions/GSConnect/Device/$target_id" \
        --method org.gtk.Actions.Activate "ring" "[]" "{}" >/dev/null 2>&1; then
        echo "✅ Orden emitida. El dispositivo '$dev_name' debería comenzar a sonar."
    else
        echo "⚠️ No se pudo activar la alarma. Verifica que el dispositivo esté emparejado, encendido y con la app abierta."
    fi
}

refresh_discovery() {
    echo "📡 Emitiendo paquetes de descubrimiento UDP en la red local..."
    if run_as_user gdbus call --session \
        --dest org.gnome.Shell.Extensions.GSConnect \
        --object-path /org/gnome/Shell/Extensions/GSConnect \
        --method org.gtk.Actions.Activate "refresh" "[]" "{}" >/dev/null 2>&1; then
        echo "✅ Señal de descubrimiento transmitida correctamente."
    else
        echo "⚠️ No se pudo enviar el pulso de descubrimiento vía DBus. ¿Está GSConnect activo?"
    fi
}

open_prefs() {
    echo "📱 Abriendo panel gráfico de preferencias de GSConnect..."
    
    # 1. Llamada nativa vía acción DBus de GSConnect
    if run_as_user gdbus call --session \
        --dest org.gnome.Shell.Extensions.GSConnect \
        --object-path /org/gnome/Shell/Extensions/GSConnect \
        --method org.gtk.Actions.Activate "preferences" "[]" "{}" >/dev/null 2>&1; then
        echo "✅ Preferencias abiertas vía DBus."
        return 0
    fi

    # 2. Utilidad estándar de extensiones de GNOME
    if command -v gnome-extensions &>/dev/null; then
        run_as_user gnome-extensions prefs "$GSCONNECT_UUID" 2>/dev/null &
        echo "✅ Lanzado diálogo mediante 'gnome-extensions prefs'."
        return 0
    fi

    # 3. Lanzador de escritorio gtk-launch
    if command -v gtk-launch &>/dev/null && [ -f "/usr/share/applications/org.gnome.Shell.Extensions.GSConnect.Preferences.desktop" ]; then
        run_as_user gtk-launch org.gnome.Shell.Extensions.GSConnect.Preferences 2>/dev/null &
        echo "✅ Lanzado mediante 'gtk-launch'."
        return 0
    fi

    # 4. Binario directo de la extensión
    if [ -x "/usr/share/gnome-shell/extensions/$GSCONNECT_UUID/gsconnect-preferences" ]; then
        run_as_user "/usr/share/gnome-shell/extensions/$GSCONNECT_UUID/gsconnect-preferences" 2>/dev/null &
        echo "✅ Ejecutado 'gsconnect-preferences'."
        return 0
    fi

    echo "⚠️ No se pudo abrir la ventana de preferencias. Asegúrate de tener una sesión gráfica GNOME Wayland iniciada."
}

restart_service() {
    echo "🔄 Reiniciando GSConnect (extensión de GNOME y demonio GJS)..."
    
    # Cerrar limpiamente vía DBus si está corriendo
    run_as_user gdbus call --session \
        --dest org.gnome.Shell.Extensions.GSConnect \
        --object-path /org/gnome/Shell/Extensions/GSConnect \
        --method org.gtk.Actions.Activate "quit" "[]" "{}" >/dev/null 2>&1 || true

    # Deshabilitar en GNOME Shell
    run_as_user gnome-extensions disable "$GSCONNECT_UUID" 2>/dev/null || true

    # Limpiar procesos huérfanos del demonio
    pkill -u "$REAL_UID" -f "gsconnect.*daemon.js" 2>/dev/null || true
    sleep 1

    # Habilitar nuevamente
    run_as_user gnome-extensions enable "$GSCONNECT_UUID" 2>/dev/null || true
    echo "✅ GSConnect reiniciado correctamente."
}

disable_service() {
    echo "🛑 Desactivando GSConnect..."
    run_as_user gnome-extensions disable "$GSCONNECT_UUID" 2>/dev/null || true
    pkill -u "$REAL_UID" -f "gsconnect.*daemon.js" 2>/dev/null || true

    # Retirar de enabled-extensions en GSettings de forma limpia usando Python
    local current_enabled
    current_enabled=$(run_as_user gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo "[]")
    if echo "$current_enabled" | grep -q "$GSCONNECT_UUID"; then
        local new_enabled
        new_enabled=$(python3 -c "
import sys, ast
try:
    val = sys.argv[1].replace('@as ', '')
    arr = ast.literal_eval(val)
    arr = [x for x in arr if x != sys.argv[2]]
    print(str(arr).replace('\"', '\''))
except Exception:
    print('[]')
" "$current_enabled" "$GSCONNECT_UUID" 2>/dev/null || echo "[]")
        run_as_user gsettings set org.gnome.shell enabled-extensions "$new_enabled" 2>/dev/null || true
    fi

    # Retirar reglas de Firewalld
    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        local def_zone active_zones all_zones
        def_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        active_zones=$(firewall-cmd --get-active-zones 2>/dev/null | awk '/^[a-zA-Z0-9_-]+$/ {print $1}' || echo "")
        all_zones=$(echo "$def_zone $active_zones" | tr ' ' '\n' | sort -u)

        for z in $all_zones; do
            $SUDO firewall-cmd --permanent --zone="$z" --remove-service=kdeconnect 2>/dev/null || true
            $SUDO firewall-cmd --zone="$z" --remove-service=kdeconnect 2>/dev/null || true
            $SUDO firewall-cmd --permanent --zone="$z" --remove-port=1714-1764/tcp --remove-port=1714-1764/udp 2>/dev/null || true
            $SUDO firewall-cmd --zone="$z" --remove-port=1714-1764/tcp --remove-port=1714-1764/udp 2>/dev/null || true
        done
        $SUDO firewall-cmd --reload 2>/dev/null || true
        echo "🔒 Reglas de red (kdeconnect) retiradas de Firewalld."
    fi
    echo "✅ GSConnect desactivado."
}

# ------------------------------------------------------------------------------
# 4. CONFIGURACIÓN DE FIREWALLD
# ------------------------------------------------------------------------------
configure_firewall() {
    echo "ℹ️ Configurando reglas en Firewalld (puertos 1714-1764 TCP/UDP y mDNS 5353/UDP)..."
    
    if ! command -v firewall-cmd &>/dev/null; then
        echo "  📦 Instalando paquete firewalld..."
        $SUDO apt-get update -qq
        $SUDO apt-get install -y firewalld 2>/dev/null || true
    fi

    # Iniciar y habilitar servicio Firewalld si no está activo
    if ! systemctl is-active --quiet firewalld 2>/dev/null; then
        $SUDO systemctl enable --now firewalld 2>/dev/null || true
    fi

    local def_zone active_zones all_zones changed=false
    def_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
    active_zones=$(firewall-cmd --get-active-zones 2>/dev/null | awk '/^[a-zA-Z0-9_-]+$/ {print $1}' || echo "")
    all_zones=$(echo "$def_zone $active_zones" | tr ' ' '\n' | sort -u)

    local has_kdeconnect_svc=false
    if firewall-cmd --get-services 2>/dev/null | grep -qw "kdeconnect"; then
        has_kdeconnect_svc=true
    fi

    for z in $all_zones; do
        if [ "$has_kdeconnect_svc" = true ]; then
            if ! $SUDO firewall-cmd --permanent --zone="$z" --query-service=kdeconnect &>/dev/null; then
                $SUDO firewall-cmd --permanent --zone="$z" --add-service=kdeconnect >/dev/null 2>&1 || true
                changed=true
            fi
            if ! $SUDO firewall-cmd --zone="$z" --query-service=kdeconnect &>/dev/null; then
                $SUDO firewall-cmd --zone="$z" --add-service=kdeconnect >/dev/null 2>&1 || true
                changed=true
            fi
        else
            # Fallback seguro mediante puertos numéricos si el servicio kdeconnect no estuviera predefinido
            if ! $SUDO firewall-cmd --permanent --zone="$z" --query-port=1714-1764/tcp &>/dev/null; then
                $SUDO firewall-cmd --permanent --zone="$z" --add-port=1714-1764/tcp --add-port=1714-1764/udp >/dev/null 2>&1 || true
                changed=true
            fi
            if ! $SUDO firewall-cmd --zone="$z" --query-port=1714-1764/tcp &>/dev/null; then
                $SUDO firewall-cmd --zone="$z" --add-port=1714-1764/tcp --add-port=1714-1764/udp >/dev/null 2>&1 || true
                changed=true
            fi
        fi

        # Servicio mDNS para descubrimiento automático Avahi
        if ! $SUDO firewall-cmd --permanent --zone="$z" --query-service=mdns &>/dev/null; then
            $SUDO firewall-cmd --permanent --zone="$z" --add-service=mdns >/dev/null 2>&1 || true
            changed=true
        fi
        if ! $SUDO firewall-cmd --zone="$z" --query-service=mdns &>/dev/null; then
            $SUDO firewall-cmd --zone="$z" --add-service=mdns >/dev/null 2>&1 || true
            changed=true
        fi
    done

    if [ "$changed" = true ]; then
        $SUDO firewall-cmd --reload >/dev/null 2>&1 || true
        echo "  ✅ Reglas de cortafuegos aplicadas y recargadas en zonas: $(echo "$all_zones" | tr '\n' ' ')."
    else
        echo "  ✅ Reglas de cortafuegos (kdeconnect y mdns) ya están activas en zonas: $(echo "$all_zones" | tr '\n' ' ')."
    fi
}

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN DE PAQUETES Y HABILITACIÓN DE EXTENSIÓN
# ------------------------------------------------------------------------------
install_packages() {
    local required_pkgs=(
        gnome-shell-extension-gsconnect
        sshfs
        python3-nautilus
        gir1.2-gsound-1.0
        gir1.2-upowerglib-1.0
        openssl
        ca-certificates
        firewalld
    )

    local to_install=()
    for pkg in "${required_pkgs[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        echo "ℹ️ Instalando paquetes de integración y soporte: ${to_install[*]}..."
        $SUDO apt-get update -qq
        $SUDO apt-get install -y "${to_install[@]}" 2>/dev/null || true
        echo "  ✅ Paquetes instalados satisfactoriamente."
    else
        echo "ℹ️ Paquetes de soporte ya presentes (gsconnect, sshfs, nautilus, gsound, upower, firewalld)."
    fi
}

enable_extension() {
    echo "ℹ️ Habilitando extensión GSConnect en GNOME Shell..."

    # Asegurar que las extensiones no estén deshabilitadas globalmente
    run_as_user gsettings set org.gnome.shell disable-user-extensions false 2>/dev/null || true

    # Registrar en enabled-extensions de GSettings si aún no figura
    local current_enabled
    current_enabled=$(run_as_user gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo "[]")
    if ! echo "$current_enabled" | grep -q "$GSCONNECT_UUID"; then
        local new_enabled
        new_enabled=$(python3 -c "
import sys, ast
try:
    val = sys.argv[1].replace('@as ', '')
    arr = ast.literal_eval(val)
    if sys.argv[2] not in arr:
        arr.append(sys.argv[2])
    print(str(arr).replace('\"', '\''))
except Exception:
    print(\"['\" + sys.argv[2] + \"']\")
" "$current_enabled" "$GSCONNECT_UUID" 2>/dev/null || echo "['$GSCONNECT_UUID']")
        run_as_user gsettings set org.gnome.shell enabled-extensions "$new_enabled" 2>/dev/null || true
    fi

    # Activar con gnome-extensions
    run_as_user gnome-extensions enable "$GSCONNECT_UUID" 2>/dev/null || true
    echo "  ✅ Extensión registrada y activada en GNOME Shell."
}

install_and_enable() {
    echo "================================================================="
    echo "📱 CONFIGURANDO GSCONNECT Y CORTAFUEGOS (SOPLOS LINUX BORO WORKSTATION)"
    echo "================================================================="

    echo "ℹ️ [1/3] Verificando e instalando paquetes necesarios..."
    install_packages

    echo "ℹ️ [2/3] Habilitando extensión en GNOME Shell..."
    enable_extension

    echo "ℹ️ [3/3] Asegurando reglas del cortafuegos Firewalld..."
    configure_firewall

    echo ""
    echo "================================================================="
    echo "✅ GSConnect y Cortafuegos configurados con éxito."
    echo "💡 Abre la aplicación KDE Connect en tu teléfono móvil (Android / iOS)."
    echo "   Tu portátil aparecerá automáticamente disponible para emparejamiento."
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 6. ENTRADA PRINCIPAL Y DESPACHO DE COMANDOS
# ------------------------------------------------------------------------------
case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --devices|-d|devices)
        show_devices
        exit 0
        ;;
    --connect|-c)
        shift
        connect_device "${1:-}"
        exit 0
        ;;
    --ring)
        shift
        ring_device "${1:-}"
        exit 0
        ;;
    --refresh)
        refresh_discovery
        exit 0
        ;;
    --open|-o|--prefs|-p)
        open_prefs
        exit 0
        ;;
    --firewall|--setup-firewall)
        configure_firewall
        exit 0
        ;;
    --restart|-r)
        restart_service
        exit 0
        ;;
    --daemon)
        local d_pids
        d_pids=$(pgrep -u "$REAL_UID" -f "gsconnect.*daemon.js" 2>/dev/null || pgrep -f "gsconnect.*daemon.js" 2>/dev/null || true)
        if [ -n "$d_pids" ]; then
            echo "✅ Demonio GSConnect activo (PID: $(echo "$d_pids" | tr '\n' ' '))"
        else
            echo "❌ Demonio GSConnect no está en ejecución. Reiniciando servicio..."
            restart_service
        fi
        exit 0
        ;;
    --install|-i)
        install_packages
        exit 0
        ;;
    --disable)
        disable_service
        exit 0
        ;;
    "")
        install_and_enable
        show_status
        ;;
    *)
        echo "Opción no reconocida: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
