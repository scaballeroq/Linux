#!/bin/bash
# github-cli.sh - Instalación de GitHub CLI para Fedora 44

set -euo pipefail

echo "ℹ️ Instalando GitHub CLI (gh) vía DNF5..."
sudo dnf5 install -y gh

echo "✅ GitHub CLI instalado correctamente."
echo "💡 Recuerda ejecutar 'gh auth login' para vincular tu cuenta."
