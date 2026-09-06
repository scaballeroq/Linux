#!/bin/bash
# ==============================================================================
# ENDURECIMIENTO DE SEGURIDAD (seguridad.sh) - CachyOS + KDE Plasma
# Optimizado para desarrollo, KDE Plasma y compatibilidad total con Podman Rootless
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🛡️ Iniciando endurecimiento de seguridad y Firewall (KDE Plasma)..."
echo "================================================================="

# 1. Configuracion de Firewall (Firewalld)
echo "ℹ️ [1/4] Instalando y configurando Firewalld..."
# CachyOS suele incluir UFW por defecto en su instalador Calamares; lo desactivamos para evitar colisiones
if systemctl is-active --quiet ufw || systemctl is-enabled --quiet ufw 2>/dev/null; then
    echo "ℹ️ Desactivando UFW previo para usar Firewalld como cortafuegos principal..."
    sudo systemctl disable --now ufw 2>/dev/null || true
fi

sudo pacman -S --needed --noconfirm firewalld 2>/dev/null || true
sudo systemctl enable --now firewalld

# Eliminar servicios innecesarios
sudo firewall-cmd --permanent --remove-service=samba-client 2>/dev/null || true

# Servicios esenciales para desarrollo y KDE Plasma
sudo firewall-cmd --permanent --add-service=kdeconnect 2>/dev/null || true
sudo firewall-cmd --permanent --add-service=mdns 2>/dev/null || true
sudo firewall-cmd --permanent --add-service=ssh 2>/dev/null || true

# Recargar firewalld
sudo firewall-cmd --reload

# 2. DNS-over-TLS y Privacidad DNS (Systemd-resolved)
echo "ℹ️ [2/4] Configurando DNS seguro (Systemd-resolved)..."
sudo mkdir -p /etc/systemd/resolved.conf.d/
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null
[Resolve]
DNS=9.9.9.9#dns.quad9.net 1.1.1.1#cloudflare-dns.com 2620:fe::fe#dns.quad9.net 2606:4700:4700::1111#cloudflare-dns.com
FallbackDNS=8.8.8.8#dns.google 1.0.0.1#cloudflare-dns.com
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
EOF
sudo systemctl restart systemd-resolved 2>/dev/null || true

# 3. Endurecimiento del Kernel y soporte total para Podman Rootless
echo "ℹ️ [3/4] Aplicando parametros de Kernel (sysctl) para desarrollo y Podman..."
cat <<EOF | sudo tee /etc/sysctl.d/99-security.conf > /dev/null
# Restricciones de kernel (equilibrado para desarrollo y depuracion)
kernel.dmesg_restrict=1
kernel.kptr_restrict=1

# Proteccion contra spoofing y ataques de red
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1

# Reenvio de paquetes para redes de contenedores (Podman)
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1

# Soporte para contenedores Podman Rootless y puertos de desarrollo (<1024)
net.ipv4.ip_unprivileged_port_start=80
net.ipv4.ping_group_range=0 2147483647
user.max_user_namespaces=65536
EOF
sudo sysctl --system > /dev/null || true

# 4. Auditoria de permisos
echo "ℹ️ [4/4] Asegurando permisos de directorios criticos..."
sudo chmod 700 /root

# 5. Verificacion de estado
echo "================================================================="
echo "🔍 Verificando configuracion de seguridad..."
echo "  Firewalld activo:              $(sudo firewall-cmd --state 2>/dev/null || echo 'no disponible')"
echo "  DNS-over-TLS:                  $(grep -o 'DNSOverTLS=.*' /etc/systemd/resolved.conf.d/dot.conf 2>/dev/null || echo 'no configurado')"
echo "  Puertos sin privilegios Podman:$(sysctl -n net.ipv4.ip_unprivileged_port_start 2>/dev/null || echo 'no disponible')"
echo "  Reenvio IP (Podman Networks):  $(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo 'no disponible')"
echo "  User namespaces (Podman):      $(sysctl -n user.max_user_namespaces 2>/dev/null || echo 'no disponible')"
echo "================================================================="
echo "✅ Configuracion de seguridad para CachyOS (KDE Plasma + Podman) completada."
echo "================================================================="
