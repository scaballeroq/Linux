#!/bin/bash
# mise.sh - Instalador de Mise (Gestor de Versiones) para Manjaro

set -euo pipefail

if command -v mise &> /dev/null; then
    echo "✅ Mise ya está instalado."
else
    echo "ℹ️ Instalando Mise vía Pacman..."
    sudo pacman -S --needed --noconfirm mise || curl https://mise.run | sh
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
    if ! grep -q "mise activate bash" ~/.bashrc; then
        echo -e '\n# Mise (Language Version Manager)\neval "$(mise activate bash)"' >> ~/.bashrc
    fi
fi

echo "✅ Mise listo. Reinicia tu terminal o ejecuta: source ~/.bashrc"
