#!/bin/bash
# dotnet.sh - .NET SDK Installation via Mise

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Ejecuta ./mise.sh primero."
    exit 1
fi

echo "🟣 Instalando .NET SDK (LTS) vía Mise..."
mise use --global dotnet@lts

echo ""
echo "✅ .NET SDK instalado correctamente."
echo "💡 Mise gestiona automáticamente el PATH y shims de dotnet."

