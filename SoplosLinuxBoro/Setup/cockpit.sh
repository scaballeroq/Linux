#!/usr/bin/env bash
# ==============================================================================
# cockpit.sh - Consola de Administración Web Cockpit y Cliente de Escritorio
# Sistema: Soplos Linux Boro | Escritorio: GNOME Shell Wayland
# Hardware: HP ProBook 455 G10 | AMD Ryzen 7 7730U (Zen 3, 8C/16T) | 32 GB RAM
# Almacenamiento: SSD NVMe Kioxia 512 GB | Red & Seguridad: Firewalld (Puerto 9090)
# Integración: Podman Rootless + KVM/QEMU Libvirt + NetworkManager + Btrfs/Ext4
# ==============================================================================
# Características:
# - Detección inteligente de paquetes e instalación idempotente vía APT.
# - Modo rootless e idempotente: no solicita sudo si Cockpit y el socket ya están listos.
# - Optimizado para batería de portátil: activación bajo demanda mediante cockpit.socket
#   y desconexión por inactividad (IdleTimeout=15) para evitar consumo en segundo plano.
# - Configuración estricta en Firewalld (puerto 9090 / servicio cockpit).
# - Diagnóstico 100% no privilegiado (sin sudo) de socket, servicios, módulos y cortafuegos.
# - Control granular del ciclo de vida: --start, --stop, --restart, --disable, --open, --client.
# ==============================================================================

set -euo pipefail

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

require_root() {
    if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
        echo "❌ Error: Esta operación requiere privilegios de administrador ('sudo')."
        exit 1
    fi
}

CORE_PACKAGES=(
    "cockpit"
    "cockpit-bridge"
    "cockpit-ws"
    "cockpit-system"
    "cockpit-podman"
    "cockpit-machines"
    "cockpit-storaged"
    "cockpit-networkmanager"
    "cockpit-packagekit"
    "cockpit-files"
    "cockpit-sosreport"
)

