#!/bin/bash
# ==============================================================================
# python.sh - Instalación de Python (Última versión Estable/LTS) vía Mise
# Optimizado para CachyOS, KDE Plasma 6 y Zsh / Bash (pip, uv, dependencias)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🐍 Instalando Python (Última versión Estable/LTS) para CachyOS"
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
        sudo -u "$REAL_USER" env HOME="$USER_HOME" PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    else
        PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
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

# 2. Dependencias de compilación para Python y extensiones nativas C/C++
echo "ℹ️ [1/3] Verificando dependencias de compilación para Python..."
MISSING_PKGS=$(pacman -T base-devel openssl zlib bzip2 readline sqlite curl git ncurses xz tk libffi 2>/dev/null || true)
if [ -n "$MISSING_PKGS" ]; then
    echo "  ⬇️ Instalando librerías requeridas: $MISSING_PKGS..."
    $SUDO pacman -S --needed --noconfirm $MISSING_PKGS
else
    echo "  ✅ Dependencias de compilación ya instaladas."
fi

# 3. Instalar la última versión estable / LTS de Python con Mise
echo "ℹ️ [2/3] Descargando e instalando Python (LTS/Stable) vía Mise..."
run_as_user mise use --global python@latest
run_as_user mise reshim 2>/dev/null || true

# 4. Actualizar pip
echo "ℹ️ [3/3] Actualizando gestor de paquetes pip..."
run_as_user mise exec python@latest -- python -m pip install --upgrade pip --quiet 2>/dev/null || true
run_as_user mise reshim 2>/dev/null || true

# Obtener versión instalada
PYTHON_VER=$(run_as_user mise exec python@latest -- python --version 2>/dev/null || echo "instalado")
PIP_VER=$(run_as_user mise exec python@latest -- pip --version 2>/dev/null | awk '{print $2}' || echo "instalado")

echo "================================================================="
echo "✅ Python configurado con éxito para CachyOS y KDE Plasma 6:"
echo "  • Runtime:     $PYTHON_VER"
echo "  • Pip:         v$PIP_VER"
echo "  • Shims:       ~/.local/share/mise/shims"
echo "  • Shells:      Bash & Zsh"
echo "================================================================="
