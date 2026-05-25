#!/bin/bash
# antigravity.sh - Google Antigravity installation for Kubuntu/Ubuntu

set -e

echo "ℹ️ Configurando repositorio de Google Antigravity para Kubuntu/Ubuntu..."

# 1. Crear directorio para keyrings si no existe
sudo mkdir -p /etc/apt/keyrings

# 2. Descargar y añadir la clave GPG
curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg

# 3. Añadir el repositorio a la lista de fuentes
echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null

# 4. Actualizar e instalar
echo "ℹ️ Instalando Antigravity..."
sudo apt update
sudo apt install -y antigravity

echo "✅ Google Antigravity instalado."
