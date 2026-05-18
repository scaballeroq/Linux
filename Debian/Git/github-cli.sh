#!/bin/bash
# github-cli.sh - GitHub CLI Installation for Debian

set -e

echo "ℹ️ Instalando GitHub CLI (gh) desde el repo oficial..."

# 1. Asegurar dependencias
sudo apt update
sudo apt install -y curl gpg

# 2. Añadir GPG key
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

# 3. Añadir el repositorio
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# 4. Instalar
sudo apt update
sudo apt install -y gh

echo "✅ GitHub CLI instalado correctamente."
