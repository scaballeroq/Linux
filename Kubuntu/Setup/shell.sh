#!/bin/bash
# shell.sh - Instalación de herramientas modernas de terminal y prompt Starship para Debian

set -e

echo "ℹ️ Instalando utilidades de terminal modernas..."
sudo apt update
sudo apt install -y \
    eza \
    bat \
    fzf \
    zoxide \
    ripgrep \
    fd-find \
    tealdeer \
    duf \
    du-dust \
    procs

# En Debian, bat y fd tienen nombres diferentes para evitar conflictos
echo "ℹ️ Configurando symlinks para bat y fd..."
mkdir -p ~/.local/bin
[ -f /usr/bin/batcat ] && ln -sf /usr/bin/batcat ~/.local/bin/bat
[ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind ~/.local/bin/fd

echo "✅ Utilidades de terminal instaladas correctamente."

echo "ℹ️ Instalando Starship..."
# El método más fiable en Debian para tener la última versión
curl -sS https://starship.rs/install.sh | sh -s -- -y

# Configuración Modular (Siguiendo el estilo de Fedora)
if [ -d "/etc/bashrc.d" ] || [ -d "$HOME/.bashrc.d" ]; then
    mkdir -p ~/.bashrc.d
    cat <<EOF > ~/.bashrc.d/starship.sh
# Starship Prompt Configuration
eval "\$(starship init bash)"
EOF
    echo "✅ Configuración modular de Starship creada en ~/.bashrc.d/starship.sh"
else
    # Si no hay soporte para .bashrc.d, lo añadimos a .bashrc
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
