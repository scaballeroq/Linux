#!/bin/bash
# github-cli.sh - Instalación de GitHub CLI (gh) para Manjaro Linux

set -euo pipefail

echo "ℹ️ Instalando GitHub CLI (gh) vía Pacman..."
sudo pacman -S --needed --noconfirm github-cli

echo "✅ GitHub CLI instalado correctamente:"
gh --version | head -n1 || true
