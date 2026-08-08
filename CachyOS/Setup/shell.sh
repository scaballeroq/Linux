#!/bin/bash
# shell.sh - Instalación de herramientas modernas de terminal y prompt Starship para CachyOS

set -euo pipefail

echo "ℹ️ Instalando utilidades de terminal modernas vía Pacman..."
sudo pacman -S --needed --noconfirm \
    eza \
    bat \
    fzf \
    zoxide \
    ripgrep \
    fd \
    tealdeer \
    duf \
    dust \
    procs \
    starship

echo "✅ Utilidades de terminal instaladas correctamente."

# Configuración Modular
if [ -d "/etc/bashrc.d" ] || [ -d "$HOME/.bashrc.d" ]; then
    mkdir -p ~/.bashrc.d
    cat <<'EOF' > ~/.bashrc.d/starship.sh
# Starship Prompt Configuration
eval "$(starship init bash)"
EOF
    echo "✅ Configuración modular de Starship creada en ~/.bashrc.d/starship.sh"
else
    if ! grep -q "starship init bash" ~/.bashrc; then
        echo '' >> ~/.bashrc
        echo '# Starship Prompt' >> ~/.bashrc
        echo 'eval "$(starship init bash)"' >> ~/.bashrc
    fi
fi

# Asegurar que existe el directorio de configuración
mkdir -p ~/.config

# Copiar config predeterminada si existe
if [ -f "starship.toml" ]; then
    cp starship.toml ~/.config/starship.toml
elif [ -f "Setup/starship.toml" ]; then
    cp Setup/starship.toml ~/.config/starship.toml
fi

echo "✅ Instalación y configuración completadas. Reinicia la terminal."
