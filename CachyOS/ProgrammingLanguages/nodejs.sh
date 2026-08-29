#!/bin/bash
# ==============================================================================
# nodejs.sh - Instalación de Node.js (Última LTS) vía Mise para CachyOS
# Optimizado para KDE Plasma 6 y Zsh (npm, pnpm, yarn vía Corepack)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🟢 Instalando Node.js (Última versión LTS) para CachyOS"
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

export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" COREPACK_ENABLE_DOWNLOAD_PROMPT=0 PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    else
        COREPACK_ENABLE_DOWNLOAD_PROMPT=0 PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    fi
}

# Exportar PATH para este proceso
export PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/bin:$PATH"

# 1. Asegurar que Mise está presente
if ! command -v mise &> /dev/null && [ ! -x "$USER_HOME/.local/bin/mise" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/mise.sh" ]; then
        echo "ℹ️ Mise no encontrado. Ejecutando instalador $SCRIPT_DIR/mise.sh..."
        bash "$SCRIPT_DIR/mise.sh"
    else
        echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
        exit 1
    fi
fi

# 2. Dependencias de compilación para módulos nativos (node-gyp / C++)
echo "ℹ️ [1/3] Verificando dependencias de compilación para módulos nativos (node-gyp)..."
MISSING_PKGS=$(pacman -T base-devel curl python gcc make 2>/dev/null || true)
if [ -n "$MISSING_PKGS" ]; then
    echo "  ⬇️ Instalando paquetes faltantes: $MISSING_PKGS..."
    $SUDO pacman -S --needed --noconfirm $MISSING_PKGS
else
    echo "  ✅ Dependencias ya instaladas."
fi

# 3. Instalar la última versión LTS de Node.js de forma global con Mise
echo "ℹ️ [2/3] Descargando e instalando la última versión Node.js LTS vía Mise..."
run_as_user mise use --global node@lts

# 4. Habilitar Corepack para soportar pnpm y yarn de serie
echo "ℹ️ [3/3] Habilitando Corepack (pnpm y yarn) y regenerando shims..."
run_as_user mise exec node@lts -- corepack enable 2>/dev/null || true
run_as_user mise reshim 2>/dev/null || true

# Obtener versiones instaladas
NODE_VER=$(run_as_user mise exec node@lts -- node --version 2>/dev/null || echo "instalado")
NPM_VER=$(run_as_user mise exec node@lts -- npm --version 2>/dev/null || echo "instalado")
PNPM_VER=$(run_as_user mise exec node@lts -- pnpm --version 2>/dev/null || echo "disponible vía corepack")
YARN_VER=$(run_as_user mise exec node@lts -- yarn --version 2>/dev/null || echo "disponible vía corepack")

echo "================================================================="
echo "✅ Node.js LTS configurado con éxito para CachyOS y Zsh:"
echo "  • Node.js:  $NODE_VER (LTS)"
echo "  • npm:      $NPM_VER"
echo "  • pnpm:     $PNPM_VER"
echo "  • yarn:     $YARN_VER"
echo "  • Entorno:  KDE Plasma 6 + Zsh (~/.local/share/mise/shims)"
echo "================================================================="
