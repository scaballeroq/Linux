#!/bin/bash
# nodejs.sh - Node.js Installation via Mise for Manjaro

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando dependencias de compilación para Node.js (node-gyp)..."
sudo pacman -S --needed --noconfirm base-devel curl python gcc make

echo "ℹ️ Instalando Node.js LTS (22) vía Mise..."
mise use --global node@22

echo "ℹ️ Configurando Corepack (pnpm/yarn)..."
mise exec node@22 -- corepack enable
mise reshim

echo "✅ Node.js 22, npm y corepack (pnpm/yarn) configurados correctamente."
