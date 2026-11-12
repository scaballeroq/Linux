#!/usr/bin/env bash
# ==============================================================================
#  seguridad.sh - Endurecimiento de Seguridad, Red y UFW por Defecto
#  Sistema: Arch Linux / Omarchy (Hyprland Wayland)
#  Entorno: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Podman Rootless / Libvirt)
# ==============================================================================
# Características:
#   - Cortafuegos nativo por defecto en Omarchy: UFW (Uncomplicated Firewall).
#   - Desactivación y enmascaramiento de Firewalld (para evitar colisiones de iptables/nftables).
#   - Políticas base: Deny incoming, Allow outgoing, Logging low.
#   - Enrutamiento y reenvío optimizado (DEFAULT_FORWARD_POLICY="ACCEPT") para Podman / Docker / KVM.
#   - Reglas esenciales de escritorio y servicios en LAN:
#     * LocalSend (53317 TCP/UDP).
#     * GSConnect / KDE Connect (1714:1764 TCP/UDP).
#     * mDNS (5353 UDP) para descubrimiento de impresoras y servicios .local.
#     * SSH (22 TCP) para acceso administrativo remoto.
#     * Reglas DNS de contenedores (Docker/Podman DNS en 172.17.0.1:53).
#   - Gestión modular de puertos:
#     * Puertos de desarrollo modular (--dev-ports): 3000, 5173, 8000, 8080 TCP.
#     * Cockpit Web Console (--cockpit): 9090 TCP.
#     * Apertura y cierre de puertos personalizados (--allow-port, --deny-port, --delete-port).
#   - Endurecimiento de red y Kernel (/etc/sysctl.d/99-omarchy-security-podman.conf):
#     * net.ipv4.ip_unprivileged_port_start = 80 (permite a Podman rootless exponer 80/443).
#     * net.ipv4.ping_group_range = 0 2147483647 (ping en contenedores rootless).
#     * net.ipv4.ip_forward = 1 y net.ipv6.conf.all.forwarding = 1 (enrutamiento de paquetes).
#     * net.ipv6.conf.all.accept_ra = 2 (preserva autoconfiguración IPv6 SLAAC con reenvío activo).
#     * Filtro anti-spoofing rp_filter = 1, SYN cookies y protección contra redirects.
#     * Restricción de memoria kernel.kptr_restrict = 2 y dmesg_restrict = 1.
#   - DNS-over-TLS oportunista y DNSSEC en systemd-resolved (/etc/systemd/resolved.conf.d/).
#   - Diagnóstico O(1) de solo lectura (--status).
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN ESTÉTICA
# ------------------------------------------------------------------------------
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

# ------------------------------------------------------------------------------
# 2. PRIVILEGIOS Y RUTAS DE CONFIGURACIÓN
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo -e "${RED}❌ Error: 'sudo' no está disponible. Ejecuta este script con privilegios de superusuario.${NC}" >&2
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

SYSCTL_SEC_FILE="/etc/sysctl.d/99-omarchy-security-podman.conf"
RESOLVED_DROPIN_DIR="/etc/systemd/resolved.conf.d"
RESOLVED_DROPIN_FILE="$RESOLVED_DROPIN_DIR/99-dns-over-tls.conf"
UFW_DEFAULT_CONFIG="/etc/default/ufw"

ACTION="apply"
DEV_PORTS_ACTION="none"
COCKPIT_ACTION=false
CUSTOM_PORT_ACTION="none"
CUSTOM_PORT=""
CUSTOM_COMMENT=""

# Puertos locales de desarrollo estándar
DEV_PORTS=(
    "3000/tcp"   # Next.js / React / Node.js
    "5173/tcp"   # Vite / Vue / Svelte
    "8000/tcp"   # FastAPI / Django / Python dev
    "8080/tcp"   # Web proxy / Spring Boot / Contenedores
)

# ------------------------------------------------------------------------------
# 3. AYUDA Y DIAGNÓSTICO DEL SISTEMA (--status / --help)
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}🛡️  Gestor de Seguridad, Red y UFW - Omarchy Workstation (Hyprland Wayland)${NC}

