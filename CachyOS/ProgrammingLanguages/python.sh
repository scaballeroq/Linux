#!/bin/bash
# ==============================================================================
# python.sh - Instalación y Optimización de Python y uv vía Mise
# Optimizado para CachyOS (PGO/LTO), KDE Plasma 6 (environment.d) y Zsh / Bash
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🐍 Instalando y Optimizando Python & uv para CachyOS"
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

# Flags de optimización para compilación de Python en CachyOS (PGO + LTO + multinúcleo)
NPROC=$(nproc 2>/dev/null || echo 4)
export MAKEFLAGS="-j$NPROC"
export PYTHON_CONFIGURE_OPTS="--enable-optimizations --with-lto"
export UV_LINK_MODE="copy"

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" MAKEFLAGS="-j$NPROC" PYTHON_CONFIGURE_OPTS="--enable-optimizations --with-lto" UV_LINK_MODE="copy" PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    else
        MAKEFLAGS="-j$NPROC" PYTHON_CONFIGURE_OPTS="--enable-optimizations --with-lto" UV_LINK_MODE="copy" PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    fi
}

# Exportar PATH para este proceso
export PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/bin:$PATH"

# 1. Asegurar que Mise está presente
if ! command -v mise &> /dev/null && [ ! -x "$USER_HOME/.local/bin/mise" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/mise.sh" ]; then
        echo "ℹ️ Mise no encontrado. Ejecutando instalador $SCRIPT_DIR/mise.sh..."
        bash "$SCRIPT_DIR/mise.sh"
    else
        echo "❌ Error: 'mise' no está instalado. Por favor ejecuta ./mise.sh primero."
        exit 1
    fi
fi

# 2. Dependencias de compilación y librerías del sistema para Python en CachyOS
echo "ℹ️ [1/5] Verificando dependencias nativas del sistema..."
MISSING_PKGS=$(pacman -T base-devel openssl zlib bzip2 readline sqlite curl git ncurses xz tk libffi 2>/dev/null || true)
if [ -n "$MISSING_PKGS" ]; then
    echo "  ⬇️ Instalando librerías requeridas: $MISSING_PKGS..."
    $SUDO pacman -S --needed --noconfirm $MISSING_PKGS
else
    echo "  ✅ Dependencias nativas ya instaladas."
fi

# 3. Instalar la última versión estable de Python y uv con Mise
echo "ℹ️ [2/5] Descargando e instalando Python (Latest) y uv vía Mise..."
run_as_user mise use --global python@latest
run_as_user mise use --global uv@latest

# 4. Actualizar pip, setuptools y wheel
echo "ℹ️ [3/5] Actualizando herramientas base de empaquetado (pip, setuptools, wheel)..."
run_as_user mise exec python@latest -- python -m pip install --upgrade pip setuptools wheel --quiet 2>/dev/null || true
run_as_user mise reshim 2>/dev/null || true

# 5. Integración con KDE Plasma 6 (environment.d) y Shells (Zsh / Bash)
echo "ℹ️ [4/5] Configurando variables de entorno para KDE Plasma 6 y Shells..."
ENV_DIR="$USER_HOME/.config/environment.d"
BASHRC_D="$USER_HOME/.bashrc.d"
ZSHRC_D="$USER_HOME/.zshrc.d"
run_as_user mkdir -p "$ENV_DIR" "$BASHRC_D" "$ZSHRC_D"

# 5.1. KDE Plasma 6 (sesión gráfica, VS Code, PyCharm, Antigravity)
cat << 'EOF' | run_as_user tee "$ENV_DIR/10-python.conf" > /dev/null
# Integración de Python & uv para KDE Plasma 6 / Wayland
PYTHONUNBUFFERED=1
UV_LINK_MODE=copy
EOF

# 5.2. Shell Zsh
cat << 'EOF' | run_as_user tee "$ZSHRC_D/python.zsh" > /dev/null
# Python & uv Environment Settings
export PYTHONUNBUFFERED=1
export UV_LINK_MODE=copy
EOF

# 5.3. Shell Bash
cat << 'EOF' | run_as_user tee "$BASHRC_D/python.sh" > /dev/null
# Python & uv Environment Settings
export PYTHONUNBUFFERED=1
export UV_LINK_MODE=copy
EOF

# 6. Configurar autocompletado en Zsh y Bash
echo "ℹ️ [5/5] Generando autocompletados para Zsh y Bash (uv, uvx, pip)..."
COMPLETIONS_DIR="$USER_HOME/.local/share/bash-completion/completions"
ZSH_COMPLETIONS_DIR="$USER_HOME/.local/share/zsh/site-functions"
ZFUNC_DIR="$USER_HOME/.zfunc"
run_as_user mkdir -p "$COMPLETIONS_DIR" "$ZSH_COMPLETIONS_DIR" "$ZFUNC_DIR"

if command -v mise &>/dev/null; then
    # uv autocompletion
    run_as_user mise exec uv@latest -- uv generate-shell-completion bash > "$COMPLETIONS_DIR/uv" 2>/dev/null || true
    run_as_user mise exec uv@latest -- uv generate-shell-completion zsh > "$ZSH_COMPLETIONS_DIR/_uv" 2>/dev/null || true
    run_as_user mise exec uv@latest -- uv generate-shell-completion zsh > "$ZFUNC_DIR/_uv" 2>/dev/null || true

    # uvx autocompletion
    run_as_user mise exec uv@latest -- uvx --generate-shell-completion bash > "$COMPLETIONS_DIR/uvx" 2>/dev/null || true
    run_as_user mise exec uv@latest -- uvx --generate-shell-completion zsh > "$ZSH_COMPLETIONS_DIR/_uvx" 2>/dev/null || true
    run_as_user mise exec uv@latest -- uvx --generate-shell-completion zsh > "$ZFUNC_DIR/_uvx" 2>/dev/null || true

    # pip autocompletion
    run_as_user mise exec python@latest -- pip completion --bash > "$COMPLETIONS_DIR/pip" 2>/dev/null || true
    run_as_user mise exec python@latest -- pip completion --zsh > "$ZSH_COMPLETIONS_DIR/_pip" 2>/dev/null || true
    run_as_user mise exec python@latest -- pip completion --zsh > "$ZFUNC_DIR/_pip" 2>/dev/null || true
fi

# Obtener versiones instaladas
PYTHON_VER=$(run_as_user mise exec python@latest -- python --version 2>/dev/null || echo "Python instalado")
UV_VER=$(run_as_user mise exec uv@latest -- uv --version 2>/dev/null || echo "uv instalado")
PIP_VER=$(run_as_user mise exec python@latest -- pip --version 2>/dev/null | awk '{print $2}' || echo "pip instalado")

echo "================================================================="
echo "✅ Python & uv configurados con éxito para CachyOS y KDE Plasma 6:"
echo "  • Python:      $PYTHON_VER"
echo "  • uv:          $UV_VER (Gestor ultrarrápido en Rust)"
echo "  • pip:         v$PIP_VER (setuptools + wheel actualizados)"
echo "  • KDE Plasma:  ~/.config/environment.d/10-python.conf"
echo "  • Shells:      Bash & Zsh con autocompletado nativo (_uv, _uvx, _pip)"
echo "================================================================="
