#!/bin/bash
# cockpit.sh - Instalación y configuración de Cockpit para administración web

set -e

echo "🚀 Configurando Cockpit (Panel de Administración Web)..."

# 1. Instalación de Cockpit y extensiones útiles
# Incluimos soporte para Podman, Máquinas Virtuales y Paquetes
echo "ℹ️ Instalando Cockpit y extensiones..."
sudo dnf5 install -y cockpit cockpit-podman cockpit-machines cockpit-packagekit cockpit-storaged cockpit-networkmanager

# 2. Habilitar el servicio vía Socket (Eficiencia)
# Al igual que con Libvirt, el socket activará el servicio solo cuando accedas a él.
echo "ℹ️ Habilitando Cockpit Socket..."
sudo systemctl enable --now cockpit.socket

# 3. Configuración del Firewall
# Cockpit usa el puerto 9090 por defecto.
echo "ℹ️ Abriendo puerto 9090 en el Firewall (Zona Work)..."
sudo firewall-cmd --permanent --zone=work --add-service=cockpit
sudo firewall-cmd --reload

echo "✅ Cockpit configurado correctamente."
echo "🌐 Puedes acceder desde: https://localhost:9090 (o la IP de tu máquina)"
echo "💡 Usa tu usuario y contraseña de sistema para entrar."
