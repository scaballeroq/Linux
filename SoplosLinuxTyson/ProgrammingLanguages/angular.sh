#!/bin/bash
# angular.sh - Instalación de Angular CLI vía Mise

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando Angular CLI (@angular/cli@latest) vía Mise..."
mise use --global npm:@angular/cli@latest
mise reshim

echo "✅ Angular CLI instalado y configurado correctamente."
