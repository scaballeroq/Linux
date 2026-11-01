#!/usr/bin/env bash
# ==============================================================================
# SEGURIDAD Y RED DE DESARROLLO (seguridad.sh) - Soplos Linux Boro (GNOME Shell)
# ==============================================================================
# Configuración orientada a estación de trabajo local/hogar para desarrollo:
# • Cortafuegos nativo UFW (Uncomplicated Firewall) por defecto con GUI GUFW.
# • Soporte integrado para:
#   * Podman Rootless y contenedores de desarrollo.
#   * KVM / Libvirt (tráfico virbr0 y reenvío de paquetes DEFAULT_FORWARD_POLICY="ACCEPT").
#   * GSConnect (1714:1764 TCP/UDP) y mDNS (5353 UDP) para integración móvil y red local.
#   * SSH (22/tcp) y Cockpit (9090/tcp, si está instalado).
# • Sysctl: IP Forwarding con accept_ra=2 (IPv6 estable), puertos sin privilegios (>=80),
#   namespaces de usuario optimizados y diagnóstico de restricción AppArmor.
# • Entorno de trabajo doméstico: IP y DHCP estables, sin MAC Randomization disruptiva.
# • Soporte CLI: --status / -s, --dev-ports / -d, --help / -h.
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
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

show_help() {
    cat <<EOF
🛡️ Gestor de Seguridad y Red de Desarrollo - Soplos Linux Boro
(Optimizado para desarrollo doméstico: Podman Rootless + KVM/Libvirt + UFW / GUFW)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Configura UFW (Podman, KVM, GSConnect, SSH), asegura políticas
                      y aplica parámetros sysctl esenciales para desarrollo.
  --status, -s        Muestra el diagnóstico de UFW, GUFW, reglas activas y sysctl.
  --dev-ports, -d     Abre en UFW los puertos locales de desarrollo (Vite: 5173, Next.js: 3000,
                      FastAPI: 8000, Contenedores Web: 8080).
  --help, -h          Muestra este mensaje de ayuda.

Características configuradas:
  • UFW / GUFW:       Políticas por defecto (Deny incoming, Allow outgoing, Accept forward).
  • Servicios LAN:    GSConnect (1714-1764 TCP/UDP), mDNS (5353 UDP), SSH y Cockpit (si existe).
  • KVM / Libvirt:    Tráfico en interfaz virtual 'virbr0' permitido y forward policy activa.
  • Podman Rootless:  Puertos sin privilegios a partir de 80 y user namespaces elevados.
  • Sysctl Dev:       IP forwarding (IPv4/IPv6 con accept_ra=2 para preservar SLAAC).
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE SEGURIDAD Y RED DE DESARROLLO - SOPLOS LINUX BORO (GNOME)"
    echo "================================================================="
    
    # 1. UFW y GUFW
    local ufw_service="inactivo"
    if systemctl is-active --quiet ufw 2>/dev/null; then
        ufw_service="activo"
    fi
    echo "• UFW (servicio systemd):     $([ "$ufw_service" = "activo" ] && echo "✅ activo" || echo "❌ inactivo")"

    if command -v gufw &>/dev/null; then
        echo "• GUFW (interfaz gráfica):    ✅ instalada (/usr/bin/gufw)"
    else
        echo "• GUFW (interfaz gráfica):    ⚠️ no instalada"
    fi

    # Comprobar estado de reglas UFW si se tienen permisos
    if [ "$EUID" -eq 0 ] || sudo -n true 2>/dev/null; then
        echo "-----------------------------------------------------------------"
        echo "📋 Reglas y Políticas de UFW:"
        $SUDO ufw status verbose 2>/dev/null || echo "  (No se pudo obtener el estado detallado de UFW)"
    else
        echo "-----------------------------------------------------------------"
        echo "ℹ️ Para ver las reglas detalladas de UFW ejecuta: sudo $0 --status"
        if [ -f /etc/default/ufw ]; then
            local def_in def_out def_fwd
            def_in=$(grep '^DEFAULT_INPUT_POLICY=' /etc/default/ufw | cut -d= -f2 | tr -d '"' || echo "n/a")
            def_out=$(grep '^DEFAULT_OUTPUT_POLICY=' /etc/default/ufw | cut -d= -f2 | tr -d '"' || echo "n/a")
            def_fwd=$(grep '^DEFAULT_FORWARD_POLICY=' /etc/default/ufw | cut -d= -f2 | tr -d '"' || echo "n/a")
            echo "  - Política Entrada (Default Input):   $def_in"
            echo "  - Política Salida (Default Output):   $def_out"
            echo "  - Política Reenvío (Default Forward): $def_fwd"
        fi
    fi

    echo "-----------------------------------------------------------------"
    echo "⚙️ Parámetros de Kernel (Sysctl para Podman & KVM):"
    echo "  • Reenvío IPv4 (ip_forward):                $(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo 'n/a') (Requerido: 1)"
    echo "  • Reenvío IPv6 (forwarding):                $(cat /proc/sys/net/ipv6/conf/all/forwarding 2>/dev/null || echo 'n/a') (Requerido: 1)"
    echo "  • IPv6 Router Advertisements (accept_ra):   $(cat /proc/sys/net/ipv6/conf/all/accept_ra 2>/dev/null || echo 'n/a') (Requerido: 2 si forwarding=1)"
    echo "  • Puerto inicio sin privilegios (Podman):   $(cat /proc/sys/net/ipv4/ip_unprivileged_port_start 2>/dev/null || echo 'n/a') (Recomendado: 80)"
    echo "  • Rango grupos ping (Podman rootless):      $(cat /proc/sys/net/ipv4/ping_group_range 2>/dev/null || echo 'n/a')"
    echo "  • User namespaces (max_user_namespaces):    $(cat /proc/sys/user/max_user_namespaces 2>/dev/null || echo 'n/a') (Recomendado: >= 123343)"
    echo "  • Restricción AppArmor Userns (Soplos):     $(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null || echo 'n/a') (0=libre, 1=restringido)"

    echo "-----------------------------------------------------------------"
    echo "🏠 Servicios y privacidad en red local de hogar:"
    local f2b_status="inactivo"
    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        f2b_status="activo"
    fi
    echo "  • Fail2ban:                 $f2b_status (innecesario en LAN doméstica)"
    echo "  • MAC Randomization:        $(if [ -f /etc/NetworkManager/conf.d/00-macrandomize.conf ]; then echo '⚠️ Activo (puede alterar reservas DHCP)'; else echo '✅ Inactivo (IP estática y DHCP estable)'; fi)"
    echo "================================================================="
}

