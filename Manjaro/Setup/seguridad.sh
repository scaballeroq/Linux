#!/bin/bash
# seguridad.sh - Activación y configuración de Firewall (UFW) en Manjaro Linux
# Nota: UFW/GUFW ya viene instalado por defecto en Manjaro, pero desactivado

set -euo pipefail

echo "🛡️ Activando y configurando Firewall UFW en Manjaro Linux..."

# 1. Configurar reglas por defecto (Bloquear entradas, permitir salidas)
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 2. Habilitar e iniciar servicio UFW
sudo systemctl enable --now ufw.service || true
sudo ufw --force enable

# 3. Estado
echo "================================================================="
echo "✅ Firewall UFW activado y configurado:"
sudo ufw status verbose
echo "================================================================="
