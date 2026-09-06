#!/bin/bash
# ==============================================================================
# opencode.sh - Instalación de OpenCode AI CLI para CachyOS
# Optimizado para Zsh y KDE Plasma 6
# ==============================================================================

set -euo pipefail

OPENCODE_VERSION="${1:-1.18.13}"

echo "================================================================="
echo "🤖 Instalando OpenCode AI CLI (Versión: $OPENCODE_VERSION)..."
echo "================================================================="

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecución con sudo
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# 1. Asegurar dependencias vía Pacman
echo "ℹ️ [1/3] Verificando dependencias (curl)..."
$SUDO pacman -S --needed --noconfirm curl 2>/dev/null || true

# 2. Descargar e instalar OpenCode en la versión indicada
TMP_INSTALLER="/tmp/opencode_install_$$.sh"
echo "⬇️ [2/3] Descargando e instalando OpenCode $OPENCODE_VERSION..."
curl -fsSL https://opencode.ai/install -o "$TMP_INSTALLER"

VERSION="$OPENCODE_VERSION" run_as_user bash "$TMP_INSTALLER"
rm -f "$TMP_INSTALLER"

# 3. Exportar PATH en Zsh si no estuviera ya presente
echo "⚙️ [3/3] Configurando PATH en Zsh..."
ZSHRC="$USER_HOME/.zshrc"
if [ -f "$ZSHRC" ] || [[ "${SHELL:-}" == *"zsh"* ]]; then
    run_as_user touch "$ZSHRC"
    if ! grep -q ".opencode/bin" "$ZSHRC" 2>/dev/null; then
        echo -e '\n# OpenCode AI CLI\nexport PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"' | run_as_user tee -a "$ZSHRC" > /dev/null
    fi
fi

# Exportar PATH para la sesión actual del script
export PATH="$USER_HOME/.local/bin:$USER_HOME/.opencode/bin:$PATH"

# 4. Verificación
echo "================================================================="
if command -v opencode &> /dev/null || [ -x "$USER_HOME/.local/bin/opencode" ] || [ -x "$USER_HOME/.opencode/bin/opencode" ]; then
    echo "✅ OpenCode instalado con éxito:"
    opencode --version 2>/dev/null || "$USER_HOME/.local/bin/opencode" --version 2>/dev/null || true
else
    echo "✅ Instalación finalizada."
fi
echo "💡 Para disponer del comando en tu terminal actual ejecuta: source ~/.zshrc"
echo "================================================================="
