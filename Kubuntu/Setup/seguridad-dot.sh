#!/bin/bash
# ==============================================================================
# DNS-OVER-TLS CON SYSTEMD-RESOLVED (seguridad-dot.sh) - Kubuntu
# ==============================================================================
# Configura DNS cifrado (DNS-over-TLS) para mejorar la privacidad.
# Usa Quad9 (9.9.9.9) como primario y Cloudflare (1.1.1.1) como secundario.

set -euo pipefail

echo "Iniciando configuracion de DNS cifrado (DNS-over-TLS)..."

# 1. Verificar systemd-resolved
if ! systemctl list-unit-files | grep -q systemd-resolved; then
    echo "   - systemd-resolved no detectado. Instalando..."
    sudo apt update
    sudo apt install -y systemd-resolved
fi

# 2. Crear configuracion
sudo mkdir -p /etc/systemd/resolved.conf.d/

sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null <<'EOF'
[Resolve]
DNS=9.9.9.9 1.1.1.1
DNSSEC=yes
DNSOverTLS=yes
FallbackDNS=8.8.8.8
EOF

# 3. Habilitar y reiniciar
sudo systemctl enable --now systemd-resolved
sudo systemctl restart systemd-resolved

# 4. Configurar resolv.conf
if ! grep -q "127.0.0.53" /etc/resolv.conf 2>/dev/null; then
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf || echo "No se pudo enlazar resolv.conf"
fi

echo "DNS cifrado configurado correctamente (Quad9 + Cloudflare)."
echo "Verifica con: resolvectl status"
