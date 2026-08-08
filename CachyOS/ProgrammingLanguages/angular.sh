#!/bin/bash
# angular.sh - Angular CLI Installation via Mise

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado."
    exit 1
fi

echo "ℹ️ Instalando Angular CLI latest..."
mise use --global npm:@angular/cli@latest

echo "✅ Angular CLI instalado correctamente."
