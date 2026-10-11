#!/bin/bash
# cockpit.sh - Instalación de Cockpit para Arch Linux

set -e

echo "🌐 Instalando Cockpit Web Admin..."

sudo pacman -S --noconfirm cockpit cockpit-machines

# Extensiones de Cockpit
echo "ℹ️ Instalando extensiones de Cockpit..."
sudo pacman -S --noconfirm cockpit-podman || true
sudo pacman -S --noconfirm cockpit-networkmanager || true
sudo pacman -S --noconfirm cockpit-storaged || true

# Habilitar Cockpit
echo "ℹ️ Habilitando Cockpit..."
sudo systemctl enable --now cockpit.socket

# Abrir puerto en firewalld
echo "ℹ️ Configurando Firewalld para Cockpit..."
sudo firewall-cmd --permanent --add-service=cockpit
sudo firewall-cmd --reload

echo "✅ Cockpit instalado y configurado (https://localhost:9090)"
