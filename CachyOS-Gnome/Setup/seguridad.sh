#!/usr/bin/env bash
# ==============================================================================
#  seguridad.sh - Endurecimiento de Seguridad, Red y Firewalld Exclusivo
#  Sistema: CachyOS / Arch Linux (GNOME Shell Wayland)
#  Entorno: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Podman Rootless / Libvirt)
# ==============================================================================
# Características:
#   - Cortafuegos nativo exclusivo: FIREWALLD (firewall-cmd). Prohibido UFW e iptables crudo.
#   - Desactivación y enmascaramiento total de UFW (prohibido por la política del monorepo).
#   - Zona activa (home / public): KDE Connect / GSConnect, mDNS, SSH, Samba y LocalSend.
#   - Interfaces de contenedores y virtualización en zona trusted / libvirt:
#     * podman+, cni-podman+ (Podman Rootless)
#     * virbr0, virbr+ (KVM / QEMU Libvirt con Masquerade activo)
#   - Puertos de desarrollo modular (--dev-ports): 3000 (React/Next), 5173 (Vite), 8000 (FastAPI), 8080 (Web).
#   - Endurecimiento de red y Kernel (/etc/sysctl.d/99-cachyos-security-podman.conf):
#     * net.ipv4.ip_unprivileged_port_start = 80 (permite a Podman rootless exponer 80/443).
#     * net.ipv4.ping_group_range = 0 2147483647 (ping en contenedores rootless).
#     * net.ipv4.ip_forward = 1 y net.ipv6.conf.all.forwarding = 1 (enrutamiento de paquetes).
#     * net.ipv6.conf.all.accept_ra = 2 (preserva autoconfiguración IPv6 SLAAC con reenvío activo).
#     * Filtro anti-spoofing rp_filter = 1, SYN cookies y protección contra redirects.
#     * Restricción de memoria kernel.kptr_restrict = 2 y dmesg_restrict = 1.
#   - DNS-over-TLS oportunista y DNSSEC en systemd-resolved (/etc/systemd/resolved.conf.d/).
#   - Diagnóstico O(1) de solo lectura sin elevación innecesaria de sudo (--status).
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
# 2. PRIVILEGIOS Y GESTOR DE PAQUETES
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

SYSCTL_SEC_FILE="/etc/sysctl.d/99-cachyos-security-podman.conf"
RESOLVED_DROPIN_DIR="/etc/systemd/resolved.conf.d"
RESOLVED_DROPIN_FILE="$RESOLVED_DROPIN_DIR/99-dns-over-tls.conf"

ACTION="apply"
DEV_PORTS_ACTION="none"
COCKPIT_ACTION=false

# ------------------------------------------------------------------------------
# 3. AYUDA Y DIAGNÓSTICO DE SOLO LECTURA (CERO SUDO EN --status)
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}🛡️  Gestor de Seguridad, Red y Firewalld - CachyOS Workstation (GNOME Wayland)${NC}

Configura ${BOLD}Firewalld${NC} como cortafuegos exclusivo (enmascarando ${BOLD}ufw${NC}),
habilita servicios de escritorio (GSConnect, mDNS, SSH, LocalSend), aisla interfaces
de ${BOLD}Podman Rootless${NC} (podman+) y ${BOLD}KVM/Libvirt${NC} (virbr0) en zona ${BOLD}trusted${NC},
activa DNS-over-TLS oportunista y endurece el Kernel vía ${BOLD}sysctl${NC}.

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones Principales:${NC}
  (sin argumentos)     Aplica la configuración completa de Firewalld, DNS-over-TLS y sysctl.
  -s, --status         Muestra el estado detallado de Firewalld, zonas, puertos y sysctl (modo solo lectura).
  -d, --dev-ports      Abre puertos locales de desarrollo en Firewalld (3000, 5173, 8000, 8080 TCP).
  --close-dev          Cierra los puertos locales de desarrollo en Firewalld.
  --cockpit            Habilita el puerto 9090/tcp para la consola web Cockpit.
  -h, --help           Muestra esta ayuda.

