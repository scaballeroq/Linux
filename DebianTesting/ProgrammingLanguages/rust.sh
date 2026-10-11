#!/bin/bash
# rust.sh - Rust Installation (Optimized for Debian 13)

set -euo pipefail

echo "ℹ️ Instalando dependencias de compilación para Rust..."
sudo apt update
sudo apt install -y build-essential cmake libssl-dev pkg-config curl

if ! command -v rustup &> /dev/null; then
    echo "ℹ️ Instalando Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
else
    echo "✅ Rust ya está instalado. Actualizando..."
    rustup update
fi

# Configuración Modular
if [ -d "/etc/bashrc.d" ] || [ -d "$HOME/.bashrc.d" ]; then
    mkdir -p ~/.bashrc.d
    cat <<'EOF' > ~/.bashrc.d/rust.sh
# Rust Environment
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
EOF
    echo "✅ Configuración modular de Rust creada en ~/.bashrc.d/rust.sh"
else
    # Si no hay soporte para .bashrc.d, lo añadimos a .bashrc
    if ! grep -q ".cargo/env" ~/.bashrc; then
        echo -e '\n# Rust Environment\nif [ -f "$HOME/.cargo/env" ]; then . "$HOME/.cargo/env"; fi' >> ~/.bashrc
    fi
fi

# Cargar entorno para el resto del script
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

if ! command -v cargo-binstall &> /dev/null; then
    echo "ℹ️ Instalando cargo-binstall (permite instalar binarios de Rust sin compilar)..."
    curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
else
    echo "✅ cargo-binstall ya está instalado."
fi

echo "✅ Rust configurado correctamente."
