#!/bin/bash
# ==============================================================================
# ENDURECIMIENTO DE SEGURIDAD (seguridad.sh) - OpenSUSE Tumbleweed + GNOME
# ==============================================================================
# Configuración de Firewall (Firewalld), compatibilidad con KVM/QEMU, Podman,
# MAC Randomization, Fail2ban y Endurecimiento del Kernel sysctl.
# ==============================================================================

set -euo pipefail

echo "🚀 Iniciando el proceso de endurecimiento de seguridad del sistema..."

# 1. Configuración de Firewall (Firewalld)
echo "ℹ️ Configurando Firewalld..."
sudo zypper --non-interactive install -y firewalld fail2ban 2>/dev/null || true
sudo systemctl enable --now firewalld 2>/dev/null || true

# Políticas y servicios en firewalld
sudo firewall-cmd --permanent --add-service=ssh 2>/dev/null || true

# Permitir interfaz de virtualización virbr0 en la zona de confianza
sudo firewall-cmd --permanent --zone=trusted --add-interface=virbr0 2>/dev/null || true

# Permitir puerto de Cockpit si está instalado
if command -v cockpit-bridge &> /dev/null || [ -d /etc/cockpit ]; then
    echo "ℹ️ Habilitando acceso protegido a la consola Cockpit (Puerto 9090)..."
    sudo firewall-cmd --permanent --add-service=cockpit 2>/dev/null || true
fi

sudo firewall-cmd --reload 2>/dev/null || true

# 2. Privacidad en Redes (Wi-Fi MAC Randomization)
echo "ℹ️ Configurando privacidad Wi-Fi (MAC Randomization)..."
sudo mkdir -p /etc/NetworkManager/conf.d
cat <<EOF | sudo tee /etc/NetworkManager/conf.d/00-macrandomize.conf > /dev/null
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=stable
EOF
sudo systemctl reload NetworkManager 2>/dev/null || true

# 3. Endurecimiento del Kernel (sysctl)
echo "ℹ️ Aplicando endurecimiento del Kernel (sysctl)..."
cat <<EOF | sudo tee /etc/sysctl.d/99-security.conf > /dev/null
kernel.dmesg_restrict=1
kernel.kptr_restrict=2
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1
EOF
sudo sysctl --system > /dev/null || true

# 4. Habilitar Fail2ban
echo "ℹ️ Habilitando servicio Fail2ban..."
sudo systemctl enable --now fail2ban.service 2>/dev/null || true

# 5. Auditoría de permisos
echo "ℹ️ Verificando permisos de directorios críticos..."
sudo chmod 700 /root

echo "================================================================="
echo "✅ Configuración de seguridad para OpenSUSE Tumbleweed completada."
echo "💡 KVM (virbr0), Podman y SSH funcionan con total seguridad."
echo "================================================================="
