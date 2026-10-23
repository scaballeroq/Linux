#!/usr/bin/env bash
# ==============================================================================
# SEGURIDAD Y RED DE DESARROLLO (seguridad.sh) - Ubuntu Linux (GNOME Shell)
# ==============================================================================
# Configuración orientada a estación de trabajo local/hogar para desarrollo:
# • Firewalld obligatorio: Podman Rootless (podman+), KVM/QEMU (virbr0), GSConnect, mDNS, SSH.
# • Desactivación total de UFW (prohibido en el monorepo).
# • Sysctl: IP Forwarding, puertos sin privilegios (>=80), user namespaces para Podman.
# • Entorno de trabajo doméstico: IP y DHCP estables, sin MAC Randomization disruptiva.
# ==============================================================================

set -euo pipefail

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
🛡️ Gestor de Seguridad y Red de Desarrollo - Ubuntu Linux
(Optimizado para desarrollo doméstico: Podman Rootless + KVM/Libvirt + Firewalld)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Configura Firewalld (Podman, KVM, GSConnect) y parámetros
                      sysctl esenciales para desarrollo sin privilegios ni bloqueos.
  --status, -s        Muestra el estado de Firewalld, interfaces de virtualización y sysctl.
  --help, -h          Muestra este mensaje de ayuda.

Características configuradas:
  • Firewalld:        Zona activa con GSConnect (kdeconnect), mDNS, SSH y Cockpit (si está instalado).
  • Podman Rootless:  Interfaces 'podman+' y 'cni-podman+' en zona 'trusted'.
  • KVM / Libvirt:    Puente virtual 'virbr0' en zona 'trusted' con IP Masquerade activo.
  • Sysctl Dev:       IP forwarding (IPv4/IPv6), puertos sin privilegios a partir de 80
                      y user namespaces para Podman sin sudo.
  • UFW Desactivado:  UFW deshabilitado permanentemente para evitar conflictos con Firewalld.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE SEGURIDAD Y RED DE DESARROLLO - UBUNTU (GNOME)"
    echo "================================================================="
    
    # 1. Firewalld
    local fw_status
    fw_status=$(systemctl is-active firewalld 2>/dev/null || echo "inactivo")
    echo "• Firewalld (systemd):        $fw_status"

    local ufw_status
    ufw_status=$(systemctl is-active ufw 2>/dev/null || echo "inactivo")
    echo "• UFW (prohibido):            $ufw_status $([ "$ufw_status" = "inactivo" ] && echo "✅ (correcto)" || echo "⚠️ (debe desactivarse)")"

    if [ "$fw_status" = "active" ]; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        echo "  - Zona por defecto:         $active_zone"
        if [ "$EUID" -eq 0 ] || [ -n "${SUDO:-}" ] && [ -n "${SUDO_USER:-}" ]; then
            echo "  - Servicios en $active_zone:        $($SUDO firewall-cmd --zone="$active_zone" --list-services 2>/dev/null || echo 'ninguno')"
            echo "  - Interfaces en 'trusted':  $($SUDO firewall-cmd --zone=trusted --list-interfaces 2>/dev/null || echo 'ninguna')"
            echo "  - Masquerade ($active_zone):        $($SUDO firewall-cmd --zone="$active_zone" --query-masquerade 2>/dev/null && echo '✅ Activo' || echo '❌ Inactivo')"
        else
            echo "  - Servicios e interfaces:   💡 (Ejecuta con sudo para listar reglas detalladas)"
        fi
    fi

    echo "-----------------------------------------------------------------"
    echo "⚙️ Parámetros de Kernel (Sysctl para Podman & KVM):"
    echo "  • Reenvío IPv4 (ip_forward):                $(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo 'n/a') (Requerido: 1)"
    echo "  • Reenvío IPv6 (forwarding):                $(cat /proc/sys/net/ipv6/conf/all/forwarding 2>/dev/null || echo 'n/a') (Requerido: 1)"
    echo "  • Puerto inicio sin privilegios (Podman):   $(cat /proc/sys/net/ipv4/ip_unprivileged_port_start 2>/dev/null || echo 'n/a') (Recomendado: 80)"
    echo "  • Rango grupos ping (Podman rootless):      $(cat /proc/sys/net/ipv4/ping_group_range 2>/dev/null || echo 'n/a')"
    echo "  • User namespaces (namespaces de usuario):  $(cat /proc/sys/user/max_user_namespaces 2>/dev/null || echo 'n/a')"

    echo "-----------------------------------------------------------------"
    echo "🏠 Servicios y privacidad en red local de hogar:"
    local f2b_status
    f2b_status=$(systemctl is-active fail2ban 2>/dev/null || true)
    [ -z "$f2b_status" ] && f2b_status="inactivo"
    echo "  • Fail2ban:                 $f2b_status (innecesario en LAN doméstica)"
    echo "  • MAC Randomization:        $(if [ -f /etc/NetworkManager/conf.d/00-macrandomize.conf ]; then echo '⚠️ Activo (puede alterar reservas DHCP)'; else echo '✅ Inactivo (IP estática y DHCP estable)'; fi)"
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🛡️ CONFIGURANDO SEGURIDAD Y RED PARA DESARROLLO (UBUNTU LINUX)"
echo "================================================================="