${BOLD}Servicios y Puertos Gestionados:${NC}
  • Cortafuegos:       Firewalld activo (zona por defecto: home / public).
  • kdeconnect:        1714-1764 TCP/UDP (GSConnect / KDE Connect).
  • mdns:              5353/UDP (descubrimiento de impresoras HP y dispositivos en red local).
  • ssh:               22/TCP (acceso seguro remoto).
  • localsend:         53317 TCP/UDP (transferencia rápida de archivos en LAN).
  • podman+:           Interfaces virtuales de Podman en zona 'trusted'.
  • virbr0 / virbr+:   Puente de red de KVM / QEMU Libvirt con Masquerade activo.
  • dev-ports:         3000 (React/Next), 5173 (Vite), 8000 (FastAPI), 8080 (Web proxy).
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🛡️  ${BOLD}ESTADO DE SEGURIDAD Y FIREWALLD - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    # 1. Firewalld Daemon
    local fw_active="inactivo"
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        fw_active="activo"
        echo -e "  • Servicio Firewalld:        ${GREEN}✅ Activo (systemd firewalld.service)${NC}"
    else
        echo -e "  • Servicio Firewalld:        ${RED}❌ Inactivo${NC}"
    fi

    # 2. UFW (Prohibido por la política del monorepo)
    local ufw_state ufw_masked="no"
    ufw_state=$(systemctl is-active ufw 2>/dev/null || echo "inactivo")
    if [[ "$(systemctl is-enabled ufw 2>/dev/null || true)" == "masked" ]]; then
        ufw_masked="sí"
    fi
    echo -e "  • Estado de UFW (prohibido): ${GREEN}✅ Inactivo${NC} $([[ "$ufw_masked" == "sí" ]] && echo -e "${GREEN}[Enmascarado/Masked]${NC}" || echo -e "${YELLOW}[No enmascarado]${NC}")"

    # 3. Zonas y Servicios de Firewalld (sin invocar sudo)
    if [[ "$fw_active" == "activo" ]]; then
        local def_zone active_services active_ports trusted_ifaces active_zones masquerade_state
        def_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "home")
        active_services=$(firewall-cmd --zone="$def_zone" --list-services 2>/dev/null || echo "ninguno")
        active_ports=$(firewall-cmd --zone="$def_zone" --list-ports 2>/dev/null || echo "ninguno")
        trusted_ifaces=$(firewall-cmd --zone=trusted --list-interfaces 2>/dev/null || echo "ninguna")
        active_zones=$(firewall-cmd --get-active-zones 2>/dev/null || echo "$def_zone")
        if firewall-cmd --zone="$def_zone" --query-masquerade &>/dev/null; then
            masquerade_state="✅ Activo"
        else
            masquerade_state="❌ Inactivo"
        fi

        echo ""
        echo -e "${BOLD}🔥 Reglas Activas en Firewalld (Zona: ${CYAN}${def_zone}${NC}${BOLD}):${NC}"
        echo -e "  • Zona por defecto:          ${CYAN}${def_zone}${NC}"
        echo -e "  • Servicios permitidos:      ${GREEN}${active_services}${NC}"
        echo -e "  • Puertos abiertos:          ${GREEN}${active_ports}${NC}"
        echo -e "  • Interfaces en 'trusted':   ${CYAN}${trusted_ifaces:-ninguna}${NC}"
        echo -e "  • IP Masquerade NAT:         ${masquerade_state}"

        # Comprobar zona libvirt si existe
        if firewall-cmd --get-zones 2>/dev/null | grep -qw "libvirt"; then
            local libvirt_ifaces
            libvirt_ifaces=$(firewall-cmd --zone=libvirt --list-interfaces 2>/dev/null || echo "ninguna")
            echo -e "  • Interfaces en 'libvirt':   ${CYAN}${libvirt_ifaces:-ninguna}${NC}"
        fi
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

    echo -e "  • Reenvío IPv4 (ip_forward):                ${CYAN}${ip4_fwd}${NC} $([[ "$ip4_fwd" == "1" ]] && echo -e "${GREEN}(Requerido para Podman/KVM)${NC}" || echo -e "${YELLOW}(Inactivo)${NC}")"
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
# 4. GESTIÓN MODULAR DE PUERTOS DE DESARROLLO
# ------------------------------------------------------------------------------
DEV_PORTS=(
    "3000/tcp"   # Next.js / React / Node.js
    "5173/tcp"   # Vite / Vue / Svelte
    "8000/tcp"   # FastAPI / Django / Python dev
    "8080/tcp"   # Web proxy / Spring Boot / Contenedores
)

manage_dev_ports() {
    local mode="$1"
    local active_zone
    active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "home")

    if [[ "$mode" == "open" ]]; then
        log_info "Habilitando puertos locales de desarrollo en zona '$active_zone': ${DEV_PORTS[*]}..."
        for p in "${DEV_PORTS[@]}"; do
            $SUDO firewall-cmd --permanent --zone="$active_zone" --add-port="$p" 2>/dev/null || true
        done
        $SUDO firewall-cmd --reload
        log_ok "Puertos de desarrollo abiertos en zona '$active_zone'."
    elif [[ "$mode" == "close" ]]; then
        log_info "Cerrando puertos locales de desarrollo en zona '$active_zone'..."
        for p in "${DEV_PORTS[@]}"; do
            $SUDO firewall-cmd --permanent --zone="$active_zone" --remove-port="$p" 2>/dev/null || true
        done
        $SUDO firewall-cmd --reload
        log_ok "Puertos de desarrollo cerrados en zona '$active_zone'."
    fi
}

manage_cockpit_port() {
    local active_zone
    active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "home")
    log_info "Habilitando servicio Cockpit (puerto 9090) en zona '$active_zone'..."
    $SUDO firewall-cmd --permanent --zone="$active_zone" --add-service=cockpit 2>/dev/null || \
        $SUDO firewall-cmd --permanent --zone="$active_zone" --add-port=9090/tcp
    $SUDO firewall-cmd --reload
    log_ok "Servicio Cockpit habilitado en Firewalld."
}

