#!/bin/bash
# dotnet.sh - .NET SDK Installation via Mise

set -e

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado."
    exit 1
fi

echo "ℹ️ Instalando .NET SDK 10 (LTS)"
mise use --global dotnet@10

echo "✅ .NET SDKs instalados. Nota: Mise maneja automáticamente el PATH de dotnet."