Configura ${BOLD}UFW${NC} como cortafuegos nativo por defecto en Omarchy (desactivando Firewalld),
habilita servicios de escritorio (LocalSend, GSConnect / KDE Connect, mDNS, SSH, Docker DNS),
optimiza el reenvío de paquetes para ${BOLD}Podman Rootless${NC} y ${BOLD}KVM/Libvirt${NC},
activa DNS-over-TLS oportunista y endurece el Kernel vía ${BOLD}sysctl${NC}.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones Principales:${NC}
  (sin argumentos)           Aplica la configuración completa de UFW, sysctl y DNS-over-TLS.
  -s, --status               Muestra el estado detallado de UFW, reglas, puertos y sysctl.
  -d, --dev-ports            Abre los puertos locales de desarrollo (3000, 5173, 8000, 8080 TCP).
  --close-dev                Cierra y elimina los puertos locales de desarrollo en UFW.
  --cockpit                  Habilita el puerto 9090/tcp para la consola web Cockpit.
  --allow-port PUERTO [TXT]  Abre un puerto específico con comentario opcional (ej: --allow-port 8081/tcp "Web Test").
  --deny-port PUERTO         Deniega tráfico entrante en un puerto específico (ej: --deny-port 8081/tcp).
  --delete-port PUERTO       Elimina la regla asociada a un puerto específico (ej: --delete-port 8081/tcp).
  -r, --reload               Recarga la configuración y reglas de UFW.
  -h, --help                 Muestra esta ayuda.

