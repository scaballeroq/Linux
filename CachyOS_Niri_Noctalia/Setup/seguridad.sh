#!/bin/bash
# ==============================================================================
# seguridad.sh - Configuración de Seguridad y Firewall (Firewalld) para CachyOS
# Perfil: Portátil de desarrollo doméstico (LAN segura) + QEMU/KVM + Podman
# ==============================================================================
#
# Uso:
#   ./seguridad.sh               -> Aplica la configuración completa de seguridad
#   ./seguridad.sh --status, -s  -> Muestra el diagnóstico de Firewalld, zonas y sysctl
#   ./seguridad.sh --help, -h    -> Muestra la ayuda interactiva
#
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

show_help() {
    cat <<EOF
🛡️ Gestor de Seguridad y Firewalld - CachyOS (Niri + Noctalia)
Perfil: Portátil de desarrollo en red local (QEMU/KVM + Podman Rootless)

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Aplica la configuración completa (Firewalld, QEMU, Podman, Sysctl, DNS, Systemd).
  --status, -s           Muestra el diagnóstico actual de Firewalld, zonas activas, puertos y sysctl.
  --help, -h             Muestra este mensaje de ayuda.

Características de este perfil (Portátil en casa):
  • Firewalld:           Zona predeterminada 'home' optimizada para LAN doméstica.
  • Virtualización KVM:  Puente virbr0 asignado a zona 'libvirt' con reenvío NAT automático.
  • Podman Rootless:     Puentes podman+ asignados a zona 'trusted' para interconexión limpia.
  • Puertos de Desarrollo: Abiertos en LAN para probar web apps desde móvil/tablet (3000, 5173, 8000, 8080...).
  • Kernel Sysctl:       rp_filter=2 (Loose) para puentes KVM/Podman, TCP BBR, Inotify ampliado (1M),
                         ip_forward=1, ip_unprivileged_port_start=80 y dmesg sin fricción.
  • Systemd & Tapa:      Timeouts de parada de 10s y prevención de suspensión con cargador/docking.
  • DNS Local y Privacidad: Systemd-resolved con soporte mDNS (.local), DNS-over-TLS oportunista
                         respetando la resolución local del router doméstico.
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DE SEGURIDAD Y FIREWALL (CachyOS)"
    echo "================================================================="

    echo -n "• Estado de Firewalld:          "
    if command -v firewall-cmd &>/dev/null && firewall-cmd --state &>/dev/null; then
        echo "✅ Activo ($(firewall-cmd --version 2>/dev/null || echo 'en ejecución'))"
    else
        echo "❌ Inactivo o no instalado"
    fi

    echo -n "• Estado de UFW (obsoleto):      "
    if pacman -Q ufw &>/dev/null || systemctl is-active --quiet ufw 2>/dev/null; then
        echo "⚠️ Presente o activo (se recomienda desinstalar)"
    else
        echo "✅ No instalado (limpio)"
    fi

    if command -v firewall-cmd &>/dev/null && firewall-cmd --state &>/dev/null; then
        echo "• Zona por defecto:             $(firewall-cmd --get-default-zone 2>/dev/null || echo 'desconocida')"
        echo "• Zonas activas con interfaces:"
        firewall-cmd --get-active-zones 2>/dev/null | sed 's/^/    /' || echo "    (Ninguna)"
        echo "• Servicios en zona 'home':     $(firewall-cmd --zone=home --list-services 2>/dev/null || echo 'n/a')"
        echo "• Puertos dev en zona 'home':   $(firewall-cmd --zone=home --list-ports 2>/dev/null || echo 'n/a')"
        echo "• Masquerade (NAT saliente):    $(firewall-cmd --zone=home --query-masquerade >/dev/null 2>&1 && echo '✅ Activo en home' || echo '❌ Inactivo')"
        echo "• Interfaz virbr0 en libvirt:   $(firewall-cmd --zone=libvirt --list-interfaces 2>/dev/null | grep -q 'virbr0' && echo '✅ Asignada' || echo 'ℹ️ Pendiente de inicio de red KVM')"
        echo "• Interfaces Podman en trusted: $(firewall-cmd --zone=trusted --list-interfaces 2>/dev/null || echo 'n/a')"
    fi

    echo ""
    echo "• Parámetros de Kernel (Sysctl):"
    echo "  - Reenvío IPv4 (ip_forward):   $(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo 'n/a') (esperado: 1)"
    echo "  - Reenvío IPv6:                $(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null || echo 'n/a') (esperado: 1)"
    echo "  - Modo rp_filter (KVM/Podman): $(sysctl -n net.ipv4.conf.all.rp_filter 2>/dev/null || echo 'n/a') (esperado: 2 - Loose)"
    echo "  - Puertos sin privilegios:     $(sysctl -n net.ipv4.ip_unprivileged_port_start 2>/dev/null || echo 'n/a') (esperado: 80)"
    echo "  - User namespaces:             $(sysctl -n user.max_user_namespaces 2>/dev/null || echo 'n/a') (esperado: >=65536)"
    echo "  - Restricción dmesg (debug):   $(sysctl -n kernel.dmesg_restrict 2>/dev/null || echo 'n/a') (esperado: 0)"
    echo "  - Control congestión TCP:      $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'n/a') (esperado: bbr)"
    echo "  - Inotify max_user_watches:    $(sysctl -n fs.inotify.max_user_watches 2>/dev/null || echo 'n/a') (esperado: >=1048576)"

    echo ""
    echo "• Resolución DNS (systemd-resolved):"
    echo "  - DNS-over-TLS:                $(grep -o 'DNSOverTLS=.*' /etc/systemd/resolved.conf.d/dot.conf 2>/dev/null || echo 'no configurado')"
    echo "  - MulticastDNS (.local LAN):   $(grep -o 'MulticastDNS=.*' /etc/systemd/resolved.conf.d/dot.conf 2>/dev/null || echo 'no configurado')"
    echo "================================================================="
}

