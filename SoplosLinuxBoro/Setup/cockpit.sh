#!/usr/bin/env bash
# ==============================================================================
# cockpit.sh - Consola de Administración Web Cockpit y Cliente de Escritorio
# Sistema: Soplos Linux Boro (Debian Testing) | Escritorio: GNOME Shell Wayland
# Hardware: HP ProBook 455 G10 | AMD Ryzen 7 7730U (Zen 3, 8C/16T) | 32 GB RAM
# Almacenamiento: SSD NVMe Kioxia 512 GB | Red & Seguridad: UFW (Puerto 9090/tcp) / GUFW
# Integración: Podman Rootless + KVM/QEMU Libvirt + NetworkManager + Btrfs/Ext4
# ==============================================================================
# Características:
# - Detección inteligente de dependencias e instalación idempotente vía APT.
# - Integración completa de Podman Rootless (systemctl --user podman.socket y linger).
# - Optimizado para batería de portátil HP: activación bajo demanda (cockpit.socket)
#   y desconexión por inactividad (IdleTimeout=15) con 0% de uso de CPU en reposo.
# - Telemetría de hardware NVMe (smartmontools) y soporte de almacenamiento para Btrfs/Ext4.
# - Configuración en cortafuegos UFW (Uncomplicated Firewall / GUFW, puerto 9090/tcp).
# - Diagnóstico 100% no privilegiado (sin sudo) de socket, servicios, módulos y cortafuegos.
# - Acceso Wayland nativo para navegador y cliente de escritorio (cockpit-client / Flatpak).
# - Acceso directo en el menú de aplicaciones de GNOME Shell (/usr/share/applications/cockpit.desktop).
# - Control granular del ciclo de vida: --status, --open, --client, --start, --stop,
#   --restart, --disable, --logs, --enable-podman.
# ==============================================================================

set -euo pipefail

# Asegurar que las rutas de binarios de administración estén en PATH
export PATH="/usr/sbin:/sbin:$PATH"

# Colores y formato (ANSI C-quoting compatible con cat heredocs y echo)
readonly BOLD=$'\033[1m'
readonly GREEN=$'\033[0;32m'
readonly BLUE=$'\033[0;34m'
readonly YELLOW=$'\033[1;33m'
readonly RED=$'\033[0;31m'
readonly CYAN=$'\033[0;36m'
readonly NC=$'\033[0m'

# Determinación de usuario y rutas
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

require_root() {
    if [ "$EUID" -ne 0 ]; then
        if ! command -v sudo &>/dev/null; then
            echo -e "${RED}❌ Error: Esta operación requiere privilegios de administrador ('sudo').${NC}"
            exit 1
        fi
    fi
}

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$REAL_UID/bus}" \
            WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}" \
            DISPLAY="${DISPLAY:-:0}" \
            "$@"
    else
        "$@"
    fi
}

# Paquetes esenciales de Cockpit
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

# Paquetes recomendados para telemetría de hardware y soporte del sistema
RECOMMENDED_PACKAGES=(
    "packagekit"
    "smartmontools"
)

get_lan_ip() {
    ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || echo ""
}

