#!/usr/bin/env bash
# ==============================================================================
# python.sh - Verificación de Python y Gestor 'uv' en NixOS
# ==============================================================================

set -euo pipefail

# Detección de usuario
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

export UV_LINK_MODE="copy"
export PYTHONUNBUFFERED=1

show_help() {
    cat <<EOF
🐍 Gestor de Python y UV - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica el entorno de Python y configura autocompletados e integración de UV.
  --status, -s        Comprueba las versiones de Python y uv en el sistema.
  --help, -h          Muestra este mensaje de ayuda.

Nota para NixOS:
  Tanto Python 3 como uv están declarados en:
    modules/development.nix (pkgs.python3, pkgs.uv)
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE PYTHON Y UV - NIXOS"
    echo "================================================================="
    echo -n "• Python 3 del sistema: "
    if command -v python3 &>/dev/null; then
        echo "✅ $(python3 --version 2>/dev/null) ($(which python3))"
    else
        echo "❌ No instalado"
    fi

    echo -n "• Gestor uv: "
    if command -v uv &>/dev/null; then
        echo "✅ $(uv --version 2>/dev/null) ($(which uv))"
    else
        echo "❌ No instalado"
    fi

    echo -n "• Herramienta uvx: "
    if command -v uvx &>/dev/null; then
        echo "✅ Presente"
    else
        echo "ℹ️ No disponible en PATH"
    fi
    echo "================================================================="
}

configure_uv() {
    echo "⚙️ Configurando variables de entorno para uv (~/.bashrc.d/python.sh)..."
    mkdir -p "$USER_HOME/.bashrc.d"

    cat << 'EOF' > "$USER_HOME/.bashrc.d/python.sh"
# Configuración de Python y uv
export UV_LINK_MODE="copy"
export PYTHONUNBUFFERED=1
EOF

    chown "$REAL_USER:" "$USER_HOME/.bashrc.d/python.sh" 2>/dev/null || true
    echo "✅ Entorno Python y UV configurado."
}

case "${1:-}" in
    --status|-s|status)
        check_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    *)
        configure_uv
        check_status
        ;;
esac
