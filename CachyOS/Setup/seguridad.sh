#!/bin/bash
# ==============================================================================
# ENDURECIMIENTO DE SEGURIDAD (seguridad.sh) - CachyOS + KDE Plasma
# ==============================================================================
# Configuracion de Firewall (Firewalld), DNS-over-TLS,
# MAC Randomization, Endurecimiento del Kernel sysctl y compatibilidad con Podman rootless.
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🛡️ Iniciando endurecimiento de seguridad y Firewall (KDE Plasma)..."
echo "================================================================="

# 1. Configuracion de Firewall (Firewalld)
echo "ℹ️ Instalando y configurando Firewalld..."
sudo pacman -S --needed --noconfirm firewalld 2>/dev/null || true
sudo systemctl enable --now firewalld

# Eliminar servicios innecesarios
sudo firewall-cmd --permanent --remove-service=samba-client 2>/dev/null || true

# Servicios utiles para desarrollo, KDE Plasma y laptop
sudo firewall-cmd --permanent --add-service=kdeconnect 2>/dev/null || true
sudo firewall-cmd --permanent --add-service=mdns 2>/dev/null || true
sudo firewall-cmd --permanent --add-service=ssh 2>/dev/null || true

# Recargar firewalld
sudo firewall-cmd --reload

# 2. DNS-over-TLS (Privacidad)
echo "ℹ️ Configurando DNS seguro (Systemd-resolved)..."
sudo mkdir -p /etc/systemd/resolved.conf.d/
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null
[Resolve]
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
EOF
sudo systemctl restart systemd-resolved 2>/dev/null || true

# 3. Privacidad en Redes (Wi-Fi MAC Randomization)
echo "ℹ️ Configurando privacidad Wi-Fi (MAC Randomization)..."
sudo mkdir -p /etc/NetworkManager/conf.d
cat <<EOF | sudo tee /etc/NetworkManager/conf.d/00-macrandomize.conf > /dev/null
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=stable
EOF
sudo systemctl reload NetworkManager 2>/dev/null || true

# 4. Endurecimiento del Kernel (sysctl) - Compatible con Podman rootless
echo "ℹ️ Aplicando endurecimiento del Kernel (sysctl)..."
cat <<EOF | sudo tee /etc/sysctl.d/99-security.conf > /dev/null
# Restricciones de kernel
kernel.dmesg_restrict=1
kernel.kptr_restrict=2

# Proteccion de red
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1

# Soporte para contenedores rootless (Podman)
kernel.unprivileged_userns_clone=1
user.max_user_namespaces=28633
EOF
sudo sysctl --system > /dev/null || true

# 5. Auditoria de permisos
echo "ℹ️ Verificando permisos de directorios criticos..."
sudo chmod 700 /root

# 6. Verificacion de estado
echo "================================================================="
echo "🔍 Verificando configuracion de seguridad..."
echo "  Firewalld activo: $(sudo firewall-cmd --state 2>/dev/null || echo 'no disponible')"
echo "  DNS-over-TLS: $(grep -o 'DNSOverTLS=.*' /etc/systemd/resolved.conf.d/dot.conf 2>/dev/null || echo 'no configurado')"
echo "  MAC Randomization: $(grep -o 'wifi.cloned-mac-address=.*' /etc/NetworkManager/conf.d/00-macrandomize.conf 2>/dev/null || echo 'no configurado')"
echo "  User namespaces (Podman): $(sysctl -n user.max_user_namespaces 2>/dev/null || echo 'no disponible')"
echo "================================================================="
echo "✅ Configuracion de seguridad para CachyOS (KDE Plasma) completada."
echo "================================================================="