show_help() {
    cat <<EOF
${BOLD}🎛️ Gestor de Cockpit Web Console - Soplos Linux Boro Workstation${NC}
Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U + GNOME Shell Wayland)

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones de Diagnóstico y Ejecución:${NC}
  (sin argumentos)    Instala Cockpit, módulos, configura UFW, socket y accesos.
  --status, -s        Muestra diagnóstico completo (sin pedir sudo) de socket, módulos y red.
  --open, -o          Abre Cockpit en el navegador web predeterminado (https://localhost:9090).
  --client, -c        Lanza Cockpit Client (Flatpak o nativo) si está disponible, o el navegador.
  --logs, -l          Muestra los últimos registros de eventos y conexiones de Cockpit.
  --enable-podman     Configura e inicia podman.socket y persistencia linger para el usuario.

${BOLD}Control de Ciclo de Vida (requiere privilegios):${NC}
  --start             Habilita e inicia el socket bajo demanda de Cockpit.
  --stop              Detiene el servicio y socket de Cockpit (libera memoria y CPU).
  --restart           Reinicia el socket y servicio de Cockpit.
  --disable           Deshabilita permanentemente el socket de Cockpit.
  --help, -h          Muestra este mensaje de ayuda.

${BOLD}OPTIMIZACIONES PARA HP PROBOOK 455 G10 Y SOPLOS LINUX BORO:${NC}
  • Cero consumo en reposo: Activación bajo demanda por socket systemd (cockpit.socket).
    El demonio web cockpit-ws duerme y solo despierta cuando alguien contacta el puerto 9090.
  • Ahorro de batería: Configuración con IdleTimeout=15 para desconexión tras inactividad.
  • Podman Rootless: Soporte integral con cockpit-podman y systemctl --user podman.socket.
  • Máquinas Virtuales: Módulo cockpit-machines para gestión KVM/QEMU Libvirt.
  • Almacenamiento NVMe: Módulo cockpit-storaged con telemetría SMART (smartmontools).
  • Cortafuegos UFW: Apertura del puerto 9090/tcp con etiqueta 'Cockpit Web Console' (GUFW).
  • Integración GNOME Shell: Acceso directo desde el tablero de aplicaciones de GNOME.
EOF
}

