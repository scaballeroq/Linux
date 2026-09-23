#!/bin/bash
# ==============================================================================
# mise.sh - Instalador y Optimizador de Mise (Language Runtime Manager)
# openSUSE Tumbleweed (KDE Plasma 6 + Wayland / Systemd User Environment)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "⚡ Configurando Mise (Gestor de Runtimes) para openSUSE Tumbleweed"
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
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# 1. Instalación del binario Mise vía repositorio RPM o instalador oficial
echo "ℹ️ [1/4] Verificando e instalando Mise..."
if ! command -v mise &> /dev/null && [ ! -x "$USER_HOME/.local/bin/mise" ]; then
    echo "⬇️ Configurando repositorio RPM oficial de Mise para openSUSE..."
    $SUDO rpm --import https://mise.jdx.dev/gpg-key.pub 2>/dev/null || true
    if ! zypper lr 2>/dev/null | grep -qi "mise"; then
        $SUDO zypper --non-interactive ar -f https://mise.jdx.dev/rpm mise 2>/dev/null || true
    fi
    $SUDO zypper --gpg-auto-import-keys refresh mise 2>/dev/null || true
    $SUDO zypper --non-interactive install -y mise 2>/dev/null || {
        echo "⚠️ Fallback: Descargando e instalando Mise standalone..."
        run_as_user curl -fsSL https://mise.run | run_as_user sh
    }
else
    echo "✅ Mise ya está instalado en el sistema."
fi

# Exportar PATH para la ejecución de este script
export PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/bin:$PATH"

# 2. Integración con el entorno gráfico de KDE Plasma (Systemd Environment Generators)
# Permite que IDEs (Antigravity, Kate, VS Code) y la sesión hereden los runtimes de Mise
echo "ℹ️ [2/4] Configurando variables de entorno para la sesión gráfica (environment.d)..."
ENV_DIR="$USER_HOME/.config/environment.d"
run_as_user mkdir -p "$ENV_DIR"

cat << 'EOF' | run_as_user tee "$ENV_DIR/10-mise.conf" > /dev/null
# Integración de Mise con la sesión gráfica / Wayland
PATH=${HOME}/.local/share/mise/shims:${HOME}/.local/bin:${PATH}
MISE_SHELL=bash
COREPACK_ENABLE_DOWNLOAD_PROMPT=0
EOF

# 3. Integración en Shells (Bash y Zsh)
echo "ℹ️ [3/4] Configurando integración en terminales (Bash & Zsh)..."

# 3.1. Bash
BASHRC_D="$USER_HOME/.bashrc.d"
run_as_user mkdir -p "$BASHRC_D"
cat << 'EOF' | run_as_user tee "$BASHRC_D/mise.sh" > /dev/null
# =============================================================================
# MISE VERSION MANAGER (Bash Shell Activation)
# =============================================================================
if command -v mise &>/dev/null; then
    eval "$(mise activate bash)"
fi
EOF

# Fallback si no se lee .bashrc.d
BASHRC="$USER_HOME/.bashrc"
run_as_user touch "$BASHRC"
if ! grep -q "mise activate" "$BASHRC" 2>/dev/null; then
    if ! grep -q ".bashrc.d" "$BASHRC" 2>/dev/null; then
        echo -e '\n# Mise (Language Version Manager)\nif command -v mise &>/dev/null; then eval "$(mise activate bash)"; fi' | run_as_user tee -a "$BASHRC" > /dev/null
    fi
fi

# 3.2. Zsh (condicional)
if [ -f "$USER_HOME/.zshrc" ]; then
    ZSHRC_D="$USER_HOME/.zshrc.d"
    run_as_user mkdir -p "$ZSHRC_D"
    cat << 'EOF' | run_as_user tee "$ZSHRC_D/mise.zsh" > /dev/null
# =============================================================================
# MISE VERSION MANAGER (Zsh Shell Activation)
# =============================================================================
if command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi
EOF
    if ! grep -q "mise activate" "$USER_HOME/.zshrc" 2>/dev/null; then
        if ! grep -q ".zshrc.d" "$USER_HOME/.zshrc" 2>/dev/null; then
            echo -e '\n# Mise (Language Version Manager)\nif command -v mise &>/dev/null; then eval "$(mise activate zsh)"; fi' | run_as_user tee -a "$USER_HOME/.zshrc" > /dev/null
        fi
    fi
fi

# 4. Generar autocompletado nativo
echo "ℹ️ [4/4] Generando autocompletado para Bash (y Zsh)..."
COMPLETIONS_DIR="$USER_HOME/.local/share/bash-completion/completions"
run_as_user mkdir -p "$COMPLETIONS_DIR"
if command -v mise &>/dev/null; then
    run_as_user mise completion bash > "$COMPLETIONS_DIR/mise" 2>/dev/null || true
    if [ -f "$USER_HOME/.zshrc" ]; then
        ZSH_COMPLETIONS_DIR="$USER_HOME/.local/share/zsh/site-functions"
        run_as_user mkdir -p "$ZSH_COMPLETIONS_DIR"
        run_as_user mise completion zsh > "$ZSH_COMPLETIONS_DIR/_mise" 2>/dev/null || true
    fi
fi

echo "================================================================="
echo "✅ Mise configurado con éxito para openSUSE Tumbleweed y KDE Plasma 6:"
echo "  • Binario:   $(which mise 2>/dev/null || echo "$USER_HOME/.local/bin/mise")"
echo "  • Versión:   $(run_as_user mise --version 2>/dev/null || echo 'instalado')"
echo "  • Entorno:   ~/.config/environment.d/10-mise.conf"
echo "  • Shells:    Bash (~/.bashrc.d/mise.sh)$([ -f "$USER_HOME/.zshrc" ] && echo " & Zsh (~/.zshrc.d/mise.zsh)")"
echo "================================================================="
