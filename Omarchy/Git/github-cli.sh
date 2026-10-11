#!/bin/bash
# github-cli.sh - Instalación de GitHub CLI para Omarchy (Arch Linux)

set -euo pipefail

echo "🐙 Instalando GitHub CLI..."
sudo pacman -S --needed --noconfirm github-cli

echo ""
echo "✅ GitHub CLI instalado correctamente."
echo "💡 Recuerda ejecutar 'gh auth login' para vincular tu cuenta."

