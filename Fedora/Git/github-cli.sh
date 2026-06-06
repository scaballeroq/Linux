#!/bin/bash
# github-cli.sh - GitHub CLI Installation (Optimized)

set -e

echo "ℹ️ Instalando GitHub CLI (gh) vía DNF5..."
sudo dnf5 install -y gh

echo "✅ GitHub CLI instalado correctamente."
echo "💡 Recuerda ejecutar 'gh auth login' para vincular tu cuenta."
