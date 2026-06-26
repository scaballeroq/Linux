#!/bin/bash
# gemini.sh - Gemini CLI Installation (via Mise)

set -e

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Ejecuta ./mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando Gemini CLI globalmente vía Mise/NPM..."
mise use --global npm:@google/gemini-cli@latest

echo "✅ Gemini CLI instalado correctamente."
echo "💡 Puedes empezar a usarlo ejecutando: gemini --help"
