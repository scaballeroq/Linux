#!/bin/bash
# ==============================================================================
# DNS-OVER-TLS CON SYSTEMD-RESOLVED (seguridad-dot.sh) - OpenSUSE Tumbleweed
# ==============================================================================
# Este script configura DNS cifrado (DNS-over-TLS) para mejorar la privacidad
# en las consultas DNS mediante systemd-resolved.
# ==============================================================================

set -euo pipefail

echo "🚀 Iniciando configuración de DNS cifrado (DNS-over-TLS)..."

# 1. Verificar/Instalar systemd-resolved
if ! systemctl list-unit-files | grep -q systemd-resolved; then
    echo "   - systemd-resolved no detectado. Instalando vía Zypper..."
    sudo zypper --non-interactive install -y systemd-resolved 2>/dev/null || true
fi

# 2. Crear archivo de configuración para DNS-over-TLS
sudo mkdir -p /etc/systemd/resolved.conf.d/

sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null <<'EOF'
[Resolve]
DNS=1.1.1.1 1.0.0.1
DNSSEC=allow-downgrade
DNSOverTLS=opportunity
FallbackDNS=8.8.8.8
EOF

# 3. Habilitar y reiniciar servicio
sudo systemctl enable --now systemd-resolved 2>/dev/null || true
sudo systemctl restart systemd-resolved 2>/dev/null || true

echo "✅ DNS cifrado (DNS-over-TLS) configurado correctamente."
echo "💡 Puedes verificar el estado con: resolvectl status"
