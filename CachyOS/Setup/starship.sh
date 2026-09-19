#!/bin/bash
# ==============================================================================
# starship.sh - Instalador y Gestor Opcional de Starship Prompt para CachyOS
# ==============================================================================
# Nota: CachyOS incluye por defecto Powerlevel10k (p10k) en Zsh.
# Este script te permite activar o desactivar Starship de forma opcional.
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no esta disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecucion con sudo
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
🚀 Gestor de Starship Prompt - CachyOS

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)    Instala Starship, copia la configuracion y lo activa en Zsh y Bash.
  --disable, -d       Desactiva Starship en ~/.zshrc y ~/.bashrc (restaura Powerlevel10k nativo).
  --enable, -e        Activa Starship en ~/.zshrc y ~/.bashrc.
  --status, -s        Muestra si Starship esta activo en tus shells.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

install_starship() {
    echo "================================================================="
    echo "🚀 Configurando Starship Prompt en CachyOS"
    echo "================================================================="

    # 1. Instalar binario de Starship
    if ! command -v starship &> /dev/null; then
        echo "⬇️ [1/3] Instalando Starship vía Pacman..."
        $SUDO pacman -S --needed --noconfirm starship 2>/dev/null || {
            echo "⚠️ Fallback: Descargando instalador oficial de Starship..."
            curl -sS https://starship.rs/install.sh | $SUDO sh -s -- -y -b /usr/local/bin
        }
    else
        echo "✅ [1/3] Starship ya está instalado ($(starship --version | head -n1))."
    fi

    # 2. Copiar configuracion starship.toml
    echo "🎨 [2/3] Copiando archivo de configuracion starship.toml..."
    run_as_user mkdir -p "$USER_HOME/.config"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/starship.toml" ]; then
        run_as_user cp "$SCRIPT_DIR/starship.toml" "$USER_HOME/.config/starship.toml"
        echo "  ✅ Copiado a ~/.config/starship.toml"
    fi

    # 3. Activar en Zsh y Bash
    echo "⚙️ [3/3] Activando Starship en ~/.bashrc (y ~/.zshrc si existe)..."
    enable_starship

    echo "================================================================="
    echo "✅ Starship configurado y activado con éxito."
    echo "💡 Nota: Starship proporciona un prompt moderno y enriquecido."
    echo "💡 Para revertir y volver al prompt por defecto ejecuta: $0 --disable"
    echo "================================================================="
}

enable_starship() {
    # 1. Bash (Predeterminado)
    local BASHRC="$USER_HOME/.bashrc"
    run_as_user touch "$BASHRC"
    if ! grep -q "starship init bash" "$BASHRC" 2>/dev/null; then
        echo -e '\n# Starship Prompt\neval "$(starship init bash)"' | run_as_user tee -a "$BASHRC" > /dev/null
        echo "  ✅ Starship activado en ~/.bashrc"
    else
        echo "  ℹ️ Starship ya estaba presente en ~/.bashrc"
    fi

    # 2. Zsh (Compatibilidad condicional si existe ~/.zshrc)
    local ZSHRC="$USER_HOME/.zshrc"
    if [ -f "$ZSHRC" ]; then
        if ! grep -q "starship init zsh" "$ZSHRC" 2>/dev/null; then
            echo -e '\n# Starship Prompt\neval "$(starship init zsh)"' | run_as_user tee -a "$ZSHRC" > /dev/null
            echo "  ✅ Starship activado en ~/.zshrc"
        else
            echo "  ℹ️ Starship ya estaba presente en ~/.zshrc"
        fi
    else
        echo "  ℹ️ ~/.zshrc no encontrado; se omite activación en Zsh."
    fi
}

disable_starship() {
    echo "================================================================="
    echo "🔄 Desactivando Starship para restaurar el prompt nativo..."
    echo "================================================================="

    # 1. Bash (Predeterminado)
    local BASHRC="$USER_HOME/.bashrc"
    if [ -f "$BASHRC" ] && grep -q "starship init bash" "$BASHRC" 2>/dev/null; then
        sed -i '/# Starship Prompt/d' "$BASHRC" 2>/dev/null || true
        sed -i '/eval "$(starship init bash)"/d' "$BASHRC" 2>/dev/null || true
        echo "  ✅ Starship desactivado en ~/.bashrc."
    else
        echo "  ℹ️ Starship no estaba activo en ~/.bashrc."
    fi

    # 2. Zsh (Compatibilidad)
    local ZSHRC="$USER_HOME/.zshrc"
    if [ -f "$ZSHRC" ] && grep -q "starship init zsh" "$ZSHRC" 2>/dev/null; then
        sed -i '/# Starship Prompt/d' "$ZSHRC" 2>/dev/null || true
        sed -i '/eval "$(starship init zsh)"/d' "$ZSHRC" 2>/dev/null || true
        echo "  ✅ Starship desactivado en ~/.zshrc (Powerlevel10k restaurado si está instalado)."
    elif [ -f "$ZSHRC" ]; then
        echo "  ℹ️ Starship no estaba activo en ~/.zshrc."
    fi

    echo "================================================================="
    echo "✅ Prompt nativo restaurado."
    echo "💡 Ejecuta 'source ~/.bashrc' (o 'source ~/.zshrc' si usas Zsh) para aplicar los cambios."
    echo "================================================================="
}

show_status() {
    echo "================================================================="
    echo "🔍 Estado de Starship en tus shells:"
    echo "================================================================="
    echo "• Binario instalado: $(command -v starship &>/dev/null && echo "Sí ($(starship --version | head -n1))" || echo "No")"
    echo "• Configuración:     $([ -f "$USER_HOME/.config/starship.toml" ] && echo "Presente en ~/.config/starship.toml" || echo "No presente")"
    echo "• Activo en Bash:    $(grep -q "starship init bash" "$USER_HOME/.bashrc" 2>/dev/null && echo "Sí (Starship activo)" || echo "No")"
    if [ -f "$USER_HOME/.zshrc" ]; then
        echo "• Activo en Zsh:     $(grep -q "starship init zsh" "$USER_HOME/.zshrc" 2>/dev/null && echo "Sí (Starship activo)" || echo "No (Prompt nativo / p10k)")"
    else
        echo "• Activo en Zsh:     No aplicable (~/.zshrc no existe)"
    fi
    echo "================================================================="
}

case "${1:-install}" in
    --help|-h|help)
        show_help
        ;;
    --disable|-d|disable)
        disable_starship
        ;;
    --enable|-e|enable)
        enable_starship
        ;;
    --status|-s|status)
        show_status
        ;;
    install|*)
        install_starship
        ;;
esac
