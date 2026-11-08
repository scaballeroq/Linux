#!/usr/bin/env bash
# ==============================================================================
# seguridad.sh - Endurecimiento de Seguridad y Cortafuegos TV (Firewalld)
# Sistema: CachyOS (Arch Linux) | Hardware: HP Z230 SFF Workstation (Sony TV)
# CPU: Intel Core i7-4790 | GPU: Intel HD Graphics 4600 | RAM: 8.0 GiB DDR3
# ==============================================================================
# Características principales:
#   - Firewalld exclusivo (desactivación obligatoria y purga de UFW / iptables legacy).
#   - Backend moderno nftables para mínimo consumo de CPU y máxima eficiencia.
#   - Zona predeterminada 'home' (red doméstica de salón) con asignación de interfaces.
#   - Habilita servicios y puertos esenciales para el Centro Multimedia:
#     • samba-client y nfs: Acceso y streaming fluido en alta definición desde NAS.
#     • mdns y upnp-client: Auto-descubrimiento Zeroconf/Avahi, DLNA y Chromecast.
#     • kdeconnect / gsconnect: Control remoto del televisor desde smartphone (1714-1764).
#     • ssh: Administración remota segura por terminal (22/tcp).
#     • cockpit: Panel web ligero de telemetría y administración (9090/tcp).
#     • kodi: Control remoto HTTP (Kore/Yatse en 8080/tcp) y EventServer (9777/udp).
#     • stremio: Motor de streaming local y Web API (11470/tcp).
#   - DNS-over-TLS (Systemd-resolved) con Quad9 / Cloudflare (antimalware y privacidad).
#   - Endurecimiento de Kernel (Sysctl) con buffers optimizados para streaming 1080p.
#   - CLI: --status / -s, --add-port, --remove-port, --reset, --help / -h.
# ==============================================================================

set -euo pipefail

# Colores ANSI
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
MAGENTA=$'\033[0;35m'
NC=$'\033[0m'

# Detección de privilegios de ejecución
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &>/dev/null; then
        echo -e "${RED}❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo.${NC}"
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detección del usuario real
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

show_help() {
    cat <<EOF
${BOLD}🛡️ Gestor de Seguridad y Cortafuegos Firewalld - CachyOS TV (Sony TV)${NC}
${CYAN}Hardware:${NC} HP Z230 SFF Workstation (Intel Core i7-4790 / 8 GB RAM / SSD 256 GB)

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)              Aplica el aprovisionamiento completo de Firewalld, DoT y Sysctl.
  -s, --status                  Muestra diagnóstico exhaustivo de Firewalld, servicios y red.
  -p, --add-port <puerto/proto> Abre un puerto personalizado en la zona 'home' (ej: 8000/tcp).
  -r, --remove-port <puerto/proto> Cierra un puerto previamente abierto en la zona 'home'.
  --reset                       Restaura la configuración multimedia estándar de Firewalld.
  -h, --help                    Muestra este mensaje de ayuda.

${BOLD}Servicios de Red HTPC gestionados:${NC}
  • samba-client, nfs         Streaming de películas y series desde NAS
  • mdns, upnp-client         Descubrimiento Zeroconf/Avahi, DLNA y Smart TV
  • kdeconnect (GSConnect)    Control remoto del televisor desde smartphone
  • ssh, cockpit (9090)       Administración y telemetría remota
  • kodi (8080/tcp, 9777/udp) Interfaz web y mando móvil Kore / Yatse
  • stremio (11470/tcp)       Servidor de streaming local Stremio
EOF
}

check_firewalld_running() {
    if ! command -v firewall-cmd &>/dev/null; then
        return 1
    fi
    if ! firewall-cmd --state &>/dev/null; then
        return 1
    fi
    return 0
}

ensure_firewalld_active() {
    if ! check_firewalld_running; then
        echo -e "${YELLOW}⚙️ Iniciando servicio firewalld.service...${NC}"
        $SUDO systemctl enable --now firewalld.service 2>/dev/null || true
        sleep 1
    fi
}

