#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  seguridad.sh - Endurecimiento de Red, Firewalld Exclusivo y Sysctl
#  Sistema: Fedora 45 Workstation (GNOME Wayland / Podman Rootless / Libvirt)
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

DNF_BIN="dnf5"
command -v dnf5 &>/dev/null || DNF_BIN="dnf"

SYSCTL_SEC_FILE="/etc/sysctl.d/99-fedora-security-podman.conf"
RESOLVED_DROPIN_DIR="/etc/systemd/resolved.conf.d"
RESOLVED_DROPIN_FILE="$RESOLVED_DROPIN_DIR/99-dns-over-tls.conf"

OPEN_DEV_PORTS=false
ACTION="apply"

show_help() {
    cat << EOF
${BOLD}🛡️  Endurecimiento de Seguridad y Firewalld - Fedora 45 Workstation${NC}

Configura ${BOLD}Firewalld${NC} como cortafuegos exclusivo (enmascarando ${BOLD}ufw${NC}),
habilita servicios para GSConnect/KDE Connect, mDNS, interfaz ${BOLD}podman+${NC} en zona
${BOLD}trusted${NC}, interfaz ${BOLD}virbr0${NC} en zona ${BOLD}libvirt${NC}, DNS-over-TLS oportunista y
endurecimiento de red sysctl compatible con IPv6 Router Advertisements (${BOLD}accept_ra=2${NC}).

${BOLD}Uso:${NC}
  $0 [OPCIONES]

${BOLD}Opciones:${NC}
  (sin argumentos)     Aplica configuración completa de Firewalld, DNS-over-TLS y sysctl
  -d, --dev-ports      Abre además puertos locales de desarrollo (3000, 5173, 8000, 8080 TCP)
  -s, --status         Muestra el estado de Firewalld, zonas, servicios y sysctl
  -h, --help           Muestra esta ayuda
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🛡️  ${BOLD}ESTADO DE SEGURIDAD Y FIREWALLD - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    if systemctl is-active --quiet firewalld 2>/dev/null; then
        local def_zone
        def_zone=$(sudo firewall-cmd --get-default-zone 2>/dev/null || echo "FedoraWorkstation")
        echo -e "  • Servicio Firewalld:        ${GREEN}Activo (Zona por defecto: ${BOLD}${def_zone}${NC}${GREEN})${NC}"
        echo -e "  • Servicios permitidos:      ${CYAN}$(sudo firewall-cmd --list-services 2>/dev/null || echo 'N/A')${NC}"
        echo -e "  • Puertos abiertos:          ${CYAN}$(sudo firewall-cmd --list-ports 2>/dev/null || echo 'ninguno')${NC}"
        echo -e "  • Interfaces zona trusted:   ${CYAN}$(sudo firewall-cmd --zone=trusted --list-interfaces 2>/dev/null || echo 'ninguna')${NC}"
    else
        echo -e "  • Servicio Firewalld:        ${RED}Inactivo${NC}"
    fi

    local ufw_state
    ufw_state=$(systemctl is-enabled ufw 2>/dev/null || echo "no-instalado")
    echo -e "  • Estado de UFW (prohibido): ${GREEN}${ufw_state}${NC}"

    [[ -f "$SYSCTL_SEC_FILE" ]]     && echo -e "  • Endurecimiento Sysctl:     ${GREEN}${SYSCTL_SEC_FILE}${NC}"     || echo -e "  • Endurecimiento Sysctl:     ${YELLOW}No aplicado${NC}"
    [[ -f "$RESOLVED_DROPIN_FILE" ]] && echo -e "  • DNS-over-TLS (resolved):   ${GREEN}${RESOLVED_DROPIN_FILE}${NC}" || echo -e "  • DNS-over-TLS (resolved):   ${YELLOW}Por defecto${NC}"
    echo -e "${BOLD}======================================================================${NC}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--status)    ACTION="status"; shift ;;
        -d|--dev-ports) OPEN_DEV_PORTS=true; shift ;;
        -h|--help)      show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; show_help; exit 1 ;;
    esac
done

