#!/bin/bash
# gemini.sh - Instalación de Gemini CLI vía Mise

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando Gemini CLI (@google/gemini-cli@latest) vía Mise..."
mise use --global npm:@google/gemini-cli@latest
mise reshim

echo "✅ Gemini CLI instalado y configurado correctamente."