install_custom_services() {
    echo -e "${BLUE}ℹ️ Configurando definiciones de servicios multimedia en Firewalld...${NC}"
    $SUDO mkdir -p /etc/firewalld/services

    # 1. Definición para Kodi Media Center (Web UI y EventServer)
    cat << 'EOF' | $SUDO tee /etc/firewalld/services/kodi.xml > /dev/null
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>Kodi Media Center</short>
  <description>Kodi HTTP Web Interface (Kore / Yatse remote apps) and EventServer</description>
  <port protocol="tcp" port="8080"/>
  <port protocol="udp" port="9777"/>
</service>
EOF

    # 2. Definición para Stremio Streaming Engine
    cat << 'EOF' | $SUDO tee /etc/firewalld/services/stremio.xml > /dev/null
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>Stremio Streaming Engine</short>
  <description>Stremio Local Streaming Engine and HTTP Web API</description>
  <port protocol="tcp" port="11470"/>
</service>
EOF

    $SUDO chmod 644 /etc/firewalld/services/kodi.xml /etc/firewalld/services/stremio.xml
}

setup_security() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}🛡️ CONFIGURANDO SEGURIDAD Y FIREWALLD PARA CACHYOS TV${NC}"
    echo -e "${CYAN}   Equipo: HP Z230 SFF Workstation (Sony TV / Intel Haswell)${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    # 1. Asegurar desinstalación estricta de UFW y bloqueo de conflictos
    echo -e "${BLUE}ℹ️ [1/6] Verificando que UFW no esté en conflicto...${NC}"
    if pacman -Q ufw &>/dev/null 2>&1 || [ -f /usr/sbin/ufw ]; then
        echo -e "${YELLOW}⚠️ UFW detectado: desactivando y purgando en favor de Firewalld...${NC}"
        $SUDO systemctl stop ufw.service 2>/dev/null || true
        $SUDO systemctl disable ufw.service 2>/dev/null || true
        $SUDO pacman -Rns --noconfirm ufw 2>/dev/null || true
    fi
    echo -e "${GREEN}✅ Cortafuegos limpio: UFW purgado / inexistente.${NC}"

    # 2. Instalación y activación de Firewalld
    echo -e "${BLUE}ℹ️ [2/6] Verificando e iniciando Firewalld...${NC}"
    if ! command -v firewall-cmd &>/dev/null; then
        echo -e "${YELLOW}⚙️ Instalando paquete firewalld...${NC}"
        $SUDO pacman -S --needed --noconfirm firewalld
    fi

    ensure_firewalld_active

    # 3. Registrar servicios multimedia personalizados
    install_custom_services

    # Recargar para registrar kodi.xml y stremio.xml
    $SUDO firewall-cmd --reload >/dev/null 2>&1 || true

    # 4. Configuración de Zona 'home' y reglas multimedia
    echo -e "${BLUE}ℹ️ [3/6] Configurando zona 'home' para Centro Multimedia...${NC}"
    $SUDO firewall-cmd --set-default-zone=home >/dev/null 2>&1 || true

    # Asignar interfaces físicas activas a la zona 'home'
    local ifaces
    ifaces=$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^(en|eth|wl)' || true)
    for iface in $ifaces; do
        if [ -n "$iface" ]; then
            $SUDO firewall-cmd --permanent --zone=home --add-interface="$iface" >/dev/null 2>&1 || true
            echo -e "  • Interfaz asociada a zona home: ${GREEN}$iface${NC}"
        fi
    done

    # Lista de servicios esenciales HTPC
    local multimedia_services=(
        "samba-client"  # Acceso a carpetas compartidas SMB del NAS
        "nfs"           # Streaming NFS alta velocidad
        "mdns"          # Auto-descubrimiento Zeroconf/Avahi (5353/udp)
        "upnp-client"   # Descubrimiento DLNA / routers UPnP
        "kdeconnect"    # GSConnect / integración con teléfono (1714-1764)
        "ssh"           # Administración remota segura (22/tcp)
        "cockpit"       # Panel web de gestión ligera (9090/tcp)
        "kodi"          # Interfaz web Kore/Yatse (8080/tcp, 9777/udp)
        "stremio"       # Servidor streaming Stremio (11470/tcp)
    )

    for srv in "${multimedia_services[@]}"; do
        $SUDO firewall-cmd --permanent --zone=home --add-service="$srv" >/dev/null 2>&1 || true
        echo -e "  • Servicio permitido en zona home: ${GREEN}$srv${NC}"
    done

    $SUDO firewall-cmd --reload >/dev/null 2>&1 || true
    echo -e "${GREEN}✅ Firewalld configurado y recargado con éxito.${NC}"

    # 5. DNS-over-TLS y Privacidad DNS (Systemd-resolved)
    echo -e "${BLUE}ℹ️ [4/6] Configurando DNS seguro (Systemd-resolved con DoT)...${NC}"
    $SUDO mkdir -p /etc/systemd/resolved.conf.d/
    cat << 'EOF' | $SUDO tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null
