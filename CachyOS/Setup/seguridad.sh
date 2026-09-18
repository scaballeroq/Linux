#!/bin/bash
# ==============================================================================
# ENDURECIMIENTO DE SEGURIDAD (seguridad.sh) - CachyOS + GNOME
# Optimizado para desarrollo, GNOME, Firewalld exclusivo, KVM y Podman Rootless
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🛡️ Iniciando endurecimiento de seguridad y Firewall (Firewalld)..."
echo "================================================================="

# 1. Asegurar desinstalación de UFW para evitar conflictos
if pacman -Q ufw &>/dev/null 2>&1; then
    echo "ℹ️ [1/5] UFW detectado: desactivando y desinstalando para usar Firewalld exclusivo..."
    sudo systemctl disable --now ufw 2>/dev/null || true
    sudo pacman -Rns --noconfirm ufw 2>/dev/null || true
    echo "  ✅ UFW desinstalado."
else
    echo "ℹ️ [1/5] Verificación de cortafuegos: UFW no presente."
fi

# 2. Configuración de Firewall (Firewalld exclusivo)
echo "ℹ️ [2/5] Instalando y configurando Firewalld..."
sudo pacman -S --needed --noconfirm firewalld 2>/dev/null || true
sudo systemctl enable --now firewalld

# Establecer la zona por defecto en 'home' (desarrollo seguro y controlado en LAN)
sudo firewall-cmd --set-default-zone=home

# Configurar servicios esenciales en la zona 'home'
sudo firewall-cmd --permanent --zone=home --remove-service=samba-client 2>/dev/null || true
sudo firewall-cmd --permanent --zone=home --remove-service=kdeconnect 2>/dev/null || true
sudo firewall-cmd --permanent --zone=home --add-service=ssh 2>/dev/null || true
sudo firewall-cmd --permanent --zone=home --add-service=mdns 2>/dev/null || true

# Configurar zona 'trusted' para interfaces de red de Podman Rootless
sudo firewall-cmd --permanent --zone=trusted --add-interface=podman+ 2>/dev/null || true
sudo firewall-cmd --permanent --zone=trusted --add-interface=cni-podman+ 2>/dev/null || true

# Configurar zona 'libvirt' para puente virtual de KVM (virbr0)
sudo firewall-cmd --permanent --zone=libvirt --add-interface=virbr0 2>/dev/null || true
sudo firewall-cmd --permanent --zone=libvirt --add-forward 2>/dev/null || true
sudo firewall-cmd --permanent --zone=public --add-masquerade 2>/dev/null || true

# Recargar configuración de Firewalld
sudo firewall-cmd --reload
echo "  ✅ Firewalld configurado (zona por defecto: home, trusted: podman, libvirt: virbr0)."

# 3. DNS-over-TLS y Privacidad DNS (Systemd-resolved)
echo "ℹ️ [3/5] Configurando DNS seguro (Systemd-resolved con DoT)..."
sudo mkdir -p /etc/systemd/resolved.conf.d/
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null
[Resolve]
DNS=9.9.9.9#dns.quad9.net 1.1.1.1#cloudflare-dns.com 2620:fe::fe#dns.quad9.net 2606:4700:4700::1111#cloudflare-dns.com
FallbackDNS=8.8.8.8#dns.google 1.0.0.1#cloudflare-dns.com
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
EOF
sudo systemctl restart systemd-resolved 2>/dev/null || true

# 4. Endurecimiento del Kernel y soporte para Podman Rootless & KVM
echo "ℹ️ [4/5] Aplicando parámetros de Kernel (sysctl) para desarrollo, KVM y Podman..."
cat <<EOF | sudo tee /etc/sysctl.d/99-security.conf > /dev/null
# Restricciones de kernel (equilibrado para desarrollo y depuración)
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
user.max_user_namespaces=65536
EOF
sudo sysctl --system > /dev/null || true

# 5. Auditoría de permisos
echo "ℹ️ [5/5] Asegurando permisos de directorios críticos..."
sudo chmod 700 /root

# Verificación de estado
echo "================================================================="
echo "🔍 Verificando configuración de seguridad..."
echo "  Firewalld activo:              $(sudo firewall-cmd --state 2>/dev/null || echo 'no disponible')"
echo "  Zona por defecto Firewalld:    $(sudo firewall-cmd --get-default-zone 2>/dev/null || echo 'no disponible')"
echo "  DNS-over-TLS:                  $(grep -o 'DNSOverTLS=.*' /etc/systemd/resolved.conf.d/dot.conf 2>/dev/null || echo 'no configurado')"
echo "  Puertos sin privilegios Podman:$(sysctl -n net.ipv4.ip_unprivileged_port_start 2>/dev/null || echo 'no disponible')"
echo "  Reenvío IP (Podman/KVM):       $(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo 'no disponible')"
echo "  User namespaces (Podman):      $(sysctl -n user.max_user_namespaces 2>/dev/null || echo 'no disponible')"
echo "================================================================="
echo "✅ Configuración de seguridad para CachyOS (GNOME + Podman + KVM) completada."
echo "================================================================="
