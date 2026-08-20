#!/bin/bash
# github-cli.sh - GitHub CLI Installation for OpenSUSE Tumbleweed

set -euo pipefail

echo "ℹ️ Instalando GitHub CLI (gh) vía Zypper..."

# Instalar gh desde los repositorios oficiales de openSUSE o repositorio RPM oficial de GitHub
if ! sudo zypper --non-interactive install -y gh 2>/dev/null; then
    echo "ℹ️ Añadiendo repositorio oficial RPM de GitHub CLI..."
    sudo zypper --non-interactive addrepo https://cli.github.com/packages/rpm/gh-cli.repo gh-cli 2>/dev/null || true
    sudo zypper --gpg-auto-import-keys refresh gh-cli 2>/dev/null || true
    sudo zypper --non-interactive install -y gh
fi

echo "✅ GitHub CLI (gh) instalado correctamente."
