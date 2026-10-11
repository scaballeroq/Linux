#!/bin/bash
# java.sh - Instalación de OpenJDK y dependencias para AutoFirma en Manjaro

set -euo pipefail

echo "ℹ️ Instalando OpenJDK y dependencias (nss / pcsclite)..."
sudo pacman -S --needed --noconfirm jdk-openjdk jre-openjdk nss pcsclite

echo "✅ OpenJDK y dependencias instalados correctamente."
