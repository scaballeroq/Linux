#!/bin/bash
# shell.sh - Instalación de herramientas modernas de terminal y prompt Starship para Debian Testing

set -euo pipefail

# Detectar codename de Debian
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || echo "trixie")

echo "ℹ️ Instalando utilidades de terminal modernas en Debian Testing ($CODENAME)..."
sudo apt update
sudo apt install -y \
    eza \
    bat \
    fzf \
    zoxide \
    ripgrep \
    fd-find \
    duf 2>/dev/null || sudo apt install -y eza bat fzf zoxide ripgrep fd-find duf tealdeer || true

# En Debian, bat y fd se instalan como batcat y fdfind
echo "ℹ️ Configurando symlinks locales para bat y fd..."
mkdir -p ~/.local/bin
[ -f /usr/bin/batcat ] && ln -sf /usr/bin/batcat ~/.local/bin/bat
[ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind ~/.local/bin/fd

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
    if ! grep -q "starship init bash" ~/.bashrc; then
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

echo "✅ Instalación de shell moderna completada en KDEDebian."