open_dev_ports() {
    echo "================================================================="
    echo "🌐 HABILITANDO PUERTOS DE DESARROLLO LOCAL EN UFW"
    echo "================================================================="
    if ! command -v ufw &>/dev/null; then
        echo "❌ UFW no está instalado."
        exit 1
    fi

    # Puertos habituales de desarrollo
    # 3000: Next.js / React / Node.js
    # 5173: Vite / Vue / Svelte
    # 8000: FastAPI / Django
    # 8080: Nginx / Spring Boot / Contenedores de prueba
    local dev_ports=("3000/tcp" "5173/tcp" "8000/tcp" "8080/tcp")
    echo "ℹ️ Abriendo puertos de desarrollo en UFW: ${dev_ports[*]}..."

    for port in "${dev_ports[@]}"; do
        $SUDO ufw allow "$port" comment 'Desarrollo Local' 2>/dev/null || true
    done

    $SUDO ufw reload
    echo "  ✅ Puertos de desarrollo abiertos en UFW."
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --dev-ports|-d|dev-ports)
        open_dev_ports
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🛡️ CONFIGURANDO SEGURIDAD Y RED PARA DESARROLLO (SOPLOS LINUX BORO WORKSTATION)"
echo "================================================================="

# 1. Asegurar e iniciar UFW
echo "ℹ️ [1/4] Verificando e iniciando cortafuegos UFW..."
if ! command -v ufw &>/dev/null; then
    $SUDO apt-get update
    $SUDO apt-get install -y ufw
