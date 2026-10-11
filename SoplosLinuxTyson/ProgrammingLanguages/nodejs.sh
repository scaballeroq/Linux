#!/usr/bin/env bash
# nodejs.sh - Instalación de la versión LTS de Node.js, npm, pnpm y yarn vía Mise

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando dependencias de compilación para Node.js (necesarias para node-gyp)..."
sudo apt update
sudo apt install -y build-essential curl python3 g++ make

echo "ℹ️ Instalando la última versión LTS de Node.js vía Mise..."
mise use --global node@lts

echo "ℹ️ Instalando gestores de paquetes modernos (pnpm y yarn) vía Mise..."
mise use --global pnpm@latest yarn@latest
mise reshim

echo "✅ Node.js (LTS), npm, pnpm y yarn configurados correctamente con Mise."
