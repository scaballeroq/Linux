#!/bin/bash
# seguridad.sh - Configuración de Firewall (UFW) y Endurecimiento Básico en Manjaro Linux

set -euo pipefail

echo "🛡️ Configurando Firewall UFW en Manjaro Linux..."

# 1. Instalación de UFW
sudo pacman -S --needed --noconfirm ufw

# 2. Configurar reglas por defecto (Bloquear entradas, permitir salidas)
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 3. Habilitar e iniciar servicio UFW
sudo systemctl enable --now ufw.service || true
sudo ufw --force enable

# 4. Estado
echo "================================================================="
echo "✅ Firewall UFW activado y configurado:"
sudo ufw status verbose
echo "================================================================="