${BOLD}Servicios y Puertos Gestionados en UFW:${NC}
  • Cortafuegos base:  UFW activo (política: deny incoming, allow outgoing).
  • localsend:         53317 TCP/UDP (transferencia rápida de archivos LAN).
  • kdeconnect:        1714-1764 TCP/UDP (GSConnect / KDE Connect).
  • mdns:              5353/UDP (descubrimiento de impresoras HP y dispositivos .local).
  • ssh:               22/TCP (acceso seguro remoto).
  • docker-dns:        53/UDP hacia 172.17.0.1 (desde redes 172.16.0.0/12 y 192.168.0.0/16).
  • dev-ports:         3000 (React/Next), 5173 (Vite), 8000 (FastAPI), 8080 (Web proxy).
  • cockpit:           9090/tcp (consola web de administración del sistema).
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🛡️  ${BOLD}ESTADO DE SEGURIDAD Y CORTAFUEGOS UFW - OMARCHY WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    # 1. Estado de UFW
    local ufw_srv="inactivo"
    if systemctl is-active --quiet ufw 2>/dev/null; then
        ufw_srv="activo"
        echo -e "  • Servicio systemd UFW:      ${GREEN}✅ Activo (ufw.service)${NC}"
    else
        echo -e "  • Servicio systemd UFW:      ${RED}❌ Inactivo${NC}"
    fi

    # 2. Firewalld (debe estar inactivo en Omarchy para que UFW gestione todo)
    local fw_state fw_masked="no"
    fw_state=$(systemctl is-active firewalld 2>/dev/null || echo "inactivo")
    if [[ "$(systemctl is-enabled firewalld 2>/dev/null || true)" == "masked" ]]; then
        fw_masked="sí"
    fi
    if [[ "$fw_state" == "active" ]]; then
        echo -e "  • Estado de Firewalld:       ${YELLOW}⚠️  Activo (Precaución: colisiona con UFW)${NC}"
    else
        echo -e "  • Estado de Firewalld:       ${GREEN}✅ Inactivo / Detenido${NC} $([[ "$fw_masked" == "sí" ]] && echo -e "${GREEN}[Enmascarado/Masked]${NC}" || echo -e "${CYAN}[Deshabilitado]${NC}")"
    fi

    # 3. Reglas activas en UFW
    echo ""
    echo -e "${BOLD}🔥 Reglas Activas y Puertos en UFW:${NC}"
    if command -v ufw &>/dev/null; then
        if [ "$EUID" -eq 0 ] || sudo -n true 2>/dev/null; then
            $SUDO ufw status verbose
        else
            echo -e "${YELLOW}  (Ejecuta con 'sudo $0 --status' para listar las reglas detalladas de UFW del kernel)${NC}"
            if [[ -f "/etc/ufw/user.rules" ]]; then
                echo -e "  • Reglas configuradas en /etc/ufw/user.rules:"
                grep -E "^\-A ufw-user-input" /etc/ufw/user.rules 2>/dev/null | sed 's/-A ufw-user-input /    /g' || true
            fi
        fi
    else
        echo -e "  ${RED}❌ El paquete ufw no está instalado en el sistema.${NC}"
    fi

    # 4. Parámetros Sysctl de Red y Contenedores (Lectura directa desde /proc/sys)
    echo ""
    echo -e "${BOLD}⚙️  Parámetros de Kernel Sysctl (Podman Rootless & Red):${NC}"
    local ip4_fwd ip6_fwd ip6_ra port_start ping_range kptr dmesg
    ip4_fwd=$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo "N/A")
    ip6_fwd=$(cat /proc/sys/net/ipv6/conf/all/forwarding 2>/dev/null || echo "N/A")
    ip6_ra=$(cat /proc/sys/net/ipv6/conf/all/accept_ra 2>/dev/null || echo "N/A")
    port_start=$(cat /proc/sys/net/ipv4/ip_unprivileged_port_start 2>/dev/null || echo "N/A")
    ping_range=$(cat /proc/sys/net/ipv4/ping_group_range 2>/dev/null || echo "N/A")
    kptr=$(cat /proc/sys/kernel/kptr_restrict 2>/dev/null || echo "N/A")
    dmesg=$(cat /proc/sys/kernel/dmesg_restrict 2>/dev/null || echo "N/A")

    echo -e "  • Reenvío IPv4 (ip_forward):                ${CYAN}${ip4_fwd}${NC} $([[ "$ip4_fwd" == "1" ]] && echo -e "${GREEN}(Requerido para Podman/Docker/KVM)${NC}" || echo -e "${YELLOW}(Inactivo)${NC}")"
    echo -e "  • Reenvío IPv6 (forwarding):                ${CYAN}${ip6_fwd}${NC} $([[ "$ip6_fwd" == "1" ]] && echo -e "${GREEN}(Activo)${NC}" || echo -e "${YELLOW}(Inactivo)${NC}")"
    echo -e "  • IPv6 Router Advertisements (accept_ra):   ${CYAN}${ip6_ra}${NC} $([[ "$ip6_ra" == "2" ]] && echo -e "${GREEN}(Óptimo: SLAAC preservado con forwarding)${NC}" || echo -e "${YELLOW}(Recomendado: 2)${NC}")"
    echo -e "  • Puerto sin privilegios (Podman rootless): ${CYAN}${port_start}${NC} $([[ "$port_start" == "80" ]] && echo -e "${GREEN}(Óptimo: permite exponer puertos 80/443)${NC}" || echo -e "${YELLOW}(Recomendado: 80)${NC}")"
    echo -e "  • Rango grupos ping (Podman rootless):      ${CYAN}${ping_range}${NC}"
    echo -e "  • Restricción punteros Kernel (kptr):       ${CYAN}${kptr}${NC}"
    echo -e "  • Restricción de buffer dmesg:              ${CYAN}${dmesg}${NC}"

    # 5. DNS y Resolución (systemd-resolved)
    echo ""
    echo -e "${BOLD}🌐 Resolución DNS y Privacidad (systemd-resolved):${NC}"
    [[ -f "$SYSCTL_SEC_FILE" ]]      && echo -e "  • Perfil sysctl de seguridad:${GREEN}✅ ${SYSCTL_SEC_FILE}${NC}" || echo -e "  • Perfil sysctl de seguridad:${YELLOW}⚠️ No aplicado${NC}"
    [[ -f "$RESOLVED_DROPIN_FILE" ]]  && echo -e "  • Configuración DNS-over-TLS:${GREEN}✅ ${RESOLVED_DROPIN_FILE}${NC}" || echo -e "  • Configuración DNS-over-TLS:${YELLOW}⚠️ Por defecto${NC}"

    if command -v resolvectl &>/dev/null; then
        local dot_state
        dot_state=$(resolvectl status 2>/dev/null | grep -o -E "[-+]?DNSOverTLS(=[a-zA-Z]+)?" | head -n1 || echo "N/A")
        echo -e "  • Estado en vivo DNSOverTLS: ${CYAN}${dot_state}${NC}"
    fi
    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 4. GESTIÓN DE PUERTOS EN UFW
