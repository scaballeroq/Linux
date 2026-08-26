#!/bin/bash
# cockpit.sh - Instalación y configuración avanzada de Cockpit para administración web en CachyOS

set -euo pipefail

echo "🚀 Configurando Cockpit (Panel de Administración Web de Alto Rendimiento)..."

# 1. Instalación de Cockpit y extensiones útiles vía Pacman
echo "ℹ️ Instalando Cockpit y suite completa de módulos vía Pacman..."
sudo pacman -S --needed --noconfirm \
    cockpit \
    cockpit-podman \
    cockpit-machines \
    cockpit-packagekit \
    cockpit-storaged \
    udisks2 \
    lm_sensors

# 2. Habilitar el servicio vía Socket On-Demand (Consumo 0 MB RAM en reposo)
echo "ℹ️ Habilitando Cockpit Socket..."
sudo systemctl enable --now cockpit.socket

# 3. Configuración del Firewall UFW con protección anti fuerza bruta
if command -v ufw &> /dev/null; then
    echo "ℹ️ Configurando protección en UFW para puerto 9090..."
    sudo ufw limit 9090/tcp 2>/dev/null || sudo ufw allow 9090/tcp || true
fi

# 4. Obtener IP local para mostrar enlace directo
LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || echo "127.0.0.1")

echo "================================================================="
echo "✅ Panel Web Cockpit configurado e integrado correctamente."
echo "🌐 Acceso local:       https://localhost:9090"
echo "🌐 Acceso en tu red:   https://${LOCAL_IP}:9090"
echo "💡 Inicia sesión con las credenciales de tu usuario de sistema."
echo "================================================================="