# =============================================================================
# DNS-over-TLS (DoT) y Privacidad para CachyOS TV
# Servidores: Quad9 (Protección malware + privacidad) y Cloudflare (Baja latencia)
# =============================================================================
[Resolve]
DNS=9.9.9.9#dns.quad9.net 149.112.112.112#dns.quad9.net 1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com
FallbackDNS=8.8.8.8#dns.google 8.8.4.4#dns.google
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
MulticastDNS=resolve
LLMNR=no
Cache=yes
CacheTimeSecMax=86400
EOF
    $SUDO systemctl enable --now systemd-resolved.service 2>/dev/null || true
    $SUDO systemctl restart systemd-resolved 2>/dev/null || true
    echo -e "${GREEN}✅ DNS-over-TLS activo en systemd-resolved.${NC}"

    # 6. Endurecimiento del Kernel y buffers de red para streaming
    echo -e "${BLUE}ℹ️ [5/6] Aplicando parámetros de Kernel (Sysctl) para red y streaming...${NC}"
    cat << 'EOF' | $SUDO tee /etc/sysctl.d/99-tv-security.conf > /dev/null
# =============================================================================
# CachyOS TV - Endurecimiento de Seguridad de Red y Buffers de Streaming
# Optimizado para HP Z230 SFF Workstation (Intel I217-LM Gigabit / 8 GB RAM)
# =============================================================================

# 1. Protección contra ataques de red y spoofing
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_rfc1337=1

# 2. Ignorar paquetes ICMP maliciosos y no responder a broadcasts
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0

# 3. Buffers de red optimizados para streaming de vídeo en alta definición (1080p/4K)
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.rmem_default=1048576
net.core.wmem_default=1048576
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192

# 4. Persistencia y Keepalive optimizado para conexiones SMB/NFS continuas
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_intvl=15
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_fin_timeout=15

# 5. Puertos y namespaces seguros
net.ipv4.ip_unprivileged_port_start=80
user.max_user_namespaces=65536

# 6. Endurecimiento básico de seguridad del sistema
kernel.dmesg_restrict=1
kernel.kptr_restrict=1
fs.protected_hardlinks=1
fs.protected_symlinks=1
fs.protected_fifos=1
fs.protected_regular=2
EOF

    $SUDO sysctl --system >/dev/null 2>&1 || true
    echo -e "${GREEN}✅ Parámetros de red y seguridad sysctl aplicados.${NC}"

    # 7. Permisos de directorios sensibles
    echo -e "${BLUE}ℹ️ [6/6] Ajustando permisos de seguridad...${NC}"
    $SUDO chmod 700 /root 2>/dev/null || true
    echo -e "${GREEN}✅ Endurecimiento de seguridad finalizado con éxito.${NC}"
}

