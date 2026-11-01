#!/usr/bin/env bash
# ==============================================================================
# SEGURIDAD Y RED DE DESARROLLO (seguridad.sh) - Soplos Linux Boro (GNOME Shell)
# ==============================================================================
# Configuración orientada a estación de trabajo local/hogar para desarrollo:
# • Firewalld obligatorio: Podman Rootless (podman+, cni-podman+), KVM/QEMU (virbr0, virbr+), GSConnect, mDNS, SSH.
# • Desactivación y enmascaramiento total de UFW (prohibido en el monorepo).
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
(Optimizado para desarrollo doméstico: Podman Rootless + KVM/Libvirt + Firewalld)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Configura Firewalld (Podman, KVM, GSConnect), enmascara UFW y aplica
                      parámetros sysctl esenciales para desarrollo sin privilegios ni bloqueos.
  --status, -s        Muestra el diagnóstico de Firewalld, UFW, interfaces virtuales y sysctl.
  --dev-ports, -d     Abre en Firewalld los puertos locales de desarrollo (Vite: 5173, Next.js: 3000,
                      FastAPI: 8000, Contenedores Web: 8080).
  --help, -h          Muestra este mensaje de ayuda.

Características configuradas:
  • Firewalld:        Zona activa con GSConnect (kdeconnect), mDNS, SSH y Cockpit (si está instalado).
  • Podman Rootless:  Interfaces 'podman+' y 'cni-podman+' en zona 'trusted'.
  • KVM / Libvirt:    Puente virtual 'virbr0' y 'virbr+' en zona 'trusted' con IP Masquerade activo.
  • Sysctl Dev:       IP forwarding (IPv4/IPv6 con accept_ra=2 para preservar SLAAC),
                      puertos sin privilegios a partir de 80 y user namespaces elevados (262144).
  • UFW Enmascarado:  UFW deshabilitado y enmascarado (masked) para impedir reactivaciones por APT.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE SEGURIDAD Y RED DE DESARROLLO - SOPLOS LINUX BORO (GNOME)"
    echo "================================================================="
    
    # 1. Firewalld
    local fw_status="inactivo"
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        fw_status="activo"
    fi
    echo "• Firewalld (systemd):        $([ "$fw_status" = "activo" ] && echo "✅ activo" || echo "❌ inactivo")"

    # 2. UFW
    local ufw_status="inactivo"
    local ufw_is_masked="no"
    if systemctl is-active --quiet ufw 2>/dev/null; then
        ufw_status="activo"
    fi
    if [ "$(systemctl is-enabled ufw 2>/dev/null || true)" = "masked" ]; then
        ufw_is_masked="sí"
    fi
    echo "• UFW (prohibido):            $([ "$ufw_status" = "inactivo" ] && echo "✅ inactivo (correcto)" || echo "⚠️ activo (debe desactivarse)") $([ "$ufw_is_masked" = "sí" ] && echo "[enmascarado/masked]" || echo "")"

    if [ "$fw_status" = "activo" ]; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        echo "  - Zona por defecto:         $active_zone"
        echo "  - Servicios en $active_zone:        $(firewall-cmd --zone="$active_zone" --list-services 2>/dev/null || echo 'ninguno')"
        echo "  - Puertos abiertos:         $(firewall-cmd --zone="$active_zone" --list-ports 2>/dev/null || echo 'ninguno')"
        echo "  - Interfaces en 'trusted':  $(firewall-cmd --zone=trusted --list-interfaces 2>/dev/null || echo 'ninguna')"
        echo "  - Masquerade ($active_zone):        $(firewall-cmd --zone="$active_zone" --query-masquerade 2>/dev/null && echo '✅ Activo' || echo '❌ Inactivo')"
    fi

    echo "-----------------------------------------------------------------"
    echo "⚙️ Parámetros de Kernel (Sysctl para Podman & KVM):"
    echo "  • Reenvío IPv4 (ip_forward):                $(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo 'n/a') (Requerido: 1)"
    echo "  • Reenvío IPv6 (forwarding):                $(cat /proc/sys/net/ipv6/conf/all/forwarding 2>/dev/null || echo 'n/a') (Requerido: 1)"
    echo "  • IPv6 Router Advertisements (accept_ra):   $(cat /proc/sys/net/ipv6/conf/all/accept_ra 2>/dev/null || echo 'n/a') (Requerido: 2 si forwarding=1)"
    echo "  • Puerto inicio sin privilegios (Podman):   $(cat /proc/sys/net/ipv4/ip_unprivileged_port_start 2>/dev/null || echo 'n/a') (Recomendado: 80)"
    echo "  • Rango grupos ping (Podman rootless):      $(cat /proc/sys/net/ipv4/ping_group_range 2>/dev/null || echo 'n/a')"
    echo "  • User namespaces (max_user_namespaces):    $(cat /proc/sys/user/max_user_namespaces 2>/dev/null || echo 'n/a') (Recomendado: >= 123343)"
    echo "  • Restricción AppArmor Userns (Soplos Linux Boro):     $(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null || echo 'n/a') (0=libre para rootless, 1=restringido)"

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
    echo "🌐 HABILITANDO PUERTOS DE DESARROLLO LOCAL EN FIREWALLD"
    echo "================================================================="
    if ! systemctl is-active --quiet firewalld; then
        echo "❌ Firewalld no está activo. Ejecuta primero: $0"
        exit 1
    fi

    local active_zone
    active_zone=$($SUDO firewall-cmd --get-default-zone 2>/dev/null || echo "public")

    # Puertos habituales de desarrollo
    # 3000: Next.js / React / Node.js
    # 5173: Vite / Vue / Svelte
    # 8000: FastAPI / Django
    # 8080: Nginx / Spring Boot / Contenedores de prueba
    local dev_ports=("3000/tcp" "5173/tcp" "8000/tcp" "8080/tcp")
    echo "ℹ️ Abriendo puertos en zona '$active_zone': ${dev_ports[*]}..."

    for port in "${dev_ports[@]}"; do
        $SUDO firewall-cmd --permanent --zone="$active_zone" --add-port="$port" 2>/dev/null || true
    done

    $SUDO firewall-cmd --reload
    echo "  ✅ Puertos de desarrollo abiertos en zona '$active_zone':"
    $SUDO firewall-cmd --zone="$active_zone" --list-ports
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

