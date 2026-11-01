#!/usr/bin/env bash
# ==============================================================================
# gsconnect.sh - Integración de GSConnect (KDE Connect para GNOME) y Firewalld
# Sistema: Soplos Linux Boro Workstation | Escritorio: GNOME Shell (Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics (Vega 8))
# ==============================================================================
# Características:
# - Implementación 100% nativa de GNOME (GJS) del protocolo KDE Connect (cero dependencias KDE/Qt).
# - Configuración del cortafuegos nativo Firewalld (puertos 1714-1764 TCP/UDP y mDNS 5353/UDP).
# - Integración nativa con Quick Settings, centro de notificaciones, portapapeles y Nautilus (SFTP).
# - Comprobaciones idempotentes: no solicita sudo innecesario en diagnósticos (--status).
# - Registro robusto en 'enabled-extensions' de GNOME Shell.
# - Opciones CLI completas: --status / -s, --devices / -d, --open / -o, --firewall,
#                          --restart / -r, --disable, --help / -h.
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO Y PRIVILEGIOS SUDO
# ------------------------------------------------------------------------------
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

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

GSCONNECT_UUID="gsconnect@andyholmes.github.io"

# ------------------------------------------------------------------------------
# 2. AYUDA Y ESTADO DEL SISTEMA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
📱 Gestor de GSConnect (KDE Connect para GNOME) y Cortafuegos - Soplos Linux Boro

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala GSConnect, sshfs, activa la extensión y configura Firewalld.
  --status, -s           Muestra diagnóstico completo de red, puertos, IP y estado de la extensión.
  --devices, -d          Lista los dispositivos móviles vinculados o emparejados.
  --connect, -c <IP>     Fuerza la conexión directa por IP con el móvil (evita bloqueos de router).
  --refresh              Emite paquetes de descubrimiento en la red local.
  --open, -o             Abre el panel gráfico de preferencias de GSConnect.
  --firewall             Aplica y recarga únicamente las reglas del cortafuegos Firewalld.
  --restart, -r          Reinicia el servicio y la extensión de GSConnect en GNOME Shell.
  --disable              Desactiva GSConnect y retira el servicio de Firewalld.
  --help, -h             Muestra este mensaje de ayuda.

Servicios de Red gestionados en Firewalld:
  • kdeconnect:          Puertos 1714-1764 (TCP y UDP) para enlace, archivos y multimedia.
  • mdns:                Puerto 5353 (UDP) para detección automática de dispositivos en LAN.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE GSCONNECT Y CORTAFUEGOS - SOPLOS LINUX BORO WORKSTATION"
    echo "================================================================="

    local ext_installed ext_enabled
    if [ -d "/usr/share/gnome-shell/extensions/$GSCONNECT_UUID" ] || [ -d "$USER_HOME/.local/share/gnome-shell/extensions/$GSCONNECT_UUID" ]; then
        ext_installed="✅ Instalada (paquete APT)"
    elif run_as_user gnome-extensions list 2>/dev/null | grep -q "^$GSCONNECT_UUID$"; then
        ext_installed="✅ Instalada (GNOME Shell)"
    else
        ext_installed="❌ No instalada"
    fi

    if run_as_user gsettings get org.gnome.shell enabled-extensions 2>/dev/null | grep -q "$GSCONNECT_UUID"; then
        ext_enabled="✅ Habilitada"
    elif run_as_user gnome-extensions list --enabled 2>/dev/null | grep -q "^$GSCONNECT_UUID$"; then
        ext_enabled="✅ Habilitada"
    else
        ext_enabled="❌ Deshabilitada"
    fi

    echo "• Extensión GSConnect:       $ext_installed ($ext_enabled)"
    echo "• Montaje SFTP (sshfs):      $(if command -v sshfs &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"

    local daemon_running="❌ Inactivo"
    if pgrep -f "gsconnect.*daemon.js" &>/dev/null; then
        daemon_running="✅ En ejecución (escuchando en TCP/UDP 1716)"
    fi
    echo "• Demonio en segundo plano:  $daemon_running"

    local active_iface local_ip
    active_iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' || echo "wlp2s0")
    local_ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' || echo "127.0.0.1")
    echo "• IP Local del Equipo:       $local_ip (interfaz: $active_iface)"
    echo "-----------------------------------------------------------------"
    echo "• Cortafuegos (Firewalld):"
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        echo "  - Estado de Firewalld:     ✅ Activo"
        echo "  - Zona activa:             $active_zone"
        echo "  - Servicio 'kdeconnect':   $(if firewall-cmd --zone="$active_zone" --query-service=kdeconnect &>/dev/null; then echo '✅ Permitido (1714-1764 TCP/UDP)'; else echo '❌ No permitido'; fi)"
        echo "  - Servicio 'mdns':         $(if firewall-cmd --zone="$active_zone" --query-service=mdns &>/dev/null; then echo '✅ Permitido (5353 UDP)'; else echo '❌ No permitido'; fi)"
    else
        echo "  - Estado de Firewalld:     ❌ Inactivo o no instalado"
    fi
    echo "-----------------------------------------------------------------"
    local devices
    devices=$(run_as_user gsettings get org.gnome.Shell.Extensions.GSConnect devices 2>/dev/null || echo "@as []")
    if [ "$devices" = "@as []" ] || [ -z "$devices" ]; then
        echo "• Dispositivos vinculados:   📱 Ninguno emparejado aún"
        echo ""
        echo "💡 SOLUCIÓN RÁPIDA SI EL MÓVIL NO DETECTA EL PC:"
        echo "   1. En KDE Connect en el móvil: toca (⋮) ➔ 'Añadir dispositivo por IP'"
        echo "   2. Escribe la IP de este portátil: $local_ip"
        echo "   3. O desde esta consola conecta al móvil: $0 --connect <IP_DEL_MOVIL>"
    else
        echo "• Dispositivos vinculados:   $devices"
    fi
    echo "================================================================="
}

