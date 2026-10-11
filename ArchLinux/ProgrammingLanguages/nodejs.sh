#!/bin/bash
# nodejs.sh - Node.js Installation via Mise

set -e

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando dependencias de compilación..."
sudo pacman -S --noconfirm gcc make gdbm ncurses zlib bzip2 openssl || true

echo "ℹ️ Instalando Node.js LTS (22)..."
mise use --global node@22

echo "ℹ️ Configurando Corepack (pnpm/yarn)..."
mise exec node@22 -- corepack enable
mise reshim

echo "✅ Node.js 22, npm y corepack (pnpm/yarn) configurados correctamente."