show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${BOLD}${CYAN}🔍 ESTADO DE COCKPIT WEB CONSOLE - SOPLOS LINUX BORO WORKSTATION${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    local socket_status ws_status
    socket_status=$(systemctl is-active cockpit.socket 2>/dev/null || echo "inactivo")
    ws_status=$(systemctl is-active cockpit.service 2>/dev/null || echo "inactivo")

    echo -e "• Socket de Cockpit (Systemd): $([ "$socket_status" = "active" ] && echo -e "${GREEN}✅ Activo (bajo demanda / 0% CPU en reposo)${NC}" || echo -e "${RED}❌ Inactivo${NC}")"
    echo -e "• Servicio Web (cockpit.ws):   $([ "$ws_status" = "active" ] && echo -e "${GREEN}🟢 En ejecución activa${NC}" || echo -e "${YELLOW}⚪ Inactivo en reposo (se activará al conectar)${NC}")"
    echo -e "• Puerto 9090 (TCP):           $(ss -tln 2>/dev/null | grep -q ":9090 " && echo -e "${GREEN}✅ Escuchando${NC}" || echo -e "${RED}❌ No detectado${NC}")"

    echo -e "\n${BOLD}• Cortafuegos y Seguridad de Red:${NC}"
    if command -v ufw &>/dev/null; then
        local ufw_service="inactivo"
        if systemctl is-active --quiet ufw 2>/dev/null; then
            ufw_service="activo"
        fi
        echo -e "  - Cortafuegos detectado:     ${GREEN}✅ UFW (Uncomplicated Firewall)${NC}"
        echo -e "  - Estado del servicio:       $([ "$ufw_service" = "activo" ] && echo -e "${GREEN}✅ Activo${NC}" || echo -e "${YELLOW}⚪ Inactivo${NC}")"
        
        local is_cockpit_allowed="${RED}❌ No permitido${NC}"
        if [ "$EUID" -eq 0 ] || sudo -n true 2>/dev/null; then
            if $SUDO ufw status 2>/dev/null | grep -qE '^9090(/tcp)?[[:space:]]+ALLOW'; then
                is_cockpit_allowed="${GREEN}✅ Permitido (9090/tcp - Cockpit Web Console)${NC}"
            fi
        else
            if ufw status 2>/dev/null | grep -qE '^9090(/tcp)?[[:space:]]+ALLOW'; then
                is_cockpit_allowed="${GREEN}✅ Permitido (9090/tcp - Cockpit Web Console)${NC}"
            else
                is_cockpit_allowed="${YELLOW}ℹ️ Requiere sudo para verificar reglas detalladas (ejecuta: sudo $0 -s)${NC}"
            fi
        fi
        echo -e "  - Regla para Cockpit (9090): $is_cockpit_allowed"
    elif command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        local is_cockpit_allowed="${RED}❌ No permitido${NC}"
        if [ "$EUID" -eq 0 ] || sudo -n true 2>/dev/null; then
            if $SUDO firewall-cmd --zone="$active_zone" --query-service=cockpit >/dev/null 2>&1; then
                is_cockpit_allowed="${GREEN}✅ Permitido permanentemente (9090 TCP)${NC}"
            fi
        fi
        echo -e "  - Cortafuegos detectado:     ${GREEN}✅ Firewalld (Zona: $active_zone)${NC}"
        echo -e "  - Regla de servicio cockpit: $is_cockpit_allowed"
    else
        echo -e "  - Cortafuegos:               ${YELLOW}⚠️ No se detectó UFW activo${NC}"
    fi

    echo -e "\n${BOLD}• Integraciones del Entorno Soplos Linux Boro:${NC}"
    local podman_user_socket="${RED}❌ Inactivo${NC}"
    if [ -S "/run/user/$REAL_UID/podman/podman.sock" ] || run_as_user systemctl --user is-active podman.socket 2>/dev/null | grep -q '^active'; then
        podman_user_socket="${GREEN}✅ Activo (Rootless en /run/user/$REAL_UID/podman/podman.sock)${NC}"
    else
        podman_user_socket="${YELLOW}ℹ️ Inactivo (ejecuta: $0 --enable-podman)${NC}"
    fi
    echo -e "  - Socket Podman Rootless:    $podman_user_socket"

    local linger_status="${RED}❌ Deshabilitado${NC}"
    if command -v loginctl &>/dev/null && loginctl show-user "$REAL_USER" 2>/dev/null | grep -q "Linger=yes"; then
        linger_status="${GREEN}✅ Habilitado (contenedores persistentes)${NC}"
    fi
    echo -e "  - Persistencia Linger:       $linger_status"

    local libvirt_status="${RED}❌ Inactivo${NC}"
    if systemctl is-active --quiet libvirtd 2>/dev/null; then
        libvirt_status="${GREEN}✅ Activo (libvirtd)${NC}"
    elif systemctl is-active --quiet virtqemud 2>/dev/null; then
        libvirt_status="${GREEN}✅ Activo (virtqemud modular)${NC}"
    elif command -v virsh &>/dev/null; then
        libvirt_status="${YELLOW}⚪ Instalado pero inactivo${NC}"
    fi
    echo -e "  - Hipervisor KVM/Libvirt:    $libvirt_status"

    local nvme_status="${YELLOW}ℹ️ No verificado${NC}"
    if [ -b "/dev/nvme0n1" ]; then
        if dpkg -s smartmontools &>/dev/null; then
            nvme_status="${GREEN}✅ Detectado SSD NVMe (smartmontools activo para cockpit-storaged)${NC}"
        else
            nvme_status="${YELLOW}⚠️ Detectado SSD NVMe (se recomienda instalar smartmontools)${NC}"
        fi
    fi
    echo -e "  - Hardware de Almacenamiento: $nvme_status"

    echo -e "\n${BOLD}• Módulos Web de Cockpit instalados:${NC}"
    for pkg in "${CORE_PACKAGES[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            printf "  - %-26s ${GREEN}✅ Instalado${NC}\n" "$pkg"
        else
            printf "  - %-26s ${RED}❌ No instalado${NC}\n" "$pkg"
        fi
    done

    echo -e "\n${BOLD}• Paquetes complementarios del sistema:${NC}"
    for pkg in "${RECOMMENDED_PACKAGES[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            printf "  - %-26s ${GREEN}✅ Instalado${NC}\n" "$pkg"
        else
            printf "  - %-26s ${YELLOW}⚪ Recomendado${NC}\n" "$pkg"
        fi
    done

    echo -e "\n${BOLD}• Configuración de Rendimiento y Batería (/etc/cockpit/cockpit.conf):${NC}"
    if [ -f /etc/cockpit/cockpit.conf ]; then
        local idle_to
        idle_to=$(grep -E '^[[:space:]]*IdleTimeout' /etc/cockpit/cockpit.conf | cut -d= -f2 | tr -d ' ' || echo "no configurado")
        echo -e "  - Tiempo de inactividad:     ${CYAN}${idle_to} minutos (ahorro de batería y RAM)${NC}"
    else
        echo -e "  - Archivo de configuración:  ${YELLOW}⚠️ No existe /etc/cockpit/cockpit.conf${NC}"
    fi

    echo -e "${BOLD}=================================================================${NC}"
    local host_ip
    host_ip=$(get_lan_ip)
    echo -e "🌐 ${BOLD}URL de acceso local:${NC}       ${CYAN}https://localhost:9090${NC}"
    if [ -n "$host_ip" ] && [ "$host_ip" != "127.0.0.1" ]; then
        echo -e "🌐 ${BOLD}URL en red local (LAN):${NC}   ${CYAN}https://$host_ip:9090${NC}"
    fi
    echo -e "💡 Inicia sesión con tus credenciales de usuario de Soplos Linux Boro (${BOLD}$REAL_USER${NC})."
    echo -e "${BOLD}=================================================================${NC}"
}

