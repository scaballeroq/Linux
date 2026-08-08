#!/bin/bash
# github-cli.sh - GitHub CLI Installation for CachyOS

set -euo pipefail

echo "ℹ️ Instalando GitHub CLI (gh) vía Pacman..."
sudo pacman -S --needed --noconfirm github-cli

echo "✅ GitHub CLI instalado correctamente."
