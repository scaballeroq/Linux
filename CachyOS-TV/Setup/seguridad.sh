#!/usr/bin/env bash
# ==============================================================================
# seguridad.sh - Endurecimiento de Seguridad y Cortafuegos TV (Firewalld)
# Sistema: CachyOS (Arch Linux) | Hardware: HP Z230 SFF Workstation (Sony TV)
# ==============================================================================
# Características:
#   - Firewalld exclusivo (desactivación obligatoria y purga de UFW).
#   - Habilita servicios para centro multimedia:
#     • samba-client y nfs: Acceso y streaming fluido desde NAS doméstico.
#     • mdns: Auto-descubrimiento Zeroconf/Avahi de recursos en red local.
#     • kdeconnect / gsconnect: Control remoto del televisor desde smartphone.
#     • ssh: Administración remota segura.
#   - DNS-over-TLS (Systemd-resolved) y endurecimiento sysctl de red.
#   - CLI: --status / -s, --help / -h.
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

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

show_help() {
    cat <<EOF
${BOLD}🛡️ Gestor de Seguridad y Cortafuegos - CachyOS TV (Sony TV)${NC}

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica el endurecimiento de red, servicios LAN en Firewalld y DoT.
  -s, --status        Muestra diagnóstico detallado del cortafuegos y parámetros sysctl.
  -h, --help          Muestra este mensaje de ayuda.
EOF
}

setup_security() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}🛡️ CONFIGURANDO SEGURIDAD Y FIREWALLD PARA CACHYOS TV${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    # 1. Asegurar desinstalación de UFW
    if pacman -Q ufw &>/dev/null 2>&1; then
        echo -e "${BLUE}ℹ️ [1/5] UFW detectado: eliminando para usar Firewalld exclusivo...${NC}"
        $SUDO systemctl disable --now ufw 2>/dev/null || true
        $SUDO pacman -Rns --noconfirm ufw 2>/dev/null || true
    else
        echo -e "${GREEN}✅ [1/5] Cortafuegos limpio: UFW no está presente.${NC}"
    fi

    # 2. Configuración de Firewalld para Salón y NAS
    echo -e "${BLUE}ℹ️ [2/5] Instalando y configurando Firewalld...${NC}"
    $SUDO pacman -S --needed --noconfirm firewalld 2>/dev/null || true
    $SUDO systemctl enable --now firewalld.service

    # Zona por defecto 'home' para entorno de red local seguro
    $SUDO firewall-cmd --set-default-zone=home

    # Habilitar servicios multimedia y red doméstica
    $SUDO firewall-cmd --permanent --zone=home --add-service=samba-client 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=home --add-service=nfs 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=home --add-service=mdns 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=home --add-service=ssh 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=home --add-service=kdeconnect 2>/dev/null || true

    $SUDO firewall-cmd --reload
    echo -e "${GREEN}✅ Firewalld configurado (zona: home, servicios: samba-client, nfs, mdns, ssh, kdeconnect).${NC}"

    # 3. DNS-over-TLS y Privacidad DNS (Systemd-resolved)
    echo -e "${BLUE}ℹ️ [3/5] Configurando DNS seguro (Systemd-resolved con DoT)...${NC}"
    $SUDO mkdir -p /etc/systemd/resolved.conf.d/
    cat <<EOF | $SUDO tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null
[Resolve]
DNS=9.9.9.9#dns.quad9.net 1.1.1.1#cloudflare-dns.com
FallbackDNS=8.8.8.8#dns.google
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
EOF
    $SUDO systemctl restart systemd-resolved 2>/dev/null || true
    echo -e "${GREEN}✅ DNS-over-TLS activo en systemd-resolved.${NC}"

    # 4. Endurecimiento del Kernel y buffers de red
    echo -e "${BLUE}ℹ️ [4/5] Aplicando parámetros de Kernel (sysctl) para streaming y red...${NC}"
    cat <<EOF | $SUDO tee /etc/sysctl.d/99-tv-security.conf > /dev/null
# Protección contra spoofing y ataques de red
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1

# Buffers de red optimizados para streaming de vídeo en alta definición
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216

# Soporte para puertos no privilegiados
net.ipv4.ip_unprivileged_port_start=80
user.max_user_namespaces=65536
EOF
    $SUDO sysctl --system > /dev/null || true
    echo -e "${GREEN}✅ Parámetros de red y seguridad sysctl aplicados.${NC}"

    # 5. Auditoría de permisos
    echo -e "${BLUE}ℹ️ [5/5] Asegurando permisos de directorios críticos...${NC}"
    $SUDO chmod 700 /root
    echo -e "${GREEN}✅ Endurecimiento de seguridad finalizado.${NC}"
}

show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}${BOLD}🔍 ESTADO DE SEGURIDAD Y FIREWALLD - CACHYOS TV${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    if command -v firewall-cmd &>/dev/null; then
        local fw_state default_z
        fw_state=$(firewall-cmd --state 2>/dev/null || echo "Inactivo")
        default_z=$(firewall-cmd --get-default-zone 2>/dev/null || echo "Desconocida")
        echo -e "• Firewalld:          ${GREEN}✅ $fw_state (Zona predeterminada: $default_z)${NC}"
        
        echo -e "• Servicios habilitados en zona $default_z:"
        for srv in "samba-client" "nfs" "mdns" "ssh" "kdeconnect"; do
            if firewall-cmd --zone="$default_z" --query-service="$srv" 2>/dev/null; then
                echo -e "  - $srv: ${GREEN}✅ Abierto${NC}"
            else
                echo -e "  - $srv: ${YELLOW}⚠️ Cerrado${NC}"
            fi
        done
    else
        echo -e "• Firewalld:          ${RED}❌ No instalado${NC}"
    fi

    echo -e "-----------------------------------------------------------------"
    echo -e "• UFW Conflictivo:    $([ ! -f /usr/sbin/ufw ] && echo -e "${GREEN}✅ No presente${NC}" || echo -e "${RED}⚠️ Instalado (debe eliminarse)${NC}")"
    echo -e "• DNS-over-TLS:       $(grep -o 'DNSOverTLS=.*' /etc/systemd/resolved.conf.d/dot.conf 2>/dev/null || echo "No configurado")"
    echo -e "${BOLD}=================================================================${NC}"
}

case "${1:-}" in
    -s|--status|status)
        show_status
        exit 0
        ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
    "")
        setup_security
        echo ""
        show_status
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida: $1${NC}"
        show_help
        exit 1
        ;;
esac
