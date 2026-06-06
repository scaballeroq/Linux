#!/bin/bash
# shell.sh - Instalación de herramientas modernas de terminal y prompt Starship

set -e

echo "ℹ️ Instalando utilidades de terminal modernas..."
sudo dnf5 install -y --skip-unavailable \
    eza \
    bat \
    fzf \
    zoxide \
    ripgrep \
    fd-find \
    tldr \
    duf \
    dust \
    bottom \
    procs

echo "✅ Utilidades de terminal instaladas correctamente."

echo "ℹ️ Instalando Starship..."
sudo dnf5 copr enable -y atim/starship
sudo dnf5 install -y starship

# Configuración Modular
mkdir -p ~/.bashrc.d

cat <<EOF > ~/.bashrc.d/starship.sh
# Starship Prompt Configuration
eval "\$(starship init bash)"
EOF

echo "✅ Configuración modular de Starship creada en ~/.bashrc.d/starship.sh"

# Asegurar que existe el directorio de configuración
mkdir -p ~/.config

# Copiar config predeterminada si existe
if [ -f "starship.toml" ]; then
    cp starship.toml ~/.config/starship.toml
elif [ -f "Setup/starship.toml" ]; then
    cp Setup/starship.toml ~/.config/starship.toml
fi

echo "✅ Instalación y configuración completadas. Reinicia la terminal."
