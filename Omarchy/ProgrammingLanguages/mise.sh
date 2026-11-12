#!/bin/bash
# ==============================================================================
# MISE SETUP (mise.sh) - Omarchy (Arch Linux)
# Instalación y configuración de Mise (Language Runtime Manager)
# ==============================================================================

set -euo pipefail

echo "ℹ️ Verificando e instalando Mise..."

if ! command -v mise &>/dev/null; then
    sudo pacman -S --needed --noconfirm mise
fi

echo "ℹ️ Configurando activación de Mise en el entorno Bash..."
mkdir -p "$HOME/.local/bin"

if ! grep -q 'mise activate bash' "$HOME/.bashrc" 2>/dev/null; then
    cat <<'EOF' >> "$HOME/.bashrc"

# Mise (Polyglot Runtime & Tool Version Manager)
eval "$(mise activate bash)"
EOF
    echo "  ✅ 'mise activate bash' añadido a ~/.bashrc."
else
    echo "  ✔️ Mise ya está configurado en ~/.bashrc."
fi

echo "✅ Mise configurado correctamente: $(mise --version)"
