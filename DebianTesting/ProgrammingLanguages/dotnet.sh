#!/bin/bash
# dotnet.sh - .NET SDK Installation via Mise

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado."
    exit 1
fi

echo "ℹ️ Instalando .NET SDK 10..."
mise use --global dotnet@10

echo "✅ .NET SDK 10 instalado correctamente."
