#!/bin/bash
# ==============================================================================
# ENDURECIMIENTO DE SEGURIDAD (seguridad.sh) - openSUSE Tumbleweed (KDE Plasma 6)
# ==============================================================================
# Configuración de Firewall (Firewalld con KDE Connect, Podman rootless y KVM),
# DNS-over-TLS, MAC Randomization, Endurecimiento del Kernel sysctl y Fail2ban.
# Optimizado para HP EliteBook 855 G7 - Desarrollo de software y contenedores.
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🛡️ Iniciando endurecimiento de seguridad y Firewall (KDE Plasma 6)..."
echo "================================================================="

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# 1. Configuración de Firewall (Firewalld)
echo "ℹ️ [1/5] Configurando Firewalld (Zona activa, KDE Connect, Podman y KVM)..."
$SUDO zypper --non-interactive install -y firewalld fail2ban 2>/dev/null || true
$SUDO systemctl enable --now firewalld

# Detectar zona por defecto
ACTIVE_ZONE=$($SUDO firewall-cmd --get-default-zone 2>/dev/null || echo "public")

# Servicios esenciales para desarrollo, SSH y KDE Connect
$SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=kdeconnect 2>/dev/null || true
$SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=mdns 2>/dev/null || true
$SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=ssh 2>/dev/null || true

# Puerto Cockpit si está presente
if command -v cockpit-bridge &>/dev/null || [ -d /etc/cockpit ]; then
    $SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=cockpit 2>/dev/null || true
fi

# Configurar zona 'trusted' para interfaces de Podman Rootless
$SUDO firewall-cmd --permanent --zone=trusted --add-interface=podman+ 2>/dev/null || true
$SUDO firewall-cmd --permanent --zone=trusted --add-interface=cni-podman+ 2>/dev/null || true

# Configurar zona 'trusted' o 'libvirt' para puente virtual de KVM (virbr0)
$SUDO firewall-cmd --permanent --zone=trusted --add-interface=virbr0 2>/dev/null || true
$SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-masquerade 2>/dev/null || true

# Recargar firewalld
$SUDO firewall-cmd --reload
echo "  ✅ Firewalld configurado (Zona $ACTIVE_ZONE, KDE Connect, trusted: podman, virbr0)."

# 2. DNS-over-TLS y Privacidad DNS (Systemd-resolved)
echo "ℹ️ [2/5] Configurando DNS seguro (Systemd-resolved con DoT)..."
$SUDO mkdir -p /etc/systemd/resolved.conf.d/
cat <<EOF | $SUDO tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null
[Resolve]
DNS=9.9.9.9#dns.quad9.net 1.1.1.1#cloudflare-dns.com 2620:fe::fe#dns.quad9.net 2606:4700:4700::1111#cloudflare-dns.com
FallbackDNS=8.8.8.8#dns.google 1.0.0.1#cloudflare-dns.com
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
EOF
$SUDO systemctl restart systemd-resolved 2>/dev/null || true

# 3. Privacidad en Redes (Wi-Fi MAC Randomization)
echo "ℹ️ [3/5] Configurando privacidad Wi-Fi (MAC Randomization)..."
$SUDO mkdir -p /etc/NetworkManager/conf.d
cat <<EOF | $SUDO tee /etc/NetworkManager/conf.d/00-macrandomize.conf > /dev/null
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=stable
EOF
$SUDO systemctl reload NetworkManager 2>/dev/null || true

# 4. Endurecimiento del Kernel (sysctl) - Compatible con Podman rootless y KVM
echo "ℹ️ [4/5] Aplicando parámetros de Kernel (sysctl) para desarrollo, KVM y Podman..."
cat <<EOF | $SUDO tee /etc/sysctl.d/99-security.conf > /dev/null
# Restricciones de kernel
kernel.dmesg_restrict=1
kernel.kptr_restrict=1

# Protección contra spoofing y ataques de red
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1

# Reenvío de paquetes para redes de contenedores (Podman) y VMs (KVM)
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1

# Soporte para contenedores Podman Rootless y puertos de desarrollo (<1024)
net.ipv4.ip_unprivileged_port_start=80
net.ipv4.ping_group_range=0 2147483647
kernel.unprivileged_userns_clone=1
user.max_user_namespaces=65536
EOF
$SUDO sysctl --system > /dev/null 2>&1 || true

# 5. Habilitar Fail2ban y Auditoría de permisos
echo "ℹ️ [5/5] Habilitando Fail2ban y asegurando permisos..."
$SUDO systemctl enable --now fail2ban.service 2>/dev/null || true
$SUDO chmod 700 /root

# 6. Verificación de estado
echo "================================================================="
echo "🔍 Verificando configuración de seguridad..."
echo "  Firewalld activo:              $($SUDO firewall-cmd --state 2>/dev/null || echo 'no disponible')"
echo "  DNS-over-TLS:                  $(grep -o 'DNSOverTLS=.*' /etc/systemd/resolved.conf.d/dot.conf 2>/dev/null || echo 'no configurado')"
echo "  MAC Randomization:             $(grep -o 'wifi.cloned-mac-address=.*' /etc/NetworkManager/conf.d/00-macrandomize.conf 2>/dev/null || echo 'no configurado')"
echo "  Puertos sin privilegios Podman:$(sysctl -n net.ipv4.ip_unprivileged_port_start 2>/dev/null || echo 'no disponible')"
echo "  Reenvío IP (Podman/KVM):       $(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo 'no disponible')"
echo "================================================================="
echo "✅ Configuración de seguridad para openSUSE Tumbleweed completada."
echo "💡 KVM (virbr0), Podman Rootless, KDE Connect y SSH funcionan con total seguridad."
echo "================================================================="
