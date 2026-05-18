#!/bin/bash
# cockpit.sh - Instalación y configuración de Cockpit para administración web en Debian

set -e

echo "🚀 Configurando Cockpit (Panel de Administración Web)..."

# 1. Instalación de Cockpit y extensiones útiles
echo "ℹ️ Instalando Cockpit y extensiones..."
sudo apt update
sudo apt install -y cockpit cockpit-podman cockpit-machines cockpit-packagekit cockpit-storaged cockpit-networkmanager

# 2. Habilitar el servicio vía Socket (Eficiencia)
echo "ℹ️ Habilitando Cockpit Socket..."
sudo systemctl enable --now cockpit.socket

# 3. Configuración del Firewall (UFW)
echo "ℹ️ Abriendo puerto 9090 en el Firewall (UFW)..."
sudo ufw allow 9090/tcp

echo "✅ Cockpit configurado correctamente."
echo "🌐 Puedes acceder desde: https://localhost:9090 (o la IP de tu máquina)"
echo "💡 Usa tu usuario y contraseña de sistema para entrar."
