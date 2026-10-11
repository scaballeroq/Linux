#!/bin/bash
# gemini.sh - Gemini CLI Installation (Arch Linux)

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Ejecuta ./mise.sh primero."
    exit 1
fi

echo "✨ Instalando Gemini CLI..."
mise use --global npm:@google/gemini-cli@latest

echo ""
echo "✅ Gemini CLI instalado correctamente."

