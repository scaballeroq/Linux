#!/bin/bash
# ==============================================================================
# ENDURECIMIENTO DE SEGURIDAD PARA DESARROLLADOR (seguridad.sh) - Debian 13
# ==============================================================================
# Configuración de Firewall (UFW) compatible con KVM/QEMU, Podman y Wi-Fi Móvil:
#   - Cortafuegos UFW (Bloqueo de entrada, navegación permitida)
#   - Habilitar Forwarding para Virtualización KVM (virbr0) y Podman sin romper internet en MVs
#   - Limitación anti fuerza bruta para SSH (sin hardcodear IPs para funcionar en cualquier Wi-Fi)
#   - Protección automatizada con Fail2ban
# ==============================================================================

set -euo pipefail

echo "🚀 Iniciando el proceso de endurecimiento de seguridad del sistema..."

# 1. Instalación de UFW y Fail2ban
echo "ℹ️ Paso 1: Instalando UFW y Fail2ban vía APT..."
sudo apt update
sudo apt install -y ufw fail2ban

# 2. Configurar compatibilidad con KVM/QEMU y Podman (DEFAULT_FORWARD_POLICY)
echo "ℹ️ Configurando enrutamiento de red para KVM (virbr0) y Podman..."
if [ -f /etc/default/ufw ]; then
    sudo sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
fi

# 3. Establecer las políticas de seguridad por defecto
echo "ℹ️ Estableciendo políticas por defecto (Denegar entrada, permitir salida)..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 4. Reglas específicas para KVM y Podman
echo "ℹ️ Permitiendo tráfico de interfaces virtuales (virbr0)..."
sudo ufw route allow in on virbr0 2>/dev/null || true
sudo ufw allow in on virbr0 2>/dev/null || true

# 5. Protección Anti Fuerza Bruta de SSH (Laptop Friendly - Funciona en cualquier Wi-Fi)
echo "ℹ️ Aplicando rate-limit anti fuerza bruta para SSH (Port 22)..."
sudo ufw limit ssh

# 6. Permitir puerto de Cockpit (9090) con rate-limit
if command -v cockpit-bridge &> /dev/null || [ -d /etc/cockpit ]; then
    echo "ℹ️ Habilitando acceso protegido a la consola Cockpit (Puerto 9090)..."
    sudo ufw limit 9090/tcp
fi

# 7. Activar UFW
echo "ℹ️ Activando UFW Firewall..."
sudo ufw --force enable

# 8. Configurar y habilitar Fail2ban
echo "ℹ️ Habilitando servicio Fail2ban..."
sudo systemctl enable --now fail2ban.service || true

echo "================================================================="
echo "✅ Configuración de seguridad adaptada a Desarrollador completada."
echo "💡 KVM (virbr0), Podman y SSH funcionan con total seguridad en cualquier Wi-Fi."
echo "================================================================="
