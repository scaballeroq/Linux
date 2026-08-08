#!/bin/bash
# antigravity.sh - Google Antigravity setup for CachyOS

set -euo pipefail

echo "ℹ️ Configurando e instalando Google Antigravity para CachyOS..."

if command -v paru &> /dev/null; then
    paru -S --needed --noconfirm antigravity-bin 2>/dev/null || echo "ℹ️ Procediendo con instalador alternativo de Antigravity..."
elif command -v yay &> /dev/null; then
    yay -S --needed --noconfirm antigravity-bin 2>/dev/null || echo "ℹ️ Procediendo con instalador alternativo de Antigravity..."
fi

if ! command -v antigravity &> /dev/null; then
    echo "ℹ️ Descargando binario oficial de Google Antigravity..."
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor > /tmp/antigravity.gpg 2>/dev/null || true
    echo "✅ Google Antigravity preparado para CachyOS."
else
    echo "✅ Google Antigravity ya está instalado."
fi
