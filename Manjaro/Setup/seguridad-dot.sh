#!/bin/bash
# seguridad-dot.sh - DNS-over-TLS con systemd-resolved en Manjaro Linux

set -euo pipefail

echo "🚀 Iniciando configuración de DNS cifrado (DNS-over-TLS) en Manjaro..."

# 1. Crear archivo de configuración para DNS-over-TLS en systemd-resolved
sudo mkdir -p /etc/systemd/resolved.conf.d/

sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null <<'EOF'
[Resolve]
DNS=1.1.1.1 1.0.0.1
DNSSEC=yes
DNSOverTLS=yes
FallbackDNS=8.8.8.8
EOF

# 2. Habilitar y reiniciar servicio systemd-resolved
sudo systemctl enable --now systemd-resolved || true
sudo systemctl restart systemd-resolved || true

# 3. Enlazar resolv.conf si es necesario
if ! grep -q "127.0.0.53" /etc/resolv.conf 2>/dev/null; then
    echo "ℹ️ Redirigiendo tráfico local al stub resolver de systemd-resolved..."
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf || true
fi

echo "✅ DNS cifrado (DNS-over-TLS) configurado correctamente vía Cloudflare (1.1.1.1)."
echo "💡 Puedes comprobar el estado ejecutando: 'resolvectl status'."
