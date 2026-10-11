#!/bin/bash
# python.sh - Python and UV Installation via Mise

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Ejecuta ./mise.sh primero."
    exit 1
fi

echo "🐍 Instalando Python y UV (Gestor ultrarrápido de paquetes) vía Mise..."
mise use --global python@latest
mise use --global uv@latest

echo ""
echo "✅ Python y UV instalados correctamente vía Mise."

