#!/bin/bash
# vscode.sh - Instalación de Visual Studio Code para Fedora 44 (GNOME)

set -euo pipefail

echo "ℹ️ Configurando repositorio oficial de Microsoft vía DNF5..."

# Importar clave GPG
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

# Crear archivo de repositorio para DNF5
sudo tee /etc/yum.repos.d/vscode.repo << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

echo "ℹ️ Instalando Visual Studio Code..."
sudo dnf5 install -y code

echo "✅ Visual Studio Code instalado correctamente con integración para GNOME."
