#!/bin/bash
# vscode.sh - Instalación de Visual Studio Code para Debian

set -euo pipefail

echo "ℹ️ Instalando Visual Studio Code (Repositorio Oficial)..."

# 1. Instalar dependencias
sudo apt update
sudo apt install -y wget gpg

# 2. Añadir GPG key (solo si no existe)
if [ ! -f /etc/apt/keyrings/packages.microsoft.gpg ]; then
    echo "ℹ️ Descargando clave GPG de Microsoft..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    rm -f packages.microsoft.gpg
fi

# 3. Añadir el repositorio (solo si no existe)
if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
    ARCH=$(dpkg --print-architecture)
    echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
fi

# 4. Instalar
sudo apt update
sudo apt install -y code

echo "✅ Visual Studio Code instalado correctamente."