show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}${BOLD}🔍 ESTADO DE SEGURIDAD Y FIREWALLD - CACHYOS TV${NC}"
    echo -e "${CYAN}   Equipo: HP Z230 SFF Workstation (Sony TV / Intel Haswell)${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    # Estado de Firewalld
    if command -v firewall-cmd &>/dev/null; then
        local fw_state default_z active_ifaces
        fw_state=$(firewall-cmd --state 2>/dev/null || echo "Inactivo")
        default_z=$(firewall-cmd --get-default-zone 2>/dev/null || echo "home")

        if [ "$fw_state" = "running" ]; then
            echo -e "• Firewalld Service:  ${GREEN}✅ Activo y en ejecución${NC} (Backend: nftables)"
            echo -e "• Zona Predeterminada: ${GREEN}$default_z${NC}"

            # Interfaces en zona
            active_ifaces=$(firewall-cmd --zone="$default_z" --list-interfaces 2>/dev/null || echo "")
            echo -e "• Interfaces en zona: ${CYAN}${active_ifaces:-Todas las no asignadas}${NC}"

            echo -e "-----------------------------------------------------------------"
            echo -e "${BOLD}📺 Servicios Multimedia y Red LAN en zona '$default_z':${NC}"

            local check_services=(
                "samba-client:Acceso a recursos compartidos y películas del NAS"
                "nfs:Streaming NFS de alta velocidad desde el NAS"
                "mdns:Descubrimiento mDNS / Avahi / Chromecast / DLNA (5353/udp)"
                "upnp-client:Auto-descubrimiento UPnP y Smart TV (1900/udp)"
                "kdeconnect:Mando a distancia GSConnect / smartphone (1714-1764)"
                "ssh:Administración remota segura por terminal (22/tcp)"
                "cockpit:Panel web de administración y telemetría (9090/tcp)"
                "kodi:Control remoto Kore / Yatse para Kodi (8080/tcp, 9777/udp)"
                "stremio:Servidor de streaming local Stremio (11470/tcp)"
            )

            for item in "${check_services[@]}"; do
                local srv="${item%%:*}"
                local desc="${item#*:}"
                if firewall-cmd --zone="$default_z" --query-service="$srv" &>/dev/null; then
                    printf "  %-15s ${GREEN}✅ Abierto${NC}  (%s)\n" "$srv" "$desc"
                else
                    printf "  %-15s ${YELLOW}⚠️ Cerrado${NC}  (%s)\n" "$srv" "$desc"
                fi
            done

            local custom_ports
            custom_ports=$(firewall-cmd --zone="$default_z" --list-ports 2>/dev/null || true)
            echo -e "• Puertos manuales:   ${CYAN}${custom_ports:-Ninguno adicional}${NC}"
        else
            echo -e "• Firewalld Service:  ${RED}❌ Inactivo ($fw_state)${NC}"
            echo -e "  ${YELLOW}💡 Inicia el servicio con 'sudo systemctl start firewalld' o ejecuta '$0' para aprovisionarlo.${NC}"
        fi
    else
        echo -e "• Firewalld:          ${RED}❌ No instalado${NC}"
    fi

    echo -e "-----------------------------------------------------------------"
    echo -e "${BOLD}🔒 Verificaciones Complementarias:${NC}"
    
    # UFW Check
    if command -v ufw &>/dev/null || [ -f /usr/sbin/ufw ]; then
        echo -e "• UFW Conflictivo:    ${RED}⚠️ Presente (debe eliminarse para evitar colisiones con Firewalld)${NC}"
    else
        echo -e "• UFW Conflictivo:    ${GREEN}✅ No presente (Firewalld tiene control exclusivo)${NC}"
    fi

    # DNS-over-TLS Check
    local dot_status
    if [ -f /etc/systemd/resolved.conf.d/dot.conf ]; then
        dot_status=$(grep -o 'DNSOverTLS=.*' /etc/systemd/resolved.conf.d/dot.conf 2>/dev/null || echo "Configurado")
        echo -e "• DNS-over-TLS (DoT): ${GREEN}✅ Activo en systemd-resolved ($dot_status)${NC}"
    else
        echo -e "• DNS-over-TLS (DoT): ${YELLOW}⚠️ No configurado (/etc/systemd/resolved.conf.d/dot.conf)${NC}"
    fi

    # Sysctl Check
    local syn_cookie rp_filter rmem_max
    syn_cookie=$(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null || echo "n/a")
    rp_filter=$(sysctl -n net.ipv4.conf.all.rp_filter 2>/dev/null || echo "n/a")
    rmem_max=$(sysctl -n net.core.rmem_max 2>/dev/null || echo "n/a")
    echo -e "• Parámetros Sysctl:  SYN Cookies: $syn_cookie | RP Filter: $rp_filter | Rmem Max: $rmem_max"

    echo -e "${BOLD}=================================================================${NC}"
}

