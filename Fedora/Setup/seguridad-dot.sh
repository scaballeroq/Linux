#!/bin/bash
# ==============================================================================
# DNS-OVER-TLS CON SYSTEMD-RESOLVED (seguridad-dot.sh) - Fedora 44
# ==============================================================================
# Cifra las consultas DNS en redes Wi-Fi usando Cloudflare y Quad9 con fallback.
# ==============================================================================

set -euo pipefail

echo "🛡️ Configurando DNS cifrado (DNS-over-TLS)..."

sudo mkdir -p /etc/systemd/resolved.conf.d/
cat <<'EOF' | sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net
FallbackDNS=8.8.8.8#dns.google 8.8.4.4#dns.google
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
EOF

sudo systemctl enable --now systemd-resolved 2>/dev/null || true
sudo systemctl restart systemd-resolved 2>/dev/null || true

echo "✅ DNS-over-TLS activado en systemd-resolved."


