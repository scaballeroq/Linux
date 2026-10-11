#!/bin/bash
# ==============================================================================
# ENDURECIMIENTO DE SEGURIDAD PARA PORTÁTIL DE DESARROLLO (seguridad.sh)
# Soplos Linux Tyson (Debian Testing + KDE Plasma 6 + Podman + systemd)
# ==============================================================================
# Configuración de Firewall (UFW) y Fail2ban optimizada para:
#   - Seguridad completa en Wi-Fi pública o doméstica (bloqueo por defecto de entrada).
#   - Compatibilidad total con contenedores Podman (Rootless, Netavark, Pasta) y KVM.
#   - Servidores y servicios locales de desarrollo (localhost / 127.0.0.1).
#   - Integración nativa con KDE Connect (comunicación con smartphone).
#   - Descubrimiento local de impresoras (CUPS / mDNS).
#   - Protección anti fuerza bruta para SSH y consola Cockpit.
# ==============================================================================

set -euo pipefail

echo "🚀 Iniciando configuración de seguridad y firewall para Soplos Linux Tyson..."

# 1. Instalación de UFW y Fail2ban
echo "ℹ️ Paso 1: Instalando UFW y Fail2ban vía APT..."
sudo apt update
sudo apt install -y ufw fail2ban

# 2. Configurar enrutamiento de red para contenedores Podman y KVM
echo "ℹ️ Paso 2: Configurando política de reenvío (FORWARD) para Podman y KVM..."
if [ -f /etc/default/ufw ]; then
    sudo sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
fi

# 3. Establecer políticas por defecto
echo "ℹ️ Paso 3: Estableciendo políticas de seguridad por defecto (Denegar entrada, permitir salida)..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 4. Permitir tráfico en Loopback (servidores locales de desarrollo en localhost / 127.0.0.1)
echo "ℹ️ Paso 4: Permitiendo tráfico local en interfaz loopback (lo)..."
sudo ufw allow in on lo to any

# 5. Reglas específicas para contenedores Podman y Virtualización KVM
echo "ℹ️ Paso 5: Habilitando tráfico de redes virtuales para Podman y KVM..."
# Podman (interfaces de puente virtual netavark / cni)
sudo ufw allow in on podman+ 2>/dev/null || true
sudo ufw route allow in on podman+ 2>/dev/null || true
sudo ufw route allow out on podman+ 2>/dev/null || true
sudo ufw allow in on cni-podman+ 2>/dev/null || true

# KVM / Libvirt (virbr0)
sudo ufw allow in on virbr0 2>/dev/null || true
sudo ufw route allow in on virbr0 2>/dev/null || true
sudo ufw route allow out on virbr0 2>/dev/null || true

# 6. Integración con KDE Connect (teléfono móvil en red local)
echo "ℹ️ Paso 6: Configurando puertos para KDE Connect (1714-1764 TCP/UDP)..."
sudo ufw allow 1714:1764/tcp comment 'KDE Connect'
sudo ufw allow 1714:1764/udp comment 'KDE Connect'

# 7. Descubrimiento de red local e impresoras (mDNS y CUPS)
echo "ℹ️ Paso 7: Configurando resolución mDNS y descubrimiento de impresoras..."
sudo ufw allow 5353/udp comment 'mDNS Avahi'
sudo ufw allow 631/udp comment 'CUPS browsing'

# 8. Protección Anti Fuerza Bruta de SSH (Puerto 22) y Cockpit (Puerto 9090)
echo "ℹ️ Paso 8: Aplicando rate-limit anti fuerza bruta para SSH y Cockpit..."
sudo ufw limit ssh comment 'SSH rate-limited'
if command -v cockpit-bridge &> /dev/null || [ -d /etc/cockpit ]; then
    sudo ufw limit 9090/tcp comment 'Cockpit Web Console'
fi

# 9. Activar UFW
echo "ℹ️ Paso 9: Activando cortafuegos UFW..."
sudo ufw --force enable

# 10. Configurar y habilitar Fail2ban con systemd
echo "ℹ️ Paso 10: Habilitando servicio Fail2ban en systemd..."
sudo systemctl enable --now fail2ban.service || true

echo "================================================================="
echo "✅ Seguridad y cortafuegos UFW configurados correctamente."
echo "🛡️ Resumen de protección aplicada:"
echo "   - Entrada externa: Bloqueada por defecto."
echo "   - Desarrollo local: Tráfico en localhost / 127.0.0.1 permitido."
echo "   - Podman y KVM: Enrutamiento e interfaces virtuales activas."
echo "   - KDE Plasma 6: KDE Connect y mDNS habilitados para red local."
echo "   - Acceso remoto: SSH y Cockpit protegidos con limitador de intentos."
echo "   - Monitoreo: Fail2ban activo en segundo plano vía systemd."
echo "================================================================="
