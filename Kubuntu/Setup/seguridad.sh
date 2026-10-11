#!/bin/bash
# ==============================================================================
# SEGURIDAD Y RED (Kubuntu) - Entorno de Desarrollo Doméstico y Podman
# ==============================================================================
# Optimizado para:
#   - Portátil de uso doméstico (detrás de router/NAT, red local confiable)
#   - Desarrollo de software (localhost, múltiples puertos, depuración)
#   - Podman Rootless y contenedores (Netavark, bridges, puertos privilegiados)
#   - KDE Plasma 6 (KDE Connect, descubrimiento de red local mDNS/Avahi)
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "Error: Este script requiere privilegios de superusuario."
        exit 1
    fi
else
    SUDO=""
fi

show_help() {
    cat <<EOF
Configuración de Seguridad y Red - Portátil de Desarrollo Kubuntu

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Aplica configuración de seguridad equilibrada para desarrollo y Podman.
  --status, -s           Muestra el estado de UFW, sysctl de Podman y servicios de red.
  --with-fail2ban        Instala y configura Fail2ban (útil solo si expones puertos a Internet).
  --help, -h             Muestra esta ayuda.

Ajustes incluidos:
  1. UFW Firewall:
     - Bloquea accesos externos por defecto (incoming deny, outgoing allow).
     - Tráfico ilimitado en loopback (lo) para desarrollo en localhost.
     - Tráfico permitido en interfaces virtuales de contenedores (podman+, veth+, virbr+, br0).
     - Acceso LAN a servicios locales: KDE Connect (1714-1764), Cockpit (9090), SSH (22), mDNS (5353).
     - Habilita reenvío de paquetes (FORWARD) en UFW para evitar que corte el tráfico de contenedores.
  2. Sysctl para Desarrollo y Podman Rootless:
     - Puertos no privilegiados desde 80 (permite bindear 80/443 sin root con Traefik/Nginx).
     - Ping ICMP habilitado para contenedores sin root (ping_group_range).
     - Reenvío de paquetes IPv4/IPv6 habilitado para puentes de red de Podman/KVM.
     - rp_filter=2 (loose mode) para evitar descarte de paquetes en redes de contenedores.
     - Protección de red (TCP Syncookies, anti-spoofing, no source routing).
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE SEGURIDAD Y RED - KUBUNTU"
    echo "================================================================="
    echo "UFW Firewall:                  $(if command -v ufw &>/dev/null; then $SUDO ufw status | head -n1; else echo 'No instalado'; fi)"
    echo "UFW Forward Policy:            $(grep -E '^DEFAULT_FORWARD_POLICY=' /etc/default/ufw 2>/dev/null || echo 'No configurado')"
    echo "-----------------------------------------------------------------"
    echo "ip_unprivileged_port_start:    $(sysctl -n net.ipv4.ip_unprivileged_port_start 2>/dev/null || echo 'n/a')"
    echo "ping_group_range:              $(sysctl -n net.ipv4.ping_group_range 2>/dev/null || echo 'n/a')"
    echo "ip_forward:                    $(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo 'n/a')"
    echo "rp_filter (all/default):       $(sysctl -n net.ipv4.conf.all.rp_filter 2>/dev/null || echo 'n/a') / $(sysctl -n net.ipv4.conf.default.rp_filter 2>/dev/null || echo 'n/a')"
    echo "-----------------------------------------------------------------"
    echo "Fail2ban:                      $(if systemctl is-active --quiet fail2ban 2>/dev/null; then echo 'Activo'; else echo 'Inactivo / No requerido en LAN'; fi)"
    echo "================================================================="
    if command -v ufw &>/dev/null; then
        echo ""
        echo "Reglas UFW activas:"
        $SUDO ufw status verbose
    fi
}

