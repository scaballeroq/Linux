#!/bin/bash
# firefox.sh - Instalación y configuración de Mozilla Firefox en Fedora 44

set -euo pipefail

echo "ℹ️ Instalando Mozilla Firefox oficial y paquetes de idioma vía DNF5..."
sudo dnf5 install -y firefox firefox-langpacks

echo "✅ Mozilla Firefox instalado correctamente en Fedora 44."
