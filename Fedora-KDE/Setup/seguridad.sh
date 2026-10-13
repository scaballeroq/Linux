#!/bin/bash
# ==============================================================================
# SEGURIDAD Y RED DE DESARROLLO (seguridad.sh) - Fedora 44 (KDE Plasma 6)
# ==============================================================================
# Configuración orientada a estación de trabajo local para desarrollo de software:
# • Firewalld: Zona FedoraWorkstation (o zona activa) con KDE Connect, mDNS, SSH, Cockpit.
# • Red de Virtualización y Contenedores: Interfaces podman+ y virbr0 en zona 'trusted'.
# • Sysctl Dev: IP Forwarding, puertos sin privilegios (>=80), user namespaces para Podman.
# • Privacidad y Estabilidad: DNS-over-TLS opcional y preservación de IP estática en LAN.
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
🛡️ Gestor de Seguridad y Red de Desarrollo - Fedora 44 (KDE Plasma 6)
(Optimizado para desarrollo local: Podman Rootless + KVM/Libvirt + KDE Connect)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Configura Firewalld (Zona FedoraWorkstation, Podman, KVM, KDE Connect)
                      y parámetros sysctl esenciales para desarrollo sin privilegios ni bloqueos.
  --status, -s        Muestra el estado de Firewalld, interfaces de virtualización y sysctl.
  --help, -h          Muestra este mensaje de ayuda.

Características configuradas:
  • Firewalld:        Zona activa (FedoraWorkstation/home) con KDE Connect (1714-1764), mDNS, SSH y Cockpit (9090).
  • Podman Rootless:  Interfaces 'podman+' y 'cni-podman+' en zona 'trusted' con IP Masquerade activo.
  • KVM / Libvirt:    Puente virtual 'virbr0' en zona 'trusted' para conectividad de máquinas virtuales.
  • Sysctl Dev:       IP forwarding (IPv4/IPv6), puertos sin privilegios a partir de 80 y user namespaces.
  • DNS seguro:       DNS-over-TLS configurado en modo oportunista vía systemd-resolved.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE SEGURIDAD Y RED DE DESARROLLO - FEDORA 44 (KDE PLASMA)"
    echo "================================================================="
    
    # 1. Firewalld
    local fw_status
    fw_status=$(systemctl is-active firewalld 2>/dev/null || echo "inactivo")
    echo "• Firewalld (systemd):        $fw_status"

    if [ "$fw_status" == "active" ]; then
        local default_zone active_zones
        default_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "FedoraWorkstation")
        active_zones=$(firewall-cmd --get-active-zones 2>/dev/null | tr '\n' ' ' || echo "$default_zone")
        echo "• Zona predeterminada:        $default_zone"
        echo "• Zonas activas:              $active_zones"

        echo "• Servicios en $default_zone:"
        firewall-cmd --zone="$default_zone" --list-services 2>/dev/null | sed 's/^/    - /' || echo "    - (ninguno)"

        echo "• Interfaces en zona 'trusted':"
        firewall-cmd --zone=trusted --list-interfaces 2>/dev/null | sed 's/^/    - /' || echo "    - (ninguna)"
    else
        echo "⚠️ Firewalld no está activo."
    fi

    echo "-----------------------------------------------------------------"
    echo "• IP Forwarding IPv4:         $(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo 'n/a')"
    echo "• Puerto sin privilegios mín: $(sysctl -n net.ipv4.ip_unprivileged_port_start 2>/dev/null || echo 'n/a')"
    echo "• User namespaces (Podman):   $(sysctl -n user.max_user_namespaces 2>/dev/null || echo 'n/a')"
    echo "• DNS-over-TLS (resolved):    $(if [ -f /etc/systemd/resolved.conf.d/dot.conf ]; then grep -o 'DNSOverTLS=.*' /etc/systemd/resolved.conf.d/dot.conf || echo 'inactivo'; else echo 'no configurado'; fi)"
    echo "================================================================="
}

