#!/bin/bash
# ==============================================================================
# starship.sh - Instalador y Gestor de Starship Prompt para openSUSE Tumbleweed
# ==============================================================================
# Script para instalar, configurar y gestionar Starship prompt en Bash y Zsh.
# Soporta habilitación/deshabilitación modular en ~/.bashrc.d y ~/.zshrc.d
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

BASHRC="$USER_HOME/.bashrc"
BASHRC_D="$USER_HOME/.bashrc.d"
ZSHRC="$USER_HOME/.zshrc"
ZSHRC_D="$USER_HOME/.zshrc.d"
CONFIG_DIR="$USER_HOME/.config"
STARSHIP_CONFIG="$CONFIG_DIR/starship.toml"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_CONFIG="$SCRIPT_DIR/starship.toml"

show_help() {
    cat <<EOF
🚀 Gestor de Starship Prompt - openSUSE Tumbleweed

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala Starship, despliega la configuración y lo activa en Bash y Zsh.
  --enable, -e        Activa Starship en ~/.bashrc.d/ y ~/.zshrc.d/.
  --disable, -d       Desactiva Starship y restaura el prompt predeterminado.
  --status, -s        Muestra el estado del binario, configuración y perfiles de shell.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

deploy_config() {
    echo "⚙️ Desplegando configuración en $STARSHIP_CONFIG..."
    run_as_user mkdir -p "$CONFIG_DIR"

    if [ -f "$SOURCE_CONFIG" ]; then
        if [ -f "$STARSHIP_CONFIG" ]; then
            if ! cmp -s "$SOURCE_CONFIG" "$STARSHIP_CONFIG"; then
                run_as_user cp "$STARSHIP_CONFIG" "${STARSHIP_CONFIG}.bak"
                echo "  • Copia de seguridad creada: ${STARSHIP_CONFIG}.bak"
                run_as_user cp "$SOURCE_CONFIG" "$STARSHIP_CONFIG"
                echo "  • Configuración actualizada desde Setup/starship.toml"
            else
                echo "  • Configuración ya sincronizada con Setup/starship.toml"
            fi
        else
            run_as_user cp "$SOURCE_CONFIG" "$STARSHIP_CONFIG"
            echo "  • Archivo starship.toml desplegado con éxito"
        fi
    fi
}

enable_starship() {
    echo "🔌 Activando Starship en perfiles de shell..."

    # 1. Bash: uso de ~/.bashrc.d/starship.sh
    run_as_user mkdir -p "$BASHRC_D"
    cat << 'EOF' | run_as_user tee "$BASHRC_D/starship.sh" > /dev/null
# =============================================================================
# STARSHIP PROMPT (openSUSE Tumbleweed)
# =============================================================================
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi
EOF
    echo "  ✅ Starship activado en ~/.bashrc.d/starship.sh"

    # Asegurar cargador modular en ~/.bashrc si no existe
    run_as_user touch "$BASHRC"
    if ! grep -q "\.bashrc\.d" "$BASHRC" 2>/dev/null; then
        cat << 'EOF' | run_as_user tee -a "$BASHRC" > /dev/null

# Carga modular de configuraciones y aliases (~/.bashrc.d)
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
EOF
        echo "  ✅ Cargador modular asegurado en ~/.bashrc"
    fi

    # Limpiar posibles entradas duplicadas inline en ~/.bashrc
    if grep -q "starship init bash" "$BASHRC" 2>/dev/null; then
        run_as_user sed -i '/starship init bash/d' "$BASHRC" 2>/dev/null || true
    fi

    # 2. Zsh: uso de ~/.zshrc.d/starship.zsh si existe ~/.zshrc
    if [ -f "$ZSHRC" ]; then
        run_as_user mkdir -p "$ZSHRC_D"
        cat << 'EOF' | run_as_user tee "$ZSHRC_D/starship.zsh" > /dev/null
# =============================================================================
# STARSHIP PROMPT (openSUSE Tumbleweed)
# =============================================================================
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi
EOF
        echo "  ✅ Starship activado en ~/.zshrc.d/starship.zsh"

        if ! grep -q "\.zshrc\.d" "$ZSHRC" 2>/dev/null; then
            cat << 'EOF' | run_as_user tee -a "$ZSHRC" > /dev/null

# Carga modular de configuraciones y aliases (~/.zshrc.d)
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.{sh,zsh}(N); do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
EOF
            echo "  ✅ Cargador modular asegurado en ~/.zshrc"
        fi

        if grep -q "starship init zsh" "$ZSHRC" 2>/dev/null; then
            run_as_user sed -i '/starship init zsh/d' "$ZSHRC" 2>/dev/null || true
        fi
    fi
}

disable_starship() {
    echo "================================================================="
    echo "🛑 Desactivando Starship en perfiles de shell..."
    echo "================================================================="

    # Retirar de ~/.bashrc.d
    if [ -f "$BASHRC_D/starship.sh" ]; then
        run_as_user rm -f "$BASHRC_D/starship.sh"
        echo "  • Eliminado: ~/.bashrc.d/starship.sh"
    fi

    # Limpiar líneas inline en ~/.bashrc si existieran
    if [ -f "$BASHRC" ] && grep -q "starship init bash" "$BASHRC" 2>/dev/null; then
        run_as_user sed -i '/starship init bash/d' "$BASHRC" 2>/dev/null || true
        echo "  • Limpiadas referencias en ~/.bashrc"
    fi

    # Retirar de ~/.zshrc.d
    if [ -f "$ZSHRC_D/starship.zsh" ]; then
        run_as_user rm -f "$ZSHRC_D/starship.zsh"
        echo "  • Eliminado: ~/.zshrc.d/starship.zsh"
    fi

    # Limpiar líneas inline en ~/.zshrc si existieran
    if [ -f "$ZSHRC" ] && grep -q "starship init zsh" "$ZSHRC" 2>/dev/null; then
        run_as_user sed -i '/starship init zsh/d' "$ZSHRC" 2>/dev/null || true
        echo "  • Limpiadas referencias en ~/.zshrc"
    fi

    echo "✅ Starship desactivado. Abre una nueva terminal para volver al prompt nativo."
    echo "================================================================="
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE STARSHIP PROMPT - OPENSUSE TUMBLEWEED"
    echo "================================================================="
    if command -v starship &>/dev/null; then
        echo "• Binario starship:   ✅ $(command -v starship) ($(starship --version | head -n1))"
    else
        echo "• Binario starship:   ❌ No instalado"
    fi

    if [ -f "$STARSHIP_CONFIG" ]; then
        echo "• Configuración:      ✅ Presente ($STARSHIP_CONFIG)"
    else
        echo "• Configuración:      ❌ Ausente ($STARSHIP_CONFIG)"
    fi

    local bash_active="❌ Inactivo"
    if [ -f "$BASHRC_D/starship.sh" ]; then
        bash_active="✅ Activo (~/.bashrc.d/starship.sh)"
    elif [ -f "$BASHRC" ] && grep -q "starship init bash" "$BASHRC" 2>/dev/null; then
        bash_active="✅ Activo (inline en ~/.bashrc)"
    fi
    echo "• Integración Bash:   $bash_active"

    if [ -f "$ZSHRC" ]; then
        local zsh_active="❌ Inactivo"
        if [ -f "$ZSHRC_D/starship.zsh" ]; then
            zsh_active="✅ Activo (~/.zshrc.d/starship.zsh)"
        elif grep -q "starship init zsh" "$ZSHRC" 2>/dev/null; then
            zsh_active="✅ Activo (inline en ~/.zshrc)"
        fi
        echo "• Integración Zsh:    $zsh_active"
    fi
    echo "================================================================="
}

install_starship() {
    echo "================================================================="
    echo "🚀 Configurando Starship Prompt en openSUSE Tumbleweed"
    echo "================================================================="

    # 1. Instalar binario de Starship si falta
    if ! command -v starship &> /dev/null && ! rpm -q starship &>/dev/null; then
        echo "⬇️ [1/3] Instalando Starship vía Zypper..."
        if ! $SUDO zypper --non-interactive install -y starship; then
            echo "⚠️ Instalando mediante script oficial de Starship..."
            curl -sS https://starship.rs/install.sh | $SUDO sh -s -- -y
        fi
    else
        echo "✅ [1/3] Binario de Starship disponible: $(starship --version | head -n1)"
    fi

    # 2. Configurar starship.toml
    echo "⚙️ [2/3] Configurando archivo starship.toml..."
    deploy_config

    # 3. Activar en perfiles de shell
    echo "🔌 [3/3] Activando en perfiles de inicio..."
    enable_starship

    echo "================================================================="
    echo "✅ Starship Prompt instalado y configurado con éxito."
    echo "💡 Para ver los cambios en esta sesión: eval \"\$(starship init bash)\""
    echo "================================================================="
}

case "${1:-}" in
    --disable|-d|disable)
        disable_starship
        ;;
    --enable|-e|enable)
        enable_starship
        deploy_config
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