fi

$SUDO systemctl enable --now ufw 2>/dev/null || true
$SUDO ufw --force enable

# 2. Políticas por defecto
echo "ℹ️ [2/4] Configurando políticas por defecto (Entrada: Deny, Salida: Allow, Reenvío: Accept)..."
$SUDO ufw default deny incoming
$SUDO ufw default allow outgoing

# Reenvío de paquetes para KVM (virbr0) y redes de contenedores (Podman)
if [ -f /etc/default/ufw ]; then
    $SUDO sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
fi
$SUDO ufw default allow forward 2>/dev/null || true

# 3. Servicios esenciales en la red de desarrollo
echo "ℹ️ [3/4] Configurando reglas para GSConnect, mDNS, SSH y KVM..."

# GSConnect / KDE Connect (1714:1764 TCP/UDP)
$SUDO ufw allow 1714:1764/tcp comment 'GSConnect' 2>/dev/null || true
$SUDO ufw allow 1714:1764/udp comment 'GSConnect' 2>/dev/null || true

# mDNS / Descubrimiento local Avahi/Bonjour (5353 UDP)
$SUDO ufw allow 5353/udp comment 'mDNS' 2>/dev/null || true

# SSH (22/tcp)
$SUDO ufw allow 22/tcp comment 'SSH' 2>/dev/null || true

# Cockpit Web Console (9090/tcp) si está instalado
if command -v cockpit-bridge &>/dev/null || [ -d /etc/cockpit ]; then
    $SUDO ufw allow 9090/tcp comment 'Cockpit Web Console' 2>/dev/null || true
fi

# KVM / Libvirt (puente virtual virbr0)
$SUDO ufw allow in on virbr0 comment 'KVM Libvirt virbr0 in' 2>/dev/null || true
$SUDO ufw allow out on virbr0 comment 'KVM Libvirt virbr0 out' 2>/dev/null || true

# Recargar UFW
$SUDO ufw reload
echo "  ✅ UFW configurado exitosamente con GSConnect, SSH, mDNS y KVM."

# 4. Parámetros de Kernel (sysctl) orientados a Podman Rootless y KVM
echo "ℹ️ [4/4] Aplicando parámetros de Kernel para Podman Rootless y virtualización..."
$SUDO mkdir -p /etc/sysctl.d
cat <<'EOF' | $SUDO tee /etc/sysctl.d/99-development-network.conf > /dev/null
# =============================================================================
# RED Y CONTENEDORES PARA DESARROLLO - SOPLOS LINUX BORO WORKSTATION
# =============================================================================

# Reenvío de paquetes para redes de contenedores (Podman) y VMs (KVM/QEMU)
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Preservar recepción de Router Advertisements (SLAAC) con forwarding activado
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.default.accept_ra = 2

# Permitir a Podman Rootless enlazar puertos HTTP/HTTPS estándar (>=80) sin requerir root
net.ipv4.ip_unprivileged_port_start = 80

# Permitir operaciones ICMP (ping) en contenedores sin privilegios
net.ipv4.ping_group_range = 0 2147483647

# Soporte completo de espacios de nombres de usuario (user namespaces)
kernel.unprivileged_userns_clone = 1
user.max_user_namespaces = 262144

# Nota sobre Soplos Linux Boro y AppArmor:
# Si herramientas rootless de contenedores requieren crear user namespaces no confinados:
# kernel.apparmor_restrict_unprivileged_userns = 0
EOF

$SUDO sysctl --system > /dev/null 2>&1 || true
echo "  ✅ Parámetros sysctl aplicados."

echo "================================================================="
echo "✅ Seguridad y red configuradas con UFW en Soplos Linux Boro Workstation."
echo "💡 Puedes gestionar las reglas visualmente en cualquier momento con GUFW."
echo "================================================================="
