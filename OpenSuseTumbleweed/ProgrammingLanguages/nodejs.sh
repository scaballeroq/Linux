#!/bin/bash
# nodejs.sh - Node.js Installation via Mise for OpenSUSE Tumbleweed

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando dependencias de compilación para Node.js (necesarias para node-gyp)..."
sudo zypper --non-interactive install -y curl python3 gcc gcc-c++ make 2>/dev/null || true

echo "ℹ️ Instalando Node.js LTS (22)..."
mise use --global node@22

echo "ℹ️ Configurando Corepack (pnpm/yarn)..."
mise exec node@22 -- corepack enable
mise reshim

echo "✅ Node.js 22, npm y corepack (pnpm/yarn) configurados correctamente."
