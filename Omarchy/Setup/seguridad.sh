#!/bin/bash
# ==============================================================================
# SEGURIDAD Y CORTAFUEGOS (seguridad.sh) - Omarchy (Arch Linux + Hyprland)
# Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U)
# Firewalld exclusivo (Prohibido UFW / iptables crudo), KVM y Contenedores
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🛡️ Iniciando configuración de seguridad y Firewalld para Omarchy..."
echo "================================================================="

# 1. Asegurar desinstalación y purga de UFW para evitar colisiones
if pacman -Q ufw &>/dev/null 2>&1; then
    echo "ℹ️ [1/6] UFW detectado: desactivando y desinstalando para usar Firewalld exclusivo..."
    sudo systemctl disable --now ufw 2>/dev/null || true
    sudo pacman -Rns --noconfirm ufw 2>/dev/null || true
    echo "  ✅ UFW desinstalado correctamente."
else
    echo "ℹ️ [1/6] Verificación de cortafuegos: UFW no presente."
fi

# 2. Instalación y habilitación de Firewalld
echo "ℹ️ [2/6] Instalando y asegurando el servicio Firewalld..."
sudo pacman -S --needed --noconfirm firewalld
sudo systemctl enable --now firewalld

# 3. Configuración de zonas y servicios en Firewalld
echo "ℹ️ [3/6] Configurando zonas y reglas de cortafuegos..."

# Establecer la zona por defecto en 'home' (desarrollo seguro en LAN)
sudo firewall-cmd --set-default-zone=home

# Servicios estándar seguros
sudo firewall-cmd --permanent --zone=home --add-service=ssh 2>/dev/null || true
sudo firewall-cmd --permanent --zone=home --add-service=mdns 2>/dev/null || true

# Puertos de desarrollo frecuentes (Vite, Next.js, FastAPI, Cockpit)
sudo firewall-cmd --permanent --zone=home --add-port=3000/tcp comment="Next.js / React dev" 2>/dev/null || true
sudo firewall-cmd --permanent --zone=home --add-port=5173/tcp comment="Vite dev server" 2>/dev/null || true
sudo firewall-cmd --permanent --zone=home --add-port=8000/tcp comment="FastAPI / Uvicorn" 2>/dev/null || true
sudo firewall-cmd --permanent --zone=home --add-port=9090/tcp comment="Cockpit Web Admin" 2>/dev/null || true

# Omarchy Connect / KDE Connect (Integración móvil y sincronización)
sudo firewall-cmd --permanent --zone=home --add-port=1714-1764/tcp 2>/dev/null || true
sudo firewall-cmd --permanent --zone=home --add-port=1714-1764/udp 2>/dev/null || true

# Configuración de zona 'trusted' para interfaces de contenedores (Docker / Podman)
sudo firewall-cmd --permanent --zone=trusted --add-interface=docker0 2>/dev/null || true
sudo firewall-cmd --permanent --zone=trusted --add-interface=podman+ 2>/dev/null || true
sudo firewall-cmd --permanent --zone=trusted --add-interface=cni-podman+ 2>/dev/null || true

# Configuración de zona 'libvirt' para puente de virtualización KVM/QEMU (virbr0)
sudo firewall-cmd --permanent --zone=libvirt --add-interface=virbr0 2>/dev/null || true
sudo firewall-cmd --permanent --zone=libvirt --add-forward 2>/dev/null || true
sudo firewall-cmd --permanent --zone=public --add-masquerade 2>/dev/null || true

# Recargar Firewalld
sudo firewall-cmd --reload
echo "  ✅ Firewalld configurado y recargado."

# 4. Configuración de DNS seguro (Systemd-resolved con DoT)
echo "ℹ️ [4/6] Configurando DNS seguro con DNS-over-TLS (Systemd-resolved)..."
sudo mkdir -p /etc/systemd/resolved.conf.d/
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null
[Resolve]
DNS=9.9.9.9#dns.quad9.net 1.1.1.1#cloudflare-dns.com 2620:fe::fe#dns.quad9.net 2606:4700:4700::1111#cloudflare-dns.com
FallbackDNS=8.8.8.8#dns.google 1.0.0.1#cloudflare-dns.com
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
EOF
sudo systemctl enable --now systemd-resolved 2>/dev/null || true
sudo systemctl restart systemd-resolved 2>/dev/null || true

# 5. Parámetros de Kernel (sysctl) para desarrollo, KVM y contenedores rootless
echo "ℹ️ [5/6] Aplicando parámetros de endurecimiento del Kernel (sysctl)..."
cat <<EOF | sudo tee /etc/sysctl.d/99-security.conf > /dev/null
# Restricciones de kernel y dmesg
kernel.dmesg_restrict=1
kernel.kptr_restrict=1

# Protección contra spoofing y ataques de red
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1

# Reenvío de paquetes para redes de contenedores (Docker/Podman) y VMs (KVM)
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1

# Soporte para puertos sin privilegios (<1024) y User Namespaces para Rootless
net.ipv4.ip_unprivileged_port_start=80
net.ipv4.ping_group_range=0 2147483647
user.max_user_namespaces=65536
EOF
sudo sysctl --system > /dev/null || true

# 6. Permisos de directorios críticos
echo "ℹ️ [6/6] Asegurando permisos de directorios del sistema..."
sudo chmod 700 /root

echo "================================================================="
echo "🔍 Resumen de Seguridad:"
echo "  Firewalld activo:              $(sudo firewall-cmd --state 2>/dev/null || echo 'inactivo')"
echo "  Zona por defecto:              $(sudo firewall-cmd --get-default-zone 2>/dev/null || echo 'desconocida')"
echo "  Puertos sin privilegios (<1024): $(sysctl -n net.ipv4.ip_unprivileged_port_start 2>/dev/null || echo 'N/D')"
echo "  IP Forwarding (VMs/Contenedores): $(sysctl -n net.ipv4.ip_forward 2>/dev/null || echo 'N/D')"
echo "================================================================="
echo "✅ Seguridad y Firewalld para Omarchy (Arch Linux + Hyprland) completados."
echo "================================================================="
