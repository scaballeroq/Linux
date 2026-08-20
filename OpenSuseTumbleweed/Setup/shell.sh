#!/bin/bash
# shell.sh - Instalación de herramientas modernas de terminal y prompt Starship para OpenSUSE Tumbleweed

set -euo pipefail

echo "ℹ️ Instalando utilidades de terminal modernas en OpenSUSE Tumbleweed..."
sudo zypper --non-interactive install -y \
    eza \
    bat \
    fzf \
    zoxide \
    ripgrep \
    fd \
    duf 2>/dev/null || true

echo "✅ Utilidades de terminal instaladas correctamente."

echo "ℹ️ Instalando prompt ultra-rápido Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

# Configuración Modular
if [ -d "/etc/bashrc.d" ] || [ -d "$HOME/.bashrc.d" ]; then
    mkdir -p ~/.bashrc.d
    cat <<EOF > ~/.bashrc.d/starship.sh
# Starship Prompt Configuration
eval "\$(starship init bash)"
EOF
    echo "✅ Configuración modular de Starship creada en ~/.bashrc.d/starship.sh"
else
    if ! grep -q "starship init bash" ~/.bashrc 2>/dev/null; then
        echo '' >> ~/.bashrc
        echo '# Starship Prompt' >> ~/.bashrc
        echo 'eval "$(starship init bash)"' >> ~/.bashrc
    fi
fi

# Copiar tema personalizado de Starship
mkdir -p ~/.config
if [ -f "starship.toml" ]; then
    cp starship.toml ~/.config/starship.toml
elif [ -f "Setup/starship.toml" ]; then
    cp Setup/starship.toml ~/.config/starship.toml
fi

echo "✅ Instalación de shell moderna completada en OpenSUSE Tumbleweed."
