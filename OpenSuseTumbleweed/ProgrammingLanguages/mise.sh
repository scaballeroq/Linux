#!/bin/bash
# mise.sh - Instalador de Mise (Gestor de Versiones) para OpenSUSE Tumbleweed

set -euo pipefail

if command -v mise &> /dev/null; then
    echo "✅ Mise ya está instalado."
else
    echo "ℹ️ Instalando Mise..."
    # Importar clave y añadir repositorio RPM oficial
    sudo rpm --import https://mise.jdx.dev/gpg-key.pub 2>/dev/null || true
    if ! zypper lr | grep -q "mise"; then
        sudo zypper --non-interactive addrepo https://mise.jdx.dev/rpm mise 2>/dev/null || true
    fi
    sudo zypper --gpg-auto-import-keys refresh mise 2>/dev/null || true
    
    if ! sudo zypper --non-interactive install -y mise 2>/dev/null; then
        echo "ℹ️ Instalando vía instalador oficial..."
        curl -fsSL https://mise.run | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi
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
    if ! grep -q "mise activate bash" ~/.bashrc 2>/dev/null; then
        echo -e '\n# Mise (Language Version Manager)\neval "$(mise activate bash)"' >> ~/.bashrc
    fi
fi

echo "✅ Mise listo. Reinicia tu terminal o ejecuta: source ~/.bashrc"
