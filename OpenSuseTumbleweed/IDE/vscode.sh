#!/bin/bash
# vscode.sh - Instalación de Visual Studio Code para OpenSUSE Tumbleweed (GNOME)

set -euo pipefail

echo "ℹ️ Configurando repositorio oficial de Microsoft vía Zypper..."

# Importar clave GPG
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true

# Añadir repositorio de VSCode para Zypper
if ! zypper lr | grep -q "vscode"; then
    sudo zypper --non-interactive addrepo https://packages.microsoft.com/yumrepos/vscode vscode 2>/dev/null || true
fi

# Actualizar e instalar
sudo zypper --gpg-auto-import-keys refresh vscode 2>/dev/null || true

echo "ℹ️ Instalando Visual Studio Code..."
sudo zypper --non-interactive install -y code

echo "✅ Visual Studio Code instalado correctamente con integración para GNOME."