configure_ufw() {
    echo "ℹ️ [1/3] Configurando Firewall UFW para desarrollo y Podman..."

    if ! command -v ufw &> /dev/null; then
        $SUDO apt update
        $SUDO apt install -y ufw
    fi

    # Políticas por defecto
    $SUDO ufw default deny incoming
    $SUDO ufw default allow outgoing

    # Permitir todo el tráfico en loopback (esencial para desarrollo en localhost)
    $SUDO ufw allow in on lo to any

    # Permitir tráfico en interfaces virtuales de contenedores y virtualización
    # (Evita que el firewall bloquee la comunicación entre contenedores y host)
    $SUDO ufw allow in on podman+ to any comment "Podman bridge networks"
    $SUDO ufw allow in on veth+ to any comment "Container virtual ethernet"
    $SUDO ufw allow in on virbr+ to any comment "Libvirt/KVM virtual bridge"
    $SUDO ufw allow in on br0 to any comment "LAN Bridge"

    # KDE Connect (transferencia de archivos y sincronización con móvil en red local)
    $SUDO ufw allow 1714:1764/udp comment "KDE Connect UDP"
    $SUDO ufw allow 1714:1764/tcp comment "KDE Connect TCP"

    # mDNS / Avahi (descubrimiento de impresoras locales HP, Chromecast, etc.)
    $SUDO ufw allow 5353/udp comment "mDNS/Avahi local discovery"

    # Servicios de gestión local (Cockpit y SSH) accesibles desde subredes privadas LAN
    $SUDO ufw allow from 192.168.0.0/16 to any port 9090 proto tcp comment "Cockpit Web Console LAN"
    $SUDO ufw allow from 10.0.0.0/8 to any port 9090 proto tcp comment "Cockpit Web Console LAN 10.x"
    $SUDO ufw allow from 172.16.0.0/12 to any port 9090 proto tcp comment "Cockpit Web Console LAN 172.x"

    $SUDO ufw allow from 192.168.0.0/16 to any port 22 proto tcp comment "SSH LAN"
    $SUDO ufw allow from 10.0.0.0/8 to any port 22 proto tcp comment "SSH LAN 10.x"
    $SUDO ufw allow from 172.16.0.0/12 to any port 22 proto tcp comment "SSH LAN 172.x"

    # Asegurar que el reenvío de paquetes esté permitido en UFW para evitar cortes en Netavark/Podman
    if [ -f /etc/default/ufw ]; then
        $SUDO sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
    fi

    # Activar UFW
    $SUDO ufw --force enable
    echo "✅ UFW configurado correctamente."
}

configure_sysctl() {
    echo "ℹ️ [2/3] Aplicando sysctl de seguridad y optimizaciones Podman..."

    $SUDO tee /etc/sysctl.d/99-security-podman.conf > /dev/null << 'EOF'
# ==============================================================================
# Seguridad de Red y Optimizaciones de Red para Podman / Kubuntu
# ==============================================================================

# Podman Rootless: Permitir bindear puertos privilegiados (80, 443) sin root
net.ipv4.ip_unprivileged_port_start = 80

# Podman Rootless: Permitir uso de ping dentro de contenedores
net.ipv4.ping_group_range = 0 2147483647

# Reenvío de paquetes para redes puente de contenedores (Netavark/Podman/KVM)
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Loose reverse path filtering (Modo 2: esencial para evitar descarte de tráfico
# asimétrico entre subredes de contenedores y el host)
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2

# Protección contra ataques de denegación de servicio SYN Flood
net.ipv4.tcp_syncookies = 1

# Protección contra redirecciones ICMP no solicitadas (Anti-spoofing)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Restricción moderada de ptrace (Permite depurar con GDB/Delve/IDEs normalmente)
kernel.yama.ptrace_scope = 1
EOF

    # Eliminar archivo duplicado anterior si existía para mantener orden
    if [ -f /etc/sysctl.d/99-podman-rootless.conf ]; then
        $SUDO rm -f /etc/sysctl.d/99-podman-rootless.conf
    fi
    if [ -f /etc/sysctl.d/99-security.conf ]; then
        $SUDO rm -f /etc/sysctl.d/99-security.conf
    fi

    $SUDO sysctl --system > /dev/null || true
    echo "✅ Parámetros Sysctl aplicados correctamente."
}

configure_fail2ban() {
    local ENABLE_F2B="${1:-false}"

    if [ "$ENABLE_F2B" = "true" ]; then
        echo "ℹ️ [3/3] Instalando y configurando Fail2ban (backend systemd)..."
        $SUDO apt update
        $SUDO apt install -y fail2ban

        $SUDO tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = ssh
backend = systemd
maxretry = 3
bantime = 7200
EOF

        $SUDO systemctl enable --now fail2ban 2>/dev/null || true
        echo "✅ Fail2ban configurado con backend systemd."
    else
        echo "ℹ️ [3/3] Fail2ban omitido (no necesario en un portátil doméstico detrás de NAT)."
        echo "    💡 Si expones SSH al exterior mediante redirección de puertos en el router,"
        echo "       puedes ejecutar: $0 --with-fail2ban"
    fi
}

case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --with-fail2ban)
        echo "================================================================="
        echo "APLICANDO SEGURIDAD + PODMAN + FAIL2BAN - KUBUNTU"
        echo "================================================================="
        configure_ufw
        configure_sysctl
        configure_fail2ban "true"
        echo ""
        echo "================================================================="
        echo "Configuración de seguridad completada."
        echo "================================================================="
        ;;
    "")
        echo "================================================================="
        echo "APLICANDO SEGURIDAD Y RED (ENTORNO DEV & PODMAN) - KUBUNTU"
        echo "================================================================="
        configure_ufw
        configure_sysctl
        configure_fail2ban "false"
        echo ""
        echo "================================================================="
        echo "Configuración de seguridad completada."
        echo "Verifica el estado con: $0 --status"
        echo "================================================================="
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
