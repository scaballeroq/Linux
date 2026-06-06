#!/bin/bash
# vscode.sh - Instalación de Visual Studio Code (Optimizado para Fedora)

set -e

echo "ℹ️ Configurando repositorio oficial de Microsoft vía DNF5..."

# Importar clave GPG
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

# Crear archivo de repositorio para DNF5
sudo tee /etc/yum.repos.d/vscode.repo << 'EOL'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOL

echo "ℹ️ Instalando Visual Studio Code..."
sudo dnf5 install -y code

echo "✅ VS Code instalado. Sugerencia: En KDE, VS Code detecta automáticamente el file picker nativo."
