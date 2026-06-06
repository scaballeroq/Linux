#!/bin/bash
# antigravity.sh - Google Antigravity installation (Modernized)

set -e

echo "ℹ️ Configurando repositorio de Google Antigravity..."
sudo tee /etc/yum.repos.d/antigravity.repo << EOL
[antigravity-rpm]
name=Antigravity RPM Repository
baseurl=https://us-central1-yum.pkg.dev/projects/antigravity-auto-updater-dev/antigravity-rpm
enabled=1
gpgcheck=0
repo_gpgcheck=0
EOL

echo "ℹ️ Instalando Antigravity vía DNF5..."
sudo dnf5 install -y antigravity

echo "✅ Google Antigravity instalado correctamente."
