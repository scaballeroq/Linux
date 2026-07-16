#!/bin/bash
# rust.sh - Rust Installation for Arch Linux

set -e

echo "ℹ️ Instalando dependencias de compilación para Rust..."
sudo pacman -S --noconfirm gcc cmake openssl

echo "ℹ️ Instalando Rust via rustup..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

mkdir -p ~/.bashrc.d
cat <<EOF > ~/.bashrc.d/rust.sh
# Rust Environment
if [ -f "\$HOME/.cargo/env" ]; then
    . "\$HOME/.cargo/env"
fi
EOF

. "$HOME/.cargo/env"

echo "ℹ️ Instalando utilidades útiles de Cargo..."
curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash

echo "✅ Rust instalado y configurado en ~/.bashrc.d/rust.sh"
