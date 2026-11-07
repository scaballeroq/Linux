#!/usr/bin/env bash
# ==============================================================================
# ssh-server.sh - Servidor OpenSSH Seguro (TCP Puerto 22) para Debian TV
# Sistema: Debian GNU/Linux 13 (Trixie) | Escritorio: GNOME Shell Wayland
# Hardware: HP Z230 SFF Workstation (Intel Core i7-4790) | Red: Firewalld
# ==============================================================================
# Características:
#   - Instalación y aprovisionamiento idempotente de openssh-server.
#   - Configuración segura modular en /etc/ssh/sshd_config.d/tv-sshd.conf (TCP 22).
#   - Soporte para activación bajo demanda (ssh.socket) o servicio continuo (ssh.service).
#   - Apertura estricta del puerto 22/TCP en Firewalld (prohibido UFW / iptables).
#   - Diagnóstico no privilegiado (--status) con comandos de conexión LAN listos para usar.
#   - Opciones CLI: --install, --status, --start, --stop, --restart, --disable, --help.
# ==============================================================================

set -euo pipefail

# Colores ANSI
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Detección de usuario real
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
    if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null && ! command -v pkexec &>/dev/null; then
        echo -e "${RED}❌ Error: Esta operación requiere privilegios de administrador ('sudo').${NC}"
        exit 1
    fi
}

# Determinar si el sistema usa ssh.socket o ssh.service
detect_ssh_unit() {
    if systemctl list-unit-files ssh.socket &>/dev/null && systemctl is-enabled ssh.socket &>/dev/null; then
        echo "ssh.socket"
    elif systemctl list-unit-files ssh.service &>/dev/null; then
        echo "ssh.service"
    elif systemctl list-unit-files sshd.service &>/dev/null; then
        echo "sshd.service"
    else
        echo "ssh.service"
    fi
}

show_help() {
    cat <<EOF
🔒 Gestor del Servidor OpenSSH (TCP Puerto 22) - HP Z230 SFF (Debian TV)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala openssh-server, configura el puerto 22 y abre el cortafuegos.
  --install, -i       Fuerza la instalación y configuración modular de OpenSSH.
  --status, -s        Muestra diagnóstico completo (puerto 22, systemd, Firewalld y sesiones).
  --start             Inicia el servicio/socket SSH.
  --stop              Detiene el servicio/socket SSH (cierra el acceso remoto).
  --restart           Reinicia el servicio/socket SSH aplicando nuevas configuraciones.
  --disable           Deshabilita permanentemente el inicio automático de SSH.
  --help, -h          Muestra este mensaje de ayuda.

Características de Seguridad:
  • Puerto TCP estándar: 22 (IPv4 e IPv6).
  • Autenticación por clave pública habilitada.
  • Autenticación por contraseña permitida para usuario local ($REAL_USER).
  • Acceso root directo deshabilitado (PermitRootLogin prohibit-password).
  • Integración exclusiva con Firewalld (servicio 'ssh' / 22 TCP).
EOF
}

