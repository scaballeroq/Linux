#!/bin/bash
# antigravity-CLI.sh - Instalación de Antigravity CLI (agy) para terminal

set -e

echo "ℹ️ Preparando entorno para Antigravity CLI..."

mkdir -p "$HOME/.local/bin"

UPDATE_SCRIPT="$HOME/.local/bin/update-antigravity-cli"

echo "ℹ️ Creando script de gestión: $UPDATE_SCRIPT"
tee "$UPDATE_SCRIPT" > /dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"

if [ ! -x "$HOME/.local/bin/agy" ]; then
    echo "ℹ️ Instalando Antigravity CLI desde la fuente oficial..."
    curl -fsSL https://antigravity.google/cli/install.sh | bash
else
    echo "ℹ️ El binario 'agy' ya existe. Comprobando actualizaciones..."
    "$HOME/.local/bin/agy" update
fi

echo "✅ Versión de Antigravity CLI:"
"$HOME/.local/bin/agy" --version
EOF

chmod +x "$UPDATE_SCRIPT"

echo "ℹ️ Ejecutando proceso de instalación..."
"$UPDATE_SCRIPT"

echo "🔍 Verificando disponibilidad en el sistema..."
export PATH="$HOME/.local/bin:$PATH"

if command -v agy &> /dev/null; then
    echo "✅ 'agy' está correctamente instalado y accesible."
else
    echo "⚠️ 'agy' se instaló en $HOME/.local/bin pero no se detecta en el PATH actual."
    echo "💡 Nota: Reinicia tu terminal o ejecuta 'source ~/.bashrc' para activar el PATH."
fi

echo "✅ Configuración de Antigravity CLI completada."