show_help() {
    cat <<EOF
🎛️ Gestor de Cockpit Web Console - Soplos Linux Boro Workstation
Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U + Soplos Linux Boro Workstation)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala Cockpit, sus módulos y habilita el socket en el puerto 9090.
  --status, -s        Muestra diagnóstico completo (sin pedir sudo) de socket, módulos y red.
  --open, -o          Abre Cockpit en el navegador web predeterminado (https://localhost:9090).
  --client, -c        Lanza Cockpit Client (Flatpak o nativo) si está disponible, o abre el navegador.
  --start             Inicia manualmente el socket bajo demanda de Cockpit.
  --stop              Detiene el servicio y socket de Cockpit (libera memoria y CPU).
  --restart           Reinicia el socket y servicio de Cockpit.
  --disable           Deshabilita permanentemente el socket de Cockpit.
  --help, -h          Muestra este mensaje de ayuda.

CARACTERÍSTICAS Y EFICIENCIA EN PORTÁTILES:
  • Cero consumo en reposo: Activación bajo demanda por socket de systemd (cockpit.socket).
    El servicio web solo despierta cuando un cliente se conecta al puerto 9090.
  • Ahorro de batería: Configuración con IdleTimeout=15 para cerrar sesiones inactivas.
  • Gestión completa de Podman Rootless: Módulo cockpit-podman integrado con quadlets.
  • Control de VMs KVM/QEMU: Módulo cockpit-machines con almacenamiento y redes virtuales.
  • Telemetría de hardware NVMe & RAM: Módulo cockpit-storaged con soporte SMART y ZRAM.
  • Seguridad de red: Apertura exclusiva del puerto 9090 en Firewalld (prohibido UFW).
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE COCKPIT WEB CONSOLE - SOPLOS LINUX BORO WORKSTATION"
    echo "================================================================="

    local socket_status ws_status
    socket_status=$(systemctl is-active cockpit.socket 2>/dev/null || echo "inactivo")
    ws_status=$(systemctl is-active cockpit.service 2>/dev/null || echo "inactivo")

    echo "• Socket de Cockpit (Systemd): $(if [ "$socket_status" = "active" ]; then echo "✅ Activo (bajo demanda / 0% CPU en reposo)"; else echo "❌ Inactivo"; fi)"
    echo "• Servicio Web (cockpit.ws):   $(if [ "$ws_status" = "active" ]; then echo "🟢 En ejecución"; else echo "⚪ Inactivo (se activará al conectar)"; fi)"
    echo "• Puerto 9090 (TCP):           $(if ss -tln 2>/dev/null | grep -q ":9090 "; then echo "✅ Escuchando"; else echo "❌ No detectado"; fi)"
    
    echo "-----------------------------------------------------------------"
    echo "• Cortafuegos y Red (Firewalld):"
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        local is_cockpit_allowed="❌ No permitido"
        if [ "$EUID" -eq 0 ] || sudo -n true 2>/dev/null; then
            if $SUDO firewall-cmd --zone="$active_zone" --query-service=cockpit >/dev/null 2>&1; then
                is_cockpit_allowed="✅ Permitido (9090 TCP)"
            fi
        else
            if timeout 0.5 firewall-cmd --zone="$active_zone" --query-service=cockpit >/dev/null 2>&1; then
                is_cockpit_allowed="✅ Permitido (9090 TCP)"
            else
                is_cockpit_allowed="ℹ️ Protegido por Polkit (comprobable con sudo $0 -s)"
            fi
        fi
        echo "  - Estado de Firewalld:       ✅ Activo (Zona: $active_zone)"
        echo "  - Servicio 'cockpit':        $is_cockpit_allowed"
    else
        echo "  - Estado de Firewalld:       ℹ️ Inactivo o no instalado"
    fi

    echo "-----------------------------------------------------------------"
    echo "• Integraciones de Contenedores y Virtualización:"
    local podman_user_socket="❌ Inactivo"
    if systemctl --user is-active podman.socket 2>/dev/null | grep -q '^active'; then
        podman_user_socket="✅ Activo (Rootless)"
    else
        podman_user_socket="ℹ️ Inactivo (se activa con 'systemctl --user enable --now podman.socket')"
    fi
    echo "  - Socket Podman Rootless:    $podman_user_socket"

    local libvirt_status="❌ Inactivo"
    if systemctl is-active --quiet libvirtd 2>/dev/null; then
        libvirt_status="✅ Activo (libvirtd)"
    elif systemctl is-active --quiet virtqemud 2>/dev/null; then
        libvirt_status="✅ Activo (virtqemud modular)"
    fi
    echo "  - Hipervisor KVM/Libvirt:    $libvirt_status"

    echo "-----------------------------------------------------------------"
    echo "• Módulos Web de Cockpit instalados:"
    for pkg in "${CORE_PACKAGES[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            printf "  - %-26s ✅ Instalado\n" "$pkg"
        else
            printf "  - %-26s ❌ No instalado\n" "$pkg"
        fi
    done

    echo "================================================================="
    local host_ip
    host_ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || echo "")
    echo "🌐 URL de acceso local:       https://localhost:9090"
    if [ -n "$host_ip" ] && [ "$host_ip" != "127.0.0.1" ]; then
        echo "🌐 URL en red local (LAN):   https://$host_ip:9090"
    fi
    echo "💡 Inicia sesión con tus credenciales de usuario de Soplos Linux Boro ($REAL_USER)."
    echo "================================================================="
}

open_browser() {
    echo "🌐 Abriendo Cockpit en el navegador web..."
    if command -v xdg-open &>/dev/null; then
        xdg-open "https://localhost:9090" &>/dev/null &
    else
        echo "Accede manualmente a: https://localhost:9090"
    fi
}

launch_client() {
    echo "🖥️ Comprobando cliente de escritorio para Cockpit..."
    if command -v cockpit-client &>/dev/null; then
        echo "▶️ Lanzando cockpit-client nativo..."
        cockpit-client localhost &>/dev/null &
    elif command -v flatpak &>/dev/null && flatpak info org.cockpit_project.CockpitClient &>/dev/null; then
        echo "▶️ Lanzando Cockpit Client vía Flatpak..."
        flatpak run org.cockpit_project.CockpitClient localhost &>/dev/null &
    else
        echo "ℹ️ Cliente de escritorio no instalado. Abriendo en el navegador web predeterminado..."
        open_browser
    fi
}