show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}${BOLD}🔍 ESTADO DEL SERVIDOR OPENSSH (HP Z230 SFF DEBIAN TV)${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    local ssh_unit
    ssh_unit=$(detect_ssh_unit)

    local is_installed="❌ No instalado"
    if dpkg -s openssh-server &>/dev/null; then
        local version
        version=$(dpkg -s openssh-server 2>/dev/null | grep -i "^Version:" | awk '{print $2}')
        is_installed="✅ Instalado ($version)"
    fi
    echo -e "• Paquete openssh-server:    $is_installed"

    local unit_status="inactivo"
    if systemctl is-active "$ssh_unit" &>/dev/null; then
        unit_status="active"
    fi

    echo -e "• Unidad Systemd ($ssh_unit): $(if [ "$unit_status" = "active" ]; then echo -e "${GREEN}✅ Activo (en ejecución)${NC}"; else echo -e "${RED}❌ Inactivo${NC}"; fi)"

    local port_status="❌ No escuchando"
    if ss -tln 2>/dev/null | grep -qE ":22\s"; then
        port_status="✅ Escuchando en TCP/22"
    fi
    echo -e "• Puerto 22 (SSH TCP):       $port_status"

    echo -e "-----------------------------------------------------------------"
    echo -e "• Cortafuegos (Firewalld):"
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        local default_zone
        default_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        local is_ssh_allowed="❌ Bloqueado"
        if firewall-cmd --zone="$default_zone" --query-service=ssh &>/dev/null; then
            is_ssh_allowed="✅ Permitido (servicio ssh / 22 TCP)"
        elif firewall-cmd --zone="$default_zone" --query-port=22/tcp &>/dev/null; then
            is_ssh_allowed="✅ Permitido (puerto 22/tcp explícito)"
        else
            is_ssh_allowed="⚠️ No permitido en zona '$default_zone'"
        fi
        echo -e "  - Estado de Firewalld:     ${GREEN}✅ Activo (Zona: $default_zone)${NC}"
        echo -e "  - Regla para SSH (22/TCP): $is_ssh_allowed"
    else
        echo -e "  - Estado de Firewalld:     ${YELLOW}ℹ️ Inactivo o no instalado${NC}"
    fi

    echo -e "-----------------------------------------------------------------"
    echo -e "• Sesiones SSH activas actualmente:"
    local active_sessions
    active_sessions=$(who | grep -iE "\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\)" || true)
    if [ -n "$active_sessions" ]; then
        echo "$active_sessions" | while read -r line; do
            echo -e "  - ${GREEN}👤 $line${NC}"
        done
    else
        echo -e "  - ℹ️ Ninguna sesión SSH remota activa en este momento."
    fi

    echo -e "================================================================="
    local host_ip
    host_ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || echo "")
    if [ -n "$host_ip" ] && [ "$host_ip" != "127.0.0.1" ]; then
        echo -e "📡 ${BOLD}Comando para conectar desde otro equipo de tu red:${NC}"
        echo -e "   ${GREEN}ssh ${REAL_USER}@${host_ip}${NC}"
    fi
    echo -e "📡 ${BOLD}Comando para conectar localmente:${NC}"
    echo -e "   ${GREEN}ssh ${REAL_USER}@localhost${NC}"
    echo -e "${BOLD}=================================================================${NC}"
}

start_ssh() {
    require_root
    local ssh_unit
    ssh_unit=$(detect_ssh_unit)
    echo -e "${BLUE}▶️ Iniciando servidor OpenSSH ($ssh_unit)...${NC}"
    $SUDO systemctl enable --now "$ssh_unit"
    echo -e "${GREEN}✅ Servidor OpenSSH activo en puerto 22.${NC}"
}

stop_ssh() {
    require_root
    local ssh_unit
    ssh_unit=$(detect_ssh_unit)
    echo -e "${YELLOW}⏹️ Deteniendo servidor OpenSSH ($ssh_unit)...${NC}"
    $SUDO systemctl stop "$ssh_unit" 2>/dev/null || true
    echo -e "${GREEN}✅ Servidor OpenSSH detenido.${NC}"
}

restart_ssh() {
    require_root
    local ssh_unit
    ssh_unit=$(detect_ssh_unit)
    echo -e "${BLUE}🔄 Reiniciando servidor OpenSSH ($ssh_unit)...${NC}"
    $SUDO systemctl restart "$ssh_unit"
    echo -e "${GREEN}✅ Servidor OpenSSH reiniciado correctamente.${NC}"
}

disable_ssh() {
    require_root
    local ssh_unit
    ssh_unit=$(detect_ssh_unit)
    echo -e "${YELLOW}🛑 Deshabilitando servidor OpenSSH ($ssh_unit)...${NC}"
    $SUDO systemctl disable --now "$ssh_unit" 2>/dev/null || true
    echo -e "${GREEN}✅ Servidor OpenSSH deshabilitado permanentemente.${NC}"
}

