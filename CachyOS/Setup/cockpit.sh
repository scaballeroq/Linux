#!/bin/bash
# cockpit.sh - Instalación y configuración de Cockpit para administración web en CachyOS

set -euo pipefail

echo "🚀 Configurando Cockpit (Panel de Administración Web)..."

# 1. Instalación de Cockpit y extensiones
echo "ℹ️ Instalando Cockpit y extensiones desde repositorios oficiales..."
sudo pacman -S --needed --noconfirm cockpit cockpit-podman cockpit-machines cockpit-storaged

# 2. Habilitar el servicio vía Socket (Eficiencia)
echo "ℹ️ Habilitando Cockpit Socket..."
sudo systemctl enable --now cockpit.socket

# 3. Configuración del Firewall (UFW si está instalado)
if command -v ufw &> /dev/null; then
    echo "ℹ️ Abriendo puerto 9090 en el Firewall (UFW)..."
    sudo ufw allow 9090/tcp
fi

echo "✅ Cockpit configurado correctamente."
echo "🌐 Puedes acceder desde: https://localhost:9090 (o la IP de tu máquina)"
echo "💡 Usa tu usuario y contraseña de sistema para entrar."
