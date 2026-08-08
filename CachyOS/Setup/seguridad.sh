#!/bin/bash
# ==============================================================================
# CONFIGURACIÓN BÁSICA DE SEGURIDAD (CachyOS / Arch) - Entorno de Desarrollo
# ==============================================================================
# Script simplificado para desarrollo local con contenedores (Podman/Docker).
# Configura UFW con reglas esenciales sin interferir con contenedores.
# ==============================================================================

set -euo pipefail

echo "🚀 Configurando seguridad básica del sistema..."

# ==============================================================================
# PASO 1: CONFIGURACIÓN DEL CORTAFUEGOS (FIREWALL - UFW)
# ==============================================================================
echo "ℹ️ Paso 1: Configurando UFW (Uncomplicated Firewall)..."

# 1.1 Comprobar e instalar UFW si no está presente
if ! command -v ufw &> /dev/null; then
    echo "   - UFW no detectado. Procediendo a la instalación vía Pacman..."
    sudo pacman -S --needed --noconfirm ufw
fi

# 1.2 Políticas por defecto: bloquear entrada, permitir salida
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 1.3 Permitir SSH solo desde la red local con protección contra fuerza bruta
sudo ufw limit from 192.168.1.0/24 to any port ssh

# 1.4 Activar el servicio systemd y el Firewall
sudo systemctl enable --now ufw.service
sudo ufw --force enable

# ==============================================================================
# FIN DEL PROCESO
# ==============================================================================
echo "✅ Configuración de seguridad completada."
echo "💡 Verifica las reglas activas con: sudo ufw status verbose"
