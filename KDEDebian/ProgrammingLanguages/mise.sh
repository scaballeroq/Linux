#!/bin/bash
# mise.sh - Instalador de Mise (Gestor de Versiones) para Debian 13

set -euo pipefail

if command -v mise &> /dev/null; then
    echo "✅ Mise ya está instalado."
else
    echo "ℹ️ Instalando dependencias..."
    sudo apt update
    sudo apt install -y curl gpg

    echo "ℹ️ Añadiendo repositorio de Mise..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    # Evitar volver a descargar si la llave ya existe
    if [ ! -f /etc/apt/keyrings/mise-archive-keyring.gpg ]; then
        curl -fsSL https://mise.jdx.dev/gpg-key.pub | sudo gpg --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg
    fi
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list > /dev/null

    echo "ℹ️ Instalando Mise..."
    sudo apt update
    sudo apt install -y mise
fi

# Configuración Modular 
if [ -d "/etc/bashrc.d" ] || [ -d "$HOME/.bashrc.d" ]; then
    mkdir -p ~/.bashrc.d
    cat <<'EOF' > ~/.bashrc.d/mise.sh
# Mise (Language Version Manager)
eval "$(mise activate bash)"
EOF
    echo "✅ Configuración modular de Mise creada en ~/.bashrc.d/mise.sh"
else
    # Si no hay soporte para .bashrc.d, lo añadimos a .bashrc
    if ! grep -q "mise activate bash" ~/.bashrc; then
        echo -e '\n# Mise (Language Version Manager)\neval "$(mise activate bash)"' >> ~/.bashrc
    fi
fi

echo "✅ Mise listo. Reinicia tu terminal o ejecuta: source ~/.bashrc"