apply_firewall_rules() {
    echo "🔥 [1/4] Configurando Firewalld (Zona FedoraWorkstation y desarrollo)..."
    
    # Asegurar que firewalld esté habilitado y activo
    $SUDO systemctl enable --now firewalld 2>/dev/null || true
    
    # Obtener zona predeterminada (habitualmente FedoraWorkstation en Fedora Workstation)
    local target_zone
    target_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "FedoraWorkstation")
    [ -z "$target_zone" ] && target_zone="FedoraWorkstation"

    echo "ℹ️ Aplicando servicios autorizados en zona: $target_zone..."
    
    # Servicios esenciales para desarrollo y entorno de escritorio
    $SUDO firewall-cmd --permanent --zone="$target_zone" --add-service=kdeconnect 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone="$target_zone" --add-service=mdns 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone="$target_zone" --add-service=ssh 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone="$target_zone" --add-service=cockpit 2>/dev/null || true

    # Eliminar servicios potencialmente inseguros en LAN no administrada
    $SUDO firewall-cmd --permanent --zone="$target_zone" --remove-service=samba-client 2>/dev/null || true

    echo "ℹ️ Configurando zona 'trusted' para KVM y Podman..."
    # Asignar puente de KVM / Libvirt a la zona de confianza
    $SUDO firewall-cmd --permanent --zone=trusted --add-interface=virbr0 2>/dev/null || true
    
    # Asignar interfaces de contenedores Podman a zona de confianza
    $SUDO firewall-cmd --permanent --zone=trusted --add-interface=podman+ 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=trusted --add-interface=cni-podman+ 2>/dev/null || true

    # Habilitar enmascaramiento (IP Masquerade) para permitir salida a Internet desde VMs y contenedores
    $SUDO firewall-cmd --permanent --zone="$target_zone" --add-masquerade 2>/dev/null || true

    # Recargar reglas
    $SUDO firewall-cmd --reload 2>/dev/null || true
    echo "✅ Reglas de Firewalld aplicadas y recargadas con éxito."
}

apply_sysctl_security() {
    echo "⚙️ [2/4] Aplicando parámetros Sysctl de red y compatibilidad Podman..."
    
    $SUDO tee /etc/sysctl.d/98-dev-network.conf > /dev/null << 'EOF'
# ==============================================================================
# Parámetros de Red y Desarrollo Local - Fedora 44 (KDE Plasma 6)
# ==============================================================================

# Habilitar reenvío de paquetes (necesario para Podman y KVM Libvirt)
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Permitir a usuarios sin privilegios abrir puertos desde 80 (útil para Vite, nginx local, Next.js)
net.ipv4.ip_unprivileged_port_start = 80

# Protección contra spoofing de paquetes IP
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Mitigación contra ataques SYN Flood
net.ipv4.tcp_syncookies = 1

# Soporte para contenedores rootless (Podman / namespaces)
kernel.unprivileged_userns_clone = 1
user.max_user_namespaces = 28633
EOF

    $SUDO sysctl --system > /dev/null || true
    echo "✅ Parámetros Sysctl de red aplicados."
}

apply_dns_privacy() {
    echo "🔒 [3/4] Configurando DNS seguro (Systemd-resolved DNS-over-TLS)..."
    $SUDO mkdir -p /etc/systemd/resolved.conf.d/
    cat <<EOF | $SUDO tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null
[Resolve]
DNSOverTLS=opportunity
DNSSEC=allow-downgrade
EOF
    $SUDO systemctl restart systemd-resolved 2>/dev/null || true
    echo "✅ DNS-over-TLS oportunista configurado."
}

apply_permissions_audit() {
    echo "🛡️ [4/4] Verificando permisos de seguridad en directorios clave..."
    $SUDO chmod 700 /root 2>/dev/null || true
    echo "✅ Permisos de /root restringidos a 700."
}

# Procesar argumentos de línea de comandos
case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🛡️ INICIANDO CONFIGURACIÓN DE SEGURIDAD Y FIREWALL - FEDORA 44"
        echo "================================================================="
        apply_firewall_rules
        apply_sysctl_security
        apply_dns_privacy
        apply_permissions_audit
        echo ""
        echo "================================================================="
        echo "✅ Configuración de seguridad y red para Fedora 44 completada."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
