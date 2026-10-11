#!/bin/bash
# github-cli.sh - GitHub CLI Installation for Arch Linux

set -e

echo "ℹ️ Instalando GitHub CLI (gh)..."
sudo pacman -S --noconfirm gh

echo "✅ GitHub CLI instalado correctamente."
echo "💡 Recuerda ejecutar 'gh auth login' para vincular tu cuenta."