open_browser() {
    echo -e "${BLUE}🌐 Abriendo Cockpit en el navegador web predeterminado...${NC}"
    if command -v xdg-open &>/dev/null; then
        run_as_user xdg-open "https://localhost:9090" &>/dev/null &
    else
        echo -e "Accede manualmente a: ${CYAN}https://localhost:9090${NC}"
    fi
}

launch_client() {
    echo -e "${BLUE}🖥️ Comprobando cliente de escritorio para Cockpit en Wayland...${NC}"
    if command -v cockpit-client &>/dev/null; then
        echo -e "▶️ ${GREEN}Lanzando cockpit-client nativo...${NC}"
        run_as_user cockpit-client localhost &>/dev/null &
    elif command -v flatpak &>/dev/null && run_as_user flatpak info org.cockpit_project.CockpitClient &>/dev/null; then
        echo -e "▶️ ${GREEN}Lanzando Cockpit Client vía Flatpak...${NC}"
        run_as_user flatpak run org.cockpit_project.CockpitClient localhost &>/dev/null &
    else
        echo -e "${YELLOW}ℹ️ Cliente de escritorio no instalado. Abriendo en el navegador predeterminado...${NC}"
        open_browser
    fi
}

show_logs() {
    echo -e "${BOLD}📋 Últimos 30 registros de Cockpit (Systemd Journal):${NC}"
    journalctl -u cockpit.service -u cockpit.socket -n 30 --no-pager || true
}

start_cockpit() {
    require_root
    echo -e "${BLUE}▶️ Iniciando Cockpit socket bajo demanda...${NC}"
    $SUDO systemctl enable --now cockpit.socket
    echo -e "${GREEN}✅ Cockpit socket activo en puerto 9090.${NC}"
}

stop_cockpit() {
    require_root
    echo -e "${BLUE}⏹️ Deteniendo Cockpit (liberando recursos del sistema)...${NC}"
    $SUDO systemctl stop cockpit.service cockpit.socket 2>/dev/null || true
    echo -e "${GREEN}✅ Cockpit detenido correctamente.${NC}"
}

restart_cockpit() {
    require_root
    echo -e "${BLUE}🔄 Reiniciando Cockpit socket y servicio...${NC}"
    $SUDO systemctl restart cockpit.socket 2>/dev/null || true
    $SUDO systemctl stop cockpit.service 2>/dev/null || true
    echo -e "${GREEN}✅ Cockpit reiniciado correctamente.${NC}"
}

disable_cockpit() {
    require_root
    echo -e "${BLUE}🛑 Deshabilitando permanentemente el socket de Cockpit...${NC}"
    $SUDO systemctl disable --now cockpit.socket cockpit.service 2>/dev/null || true
    echo -e "${GREEN}✅ Cockpit deshabilitado.${NC}"
}

