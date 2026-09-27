#!/usr/bin/env bash
# ==============================================================================
# starship.sh - Instalación y Configuración del Prompt Starship en NixOS
# ==============================================================================

set -euo pipefail

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$USER_HOME/.config"
CONFIG_FILE="$CONFIG_DIR/starship.toml"
BASHRC_D="$USER_HOME/.bashrc.d"
HOOK_FILE="$BASHRC_D/starship.sh"

show_help() {
    cat <<EOF
🚀 Gestor de Starship Prompt - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Despliega la configuración starship.toml y activa la integración en shell.
  --enable, -e        Activa el prompt Starship en Bash / Zsh.
  --disable, -d       Desactiva Starship y restaura el prompt predeterminado.
  --status, -s        Verifica el estado de Starship y sus archivos de configuración.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE STARSHIP PROMPT - NIXOS"
    echo "================================================================="
    echo -n "• Binario starship: "
    if command -v starship &>/dev/null; then
        echo "✅ $(starship --version | head -n1)"
    else
        echo "❌ No encontrado en PATH"
    fi

    echo -n "• Configuración starship.toml: "
    if [ -f "$CONFIG_FILE" ]; then
        echo "✅ Presente ($CONFIG_FILE)"
    else
        echo "❌ No encontrado"
    fi

    echo -n "• Integración con Bash: "
    if [ -f "$HOOK_FILE" ]; then
        echo "✅ Activa ($HOOK_FILE)"
    else
        echo "ℹ️ Inactiva"
    fi
    echo "================================================================="
}

enable_starship() {
    mkdir -p "$CONFIG_DIR" "$BASHRC_D"

    # Copiar configuración
    if [ -f "$SCRIPT_DIR/starship.toml" ]; then
        cp "$SCRIPT_DIR/starship.toml" "$CONFIG_FILE"
    fi

    # Crear hook modular en ~/.bashrc.d/starship.sh
    cat << 'EOF' > "$HOOK_FILE"
# Starship Prompt Hook
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi
EOF

    # Asegurar que ~/.bashrc cargue ~/.bashrc.d
    if [ -f "$USER_HOME/.bashrc" ] && ! grep -q "bashrc.d" "$USER_HOME/.bashrc"; then
        cat << 'EOF' >> "$USER_HOME/.bashrc"

# Cargar scripts modulares de ~/.bashrc.d
if [ -d "$HOME/.bashrc.d" ]; then
    for f in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$f" ] && source "$f"
    done
fi
EOF
    fi

    chown -R "$REAL_USER:" "$CONFIG_FILE" "$BASHRC_D" 2>/dev/null || true
    echo "✅ Starship activado con éxito. Ejecuta 'reload' o reinicia tu terminal."
}

disable_starship() {
    if [ -f "$HOOK_FILE" ]; then
        rm -f "$HOOK_FILE"
        echo "✅ Hook de Starship desactivado en $HOOK_FILE."
    else
        echo "ℹ️ Starship ya estaba desactivado."
    fi
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --enable|-e|enable)
        enable_starship
        exit 0
        ;;
    --disable|-d|disable)
        disable_starship
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    *)
        enable_starship
        ;;
esac
