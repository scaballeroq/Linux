#!/bin/bash
# nodejs.sh - Node.js Installation via Mise for Kubuntu

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando dependencias de compilación para Node.js (necesarias para node-gyp)..."
sudo apt update
sudo apt install -y build-essential curl python3 g++ make

echo "ℹ️ Instalando Node.js LTS 22..."
# Mise descarga binarios pre-compilados por defecto, lo cual es muy rápido
mise use --global node@22

echo "ℹ️ Actualizando npm a la última versión..."
# Restaurando workaround preventivo para evitar el error "Cannot find module 'promise-retry'"
# que sigue ocurriendo en npm 10.x al realizar la actualización.
mise exec node@22 -- npm cache clean --force || true
mise exec node@22 -- npm install -g promise-retry || true
mise exec node@22 -- npm install -g npm@latest

echo "✅ Node.js 22 y npm actualizados e instalados correctamente."