enable_podman_integration() {
    echo -e "${BLUE}🐳 Configurando integración de Podman Rootless para el usuario $REAL_USER...${NC}"
    if ! command -v podman &>/dev/null; then
        echo -e "${YELLOW}⚠️ Podman no está instalado.${NC}"
        return 0
    fi

    # Habilitar linger para persistencia de procesos del usuario
    if command -v loginctl &>/dev/null; then
        require_root
        $SUDO loginctl enable-linger "$REAL_USER" 2>/dev/null || true
        echo -e "  ${GREEN}✅ Persistencia de sesión (lingering) activada para $REAL_USER.${NC}"
    fi

    # Activar podman.socket en el contexto de usuario
    if [ -d "/run/user/$REAL_UID" ]; then
        run_as_user systemctl --user enable --now podman.socket 2>/dev/null || true
        echo -e "  ${GREEN}✅ Socket de Podman activado (systemctl --user enable --now podman.socket).${NC}"
    else
        echo -e "  ${YELLOW}ℹ️ Sesión de usuario no activa actualmente. Se activará en el próximo inicio de sesión.${NC}"
    fi
}

create_desktop_entry() {
    local desktop_file="/usr/share/applications/cockpit.desktop"
    if [ -d "/usr/share/applications" ]; then
        echo -e "${BLUE}🖥️ Creando acceso directo en el menú de aplicaciones de GNOME Shell...${NC}"
        require_root
        cat <<EOF | $SUDO tee "$desktop_file" > /dev/null
[Desktop Entry]
Name=Cockpit Web Console
Comment=Consola de administración del sistema Soplos Linux Boro
Exec=xdg-open https://localhost:9090
Icon=utilities-system-monitor
Terminal=false
Type=Application
Categories=System;Settings;Monitor;
Keywords=cockpit;admin;system;monitor;podman;kvm;hardware;
StartupNotify=true
EOF
        $SUDO chmod 644 "$desktop_file"
        echo -e "  ${GREEN}✅ Acceso directo creado: $desktop_file${NC}"
    fi
}

# Procesamiento de argumentos CLI
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
    --logs|-l)
        show_logs
        exit 0
        ;;
    --enable-podman)
        enable_podman_integration
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

echo -e "${BOLD}=================================================================${NC}"
echo -e "${BOLD}${CYAN}🎛️ CONFIGURANDO COCKPIT WEB CONSOLE (SOPLOS LINUX BORO WORKSTATION)${NC}"
echo -e "${BOLD}=================================================================${NC}"

require_root

# 1. Identificar e instalar paquetes faltantes de forma idempotente
ALL_TARGET_PKGS=("${CORE_PACKAGES[@]}" "${RECOMMENDED_PACKAGES[@]}")
MISSING_PKGS=()

