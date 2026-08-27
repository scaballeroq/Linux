#!/bin/bash
# cockpit.sh - Instalación y configuración avanzada de Cockpit para administración web en Soplos Linux Tyson (Debian Testing)

set -euo pipefail

echo "🚀 Configurando Cockpit (Panel de Administración Web de Alto Rendimiento) en Soplos Linux Tyson..."

# 1. Instalación de Cockpit y extensiones útiles (Podman, KVM Machines, Storage, Network, PackageKit)
echo "ℹ️ Instalando Cockpit y suite completa de módulos vía APT..."
sudo apt update
sudo apt install -y \
    cockpit \
    cockpit-podman \
    cockpit-machines \
    cockpit-packagekit \
    cockpit-storaged \
    cockpit-networkmanager \
    cockpit-system \
    cockpit-ws \
    udisks2 \
    network-manager \
    lm-sensors

# 2. Habilitar el servicio vía Socket On-Demand con systemd (Consumo 0 MB RAM en reposo)
echo "ℹ️ Habilitando Cockpit Socket en systemd..."
sudo systemctl enable --now cockpit.socket

# 3. Configuración del Firewall UFW con protección anti fuerza bruta
if command -v ufw &> /dev/null; then
    echo "ℹ️ Configurando protección en UFW para puerto 9090..."
    sudo ufw limit 9090/tcp comment 'Cockpit Web Console' 2>/dev/null || sudo ufw allow 9090/tcp || true
fi

# 4. Obtener IP local para mostrar enlace directo
LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || echo "127.0.0.1")

echo "================================================================="
echo "✅ Panel Web Cockpit configurado e integrado con Podman en Soplos Linux Tyson."
echo "🌐 Acceso local:       https://localhost:9090"
echo "🌐 Acceso en tu red:   https://${LOCAL_IP}:9090"
echo "💡 Inicia sesión con las credenciales de tu usuario de sistema."
echo "================================================================="
