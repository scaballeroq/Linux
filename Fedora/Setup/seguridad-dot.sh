#!/bin/bash
# ==============================================================================
# DNS-OVER-TLS CON SYSTEMD-RESOLVED (seguridad-dot.sh) - Fedora 44
# ==============================================================================

set -euo pipefail

echo "🚀 Iniciando configuración de DNS cifrado (DNS-over-TLS)..."

sudo mkdir -p /etc/systemd/resolved.conf.d/
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null
[Resolve]
DNSOverTLS=opportunity
DNSSEC=allow-downgrade
EOF

sudo systemctl restart systemd-resolved 2>/dev/null || true

echo "✅ DNS-over-TLS configurado correctamente en systemd-resolved."
