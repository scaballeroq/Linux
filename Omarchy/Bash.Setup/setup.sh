#!/bin/bash
# setup.sh - Integración automática de módulos Bash.Setup en ~/.bashrc para Omarchy

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🐚 Configurando integración de Bash.Setup en ~/.bashrc..."

if ! grep -q 'Bash.Setup' ~/.bashrc 2>/dev/null; then
    cat <<EOF >> ~/.bashrc

# =============================================================================
# Cargar módulos personalizados de Bash.Setup
# =============================================================================
BASH_SETUP_DIR="$SCRIPT_DIR"
if [ -d "\$BASH_SETUP_DIR" ]; then
    for f in "\$BASH_SETUP_DIR"/*.sh; do
        [ "\$f" != "\$BASH_SETUP_DIR/setup.sh" ] && [ -r "\$f" ] && source "\$f"
    done
    unset f
fi
EOF
    echo "✅ Integración agregada correctamente a ~/.bashrc."
else
    echo "ℹ️ Bash.Setup ya está configurado en ~/.bashrc."
fi

echo ""
echo "💡 Para aplicar los cambios en la terminal actual, ejecuta:"
echo "   source ~/.bashrc"