# ------------------------------------------------------------------------------
manage_dev_ports() {
    local mode="$1"
    if [[ "$mode" == "open" ]]; then
        log_info "Habilitando puertos locales de desarrollo en UFW: ${DEV_PORTS[*]}..."
        $SUDO ufw allow 3000/tcp comment 'Dev Next/React' >/dev/null 2>&1 || true
        $SUDO ufw allow 5173/tcp comment 'Dev Vite' >/dev/null 2>&1 || true
        $SUDO ufw allow 8000/tcp comment 'Dev FastAPI/Django' >/dev/null 2>&1 || true
        $SUDO ufw allow 8080/tcp comment 'Dev Web Proxy' >/dev/null 2>&1 || true
        $SUDO ufw reload >/dev/null 2>&1 || true
        log_ok "Puertos de desarrollo abiertos en UFW."
    elif [[ "$mode" == "close" ]]; then
        log_info "Cerrando puertos locales de desarrollo en UFW..."
        for p in "${DEV_PORTS[@]}"; do
            $SUDO ufw delete allow "$p" >/dev/null 2>&1 || true
        done
        $SUDO ufw reload >/dev/null 2>&1 || true
        log_ok "Puertos de desarrollo cerrados en UFW."
    fi
}

manage_cockpit_port() {
    log_info "Habilitando servicio Cockpit (puerto 9090/tcp) en UFW..."
    $SUDO ufw allow 9090/tcp comment 'Cockpit Web Console' >/dev/null 2>&1 || true
    $SUDO ufw reload >/dev/null 2>&1 || true
    log_ok "Puerto 9090/tcp (Cockpit) habilitado en UFW."
}

manage_custom_port() {
    local action="$1"
    local port="$2"
    local comment="${3:-Custom Port}"

    case "$action" in
        allow)
            log_info "Permitiendo puerto '$port' en UFW (Comentario: '$comment')..."
            $SUDO ufw allow "$port" comment "$comment"
            log_ok "Puerto '$port' permitido en UFW."
            ;;
        deny)
            log_info "Denegando puerto '$port' en UFW..."
            $SUDO ufw deny "$port"
            log_ok "Puerto '$port' denegado en UFW."
            ;;
        delete)
            log_info "Eliminando regla del puerto '$port' en UFW..."
            $SUDO ufw delete allow "$port" >/dev/null 2>&1 || $SUDO ufw delete deny "$port" >/dev/null 2>&1 || true
            log_ok "Regla del puerto '$port' eliminada en UFW."
            ;;
    esac
    $SUDO ufw reload >/dev/null 2>&1 || true
}

# ------------------------------------------------------------------------------
# 5. PARSEO DE ARGUMENTOS
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)
            ACTION="status"
            shift
            ;;
        -d|--dev-ports)
            DEV_PORTS_ACTION="open"
            shift
            ;;
        --close-dev)
            DEV_PORTS_ACTION="close"
            shift
            ;;
        --cockpit)
            COCKPIT_ACTION=true
            shift
            ;;
        --allow-port)
            CUSTOM_PORT_ACTION="allow"
            CUSTOM_PORT="${2:-}"
            if [[ -z "$CUSTOM_PORT" ]]; then
                log_err "Falta especificar el puerto para --allow-port (ej: 8081/tcp)"
                exit 1
            fi
            shift 2
            if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
                CUSTOM_COMMENT="$1"
                shift
            fi
            ;;
        --deny-port)
            CUSTOM_PORT_ACTION="deny"
            CUSTOM_PORT="${2:-}"
            if [[ -z "$CUSTOM_PORT" ]]; then
                log_err "Falta especificar el puerto para --deny-port (ej: 8081/tcp)"
                exit 1
            fi
            shift 2
            ;;
        --delete-port)
            CUSTOM_PORT_ACTION="delete"
            CUSTOM_PORT="${2:-}"
            if [[ -z "$CUSTOM_PORT" ]]; then
                log_err "Falta especificar el puerto para --delete-port (ej: 8081/tcp)"
                exit 1
            fi
            shift 2
            ;;
        -r|--reload)
            ACTION="reload"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_err "Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