if [[ "$ACTION" == "status" ]]; then
    show_status
    exit 0
fi

log_info "Verificando Firewalld y deshabilitando/enmascarando UFW (regla del monorepo)..."
if ! rpm -q firewalld &>/dev/null; then
    sudo "$DNF_BIN" install -y firewalld
fi

if systemctl list-unit-files | grep -q "^ufw.service"; then
    sudo systemctl disable --now ufw.service 2>/dev/null || true
fi
sudo systemctl mask ufw.service 2>/dev/null || true

sudo systemctl unmask firewalld.service 2>/dev/null || true
sudo systemctl enable --now firewalld.service

DEFAULT_ZONE=$(sudo firewall-cmd --get-default-zone 2>/dev/null || echo "FedoraWorkstation")
log_info "Configurando reglas permanentes en zona activa ($DEFAULT_ZONE)..."

# Servicios esenciales en la estación de trabajo: GSConnect / KDE Connect, mDNS, SSH y Samba client
sudo firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-service=kdeconnect 2>/dev/null || {
    sudo firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-port=1714-1764/tcp
    sudo firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-port=1714-1764/udp
}
sudo firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-service=mdns
sudo firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-service=ssh
sudo firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-service=samba-client 2>/dev/null || true

# LocalSend (53317 TCP/UDP)
sudo firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-port=53317/tcp
sudo firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-port=53317/udp

# Puertos de desarrollo opcionales (--dev-ports): Next.js/React (3000), Vite (5173), FastAPI/Django (8000), Web/Admin (8080)
if [[ "$OPEN_DEV_PORTS" == true ]]; then
    log_info "Habilitando puertos de desarrollo local (3000, 5173, 8000, 8080 TCP)..."
    for port in 3000 5173 8000 8080; do
        sudo firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-port="${port}/tcp"
    done
fi

# Confiar en interfaces de contenedores Podman (podman+) y bridge KVM (virbr0)
sudo firewall-cmd --permanent --zone=trusted --add-interface=podman+ 2>/dev/null || true
if sudo firewall-cmd --get-zones | grep -qw "libvirt"; then
    sudo firewall-cmd --permanent --zone=libvirt --add-interface=virbr0 2>/dev/null || true
else
    sudo firewall-cmd --permanent --zone=trusted --add-interface=virbr0 2>/dev/null || true
fi

sudo firewall-cmd --reload
log_ok "Reglas de Firewalld aplicadas y recargadas."

# Configurar DNS-over-TLS oportunista en systemd-resolved
log_info "Configurando DNS-over-TLS oportunista y DNSSEC en $RESOLVED_DROPIN_FILE..."
sudo mkdir -p "$RESOLVED_DROPIN_DIR"
sudo tee "$RESOLVED_DROPIN_FILE" > /dev/null << 'EOF'
[Resolve]
FallbackDNS=1.1.1.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net 8.8.8.8#dns.google
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
EOF
sudo systemctl reload-or-restart systemd-resolved 2>/dev/null || true

# Endurecimiento de red y soporte para contenedores Podman Rootless + KVM/IPv6 (accept_ra=2)
log_info "Aplicando endurecimiento de red y sysctl para Podman Rootless en $SYSCTL_SEC_FILE..."
sudo tee "$SYSCTL_SEC_FILE" > /dev/null << 'EOF'
# ==============================================================================
#  Seguridad de Red y Soporte Podman Rootless - Fedora 45 Workstation
# ==============================================================================

# Permitir a Podman Rootless exponer puertos desde el 80 (HTTP/HTTPS/Reverse Proxy)
net.ipv4.ip_unprivileged_port_start = 80
net.ipv4.ping_group_range = 0 2147483647

# Protección contra ataques de red e IP spoofing
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rfc1337 = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Mantener conectividad IPv6 SLAAC cuando IPv6 forwarding está activo (Podman / Libvirt)
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.default.accept_ra = 2

# Endurecimiento de memoria de Kernel
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
EOF

sudo sysctl --system >/dev/null 2>&1 || true
log_ok "Endurecimiento de seguridad completado para Fedora 45 Workstation."
show_status
