#!/bin/bash
# gemini.sh - Gemini CLI Installation

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado."
    exit 1
fi

echo "ℹ️ Instalando Gemini CLI..."
mise use --global npm:@google/gemini-cli@latest

echo "✅ Gemini CLI instalado correctamente."
