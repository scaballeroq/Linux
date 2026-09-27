#!/usr/bin/env bash
# ==============================================================================
# mise.sh - Instalador, Optimizador y Diagnóstico de Mise en NixOS
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

USER_BIN="$USER_HOME/.local/bin"
USER_BIN_MISE="$USER_BIN/mise"
MISE_DATA_DIR="$USER_HOME/.local/share/mise"
ENV_CONF_DIR="$USER_HOME/.config/environment.d"
ENV_CONF_FILE="$ENV_CONF_DIR/10-mise.conf"

show_help() {
    cat <<EOF
⚡ Gestor de Versiones Mise - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala o verifica Mise y activa la integración en el entorno de usuario.
  --status, -s        Comprueba el estado de Mise y runtimes activos.
  --update, -u        Actualiza Mise y sus runtimes instalados.
  --help, -h          Muestra este mensaje de ayuda.

Nota para NixOS:
  Mise puede utilizarse como paquete de sistema (pkgs.mise en modules/development.nix)
  o en espacio de usuario rootless (~/.local/bin/mise).
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE MISE (RUNTIME MANAGER) - NIXOS"
    echo "================================================================="
    echo -n "• Binario mise: "
    if command -v mise &>/dev/null; then
        echo "✅ $(mise --version)"
    elif [ -x "$USER_BIN_MISE" ]; then
        echo "✅ Local ($USER_BIN_MISE - $("$USER_BIN_MISE" --version))"
    else
        echo "❌ No instalado"
    fi

    echo -n "• Integración environment.d (KDE Wayland): "
    if [ -f "$ENV_CONF_FILE" ]; then
        echo "✅ Configurado ($ENV_CONF_FILE)"
    else
        echo "ℹ️ No configurado"
    fi

    echo ""
    echo "• Runtimes instalados vía Mise:"
    if command -v mise &>/dev/null; then
        mise ls 2>/dev/null || echo "  (Ninguno instalado todavía)"
    elif [ -x "$USER_BIN_MISE" ]; then
        "$USER_BIN_MISE" ls 2>/dev/null || echo "  (Ninguno instalado todavía)"
    fi
    echo "================================================================="
}

install_mise() {
    if ! command -v mise &>/dev/null && [ ! -x "$USER_BIN_MISE" ]; then
        echo "⬇️ Instalando Mise en espacio de usuario (~/.local/bin)..."
        mkdir -p "$USER_BIN"
        curl -fsSL https://mise.run | sh
    fi

    echo "⚙️ Configurando integración para KDE Plasma 6 y Shells..."
    mkdir -p "$ENV_CONF_DIR" "$USER_HOME/.bashrc.d"

    cat << 'EOF' > "$ENV_CONF_FILE"
# Configuración global de Mise para KDE Plasma y systemd user
PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
EOF

    cat << 'EOF' > "$USER_HOME/.bashrc.d/mise.sh"
# Hook de activación de Mise
if command -v mise &>/dev/null; then
    eval "$(mise activate bash)"
elif [ -x "$HOME/.local/bin/mise" ]; then
    eval "$("$HOME/.local/bin/mise" activate bash)"
fi
EOF

    chown -R "$REAL_USER:" "$ENV_CONF_FILE" "$USER_HOME/.bashrc.d/mise.sh" 2>/dev/null || true
    echo "✅ Mise configurado con éxito."
    check_status
}

case "${1:-}" in
    --status|-s|status)
        check_status
        exit 0
        ;;
    --update|-u|update)
        if command -v mise &>/dev/null; then
            mise self-update 2>/dev/null || true
            mise upgrade || true
        elif [ -x "$USER_BIN_MISE" ]; then
            "$USER_BIN_MISE" self-update 2>/dev/null || true
            "$USER_BIN_MISE" upgrade || true
        fi
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    *)
        install_mise
        ;;
esac