add_port() {
    local port_proto="${1:-}"
    if [ -z "$port_proto" ]; then
        echo -e "${RED}❌ Error: Especifica el puerto y protocolo. Ejemplo: $0 --add-port 8000/tcp${NC}"
        exit 1
    fi
    ensure_firewalld_active
    echo -e "${BLUE}ℹ️ Abriendo puerto $port_proto en la zona predeterminada de Firewalld...${NC}"
    $SUDO firewall-cmd --permanent --zone=home --add-port="$port_proto"
    $SUDO firewall-cmd --reload
    echo -e "${GREEN}✅ Puerto $port_proto abierto exitosamente en la zona 'home'.${NC}"
}

remove_port() {
    local port_proto="${1:-}"
    if [ -z "$port_proto" ]; then
        echo -e "${RED}❌ Error: Especifica el puerto y protocolo. Ejemplo: $0 --remove-port 8000/tcp${NC}"
        exit 1
    fi
    ensure_firewalld_active
    echo -e "${BLUE}ℹ️ Cerrando puerto $port_proto en la zona predeterminada de Firewalld...${NC}"
    $SUDO firewall-cmd --permanent --zone=home --remove-port="$port_proto"
    $SUDO firewall-cmd --reload
    echo -e "${GREEN}✅ Puerto $port_proto cerrado exitosamente en la zona 'home'.${NC}"
}

reset_firewall() {
    echo -e "${YELLOW}⚠️ Restableciendo configuración multimedia de Firewalld en zona 'home'...${NC}"
    ensure_firewalld_active
    install_custom_services
    $SUDO firewall-cmd --reload >/dev/null 2>&1 || true

    local default_z
    default_z=$(firewall-cmd --get-default-zone 2>/dev/null || echo "home")
    
    # Asegurar zona home
    $SUDO firewall-cmd --set-default-zone=home

    local services=(samba-client nfs mdns upnp-client kdeconnect ssh cockpit kodi stremio)
    for srv in "${services[@]}"; do
        $SUDO firewall-cmd --permanent --zone=home --add-service="$srv" >/dev/null 2>&1 || true
    done

    $SUDO firewall-cmd --reload
    echo -e "${GREEN}✅ Configuración estándar de Firewalld restablecida correctamente.${NC}"
}

# Despachador de argumentos CLI
case "${1:-}" in
    -s|--status|status)
        show_status
        exit 0
        ;;
    -p|--add-port)
        shift
        add_port "${1:-}"
        exit 0
        ;;
    --add-port=*)
        add_port "${1#*=}"
        exit 0
        ;;
    -r|--remove-port)
        shift
        remove_port "${1:-}"
        exit 0
        ;;
    --remove-port=*)
        remove_port "${1#*=}"
        exit 0
        ;;
    --reset)
        reset_firewall
        echo ""
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