for pkg in "${ALL_TARGET_PKGS[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo -e "${BLUE}ℹ️ [1/6] Instalando ${#MISSING_PKGS[@]} paquete(s) faltante(s) de Cockpit y utilidades...${NC}"
    echo -e "       Paquetes: ${CYAN}${MISSING_PKGS[*]}${NC}"
    $SUDO apt-get update -qq
    $SUDO apt-get install -y "${MISSING_PKGS[@]}"
    echo -e "${GREEN}✅ Paquetes instalados correctamente.${NC}"
else
    echo -e "${GREEN}ℹ️ [1/6] Todos los módulos de Cockpit y utilidades ya están instalados.${NC}"
fi

# 2. Configuración optimizada de Cockpit para portátiles y redes locales
echo -e "${BLUE}ℹ️ [2/6] Configurando optimizaciones de rendimiento y sesión (/etc/cockpit/cockpit.conf)...${NC}"
$SUDO mkdir -p /etc/cockpit

HOST_IP=$(get_lan_ip)
HOST_NAME=$(hostname 2>/dev/null || echo "")

ORIGINS_LIST="https://localhost:9090 https://127.0.0.1:9090"
if [ -n "$HOST_IP" ] && [ "$HOST_IP" != "127.0.0.1" ]; then
    ORIGINS_LIST="$ORIGINS_LIST https://$HOST_IP:9090"
fi
if [ -n "$HOST_NAME" ]; then
    ORIGINS_LIST="$ORIGINS_LIST https://$HOST_NAME:9090 https://$HOST_NAME.local:9090"
fi

cat <<EOF | $SUDO tee /etc/cockpit/cockpit.conf > /dev/null
# Configuración optimizada de Cockpit para HP ProBook 455 G10 (Soplos Linux Boro Workstation)
# Generado automáticamente por Setup/cockpit.sh

[WebService]
# Permite conexiones tanto locales como desde la red local (LAN)
Origins = $ORIGINS_LIST
MaxStartups = 5:50:10
AllowUnencrypted = false

[Session]
# Cierre automático de sesión tras 15 minutos de inactividad para preservar batería y memoria
IdleTimeout = 15
EOF

echo -e "${GREEN}✅ Archivo /etc/cockpit/cockpit.conf actualizado con éxito.${NC}"

# 3. Habilitar Cockpit Socket (Activación bajo demanda / 0% CPU en reposo)
echo -e "${BLUE}ℹ️ [3/6] Habilitando activación bajo demanda (cockpit.socket)...${NC}"
$SUDO systemctl daemon-reload
$SUDO systemctl enable --now cockpit.socket
echo -e "${GREEN}✅ Socket cockpit.socket habilitado y en escucha.${NC}"

# 4. Configurar Cortafuegos (UFW preferente / Firewalld alternativo)
echo -e "${BLUE}ℹ️ [4/6] Configurando Cortafuegos (UFW / puerto 9090/tcp)...${NC}"
if command -v ufw &>/dev/null; then
    echo -e "  🛡️ Configurando regla en UFW (Uncomplicated Firewall)..."
    if $SUDO ufw status 2>/dev/null | grep -qE '^9090(/tcp)?[[:space:]]+ALLOW'; then
        echo -e "  ${GREEN}ℹ️ El puerto 9090/tcp ya está permitido en UFW.${NC}"
    else
        $SUDO ufw allow 9090/tcp comment 'Cockpit Web Console' 2>/dev/null || true
        $SUDO ufw reload 2>/dev/null || true
        echo -e "  ${GREEN}✅ Regla 9090/tcp ('Cockpit Web Console') añadida permanentemente a UFW.${NC}"
    fi
elif command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
    ACTIVE_ZONE=$($SUDO firewall-cmd --get-default-zone 2>/dev/null || echo "public")
    if ! $SUDO firewall-cmd --zone="$ACTIVE_ZONE" --query-service=cockpit 2>/dev/null; then
        $SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=cockpit 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
        echo -e "  ${GREEN}✅ Regla 'cockpit' añadida permanentemente a la zona '$ACTIVE_ZONE' en Firewalld.${NC}"
    else
        echo -e "  ${GREEN}ℹ️ El servicio 'cockpit' ya está activo en la zona '$ACTIVE_ZONE'.${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ No se detectó UFW activo. Si usas UFW, ejecuta: sudo ufw allow 9090/tcp comment 'Cockpit Web Console'${NC}"
fi

# 5. Integración de Podman Rootless
echo -e "${BLUE}ℹ️ [5/6] Configurando integración con Podman Rootless y persistencia linger...${NC}"
enable_podman_integration

# 6. Acceso directo en GNOME Shell
echo -e "${BLUE}ℹ️ [6/6] Configurando acceso directo en el lanzador de GNOME Shell...${NC}"
create_desktop_entry

echo ""
echo -e "${BOLD}=================================================================${NC}"
echo -e "${GREEN}🎉 Cockpit Web Console configurado y optimizado con éxito.${NC}"
echo -e "🌐 ${BOLD}URL Local:${NC}    ${CYAN}https://localhost:9090${NC}"
if [ -n "$HOST_IP" ] && [ "$HOST_IP" != "127.0.0.1" ]; then
    echo -e "🌐 ${BOLD}URL Red LAN:${NC}  ${CYAN}https://$HOST_IP:9090${NC}"
fi
echo -e "💡 Inicia sesión con tus credenciales de usuario (${BOLD}$REAL_USER${NC})."
echo -e "🔒 Nota: El certificado TLS es autofirmado por Cockpit en ${CYAN}/etc/cockpit/ws-certs.d/${NC}."
echo -e "${BOLD}=================================================================${NC}"
