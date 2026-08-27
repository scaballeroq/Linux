#!/bin/bash
# mise.sh - Instalador de Mise (Gestor de Versiones y Runtimes) para Debian Testing / Trixie

set -euo pipefail

if command -v mise &> /dev/null; then
    echo "✅ Mise ya está instalado: $(mise --version)"
else
    echo "ℹ️ Instalando dependencias previas para Mise..."
    sudo apt update
    sudo apt install -y curl gpg

    echo "ℹ️ Configurando repositorio oficial de Mise..."
    sudo install -m 0755 -d /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/mise-archive-keyring.gpg ]; then
        curl -fsSL https://mise.jdx.dev/gpg-key.pub | sudo gpg --dearmor --yes -o /etc/apt/keyrings/mise-archive-keyring.gpg
        sudo chmod 644 /etc/apt/keyrings/mise-archive-keyring.gpg
    fi
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list > /dev/null

    echo "ℹ️ Instalando Mise vía APT..."
    sudo apt update
    sudo apt install -y mise
fi

# Configuración Modular
if [ -d "/etc/bashrc.d" ] || [ -d "$HOME/.bashrc.d" ]; then
    mkdir -p ~/.bashrc.d
    cat <<'EOF' > ~/.bashrc.d/mise.sh
# Mise (Language Version Manager)
export PATH="$HOME/.local/share/mise/shims:$PATH"
eval "$(mise activate bash)"
EOF
    echo "✅ Configuración modular de Mise creada en ~/.bashrc.d/mise.sh"
else
    # Si no hay soporte para .bashrc.d, lo añadimos a .bashrc
    if ! grep -q "mise activate bash" ~/.bashrc; then
        echo -e '\n# Mise (Language Version Manager)\nexport PATH="$HOME/.local/share/mise/shims:$PATH"\neval "$(mise activate bash)"' >> ~/.bashrc
    fi
fi

# Activar en la sesión actual
export PATH="$HOME/.local/share/mise/shims:$PATH"
eval "$(mise activate bash 2>/dev/null || true)"

echo "✅ Mise configurado correctamente."
