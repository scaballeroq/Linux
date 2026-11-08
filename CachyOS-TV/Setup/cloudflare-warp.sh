#!/usr/bin/env bash
# ==============================================================================
# cloudflare-warp.sh - Bypass de Bloqueos de ISP y La Liga para Stremio / HTPC
# Sistema: CachyOS (Arch Linux) | Hardware: HP Z230 SFF Workstation (Sony TV)
# ==============================================================================
# Propósito:
#   En España, los bloqueos judiciales dinámicos solicitados por "La Liga" fuerzan
#   a las operadoras (Movistar, Vodafone, Orange, Digi, MásMóvil) a bloquear rangos
#   de IPs de servidores de streaming, CDNs y trackers P2P durante las jornadas de fútbol.
#   Esto provoca que Stremio (Torrentio, Debrid, addons comunitarios) se congele o no cargue.
#
# Solución técnica:
#   Cloudflare WARP redirige todo el tráfico o DNS a través de la red global Anycast
#   de Cloudflare mediante el protocolo WireGuard cifrado, anulando por completo
#   el bloqueo de SNI, DNS Hijacking y filtrado de IP a nivel de operadora sin
#   necesidad de pagar suscripciones de VPNs comerciales y manteniendo latencias mínimas.
#
# Características del script:
#   - Instalación nativa mediante pacman (repositorio oficial CachyOS / Chaotic-AUR).
#   - Habilitación del servicio systemd 'warp-svc.service'.
#   - Registro automático (--accept-tos) y modo túnel completo 'warp'.
#   - Integración con Firewalld (interfaz CloudflareWARP en zona 'trusted').
#   - CLI completo: --status, --connect, --disconnect, --toggle, --uninstall, --help.
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

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo -e "${RED}❌ Error: 'sudo' no está disponible.${NC}"
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detección de usuario real
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

show_help() {
    cat <<EOF
${BOLD}🛡️ Gestor de Cloudflare WARP - CachyOS TV (Bypass Bloqueos La Liga / Stremio)${NC}
${CYAN}Hardware:${NC} HP Z230 SFF Workstation (Sony TV 1080p)

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)    Instala, registra, configura Firewalld y conecta Cloudflare WARP.
  -c, --connect       Conecta el túnel WARP para saltar los bloqueos de streaming.
  -d, --disconnect    Desconecta el túnel WARP (vuelve a la conexión directa de tu ISP).
  -t, --toggle        Alterna entre conectar y desconectar según el estado actual.
  -s, --status        Muestra el estado de la conexión, IP pública y comprobación de WARP.
  -u, --uninstall     Desconecta, detiene el servicio y desinstala el cliente WARP.
  -h, --help          Muestra este mensaje de ayuda.

${BOLD}¿Por qué es necesario para Stremio en España?${NC}
  Los fines de semana durante partidos de fútbol, los operadores bloquean por orden judicial
  cientos de direcciones IP dinámicas y dominios CDN utilizados por reproductores P2P
  y addons de Stremio. Cloudflare WARP encapsula tus peticiones bajo WireGuard, impidiendo
  que el router o tu operadora puedan inspeccionar o bloquear las fuentes de vídeo.
EOF
}

check_service_active() {
    systemctl is-active --quiet warp-svc.service 2>/dev/null
}

ensure_service_running() {
    if ! check_service_active; then
        echo -e "${BLUE}ℹ️ Iniciando servicio de sistema warp-svc.service...${NC}"
        $SUDO systemctl enable --now warp-svc.service 2>/dev/null || true
        sleep 2
    fi
}