done

if [[ "$ACTION" == "status" ]]; then
    show_status
    exit 0
fi

if [[ "$ACTION" == "reload" ]]; then
    log_info "Recargando cortafuegos UFW..."
    $SUDO ufw reload
    log_ok "UFW recargado exitosamente."
    exit 0
fi

if [[ "$CUSTOM_PORT_ACTION" != "none" ]]; then
    manage_custom_port "$CUSTOM_PORT_ACTION" "$CUSTOM_PORT" "$CUSTOM_COMMENT"
    echo ""
    show_status
    exit 0
fi

if [[ "$DEV_PORTS_ACTION" == "close" ]]; then
    manage_dev_ports "close"
    echo ""
    show_status
    exit 0
fi

if [[ "$DEV_PORTS_ACTION" == "open" && "$ACTION" != "apply" ]]; then
    manage_dev_ports "open"
    echo ""
    show_status
    exit 0
fi

# ------------------------------------------------------------------------------
# 6. CONFIGURACIÓN COMPLETA DE SEGURIDAD Y UFW POR DEFECTO
# ------------------------------------------------------------------------------
echo -e "${BOLD}======================================================================${NC}"
echo -e "  🛡️  ${BOLD}CONFIGURANDO SEGURIDAD, RED Y UFW - OMARCHY WORKSTATION${NC}"
echo -e "${BOLD}======================================================================${NC}"

# Paso 1: Asegurar UFW y desactivar Firewalld para evitar colisiones
log_info "[1/5] Verificando UFW y desactivando Firewalld..."
if ! pacman -Q ufw &>/dev/null; then
    log_info "Instalando paquete ufw mediante pacman..."
    $SUDO pacman -S --needed --noconfirm ufw
fi

# Desactivar y enmascarar Firewalld si estuviera presente
if systemctl list-unit-files 2>/dev/null | grep -q "^firewalld.service"; then
    log_info "Desactivando y enmascarando Firewalld para evitar conflictos de nftables..."
    $SUDO systemctl disable --now firewalld.service 2>/dev/null || true
    $SUDO systemctl mask firewalld.service 2>/dev/null || true
fi

# Habilitar e iniciar UFW en systemd
$SUDO systemctl unmask ufw.service 2>/dev/null || true
$SUDO systemctl enable --now ufw.service

# Paso 2: Políticas base y configuración de reenvío en UFW
log_info "[2/5] Estableciendo políticas base y reenvío de paquetes en UFW..."
$SUDO ufw --force default deny incoming
$SUDO ufw --force default allow outgoing
$SUDO ufw logging low

# Configurar DEFAULT_FORWARD_POLICY="ACCEPT" para permitir enrutamiento de Podman/Docker/KVM
if [[ -f "$UFW_DEFAULT_CONFIG" ]]; then
    if grep -q '^DEFAULT_FORWARD_POLICY=' "$UFW_DEFAULT_CONFIG"; then
        $SUDO sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' "$UFW_DEFAULT_CONFIG"
    else
        echo 'DEFAULT_FORWARD_POLICY="ACCEPT"' | $SUDO tee -a "$UFW_DEFAULT_CONFIG" >/dev/null
    fi
fi

# Paso 3: Reglas esenciales de escritorio y servicios en LAN
log_info "[3/5] Configurando puertos y servicios esenciales en UFW..."

# LocalSend (53317 TCP/UDP)
$SUDO ufw allow 53317/tcp comment 'LocalSend' >/dev/null 2>&1 || true
$SUDO ufw allow 53317/udp comment 'LocalSend' >/dev/null 2>&1 || true

