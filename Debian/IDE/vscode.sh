#!/bin/bash
# vscode.sh - Instalación de Visual Studio Code para Debian

set -e

echo "ℹ️ Instalando Visual Studio Code (Repositorio Oficial)..."

# 1. Instalar dependencias
sudo apt update
sudo apt install -y wget gpg apt-transport-https

# 2. Añadir GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg

# 3. Añadir el repositorio
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg

# 4. Instalar
sudo apt update
sudo apt install -y code

echo "✅ Visual Studio Code instalado correctamente."