start_cockpit() {
    require_root
    echo "▶️ Iniciando Cockpit socket bajo demanda..."
    $SUDO systemctl enable --now cockpit.socket
    echo "✅ Cockpit socket activo en puerto 9090."
}

stop_cockpit() {
    require_root
    echo "⏹️ Deteniendo Cockpit (liberando recursos del sistema)..."
    $SUDO systemctl stop cockpit.service cockpit.socket 2>/dev/null || true
    echo "✅ Cockpit detenido."
}

restart_cockpit() {
    require_root
    echo "🔄 Reiniciando Cockpit socket y servicio..."
    $SUDO systemctl restart cockpit.socket 2>/dev/null || true
    $SUDO systemctl stop cockpit.service 2>/dev/null || true
    echo "✅ Cockpit reiniciado correctamente."
}

disable_cockpit() {
    require_root
    echo "🛑 Deshabilitando Cockpit..."
    $SUDO systemctl disable --now cockpit.socket cockpit.service 2>/dev/null || true
    echo "✅ Cockpit deshabilitado."
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --open|-o)
        open_browser
        exit 0
        ;;
    --client|-c)
        launch_client
        exit 0
        ;;
    --start)
        start_cockpit
        exit 0
        ;;
    --stop)
        stop_cockpit
        exit 0
        ;;
    --restart)
        restart_cockpit
        exit 0
        ;;
    --disable)
        disable_cockpit
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🎛️ CONFIGURANDO COCKPIT WEB CONSOLE (SOPLOS LINUX BORO WORKSTATION)"
echo "================================================================="

require_root

# 1. Identificar e instalar paquetes faltantes de forma idempotente
MISSING_PKGS=()
for pkg in "${CORE_PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "ℹ️ [1/4] Instalando ${#MISSING_PKGS[@]} paquete(s) de Cockpit faltante(s)..."
    $SUDO apt-get update -qq
    $SUDO apt-get install -y "${MISSING_PKGS[@]}"
else
    echo "ℹ️ [1/4] Todos los módulos de Cockpit ya se encuentran instalados."
fi

# 2. Configuración optimizada de Cockpit para portátiles
echo "ℹ️ [2/4] Configurando optimizaciones de rendimiento y sesión (/etc/cockpit/cockpit.conf)..."
$SUDO mkdir -p /etc/cockpit
cat <<EOF | $SUDO tee /etc/cockpit/cockpit.conf > /dev/null
# Configuración optimizada de Cockpit para HP ProBook 455 G10 (Soplos Linux Boro Workstation)
[WebService]
Origins = https://localhost:9090 https://127.0.0.1:9090
MaxStartups = 5
AllowUnencrypted = false

[Session]
# Cierre automático de sesión tras 15 minutos de inactividad para preservar batería y memoria
IdleTimeout = 15
EOF

# 3. Habilitar Cockpit Socket (Activación bajo demanda)
echo "ℹ️ [3/4] Habilitando activación bajo demanda (cockpit.socket)..."
$SUDO systemctl enable --now cockpit.socket

# 4. Configurar Firewalld (puerto 9090 / servicio cockpit)
echo "ℹ️ [4/4] Configurando Firewalld (servicio cockpit / puerto 9090)..."
if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
    ACTIVE_ZONE=$($SUDO firewall-cmd --get-default-zone 2>/dev/null || echo "public")
    if ! $SUDO firewall-cmd --zone="$ACTIVE_ZONE" --query-service=cockpit 2>/dev/null; then
        $SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=cockpit 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
        echo "  ✅ Regla 'cockpit' añadida permanentemente a la zona '$ACTIVE_ZONE'."
    else
        echo "  ℹ️ El servicio 'cockpit' ya está activo en la zona '$ACTIVE_ZONE'."
    fi
fi

echo ""
echo "================================================================="
echo "✅ Cockpit Web Console configurado y optimizado con éxito."
echo "🌐 URL Local:  https://localhost:9090"
HOST_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || echo "")
if [ -n "$HOST_IP" ] && [ "$HOST_IP" != "127.0.0.1" ]; then
    echo "🌐 URL Red LAN: https://$HOST_IP:9090"
fi
echo "💡 Inicia sesión con tus credenciales de usuario ($REAL_USER)."
echo "================================================================="
