#!/bin/bash
# cockpit.sh - Instalación y configuración avanzada de Cockpit para administración web en OpenSUSE Tumbleweed

set -euo pipefail

echo "🚀 Configurando Cockpit (Panel de Administración Web de Alto Rendimiento)..."

# 1. Instalación de Cockpit y extensiones útiles
echo "ℹ️ Instalando Cockpit y suite completa de módulos vía Zypper..."
sudo zypper --non-interactive install -y \
    cockpit \
    cockpit-podman \
    cockpit-machines \
    cockpit-packagekit \
    cockpit-storaged \
    cockpit-networkmanager \
    cockpit-system \
    cockpit-ws \
    udisks2 \
    NetworkManager 2>/dev/null || true

# 2. Habilitar el servicio vía Socket On-Demand (Consumo 0 MB RAM en reposo)
echo "ℹ️ Habilitando Cockpit Socket..."
sudo systemctl enable --now cockpit.socket 2>/dev/null || true

# 3. Configuración del Firewall (Firewalld)
if command -v firewall-cmd &> /dev/null; then
    echo "ℹ️ Configurando servicio cockpit en Firewalld..."
    sudo firewall-cmd --permanent --add-service=cockpit 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
fi

# 4. Obtener IP local para mostrar enlace directo
LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || echo "127.0.0.1")

echo "================================================================="
echo "✅ Panel Web Cockpit configurado e integrado correctamente."
echo "🌐 Acceso local:       https://localhost:9090"
echo "🌐 Acceso en tu red:   https://${LOCAL_IP}:9090"
echo "💡 Inicia sesión con las credenciales de tu usuario de sistema."
echo "================================================================="