register_client() {
    echo -e "${BLUE}ℹ️ Registrando cliente en la red de Cloudflare...${NC}"
    # Aceptar términos y registrar cuenta anónima
    if run_as_user warp-cli --accept-tos registration new &>/dev/null; then
        echo -e "${GREEN}✅ Registro nuevo completado con éxito.${NC}"
    elif run_as_user warp-cli registration new &>/dev/null; then
        echo -e "${GREEN}✅ Registro completado.${NC}"
    elif run_as_user warp-cli register &>/dev/null; then
        echo -e "${GREEN}✅ Registro clásico completado.${NC}"
    else
        echo -e "${YELLOW}ℹ️ Cliente ya registrado o existente.${NC}"
    fi

    # Configurar modo túnel completo (WARP) para cifrar todo el tráfico y DNS
    echo -e "${BLUE}ℹ️ Estableciendo modo de operación en 'warp' (Túnel WireGuard completo)...${NC}"
    run_as_user warp-cli mode warp 2>/dev/null || run_as_user warp-cli set-mode warp 2>/dev/null || true
}

configure_firewall() {
    echo -e "${BLUE}ℹ️ Configurando reglas en Firewalld para el túnel WARP...${NC}"
    if command -v firewall-cmd &>/dev/null; then
        # Añadir la interfaz virtual de CloudflareWARP a la zona trusted para tráfico fluido
        $SUDO firewall-cmd --permanent --zone=trusted --add-interface=CloudflareWARP 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
        echo -e "${GREEN}✅ Interfaz 'CloudflareWARP' autorizada en zona 'trusted' de Firewalld.${NC}"
    fi
}

install_warp() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}🚀 INSTALANDO Y CONFIGURANDO CLOUDFLARE WARP (CACHYOS TV)${NC}"
    echo -e "${CYAN}   Solución antipiratería / desbloqueo de Stremio en España${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    if ! command -v warp-cli &>/dev/null; then
        echo -e "${BLUE}📦 [1/4] Instalando paquete cloudflare-warp-bin...${NC}"
        $SUDO pacman -S --needed --noconfirm cloudflare-warp-bin 2>/dev/null || {
            echo -e "${YELLOW}⚠️ Intentando instalación con helper AUR (paru/yay)...${NC}"
            if command -v paru &>/dev/null; then
                run_as_user paru -S --needed --noconfirm cloudflare-warp-bin
            elif command -v yay &>/dev/null; then
                run_as_user yay -S --needed --noconfirm cloudflare-warp-bin
            else
                echo -e "${RED}❌ Error: No se pudo instalar cloudflare-warp-bin.${NC}"
                exit 1
            fi
        }
        echo -e "${GREEN}✅ Paquete cloudflare-warp-bin instalado.${NC}"
    else
        echo -e "${GREEN}✅ [1/4] cloudflare-warp-bin ya está instalado.${NC}"
    fi

    echo -e "${BLUE}⚙️ [2/4] Verificando e iniciando el servicio warp-svc...${NC}"
    ensure_service_running

    echo -e "${BLUE}🔑 [3/4] Inicializando registro y modo de conexión...${NC}"
    register_client

    echo -e "${BLUE}🛡️ [4/4] Integración con Firewalld...${NC}"
    configure_firewall

    echo -e "${BLUE}🌐 Conectando túnel Cloudflare WARP...${NC}"
    connect_warp

    echo ""
    show_status
}

connect_warp() {
    ensure_service_running
    echo -e "${BLUE}🌐 Conectando a Cloudflare WARP...${NC}"
    run_as_user warp-cli connect 2>/dev/null || true
    sleep 2
    if is_warp_connected; then
        echo -e "${GREEN}✅ Túnel WARP Conectado. Tráfico protegido contra bloqueos de ISP.${NC}"
    else
        echo -e "${YELLOW}⚠️ Comando de conexión enviado. Comprueba con '$0 --status'.${NC}"
    fi
}

disconnect_warp() {
    echo -e "${BLUE}🔌 Desconectando de Cloudflare WARP...${NC}"
    run_as_user warp-cli disconnect 2>/dev/null || true
    sleep 1
    echo -e "${GREEN}✅ Desconectado de WARP. Navegando con la conexión directa de tu ISP.${NC}"
}