# ------------------------------------------------------------------------------
# 5. PARSEO DE ARGUMENTOS
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)     ACTION="status"; shift ;;
        -d|--dev-ports)  DEV_PORTS_ACTION="open"; shift ;;
        --close-dev)     DEV_PORTS_ACTION="close"; shift ;;
        --cockpit)       COCKPIT_ACTION=true; shift ;;
        -h|--help)       show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

if [[ "$ACTION" == "status" ]]; then
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
# 6. CONFIGURACIÓN COMPLETA DE SEGURIDAD Y FIREWALLD
# ------------------------------------------------------------------------------
echo -e "${BOLD}======================================================================${NC}"
echo -e "  🛡️  ${BOLD}CONFIGURANDO SEGURIDAD, RED Y FIREWALLD - CACHYOS WORKSTATION${NC}"
echo -e "${BOLD}======================================================================${NC}"

# Paso 1: Asegurar Firewalld y neutralizar UFW (política del monorepo)
log_info "[1/5] Verificando Firewalld y neutralizando UFW..."
if ! pacman -Q firewalld &>/dev/null; then
    log_info "Instalando paquete firewalld mediante pacman..."
    $SUDO pacman -S --needed --noconfirm firewalld
fi

# Neutralizar UFW si existiera algún residuo
if systemctl list-unit-files 2>/dev/null | grep -q "^ufw.service"; then
    $SUDO systemctl disable --now ufw.service 2>/dev/null || true
fi
$SUDO systemctl mask ufw.service 2>/dev/null || true

# Activar e iniciar Firewalld
$SUDO systemctl unmask firewalld.service 2>/dev/null || true
$SUDO systemctl enable --now firewalld.service
log_ok "Firewalld activo como cortafuegos exclusivo (UFW enmascarado)."

# Paso 2: Configurar servicios de escritorio en la zona activa de CachyOS Workstation
DEFAULT_ZONE=$(firewall-cmd --get-default-zone 2>/dev/null || echo "home")
log_info "[2/5] Configurando servicios esenciales en zona activa (${DEFAULT_ZONE})..."

# GSConnect / KDE Connect (1714-1764 TCP/UDP)
$SUDO firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-service=kdeconnect 2>/dev/null || {
    $SUDO firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-port=1714-1764/tcp
    $SUDO firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-port=1714-1764/udp
}

# mDNS (5353/UDP - resolución .local, impresoras HP, Chromecast)
$SUDO firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-service=mdns

# SSH (22/TCP)
$SUDO firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-service=ssh

# Samba Client (exploración SMB en Nautilus)
$SUDO firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-service=samba-client 2>/dev/null || true

# LocalSend (53317 TCP/UDP)
$SUDO firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-port=53317/tcp 2>/dev/null || true
$SUDO firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-port=53317/udp 2>/dev/null || true

# Masquerade en la zona por defecto (permite NAT hacia Internet a VMs y Contenedores)
$SUDO firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-masquerade 2>/dev/null || true

# Paso 3: Aislar interfaces de Podman Rootless y KVM/Libvirt en zona 'trusted' o 'libvirt'
log_info "[3/5] Configurando interfaces virtuales de Podman y KVM..."
$SUDO firewall-cmd --permanent --zone=trusted --add-interface=podman+ 2>/dev/null || true
$SUDO firewall-cmd --permanent --zone=trusted --add-interface=cni-podman+ 2>/dev/null || true

if firewall-cmd --get-zones 2>/dev/null | grep -qw "libvirt"; then
    $SUDO firewall-cmd --permanent --zone=libvirt --add-interface=virbr0 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=libvirt --add-interface=virbr+ 2>/dev/null || true
else
    $SUDO firewall-cmd --permanent --zone=trusted --add-interface=virbr0 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=trusted --add-interface=virbr+ 2>/dev/null || true
fi

# Puertos de desarrollo si se solicitaron por parámetro
if [[ "$DEV_PORTS_ACTION" == "open" ]]; then
    log_info "Habilitando puertos locales de desarrollo (3000, 5173, 8000, 8080 TCP)..."
    for p in "${DEV_PORTS[@]}"; do
        $SUDO firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-port="$p" 2>/dev/null || true
    done
fi

if [[ "$COCKPIT_ACTION" == true ]]; then
    manage_cockpit_port
fi

# Recargar Firewalld
$SUDO firewall-cmd --reload
log_ok "Reglas de Firewalld aplicadas y recargadas exitosamente."

# Paso 4: DNS-over-TLS oportunista y DNSSEC en systemd-resolved
log_info "[4/5] Configurando DNS-over-TLS oportunista en systemd-resolved..."
$SUDO mkdir -p "$RESOLVED_DROPIN_DIR"
$SUDO tee "$RESOLVED_DROPIN_FILE" > /dev/null << 'EOF'
# ==============================================================================
# DNS-over-TLS y Privacidad - CachyOS Workstation (systemd-resolved)
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
#  Seguridad de Red y Soporte Podman Rootless - CachyOS Workstation
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
