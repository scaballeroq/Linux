#!/bin/bash
# go.sh - Instalación de Go (Golang) y configuración de entorno vía Mise

set -euo pipefail

if ! command -v mise &> /dev/null; then
    echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
    exit 1
fi

echo "ℹ️ Instalando Go latest vía Mise..."
mise use --global go@latest
mise reshim

# Configuración Modular de GOPATH y GOBIN
if [ -d "/etc/bashrc.d" ] || [ -d "$HOME/.bashrc.d" ]; then
    mkdir -p ~/.bashrc.d
    cat <<'EOF' > ~/.bashrc.d/go.sh
# Go Environment
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"
EOF
    echo "✅ Configuración modular de Go creada en ~/.bashrc.d/go.sh"
else
    if ! grep -q "GOPATH" ~/.bashrc; then
        echo -e '\n# Go Environment\nexport GOPATH="$HOME/go"\nexport PATH="$GOPATH/bin:$PATH"' >> ~/.bashrc
    fi
fi

echo "✅ Go configurado correctamente."
