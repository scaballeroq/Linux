#!/bin/bash
# =============================================================================
# python.sh - Instalador de Python Estable y Herramientas (uv/pip) vía Mise
# =============================================================================
# - Instala dependencias de compilación para paquetes nativos (C/C++ extensions)
# - Instala la última versión estable recomendada de Python (python@latest)
# - Instala uv (el gestor de paquetes y proyectos Python ultrarrápido)
# - Actualiza pip, setuptools y wheel
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
Instalador de Python Estable (Mise) - Kubuntu

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Instala dependencias, la última versión estable de Python, uv y pip.
  --status, -s           Muestra las versiones activas de Python, uv, pip y estado en Mise.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE PYTHON Y HERRAMIENTAS - KUBUNTU"
    echo "================================================================="
    echo "Python (Mise):                 $(run_as_user mise which python 2>/dev/null || echo 'No instalado')"
    echo "Versión Python:                $(run_as_user python3 --version 2>/dev/null || run_as_user python --version 2>/dev/null || echo 'n/a')"
    echo "Versión Pip:                   $(run_as_user pip --version 2>/dev/null || echo 'n/a')"
    echo "Versión uv:                    $(run_as_user uv --version 2>/dev/null || echo 'n/a')"
    echo "================================================================="
    if command -v mise &>/dev/null; then
        echo ""
        echo "Versiones de Python en Mise:"
        run_as_user mise ls python 2>/dev/null || true
    fi
}

install_python() {
    echo "================================================================="
    echo "INSTALANDO PYTHON (ÚLTIMA VERSIÓN ESTABLE) VÍA MISE - KUBUNTU"
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

    # 2. Instalar dependencias para compilación de librerías nativas de Python (C/C++ extensions)
    echo "ℹ️ [1/4] Instalando dependencias de compilación y librerías base..."
    $SUDO apt update
    $SUDO apt install -y \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        curl \
        git \
        libncurses-dev \
        xz-utils \
        tk-dev \
        libxml2-dev \
        libxmlsec1-dev \
        libffi-dev \
        liblzma-dev \
        pkg-config \
        2>/dev/null || true

    # 3. Instalar la última versión estable de Python
    echo "ℹ️ [2/4] Descargando e instalando la última versión estable de Python (python@latest)..."
    run_as_user mise use --global python@latest

    # 4. Instalar uv (gestor moderno y ultrarrápido de paquetes/entornos virtuales)
    echo "ℹ️ [3/4] Instalando gestor uv (uv@latest)..."
    run_as_user mise use --global uv@latest 2>/dev/null || true

    # 5. Actualizar pip, setuptools y wheel
    echo "ℹ️ [4/4] Actualizando pip, setuptools y wheel..."
    run_as_user mise exec python@latest -- python -m pip install --upgrade pip setuptools wheel 2>/dev/null || true

    echo ""
    echo "================================================================="
    echo "✅ Python y herramientas de desarrollo instaladas correctamente."
    echo "   - Python : $(run_as_user python3 --version 2>/dev/null || run_as_user python --version 2>/dev/null || echo 'latest')"
    echo "   - uv     : $(run_as_user uv --version 2>/dev/null || echo 'latest')"
    echo "   - pip    : $(run_as_user pip --version 2>/dev/null || echo 'latest')"
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
        install_python
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
