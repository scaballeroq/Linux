#!/bin/bash
# meld.sh - Instalación de Meld para Debian

set -e

echo "ℹ️ Instalando Meld..."
sudo apt update
sudo apt install -y meld
echo "✅ Meld instalado."
