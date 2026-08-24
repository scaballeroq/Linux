#!/bin/bash
# rust.sh - Rust Installation for Arch Linux (Omarchy)

set -euo pipefail

echo "🦀 Instalando Rustup y dependencias de compilación desde repositorios oficiales..."
sudo pacman -S --needed --noconfirm rustup gcc cmake openssl

echo "ℹ️ Configurando toolchain estable de Rust..."
rustup default stable

# Asegurar que ~/.cargo/env se cargue en ~/.bashrc si aún no está presente
if ! grep -q '\.cargo/env' ~/.bashrc 2>/dev/null; then
    echo "ℹ️ Agregando entorno de Cargo a ~/.bashrc..."
    echo -e '\n# Rust / Cargo Environment\n[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"' >> ~/.bashrc
fi

# Cargar entorno en la sesión actual
if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
fi

echo "🚀 Instalando cargo-binstall (Instalador binario rápido para utilidades de Cargo)..."
if ! command -v cargo-binstall &> /dev/null; then
    curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
fi

echo ""
echo "✅ Rust toolchain estable y cargo-binstall configurados correctamente."

