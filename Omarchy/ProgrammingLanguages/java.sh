#!/bin/bash
# java.sh - Instalación de OpenJDK y dependencias para AutoFirma (Arch Linux)

set -euo pipefail

echo "☕ Instalando OpenJDK y dependencias para AutoFirma..."
sudo pacman -S --needed --noconfirm jdk-openjdk nss

echo ""
echo "✅ OpenJDK y dependencias para AutoFirma instalados correctamente."

