#!/bin/bash
# ==============================================================================
# mise.sh - Instalador y Optimizador de Mise (Language Runtime Manager)
# Adaptado para CachyOS + KDE Plasma 6 (Wayland / Systemd User Environment)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "⚡ Configurando Mise (Gestor de Runtimes) para CachyOS + KDE Plasma 6"
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

# 1. Instalación del binario Mise
echo "ℹ️ [1/4] Verificando e instalando Mise..."
if ! command -v mise &> /dev/null && [ ! -x "$USER_HOME/.local/bin/mise" ]; then
    echo "⬇️ Instalando Mise vía Pacman..."
    $SUDO pacman -S --needed --noconfirm mise 2>/dev/null || {
        echo "⚠️ Fallback: Descargando Mise standalone..."
        run_as_user curl -fsSL https://mise.run | run_as_user sh
    }
else
    echo "✅ Mise ya está instalado en el sistema."
fi

# Exportar PATH para la ejecución de este script
export PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/bin:$PATH"

# 2. Integración con el entorno gráfico de KDE Plasma 6 (Systemd Environment Generators)
# Permite que IDEs (Antigravity, VS Code, JetBrains), KRunner y Dolphin hereden los runtimes de Mise
echo "ℹ️ [2/4] Configurando variables de entorno para KDE Plasma 6 (environment.d)..."
ENV_DIR="$USER_HOME/.config/environment.d"
run_as_user mkdir -p "$ENV_DIR"

cat << 'EOF' | run_as_user tee "$ENV_DIR/10-mise.conf" > /dev/null
# Integración de Mise con la sesión gráfica de KDE Plasma 6 / Wayland
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
if [ -f "$USER_HOME/.bashrc" ] && ! grep -q "mise activate" "$USER_HOME/.bashrc" 2>/dev/null; then
    if ! grep -q ".bashrc.d" "$USER_HOME/.bashrc" 2>/dev/null; then
        echo -e '\n# Mise (Language Version Manager)\nif command -v mise &>/dev/null; then eval "$(mise activate bash)"; fi' | run_as_user tee -a "$USER_HOME/.bashrc" > /dev/null
    fi
fi

# 3.2. Zsh
ZSHRC="$USER_HOME/.zshrc"
ZSHRC_D="$USER_HOME/.zshrc.d"
if [ -d "$ZSHRC_D" ]; then
    cat << 'EOF' | run_as_user tee "$ZSHRC_D/mise.zsh" > /dev/null
# =============================================================================
# MISE VERSION MANAGER (Zsh Shell Activation)
# =============================================================================
if command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi
EOF
fi

if [ -f "$ZSHRC" ] || [[ "${SHELL:-}" == *"zsh"* ]]; then
    run_as_user touch "$ZSHRC"
    if ! grep -q "mise activate zsh" "$ZSHRC" 2>/dev/null; then
        echo -e '\n# Mise (Language Version Manager)\nif command -v mise &>/dev/null; then eval "$(mise activate zsh)"; fi' | run_as_user tee -a "$ZSHRC" > /dev/null
        echo "  ✅ Activación de Mise añadida a ~/.zshrc"
    fi
fi

# 3.3. Autocompletados (Bash y Zsh)
COMPLETIONS_DIR="$USER_HOME/.local/share/bash-completion/completions"
ZSH_COMPLETIONS_DIR="$USER_HOME/.local/share/zsh/site-functions"
ZFUNC_DIR="$USER_HOME/.zfunc"
run_as_user mkdir -p "$COMPLETIONS_DIR" "$ZSH_COMPLETIONS_DIR" "$ZFUNC_DIR"

if command -v mise &>/dev/null; then
    run_as_user mise completion bash > "$COMPLETIONS_DIR/mise" 2>/dev/null || true
    run_as_user mise completion zsh > "$ZSH_COMPLETIONS_DIR/_mise" 2>/dev/null || true
    run_as_user mise completion zsh > "$ZFUNC_DIR/_mise" 2>/dev/null || true
fi

# 4. Generar Shims iniciales
echo "ℹ️ [4/4] Inicializando y regenerando shims de Mise..."
if command -v mise &>/dev/null; then
    run_as_user mise reshim 2>/dev/null || true
fi

echo "================================================================="
echo "✅ Mise configurado con éxito para CachyOS y KDE Plasma 6:"
echo "  • CLI & Shims:  ~/.local/share/mise/shims y /usr/bin/mise"
echo "  • KDE Plasma 6: ~/.config/environment.d/10-mise.conf (sesión gráfica e IDEs)"
echo "  • Shell Bash:   ~/.bashrc.d/mise.sh + autocompletado"
echo "  • Shell Zsh:    ~/.zshrc + autocompletado (_mise)"
echo "================================================================="