# 1. Desactivar UFW si estuviese activo
echo "ℹ️ [1/4] Desactivando UFW para asegurar Firewalld como único motor..."
if command -v ufw &>/dev/null; then
    $SUDO ufw disable 2>/dev/null || true
    $SUDO systemctl disable --now ufw 2>/dev/null || true
    echo "  ✅ UFW desactivado."
fi

# 2. Asegurar e iniciar Firewalld
echo "ℹ️ [2/4] Instalando y habilitando Firewalld..."
if ! command -v firewall-cmd &>/dev/null; then
    $SUDO apt-get update -qq
    $SUDO apt-get install -y firewalld 2>/dev/null || true
fi
$SUDO systemctl enable --now firewalld

ACTIVE_ZONE=$($SUDO firewall-cmd --get-default-zone 2>/dev/null || echo "public")

# 3. Servicios de red en zona activa
echo "ℹ️ [3/4] Configurando servicios en zona '$ACTIVE_ZONE' y zona 'trusted'..."
# Servicio kdeconnect es el nombre nativo de protocolo en firewalld para GSConnect
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

# Configurar zona 'trusted' para puente virtual de KVM (virbr0) y NAT
$SUDO firewall-cmd --permanent --zone=trusted --add-interface=virbr0 2>/dev/null || true
$SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-masquerade 2>/dev/null || true

# Recargar firewalld
$SUDO firewall-cmd --reload
echo "  ✅ Firewalld configurado (GSConnect, SSH, mDNS, Podman rootless y KVM virbr0)."

# 4. Parámetros de Kernel (sysctl) orientados a Podman Rootless y KVM
echo "ℹ️ [4/4] Aplicando parámetros de Kernel para Podman Rootless y virtualización..."
$SUDO mkdir -p /etc/sysctl.d
cat <<'EOF' | $SUDO tee /etc/sysctl.d/99-development-network.conf > /dev/null
# =============================================================================
# RED Y CONTENEDORES PARA DESARROLLO - UBUNTU LINUX
# =============================================================================

# Reenvío de paquetes para redes de contenedores (Podman) y VMs (KVM/QEMU)
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Permitir a Podman Rootless enlazar puertos HTTP/HTTPS estándar (>=80) sin requerir root
net.ipv4.ip_unprivileged_port_start = 80

# Permitir operaciones ICMP (ping) en contenedores sin privilegios
net.ipv4.ping_group_range = 0 2147483647

# Soporte completo de espacios de nombres de usuario (user namespaces)
kernel.unprivileged_userns_clone = 1
user.max_user_namespaces = 65536
EOF

$SUDO sysctl --system > /dev/null 2>&1 || true
echo "  ✅ Parámetros sysctl aplicados."

echo "================================================================="
echo "✅ Seguridad y red de desarrollo configuradas exitosamente en Ubuntu."
echo "================================================================="
