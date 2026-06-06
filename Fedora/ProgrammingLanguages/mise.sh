#!/bin/bash
# mise.sh - Instalador de Mise (Gestor de Versiones)

set -e

echo "ℹ️ Instalando dependencias..."
sudo dnf install -y dnf-plugins-core wget curl

echo "ℹ️ Añadiendo repositorio de Mise..."
sudo curl -o /etc/yum.repos.d/mise.repo https://mise.jdx.dev/rpm/mise.repo

echo "ℹ️ Instalando Mise..."
sudo dnf5 install -y mise

# Configuración Modular
mkdir -p ~/.bashrc.d

cat <<EOF > ~/.bashrc.d/mise.sh
# Mise (Language Version Manager)
eval "\$(mise activate bash)"
EOF

echo "✅ Mise configurado modularmente en ~/.bashrc.d/mise.sh"
