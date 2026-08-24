#!/bin/bash
# angular.sh - Angular CLI Installation via Mise

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Ejecuta ./mise.sh primero."
    exit 1
fi

echo "🅰️ Instalando Angular CLI globalmente vía Mise/NPM..."
mise use --global npm:@angular/cli@latest

echo "ℹ️ Configurando autocompletado de Angular..."
mkdir -p ~/.local/share/bash-completion/completions
if command -v ng &> /dev/null; then
    ng completion script > ~/.local/share/bash-completion/completions/ng 2>/dev/null || true
fi

echo ""
echo "✅ Angular CLI instalado y autocompletado configurado en ~/.local/share/bash-completion/completions/ng"

