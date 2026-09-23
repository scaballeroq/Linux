#!/bin/bash
# ==============================================================================
# starship.sh - Instalador y Gestor de Starship Prompt para openSUSE Tumbleweed
# ==============================================================================
# Script para instalar, configurar y gestionar Starship prompt en Bash y Zsh.
# ==============================================================================

set -euo pipefail

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

show_help() {
    cat <<EOF
🚀 Gestor de Starship Prompt - openSUSE Tumbleweed

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala Starship, copia la configuración y lo activa en Zsh y Bash.
  --disable, -d       Desactiva Starship en ~/.zshrc y ~/.bashrc.
  --enable, -e        Activa Starship en ~/.zshrc y ~/.bashrc.
  --status, -s        Muestra si Starship está activo en tus shells.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

install_starship() {
    echo "================================================================="
    echo "🚀 Configurando Starship Prompt en openSUSE Tumbleweed"
    echo "================================================================="

    # 1. Instalar binario de Starship
    if ! command -v starship &> /dev/null; then
        echo "⬇️ [1/3] Instalando Starship vía Zypper..."
        if ! $SUDO zypper --non-interactive install -y starship 2>/dev/null; then
            echo "⚠️ Instalando mediante script oficial de Starship..."
            curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi
    else
        echo "✅ [1/3] Binario de Starship ya presente: $(starship --version | head -n1)"
    fi

    # 2. Configurar starship.toml
    echo "⚙️ [2/3] Desplegando archivo de configuración en ~/.config/starship.toml..."
    run_as_user mkdir -p "$USER_HOME/.config"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/starship.toml" ]; then
        run_as_user cp "$SCRIPT_DIR/starship.toml" "$USER_HOME/.config/starship.toml"
        echo "  • starship.toml copiado desde Setup/starship.toml"
    fi

    # 3. Activar en Bash (y Zsh si existe)
    echo "🔌 [3/3] Activando Starship en perfiles de shell..."
    enable_starship

    echo "================================================================="
    echo "✅ Starship Prompt instalado y configurado con éxito."
    echo "💡 Para ver los cambios en esta terminal: eval \"\$(starship init bash)\""
    echo "================================================================="
}

enable_starship() {
    local bashrc="$USER_HOME/.bashrc"
    local bashrc_d="$USER_HOME/.bashrc.d"
    local zshrc="$USER_HOME/.zshrc"
    local zshrc_d="$USER_HOME/.zshrc.d"

    # En Bash modular (~/.bashrc.d/starship.sh)
    if [ -d "$bashrc_d" ]; then
        run_as_user mkdir -p "$bashrc_d"
        cat << 'EOF' | run_as_user tee "$bashrc_d/starship.sh" > /dev/null
# =============================================================================
# STARSHIP PROMPT
# =============================================================================
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi
EOF
        echo "  ✅ Starship activado en ~/.bashrc.d/starship.sh"
    elif [ -f "$bashrc" ]; then
        if ! grep -q "starship init bash" "$bashrc" 2>/dev/null; then
            echo -e '\n# Starship Prompt\nif command -v starship &>/dev/null; then eval "$(starship init bash)"; fi' | run_as_user tee -a "$bashrc" > /dev/null
            echo "  ✅ Starship añadido a ~/.bashrc"
        fi
    fi

    # En Zsh si existe ~/.zshrc
    if [ -f "$zshrc" ]; then
        if [ -d "$zshrc_d" ]; then
            run_as_user mkdir -p "$zshrc_d"
            cat << 'EOF' | run_as_user tee "$zshrc_d/starship.zsh" > /dev/null
# =============================================================================
# STARSHIP PROMPT
# =============================================================================
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi
EOF
            echo "  ✅ Starship activado en ~/.zshrc.d/starship.zsh"
        elif ! grep -q "starship init zsh" "$zshrc" 2>/dev/null; then
            echo -e '\n# Starship Prompt\nif command -v starship &>/dev/null; then eval "$(starship init zsh)"; fi' | run_as_user tee -a "$zshrc" > /dev/null
            echo "  ✅ Starship añadido a ~/.zshrc"
        fi
    fi
}

disable_starship() {
    echo "================================================================="
    echo "🛑 Desactivando Starship en archivos de configuración..."
    echo "================================================================="
    local bashrc_d="$USER_HOME/.bashrc.d"
    local zshrc_d="$USER_HOME/.zshrc.d"

    # Retirar de ~/.bashrc.d
    if [ -f "$bashrc_d/starship.sh" ]; then
        run_as_user rm -f "$bashrc_d/starship.sh"
        echo "  • Eliminado: $bashrc_d/starship.sh"
    fi

    # Comentar en ~/.bashrc si estuviera insertado
    if [ -f "$USER_HOME/.bashrc" ]; then
        sed -i 's/^eval "\$(starship init bash)"/# eval "\$(starship init bash)"/' "$USER_HOME/.bashrc" 2>/dev/null || true
    fi

    # Retirar de ~/.zshrc.d
    if [ -f "$zshrc_d/starship.zsh" ]; then
        run_as_user rm -f "$zshrc_d/starship.zsh"
        echo "  • Eliminado: $zshrc_d/starship.zsh"
    fi

    # Comentar en ~/.zshrc
    if [ -f "$USER_HOME/.zshrc" ]; then
        sed -i 's/^eval "\$(starship init zsh)"/# eval "\$(starship init zsh)"/' "$USER_HOME/.zshrc" 2>/dev/null || true
    fi

    echo "✅ Starship desactivado. Abre una nueva terminal para volver al prompt nativo."
    echo "================================================================="
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE STARSHIP PROMPT"
    echo "================================================================="
    echo "• Binario starship: $(if command -v starship &>/dev/null; then echo "✅ Instalado ($(starship --version | head -n1))"; else echo "❌ No instalado"; fi)"
    echo "• Archivo de config: $(if [ -f "$USER_HOME/.config/starship.toml" ]; then echo "✅ Presente (~/.config/starship.toml)"; else echo "❌ Ausente"; fi)"
    echo "• Activo en Bash:    $(if [ -f "$USER_HOME/.bashrc.d/starship.sh" ] || grep -q 'starship init bash' "$USER_HOME/.bashrc" 2>/dev/null; then echo "✅ Sí"; else echo "❌ No"; fi)"
    if [ -f "$USER_HOME/.zshrc" ]; then
        echo "• Activo en Zsh:     $(if [ -f "$USER_HOME/.zshrc.d/starship.zsh" ] || grep -q 'starship init zsh' "$USER_HOME/.zshrc" 2>/dev/null; then echo "✅ Sí"; else echo "❌ No"; fi)"
    fi
    echo "================================================================="
}

case "${1:-}" in
    --disable|-d|disable)
        disable_starship
        ;;
    --enable|-e|enable)
        enable_starship
        echo "✅ Starship activado en tus archivos de inicio de shell."
        ;;
    --status|-s|status)
        show_status
        ;;
    --help|-h|help)
        show_help
        ;;
    "")
        install_starship
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
