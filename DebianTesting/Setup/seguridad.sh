#!/bin/bash
# ==============================================================================
# SEGURIDAD Y CORTAFUEGOS PARA PORTÁTIL / DESARROLLADOR (seguridad.sh) - Debian
# ==============================================================================
# Configuración de Firewall (UFW) optimizada para portátil y desarrollo:
#   - Cortafuegos UFW (Bloqueo total de conexiones entrantes no solicitadas)
#   - Navegación y conexiones salientes 100% permitidas
#   - Habilitar Forwarding para Virtualización KVM (virbr0) y Podman/Docker sin romper internet
#   - Ligero y eficiente (sin demonios de servidor como Fail2ban para ahorrar batería y RAM)
# ==============================================================================

set -euo pipefail

echo "🚀 Iniciando configuración del cortafuegos (UFW) para portátil..."

# 1. Instalación de UFW y GUFW (Interfaz gráfica)
echo "ℹ️ Paso 1: Instalando UFW y GUFW vía APT..."
sudo apt update
sudo apt install -y ufw gufw

# 2. Configurar compatibilidad con KVM/QEMU y Podman (DEFAULT_FORWARD_POLICY)
echo "ℹ️ Paso 2: Configurando enrutamiento de red para KVM (virbr0) y Podman/Docker..."
if [ -f /etc/default/ufw ]; then
    sudo sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
fi

# 3. Establecer las políticas de seguridad por defecto
echo "ℹ️ Paso 3: Estableciendo políticas por defecto (Denegar entrada, permitir salida)..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 4. Reglas específicas para KVM y Podman (comunicación interna)
echo "ℹ️ Paso 4: Permitiendo tráfico de interfaces virtuales internas (virbr0)..."
sudo ufw route allow in on virbr0 2>/dev/null || true
sudo ufw allow in on virbr0 2>/dev/null || true

# 5. Activar UFW
echo "ℹ️ Paso 5: Activando UFW Firewall..."
sudo ufw --force enable

echo "================================================================="
echo "✅ Configuración de seguridad para portátil completada con éxito."
echo "🛡️ Tu equipo está protegido contra conexiones entrantes en cualquier red Wi-Fi."
echo "💡 KVM (virbr0) y Podman/Docker disponen de conectividad completa a Internet."
echo "================================================================="
