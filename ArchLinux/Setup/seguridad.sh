#!/bin/bash
# seguridad.sh - Hardening de seguridad para Arch Linux con GNOME

set -e

echo "🔒 Iniciando configuración de seguridad..."

# 1. Firewalld
echo "ℹ️ Configurando Firewalld..."
sudo pacman -S --noconfirm firewalld
sudo systemctl enable --now firewalld
sudo firewall-cmd --permanent --remove-service=samba-client || true
sudo firewall-cmd --permanent --add-service=gnome-browser || true

# 2. DNS-over-TLS (opportunity mode) via systemd-resolved
echo "ℹ️ Configurando DNS-over-TLS..."
sudo systemctl enable --now systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
if [ -f /etc/systemd/resolved.conf ]; then
    sudo sed -i 's/^#DNSOverTLS=.*/DNSOverTLS=opportunistic/' /etc/systemd/resolved.conf
fi
sudo systemctl restart systemd-resolved

# 3. Wi-Fi MAC randomization via NetworkManager
echo "ℹ️ Configurando randomización de MAC para Wi-Fi..."
sudo mkdir -p /etc/NetworkManager/conf.d
cat << 'EOF' | sudo tee /etc/NetworkManager/conf.d/00-macrandomize.conf
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
EOF
sudo systemctl restart NetworkManager

# 4. Kernel hardening via sysctl
echo "ℹ️ Aplicando hardening del kernel..."
cat << 'EOF' | sudo tee /etc/sysctl.d/99-hardening.conf
# Restringir acceso a logs del kernel
kernel.dmesg_restrict = 1
# Ocultar punteros del kernel
kernel.kptr_restrict = 2
# Activar reverse path filtering
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
# Activar SYN cookies
net.ipv4.tcp_syncookies = 1
# Ignorar ICMP broadcast
net.ipv4.icmp_echo_ignore_broadcasts = 1
# Ignorar ICMP redirect
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
EOF
sudo sysctl --system

# 5. Permisos de /root
echo "ℹ️ Restringiendo permisos de /root..."
sudo chmod 700 /root

echo "✅ Configuración de seguridad completada"
