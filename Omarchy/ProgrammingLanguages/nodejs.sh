#!/bin/bash
# nodejs.sh - Node.js, PNPM and Yarn Installation via Mise

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Ejecuta ./mise.sh primero."
    exit 1
fi

echo "🟢 Instalando Node.js (LTS), PNPM y Yarn vía Mise..."
mise use --global node@lts
mise use --global pnpm@latest
mise use --global yarn@latest

echo ""
echo "✅ Node.js, npm, pnpm y yarn configurados correctamente vía Mise."