connect_device() {
    local ip="${1:-}"
    if [ -z "$ip" ]; then
        read -rp "Introduce la IP de tu teléfono móvil (ej: 192.168.1.X): " ip
    fi
    if [ -z "$ip" ]; then
        echo "❌ Error: Dirección IP no válida."
        exit 1
    fi
    echo "📡 Enviando paquete de conexión directa a $ip:1716..."
    run_as_user gdbus call --session \
        --dest org.gnome.Shell.Extensions.GSConnect \
        --object-path /org/gnome/Shell/Extensions/GSConnect \
        --method org.gtk.Actions.Activate "connect" "[<string '$ip'>]" "{}" >/dev/null 2>&1 || true
    echo "✅ Paquete enviado a $ip. Abre la app KDE Connect en tu móvil para verificar la solicitud."
}

refresh_discovery() {
    echo "📡 Transmitiendo paquetes de descubrimiento en la red local..."
    run_as_user gdbus call --session \
        --dest org.gnome.Shell.Extensions.GSConnect \
        --object-path /org/gnome/Shell/Extensions/GSConnect \
        --method org.gtk.Actions.Activate "refresh" "[]" "{}" >/dev/null 2>&1 || true
    echo "✅ Señal de descubrimiento difundida."
}

open_prefs() {
    echo "📱 Abriendo preferencias de GSConnect..."
    if command -v gtk-launch &>/dev/null && [ -f "/usr/share/applications/org.gnome.Shell.Extensions.GSConnect.Preferences.desktop" ]; then
        run_as_user gtk-launch org.gnome.Shell.Extensions.GSConnect.Preferences 2>/dev/null || true
    elif [ -x "/usr/share/gnome-shell/extensions/$GSCONNECT_UUID/gsconnect-preferences" ]; then
        run_as_user "/usr/share/gnome-shell/extensions/$GSCONNECT_UUID/gsconnect-preferences" &
    else
        run_as_user gnome-extensions prefs "$GSCONNECT_UUID" 2>/dev/null || true
    fi
}

restart_service() {
    echo "🔄 Reiniciando GSConnect..."
    run_as_user gnome-extensions disable "$GSCONNECT_UUID" 2>/dev/null || true
    sleep 1
    run_as_user gnome-extensions enable "$GSCONNECT_UUID" 2>/dev/null || true
    echo "✅ GSConnect reiniciado."
}

disable_service() {
    echo "🛑 Desactivando GSConnect..."
    run_as_user gnome-extensions disable "$GSCONNECT_UUID" 2>/dev/null || true

    # Retirar de enabled-extensions en GSettings
    local current_enabled
    current_enabled=$(run_as_user gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo "[]")
    if echo "$current_enabled" | grep -q "$GSCONNECT_UUID"; then
        local new_enabled
        new_enabled=$(echo "$current_enabled" | sed "s/'$GSCONNECT_UUID', //g; s/, '$GSCONNECT_UUID'//g; s/'$GSCONNECT_UUID'//g")
        run_as_user gsettings set org.gnome.shell enabled-extensions "$new_enabled" 2>/dev/null || true
    fi

    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        $SUDO firewall-cmd --permanent --zone="$active_zone" --remove-service=kdeconnect 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
        echo "🔒 Reglas de red (kdeconnect) retiradas de Firewalld."
    fi
    echo "✅ GSConnect desactivado."
}

