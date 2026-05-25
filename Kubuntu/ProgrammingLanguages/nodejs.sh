#!/bin/bash
# nodejs.sh - Node.js and pnpm Installation via Mise for Kubuntu

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

echo "ℹ️ Activando Corepack y configurando pnpm..."
# pnpm es un gestor de paquetes más rápido y seguro que npm:
#   - Más rápido: Usa enlaces duros (hard links) a un store central.
#   - Más seguro: Crea un node_modules no plano, impidiendo accesos fantasmas a dependencias.
#   - Corepack es la herramienta nativa de Node.js para gestionar de forma segura pnpm y yarn.
mise exec node@22 -- corepack enable
mise exec node@22 -- corepack prepare pnpm@latest --activate

echo "✅ Node.js 22, npm y pnpm actualizados e instalados correctamente."