install_and_configure_ssh() {
    require_root
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}${BOLD}🔒 INSTALANDO Y CONFIGURANDO SERVIDOR OPENSSH (TCP/22)${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    # 1. Instalación de paquetes
    echo -e "${BLUE}ℹ️ [1/4] Verificando e instalando openssh-server vía APT...${NC}"
    if ! dpkg -s openssh-server &>/dev/null; then
        $SUDO apt-get update -qq
        $SUDO apt-get install -y openssh-server openssh-client
        echo -e "${GREEN}✅ openssh-server instalado correctamente.${NC}"
    else
        echo -e "${GREEN}✅ openssh-server ya se encuentra instalado.${NC}"
    fi

    # 2. Configuración modular de seguridad en /etc/ssh/sshd_config.d/
    echo -e "${BLUE}ℹ️ [2/4] Configurando parámetros de seguridad (/etc/ssh/sshd_config.d/tv-sshd.conf)...${NC}"
    $SUDO mkdir -p /etc/ssh/sshd_config.d

    cat <<'EOF' | $SUDO tee /etc/ssh/sshd_config.d/tv-sshd.conf > /dev/null
# ==============================================================================
# Configuración OpenSSH Server - Debian TV (HP Z230 SFF Workstation)
# ==============================================================================
Port 22
ListenAddress 0.0.0.0
ListenAddress ::

# Autenticación y permisos
PermitRootLogin prohibit-password
PubkeyAuthentication yes
PasswordAuthentication yes
KbdInteractiveAuthentication no

# Seguridad y desconexión por inactividad (15 min = 300s x 3)
ClientAliveInterval 300
ClientAliveCountMax 3

# Optimización para entorno Wayland
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
    $SUDO chmod 644 /etc/ssh/sshd_config.d/tv-sshd.conf
    echo -e "${GREEN}✅ Configuración modular aplicada (Puerto TCP 22 activo).${NC}"

    # 3. Comprobar sintaxis de sshd
    echo -e "${BLUE}ℹ️ [3/4] Validando sintaxis de configuración de sshd...${NC}"
    if $SUDO /usr/sbin/sshd -t; then
        echo -e "${GREEN}✅ Sintaxis de configuración verificada con éxito.${NC}"
    else
        echo -e "${RED}❌ Error en la sintaxis de configuración de sshd.${NC}"
        exit 1
    fi

    # Activar y habilitar unidad de systemd
    local ssh_unit
    ssh_unit=$(detect_ssh_unit)
    echo -e "${BLUE}ℹ️ [3/4] Habilitando e iniciando unidad de systemd ($ssh_unit)...${NC}"
    $SUDO systemctl daemon-reload
    $SUDO systemctl enable --now "$ssh_unit"

    # 4. Configuración estricta en Firewalld (prohibido UFW / iptables directas)
    echo -e "${BLUE}ℹ️ [4/4] Configurando cortafuegos Firewalld (servicio ssh / 22 TCP)...${NC}"
    if command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone
        active_zone=$($SUDO firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        if ! $SUDO firewall-cmd --zone="$active_zone" --query-service=ssh &>/dev/null; then
            $SUDO firewall-cmd --permanent --zone="$active_zone" --add-service=ssh &>/dev/null || true
            $SUDO firewall-cmd --reload &>/dev/null || true
            echo -e "${GREEN}  ✅ Servicio 'ssh' (puerto 22) permitido permanentemente en Firewalld (Zona: $active_zone).${NC}"
        else
            echo -e "${GREEN}  ℹ️ El servicio 'ssh' ya está habilitado en Firewalld (Zona: $active_zone).${NC}"
        fi
    fi

    echo ""
    echo -e "${GREEN}✅ Servidor OpenSSH (TCP 22) instalado y configurado correctamente.${NC}"
    echo ""
    show_status
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --start|start)
        start_ssh
        exit 0
        ;;
    --stop|stop)
        stop_ssh
        exit 0
        ;;
    --restart|restart)
        restart_ssh
        exit 0
        ;;
    --disable|disable)
        disable_ssh
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    --install|-i|install|"")
        install_and_configure_ssh
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida: $1${NC}"
        show_help
        exit 1
        ;;
esac

