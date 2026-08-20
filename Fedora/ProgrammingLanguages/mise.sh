#!/bin/bash
# mise.sh - Instalador de Mise (Gestor de Versiones) para Fedora 44

set -euo pipefail

if command -v mise &> /dev/null; then
    echo "✅ Mise ya está instalado."
else
    echo "ℹ️ Configurando repositorio oficial de Mise para DNF5..."
    sudo tee /etc/yum.repos.d/mise.repo << 'EOF'
[mise]
name=Mise
baseurl=https://mise.jdx.dev/rpm
enabled=1
gpgcheck=1
gpgkey=https://mise.jdx.dev/gpg-key.pub
EOF

    echo "ℹ️ Instalando Mise vía DNF5..."
    sudo dnf5 check-update --refresh || true
    sudo dnf5 install -y mise
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
