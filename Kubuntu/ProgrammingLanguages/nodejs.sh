#!/bin/bash
# =============================================================================
# nodejs.sh - Instalador de Node.js LTS, npm y pnpm vía Mise para Kubuntu
# =============================================================================
# - Instala dependencias de compilación para paquetes nativos (node-gyp / C++)
# - Instala y configura automáticamente la última versión Node.js LTS (node@lts)
# - Actualiza npm a la última versión
# - Activa Corepack y configura pnpm (pnpm@latest)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "Error: Este script requiere privilegios de superusuario."
        exit 1
    fi
else
    SUDO=""
fi

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

show_help() {
    cat <<EOF
Instalador de Node.js LTS (Mise) - Kubuntu

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Instala dependencias, la última versión LTS de Node.js, npm y pnpm.
  --status, -s           Muestra las versiones activas de Node.js, npm, pnpm y estado en Mise.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE NODE.JS Y GESTORES DE PAQUETES - KUBUNTU"
    echo "================================================================="
    echo "Node.js (Mise):                $(run_as_user mise which node 2>/dev/null || echo 'No instalado')"
    echo "Versión Node.js:               $(run_as_user node --version 2>/dev/null || echo 'n/a')"
    echo "Versión npm:                   $(run_as_user npm --version 2>/dev/null || echo 'n/a')"
    echo "Versión pnpm:                  $(run_as_user pnpm --version 2>/dev/null || echo 'n/a')"
    echo "================================================================="
    if command -v mise &>/dev/null; then
        echo ""
        echo "Versiones de Node en Mise:"
        run_as_user mise ls node 2>/dev/null || true
    fi
}

install_nodejs() {
    echo "================================================================="
    echo "INSTALANDO NODE.JS (ÚLTIMA VERSIÓN LTS) VÍA MISE - KUBUNTU"
    echo "================================================================="

    # 1. Asegurar que Mise está instalado
    if ! command -v mise &> /dev/null && [ ! -x "$USER_HOME/.local/bin/mise" ]; then
        echo "ℹ️ Mise no detectado. Instalando Mise primero..."
        if [ -f "$SCRIPT_DIR/mise.sh" ]; then
            bash "$SCRIPT_DIR/mise.sh"
        else
            echo "❌ Error: No se encontró mise.sh en $SCRIPT_DIR"
            exit 1
        fi
    fi

    # 2. Instalar dependencias para compilación de módulos nativos (node-gyp / C++)
    echo "ℹ️ [1/4] Instalando dependencias del sistema para node-gyp..."
    $SUDO apt update
    $SUDO apt install -y \
        build-essential \
        python3 \
        pkg-config \
        libssl-dev \
        curl \
        g++ \
        make \
        2>/dev/null || true

    # 3. Instalar siempre la última versión LTS de Node.js
    echo "ℹ️ [2/4] Instalando la última versión Node.js LTS (node@lts)..."
    run_as_user mise use --global node@lts

    # 4. Actualizar npm a la última versión
    echo "ℹ️ [3/4] Actualizando npm a la última versión..."
    run_as_user mise exec node@lts -- npm install -g npm@latest 2>/dev/null || true

    # 5. Activar Corepack e instalar pnpm (gestor recomendado de paquetes)
    echo "ℹ️ [4/4] Configurando Corepack y pnpm..."
    run_as_user mise exec node@lts -- corepack enable 2>/dev/null || true
    run_as_user mise use --global pnpm@latest 2>/dev/null || \
    run_as_user mise exec node@lts -- corepack prepare pnpm@latest --activate 2>/dev/null || true

    echo ""
    echo "================================================================="
    echo "✅ Node.js LTS, npm y pnpm configurados con éxito."
    echo "   - Node.js : $(run_as_user node --version 2>/dev/null || echo 'LTS')"
    echo "   - npm     : $(run_as_user npm --version 2>/dev/null || echo 'latest')"
    echo "   - pnpm    : $(run_as_user pnpm --version 2>/dev/null || echo 'latest')"
    echo "================================================================="
}

case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    "")
        install_nodejs
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
