#!/bin/bash
# ==============================================================================
# DNS-OVER-TLS CON SYSTEMD-RESOLVED (seguridad-dot.sh)
# ==============================================================================
# Este script configura DNS cifrado (DNS-over-TLS) para mejorar la privacidad
# en las consultas DNS. No es necesario para la seguridad básica del sistema,
# pero evita que tu ISP vea qué dominios visitas.
#
# ADVERTENCIA: Añade dependencia de terceros (Cloudflare) y puede causar
# problemas si los servidores DNS fallan. Usar bajo criterio.
# ==============================================================================

set -euo pipefail

echo "🚀 Iniciando configuración de DNS cifrado (DNS-over-TLS)..."

# 1. Verificar systemd-resolved
if ! systemctl list-unit-files | grep -q systemd-resolved; then
    echo "   - systemd-resolved no detectado. Procediendo a la instalación..."
    sudo apt update
    sudo apt install -y systemd-resolved
fi

# 2. Crear archivo de configuración para DNS-over-TLS
sudo mkdir -p /etc/systemd/resolved.conf.d/

sudo tee /etc/systemd/resolved.conf.d/dot.conf > /dev/null <<'EOF'
[Resolve]
DNS=1.1.1.1 1.0.0.1
DNSSEC=yes
DNSOverTLS=yes
FallbackDNS=8.8.8.8
EOF

# 3. Habilitar, arrancar y reiniciar el servicio
sudo systemctl enable --now systemd-resolved
sudo systemctl restart systemd-resolved

# 4. Configurar el sistema para usar este nuevo DNS interno
if ! grep -q "127.0.0.53" /etc/resolv.conf 2>/dev/null; then
    echo "   - Redirigiendo el tráfico local al DNS cifrado..."
    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf || echo "⚠️ No se pudo enlazar resolv.conf (Ignorar si estás en WSL o Docker)"
fi

echo "✅ DNS cifrado configurado correctamente."
echo "💡 Nota: Tu tráfico DNS ahora está cifrado vía Cloudflare (1.1.1.1)."
echo "   Puedes verificar que está funcionando correctamente ejecutando: 'resolvectl status'."