apply_security() {
    echo "================================================================="
    echo "🛡️ Configurando Seguridad, Firewalld, QEMU/KVM y Podman (CachyOS)"
    echo "================================================================="

    # 1. Migración limpia de UFW a Firewalld
    echo "ℹ️ [1/6] Asegurando Firewalld como motor de cortafuegos principal..."
    if pacman -Q ufw &>/dev/null || command -v ufw &>/dev/null; then
        echo "  🗑️ Desinstalando UFW y ufw-extras para evitar colisiones con Firewalld..."
        $SUDO ufw disable 2>/dev/null || true
        $SUDO systemctl disable --now ufw 2>/dev/null || true
        $SUDO pacman -Rsn --noconfirm ufw ufw-extras 2>/dev/null || $SUDO systemctl mask ufw 2>/dev/null || true
        echo "  ✅ UFW eliminado del sistema."
    fi

    # Instalar Firewalld e iptables si no están presentes
    $SUDO pacman -S --needed --noconfirm firewalld iptables
    $SUDO systemctl enable --now firewalld

    # 2. Configuración de Firewalld para el entorno de desarrollo doméstico
    echo "ℹ️ [2/6] Configurando zonas y servicios en Firewalld..."
    # Establecer 'home' como zona predeterminada (ideal para portátiles en LAN doméstica)
    $SUDO firewall-cmd --set-default-zone=home

    # Servicios esenciales en la zona 'home'
    $SUDO firewall-cmd --permanent --zone=home --add-service=ssh 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=home --add-service=mdns 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=home --add-service=cockpit 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=home --add-service=http 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=home --add-service=https 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=home --add-service=samba-client 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=home --add-service=kdeconnect 2>/dev/null || true

    # Puertos para servidores de desarrollo y pruebas locales (móvil, tablet, otros equipos en LAN)
    $SUDO firewall-cmd --permanent --zone=home --add-port=3000-3010/tcp 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=home --add-port=5173-5175/tcp 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=home --add-port=8000-8080/tcp 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=home --add-port=8501/tcp 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=home --add-port=53317/tcp 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=home --add-port=53317/udp 2>/dev/null || true

    # Habilitar NAT / Masquerade para que VMs y contenedores puedan salir a internet
    $SUDO firewall-cmd --permanent --zone=home --add-masquerade 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=public --add-masquerade 2>/dev/null || true

    # 3. Integración con Virtualización (QEMU/KVM) y Podman
    echo "ℹ️ [3/6] Integrando puentes virtuales de QEMU/KVM y redes Podman..."

    # QEMU / KVM (Libvirt)
    # Habilitar forward y asignar virbr0 a la zona 'libvirt'
    $SUDO firewall-cmd --permanent --zone=libvirt --add-forward 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=libvirt --add-interface=virbr0 2>/dev/null || true

    # Configurar backend de libvirt a iptables (iptables-nft) para máxima compatibilidad con Firewalld
    if [ -f /etc/libvirt/network.conf ]; then
        $SUDO sed -i 's/^#*firewall_backend = .*/firewall_backend = "iptables"/' /etc/libvirt/network.conf 2>/dev/null || true
    fi

    # Podman (Rootless y puentes de contenedores)
    # Asignar podman0 y podman+ a la zona 'trusted' para evitar bloqueos internos entre contenedores
    $SUDO firewall-cmd --permanent --zone=trusted --add-interface=podman0 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=trusted --add-interface=podman+ 2>/dev/null || true
    $SUDO firewall-cmd --permanent --zone=trusted --add-forward 2>/dev/null || true

    # Recargar Firewalld para aplicar cambios
    $SUDO firewall-cmd --reload >/dev/null

    # 4. Parámetros de Kernel (Sysctl) optimizados para Desarrollo, KVM y Podman
    echo "ℹ️ [4/6] Aplicando parámetros de Kernel (Sysctl) en /etc/sysctl.d/99-security.conf..."
    $SUDO mkdir -p /etc/sysctl.d
    cat <<EOF | $SUDO tee /etc/sysctl.d/99-security.conf > /dev/null
# ==============================================================================
# 99-security.conf - Optimización de Seguridad, Red y Virtualización (CachyOS)
# Perfil: Portátil de desarrollo doméstico (QEMU/KVM + Podman Rootless)
# ==============================================================================

# 1. Depuración y observabilidad del sistema sin fricción
# Permite revisar dmesg sin requerir sudo en un portátil personal
kernel.dmesg_restrict = 0
kernel.kptr_restrict = 1

# 2. Protección de red y enrutamiento simétrico para puentes virtuales
# rp_filter=2 (Loose Mode): Evita caídas silenciosas de paquetes en puentes
# virtuales (virbr0 de Libvirt y podman0 de Podman) protegiendo contra spoofing
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
net.ipv4.tcp_syncookies = 1

# 3. Reenvío IP esencial para NAT en VMs (QEMU) y Contenedores (Podman)
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# 4. Soporte para Podman Rootless y enlace a puertos privilegiados (<1024)
# Permite enlazar puertos 80/443 (Nginx, Traefik, etc.) sin ser root
net.ipv4.ip_unprivileged_port_start = 80
net.ipv4.ping_group_range = 0 2147483647
user.max_user_namespaces = 65536

# 5. Rendimiento de red y desarrollo (BBR, inotify para IDEs y Webpack)
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 8192
vm.max_map_count = 16777216
net.core.default_qdisc = fq_pie
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.somaxconn = 4096
EOF

    $SUDO sysctl --system > /dev/null || true

    # 5. DNS Seguro, mDNS y Red Doméstica (Systemd-resolved)
    echo "ℹ️ [5/6] Configurando DNS seguro y resolución local en systemd-resolved..."
    $SUDO mkdir -p /etc/systemd/resolved.conf.d/
    cat <<EOF | $SUDO tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null
[Resolve]
# Servidores seguros de respaldo con DNS-over-TLS si el DNS doméstico no responde
FallbackDNS=9.9.9.9#dns.quad9.net 1.1.1.1#cloudflare-dns.com 8.8.8.8#dns.google
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
MulticastDNS=yes
LLMNR=yes
EOF

    $SUDO systemctl restart systemd-resolved 2>/dev/null || true

    # 6. Timeouts de parada y comportamiento de tapa en Systemd
    echo "ℹ️ [6/6] Optimizando timeouts de parada de Systemd y comportamiento de tapa..."
    $SUDO mkdir -p /etc/systemd/system.conf.d /etc/systemd/user.conf.d /etc/systemd/logind.conf.d

    cat << 'EOF' | $SUDO tee /etc/systemd/system.conf.d/99-timeout.conf > /dev/null
[Manager]
DefaultTimeoutStopSec=10s
DefaultTimeoutAbortSec=10s
EOF

    cat << 'EOF' | $SUDO tee /etc/systemd/user.conf.d/99-timeout.conf > /dev/null
[Manager]
DefaultTimeoutStopSec=10s
DefaultTimeoutAbortSec=10s
EOF

    # Comportamiento de tapa (evita suspender si está conectado a la corriente o pantallas externas)
    cat << 'EOF' | $SUDO tee /etc/systemd/logind.conf.d/99-lid-behavior.conf > /dev/null
[Login]
HandleLidSwitchDocked=ignore
HandleLidSwitchExternalPower=ignore
EOF

    # Asegurar permisos de directorios críticos
    $SUDO chmod 700 /root

    echo "================================================================="
    echo "✅ Optimización de seguridad, red y Firewalld completada con éxito."
    echo "================================================================="
    check_status
}

case "${1:-}" in
    --status|-s|status)
        check_status
        ;;
    --help|-h|help)
        show_help
        ;;
    "")
        apply_security
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        echo "Usa '$0 --help' para ver las opciones disponibles."
        exit 1
        ;;
esac
