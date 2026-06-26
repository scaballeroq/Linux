#!/bin/bash
# angular.sh - Angular CLI Installation via Mise

set -e

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado."
    exit 1
fi

echo "ℹ️ Instalando Angular CLI globalmente vía Mise/NPM..."
mise use --global npm:@angular/cli@latest

echo "ℹ️ Configurando autocompletado de Angular..."
mkdir -p ~/.bashrc.d
cat <<EOF > ~/.bashrc.d/angular.sh
# Angular CLI completion
if command -v ng &> /dev/null; then
  source <(ng completion script)
fi
EOF

echo "✅ Angular CLI instalado y autocompletado configurado en ~/.bashrc.d/angular.sh"