# ------------------------------------------------------------------------------
# 3. CONFIGURACIÓN DE FIREWALLD
# ------------------------------------------------------------------------------
configure_firewall() {
    echo "ℹ️ Configurando reglas en Firewalld (puertos 1714-1764 TCP/UDP y mDNS)..."
    if ! command -v firewall-cmd &>/dev/null; then
        $SUDO apt-get update -qq
        $SUDO apt-get install -y firewalld 2>/dev/null || true
    fi

    $SUDO systemctl enable --now firewalld 2>/dev/null || true

    local active_zone changed=false
    active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")

    if ! $SUDO firewall-cmd --permanent --zone="$active_zone" --query-service=kdeconnect 2>/dev/null; then
        $SUDO firewall-cmd --permanent --zone="$active_zone" --add-service=kdeconnect > /dev/null 2>&1 || true
        changed=true
    fi

    if ! $SUDO firewall-cmd --permanent --zone="$active_zone" --query-service=mdns 2>/dev/null; then
        $SUDO firewall-cmd --permanent --zone="$active_zone" --add-service=mdns > /dev/null 2>&1 || true
        changed=true
    fi

    if [ "$changed" = true ]; then
        $SUDO firewall-cmd --reload > /dev/null 2>&1 || true
        echo "  ✅ Reglas de cortafuegos aplicadas y recargadas en Firewalld (zona: $active_zone)."
    else
        echo "  ✅ Reglas de cortafuegos (kdeconnect y mdns) ya están activas en zona '$active_zone'."
    fi
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN DE PAQUETES Y HABILITACIÓN DE EXTENSIÓN
# ------------------------------------------------------------------------------
install_and_enable() {
    echo "================================================================="
    echo "📱 CONFIGURANDO GSCONNECT Y CORTAFUEGOS (SOPLOS LINUX BORO WORKSTATION)"
    echo "================================================================="

    # 1. Comprobar paquetes faltantes
    local to_install=()
    for pkg in gnome-shell-extension-gsconnect sshfs openssl ca-certificates firewalld; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        echo "ℹ️ [1/3] Instalando paquetes de soporte y sshfs: ${to_install[*]}..."
        $SUDO apt-get update -qq
        $SUDO apt-get install -y "${to_install[@]}" 2>/dev/null || true
    else
        echo "ℹ️ [1/3] Paquetes de soporte ya instalados (GSConnect, sshfs, firewalld)."
    fi

    # 2. Registrar en GSettings enabled-extensions y activar
    echo "ℹ️ [2/3] Habilitando extensión GSConnect en GNOME Shell..."
    local current_enabled
    current_enabled=$(run_as_user gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo "[]")
    if ! echo "$current_enabled" | grep -q "$GSCONNECT_UUID"; then
        if [[ "$current_enabled" == "@as []" || "$current_enabled" == "[]" ]]; then
            run_as_user gsettings set org.gnome.shell enabled-extensions "['$GSCONNECT_UUID']" 2>/dev/null || true
        else
            local new_enabled
            new_enabled=$(echo "$current_enabled" | sed "s/]/, '$GSCONNECT_UUID']/")
            run_as_user gsettings set org.gnome.shell enabled-extensions "$new_enabled" 2>/dev/null || true
        fi
    fi
    run_as_user gnome-extensions enable "$GSCONNECT_UUID" 2>/dev/null || true

    # 3. Configurar Firewalld
    echo "ℹ️ [3/3] Asegurando reglas de cortafuegos..."
    configure_firewall

    echo ""
    echo "================================================================="
    echo "✅ GSConnect y Cortafuegos configurados con éxito."
    echo "💡 Abre la aplicación KDE Connect en tu teléfono móvil (Android / iOS)."
    echo "   Tu portátil aparecerá automáticamente para emparejamiento."
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 5. ENTRADA PRINCIPAL
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
    --devices|-d)
        show_status
        exit 0
        ;;
    --connect|-c)
        shift
        connect_device "${1:-}"
        exit 0
        ;;
    --refresh)
        refresh_discovery
        exit 0
        ;;
    --open|-o)
        open_prefs
        exit 0
        ;;
    --firewall)
        configure_firewall
        exit 0
        ;;
    --restart|-r)
        restart_service
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
        show_help
        exit 1
        ;;
esac
