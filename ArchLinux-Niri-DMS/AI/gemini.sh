#!/bin/bash
# gemini.sh - Instalación de Gemini CLI para Arch Linux vía Mise / NPM

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Ejecuta ./ProgrammingLanguages/mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando Google Gemini CLI globalmente vía Mise/NPM..."
mise use --global npm:@google/gemini-cli@latest

echo "✅ Gemini CLI instalado correctamente."
echo "💡 Para usarlo ejecuta: gemini --help"