# GSConnect / KDE Connect (1714:1764 TCP/UDP)
$SUDO ufw allow 1714:1764/tcp comment 'KDE Connect' >/dev/null 2>&1 || true
$SUDO ufw allow 1714:1764/udp comment 'KDE Connect' >/dev/null 2>&1 || true

# mDNS (5353/UDP - resolución .local, impresoras HP, Chromecast)
$SUDO ufw allow 5353/udp comment 'mDNS Discovery' >/dev/null 2>&1 || true

# SSH (22/TCP - acceso administrativo)
$SUDO ufw allow 22/tcp comment 'SSH Remote Access' >/dev/null 2>&1 || true

# Docker / Podman DNS (resolución interna de contenedores hacia host 172.17.0.1)
$SUDO ufw allow proto udp from 172.16.0.0/12 to 172.17.0.1 port 53 comment 'allow-docker-dns' >/dev/null 2>&1 || true
$SUDO ufw allow proto udp from 192.168.0.0/16 to 172.17.0.1 port 53 comment 'allow-docker-dns' >/dev/null 2>&1 || true

# Puertos de desarrollo si se solicitaron por parámetro
if [[ "$DEV_PORTS_ACTION" == "open" ]]; then
    manage_dev_ports "open"
fi

# Consola Cockpit si se solicitó por parámetro
if [[ "$COCKPIT_ACTION" == true ]]; then
    manage_cockpit_port
fi

# Habilitar UFW de forma no interactiva y recargar
$SUDO ufw --force enable
$SUDO ufw reload
log_ok "Cortafuegos UFW activo y configurado como predeterminado."

# Paso 4: DNS-over-TLS oportunista y DNSSEC en systemd-resolved
log_info "[4/5] Configurando DNS-over-TLS oportunista en systemd-resolved..."
$SUDO mkdir -p "$RESOLVED_DROPIN_DIR"
$SUDO tee "$RESOLVED_DROPIN_FILE" > /dev/null << 'EOF'
# ==============================================================================
# DNS-over-TLS y Privacidad - Omarchy Workstation (systemd-resolved)
# ==============================================================================
[Resolve]
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
FallbackDNS=1.1.1.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net 8.8.8.8#dns.google
EOF

$SUDO systemctl reload-or-restart systemd-resolved 2>/dev/null || true
log_ok "systemd-resolved configurado con DNS-over-TLS."

# Paso 5: Endurecimiento de red y sysctl para Podman Rootless + IPv6 SLAAC
log_info "[5/5] Desplegando parámetros sysctl de seguridad en $SYSCTL_SEC_FILE..."
$SUDO tee "$SYSCTL_SEC_FILE" > /dev/null << 'EOF'
# ==============================================================================
#  Seguridad de Red y Soporte Podman Rootless - Omarchy Workstation
#  HP ProBook 455 G10 (AMD Ryzen 7 7730U / Libvirt / Podman)
# ==============================================================================

# Permitir a Podman Rootless exponer puertos desde el 80 (HTTP/HTTPS) sin sudo
net.ipv4.ip_unprivileged_port_start = 80
net.ipv4.ping_group_range = 0 2147483647

# Reenvío de paquetes IP para contenedores Podman y máquinas virtuales KVM
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Preservar autoconfiguración IPv6 SLAAC cuando el reenvío está activo (CRÍTICO)
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.default.accept_ra = 2

# Protección contra ataques de red y spoofing de IP (Filtro inverso RFC 3704)
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rfc1337 = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignorar paquetes de redirección ICMP maliciosos
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Protección del sistema de archivos contra explotación de enlaces
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_regular = 2
fs.protected_fifos = 2

# Endurecimiento de punteros y mensajes de depuración del Kernel
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1

# Ampliar límite de namespaces de usuario para múltiples contenedores y Toolbx
user.max_user_namespaces = 262144
EOF

$SUDO sysctl -p "$SYSCTL_SEC_FILE" >/dev/null 2>&1 || true
log_ok "Parámetros sysctl de seguridad y Podman aplicados."

echo ""
show_status