# 1. Desactivar y enmascarar UFW
echo "ℹ️ [1/4] Desactivando y enmascarando UFW (Firewalld como único motor)..."
if command -v ufw &>/dev/null; then
    $SUDO ufw disable 2>/dev/null || true
fi
$SUDO systemctl disable --now ufw 2>/dev/null || true
$SUDO systemctl mask ufw 2>/dev/null || true
echo "  ✅ UFW desactivado y enmascarado permanentemente."

# 2. Asegurar e iniciar Firewalld
echo "ℹ️ [2/4] Verificando e instalando Firewalld..."
if ! command -v firewall-cmd &>/dev/null; then
    $SUDO apt-get update
    $SUDO apt-get install -y firewalld
fi
$SUDO systemctl unmask firewalld 2>/dev/null || true
$SUDO systemctl enable --now firewalld

ACTIVE_ZONE=$($SUDO firewall-cmd --get-default-zone 2>/dev/null || echo "public")

# 3. Servicios de red en zona activa
echo "ℹ️ [3/4] Configurando servicios en zona '$ACTIVE_ZONE' y zona 'trusted'..."
# Servicio kdeconnect es el nombre nativo de protocolo en firewalld para GSConnect (1714-1764 TCP/UDP)
$SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=kdeconnect 2>/dev/null || true
$SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=mdns 2>/dev/null || true
$SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=ssh 2>/dev/null || true

# Cockpit si está presente
if command -v cockpit-bridge &>/dev/null || [ -d /etc/cockpit ]; then
    $SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=cockpit 2>/dev/null || true
fi

# Configurar zona 'trusted' para interfaces de Podman Rootless
$SUDO firewall-cmd --permanent --zone=trusted --add-interface=podman+ 2>/dev/null || true
$SUDO firewall-cmd --permanent --zone=trusted --add-interface=cni-podman+ 2>/dev/null || true

# Configurar zona 'trusted' para puente virtual de KVM (virbr0 y virbr+) y NAT Masquerade
$SUDO firewall-cmd --permanent --zone=trusted --add-interface=virbr0 2>/dev/null || true
$SUDO firewall-cmd --permanent --zone=trusted --add-interface=virbr+ 2>/dev/null || true
$SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-masquerade 2>/dev/null || true

# Recargar firewalld
$SUDO firewall-cmd --reload
echo "  ✅ Firewalld configurado (GSConnect, SSH, mDNS, Podman rootless y KVM virbr0)."

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

# Nota sobre Soplos Linux Boro 24.04/26.10 y AppArmor:
# Si herramientas rootless de contenedores requieren crear user namespaces no confinados,
# se puede permitir explícitamente descomentando:
# kernel.apparmor_restrict_unprivileged_userns = 0
EOF

$SUDO sysctl --system > /dev/null 2>&1 || true
echo "  ✅ Parámetros sysctl aplicados."

echo "================================================================="
echo "✅ Seguridad y red de desarrollo configuradas exitosamente en Soplos Linux Boro Workstation."
echo "================================================================="
