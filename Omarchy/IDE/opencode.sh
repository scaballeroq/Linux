#!/bin/bash
# opencode.sh - Instalación de OpenCode AI CLI/Editor para Arch Linux

set -euo pipefail

OPENCODE_VERSION="${1:-1.18.13}"

echo "🤖 Instalando OpenCode (Versión: $OPENCODE_VERSION)..."

# 1. Asegurar dependencias (curl)
if ! command -v curl &> /dev/null; then
    echo "ℹ️ Instalando curl..."
    sudo pacman -S --noconfirm curl
fi

# 2. Descargar e instalar OpenCode en la versión indicada
TMP_INSTALLER="/tmp/opencode_install_$$.sh"
echo "⬇️ Descargando instalador de OpenCode..."
curl -fsSL https://opencode.ai/install -o "$TMP_INSTALLER"

echo "⚙️ Ejecutando instalador para versión $OPENCODE_VERSION..."
VERSION="$OPENCODE_VERSION" bash "$TMP_INSTALLER"

# Limpiar script temporal
rm -f "$TMP_INSTALLER"

# 3. Exportar PATH para la sesión actual
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

# 4. Verificación
echo "================================================================="
if command -v opencode &> /dev/null || [ -x "$HOME/.local/bin/opencode" ] || [ -x "$HOME/.opencode/bin/opencode" ]; then
    echo "✅ OpenCode instalado con éxito:"
    opencode --version 2>/dev/null || "$HOME/.local/bin/opencode" --version 2>/dev/null || true
else
    echo "✅ Instalación finalizada. Reinicia la terminal para disponer del comando 'opencode'."
fi
echo "================================================================="
