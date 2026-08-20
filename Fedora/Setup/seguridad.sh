#!/bin/bash
# ==============================================================================
# ENDURECIMIENTO DE SEGURIDAD (seguridad.sh) - Fedora 44 Workstation + GNOME
# ==============================================================================
# Configuración de Firewall (Firewalld - Zona FedoraWorkstation), DNS-over-TLS,
# MAC Randomization y Endurecimiento del Kernel sysctl.
# ==============================================================================

set -euo pipefail

echo "🚀 Iniciando el proceso de endurecimiento de seguridad del sistema..."

# 1. Configuración de Firewall (Firewalld)
echo "ℹ️ Configurando Firewalld (Zona FedoraWorkstation)..."
sudo systemctl enable --now firewalld

sudo firewall-cmd --permanent --zone=FedoraWorkstation --remove-service=samba-client 2>/dev/null || true
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=kdeconnect 2>/dev/null || true
sudo firewall-cmd --reload

# 2. DNS-over-TLS (Privacidad)
echo "ℹ️ Configurando DNS seguro (Systemd-resolved)..."
sudo mkdir -p /etc/systemd/resolved.conf.d/
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null
[Resolve]
DNSOverTLS=opportunity
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

# 4. Endurecimiento del Kernel (sysctl)
echo "ℹ️ Aplicando endurecimiento del Kernel (sysctl)..."
cat <<EOF | sudo tee /etc/sysctl.d/99-security.conf > /dev/null
kernel.dmesg_restrict=1
kernel.kptr_restrict=2
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1
EOF
sudo sysctl --system > /dev/null || true

# 5. Auditoría de permisos
echo "ℹ️ Verificando permisos de directorios críticos..."
sudo chmod 700 /root

echo "================================================================="
echo "✅ Configuración de seguridad para Fedora 44 completada."
echo "================================================================="
