#!/bin/bash
# dotnet.sh - Instalación de .NET SDK y dependencias de ejecución vía Mise

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando dependencias del sistema para .NET (ICU, SSL, Zlib)..."
sudo apt update
sudo apt install -y libicu-dev libssl-dev zlib1g curl

echo "ℹ️ Instalando .NET SDK vía Mise..."
mise use --global dotnet@latest
mise reshim

echo "✅ .NET SDK instalado y configurado correctamente."