is_warp_connected() {
    local trace
    trace=$(curl -s --max-time 3 https://www.cloudflare.com/cdn-cgi/trace 2>/dev/null || true)
    if echo "$trace" | grep -qi "warp=on"; then
        return 0
    elif echo "$trace" | grep -qi "warp=plus"; then
        return 0
    fi
    return 1
}

toggle_warp() {
    if is_warp_connected; then
        disconnect_warp
    else
        connect_warp
    fi
}

show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}${BOLD}🔍 ESTADO DE CONEXIÓN CLOUDFLARE WARP (CACHYOS TV)${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    if ! command -v warp-cli &>/dev/null; then
        echo -e "• Paquete WARP:       ${RED}❌ No instalado (ejecuta '$0' para instalarlo)${NC}"
        echo -e "${BOLD}=================================================================${NC}"
        return 0
    fi

    echo -e "• Paquete WARP:       ${GREEN}✅ Instalado ($(pacman -Q cloudflare-warp-bin 2>/dev/null || echo "activo"))${NC}"
    
    if check_service_active; then
        echo -e "• Servicio Daemon:    ${GREEN}✅ warp-svc.service activo${NC}"
    else
        echo -e "• Servicio Daemon:    ${RED}❌ warp-svc.service inactivo${NC}"
    fi

    # Estado CLI interno
    local cli_status
    cli_status=$(run_as_user warp-cli status 2>/dev/null || echo "Desconocido")
    echo -e "• Estado interno:     ${CYAN}$cli_status${NC}"

    # Verificación de IP pública y bypass
    echo -e "-----------------------------------------------------------------"
    local trace_info ip_pub loc_pub warp_active
    trace_info=$(curl -s --max-time 3 https://www.cloudflare.com/cdn-cgi/trace 2>/dev/null || true)
    ip_pub=$(echo "$trace_info" | grep -i '^ip=' | cut -d= -f2 || echo "n/a")
    loc_pub=$(echo "$trace_info" | grep -i '^loc=' | cut -d= -f2 || echo "n/a")
    warp_active=$(echo "$trace_info" | grep -i '^warp=' | cut -d= -f2 || echo "off")

    echo -e "• IP Pública actual:  ${BOLD}${CYAN}${ip_pub:-n/a}${NC} (Ubicación: ${loc_pub:-n/a})"

    if [ "$warp_active" = "on" ] || [ "$warp_active" = "plus" ]; then
        echo -e "• Túnel WARP:         ${GREEN}${BOLD}✅ ACTIVO ($warp_active)${NC}"
        echo -e "• Protección Stremio: ${GREEN}🛡️ Bloqueos de ISP y La Liga eludidos con éxito.${NC}"
    else
        echo -e "• Túnel WARP:         ${YELLOW}⚠️ INACTIVO (Conexión directa de operadora)${NC}"
        echo -e "• Protección Stremio: ${RED}⚠️ Vulnerable a bloqueos dinámicos en streaming.${NC}"
        echo -e "  ${CYAN}💡 Conéctalo ejecutando: $0 --connect${NC}"
    fi
    echo -e "${BOLD}=================================================================${NC}"
}

uninstall_warp() {
    echo -e "${YELLOW}⚠️ Desinstalando Cloudflare WARP...${NC}"
    run_as_user warp-cli disconnect 2>/dev/null || true
    $SUDO systemctl stop warp-svc.service 2>/dev/null || true
    $SUDO systemctl disable warp-svc.service 2>/dev/null || true

    if command -v firewall-cmd &>/dev/null; then
        $SUDO firewall-cmd --permanent --zone=trusted --remove-interface=CloudflareWARP 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
    fi

    $SUDO pacman -Rns --noconfirm cloudflare-warp-bin 2>/dev/null || true
    echo -e "${GREEN}✅ Cloudflare WARP desinstalado y servicio detenido.${NC}"
}

# Despachador de argumentos CLI
case "${1:-}" in
    -c|--connect|connect)
        connect_warp
        ;;
    -d|--disconnect|disconnect)
        disconnect_warp
        ;;
    -t|--toggle|toggle)
        toggle_warp
        ;;
    -s|--status|status)
        show_status
        ;;
    -u|--uninstall|uninstall)
        uninstall_warp
        ;;
    -h|--help|help)
        show_help
        ;;
    "")
        install_warp
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida: $1${NC}"
        show_help
        exit 1
        ;;
esac

