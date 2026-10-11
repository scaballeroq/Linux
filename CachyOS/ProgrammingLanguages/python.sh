#!/bin/bash
# ==============================================================================
# python.sh - Instalación y Optimización de Python y uv vía Mise
# Optimizado para CachyOS (PGO/LTO), GNOME (environment.d) y Zsh / Bash
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

# 2. Dependencias del sistema y librerías nativas para Python en CachyOS
echo "ℹ️ [1/5] Verificando dependencias nativas del sistema (python, gobject, base-devel)..."
MISSING_PKGS=$(pacman -T base-devel python python-pip python-gobject openssl zlib bzip2 readline sqlite curl git ncurses xz tk libffi 2>/dev/null || true)
if [ -n "$MISSING_PKGS" ]; then
    echo "  ⬇️ Instalando librerías requeridas: $MISSING_PKGS..."
    $SUDO pacman -S --needed --noconfirm $MISSING_PKGS
else
    echo "  ✅ Dependencias nativas ya instaladas."
fi

# 3. Instalar uv con Mise de forma global (Python se mantiene en el sistema para no romper apps como gnome-tweaks)
echo "ℹ️ [2/5] Instalando gestor uv vía Mise..."
run_as_user mise use --global uv@latest

# 4. Asegurar que no existan shims globales de Python en Mise
run_as_user mise unuse --global python 2>/dev/null || true
run_as_user mise reshim 2>/dev/null || true

# 5. Integración con GNOME (environment.d) y Shells (Bash predeterminado / Zsh condicional)
echo "ℹ️ [4/5] Configurando variables de entorno para GNOME y Shells..."
ENV_DIR="$USER_HOME/.config/environment.d"
BASHRC_D="$USER_HOME/.bashrc.d"
run_as_user mkdir -p "$ENV_DIR" "$BASHRC_D"

# 5.1. GNOME (sesión gráfica, VS Code, PyCharm, Antigravity)
cat << 'EOF' | run_as_user tee "$ENV_DIR/10-python.conf" > /dev/null
# Integración de Python & uv para GNOME / Wayland
PYTHONUNBUFFERED=1
UV_LINK_MODE=copy
EOF

# 5.2. Shell Bash (Predeterminada)
cat << 'EOF' | run_as_user tee "$BASHRC_D/python.sh" > /dev/null
# Python & uv Environment Settings
export PYTHONUNBUFFERED=1
export UV_LINK_MODE=copy
EOF

# 5.3. Shell Zsh (Compatibilidad condicional si existe ~/.zshrc)
if [ -f "$USER_HOME/.zshrc" ]; then
    ZSHRC_D="$USER_HOME/.zshrc.d"
    run_as_user mkdir -p "$ZSHRC_D"
    cat << 'EOF' | run_as_user tee "$ZSHRC_D/python.zsh" > /dev/null
# Python & uv Environment Settings
export PYTHONUNBUFFERED=1
export UV_LINK_MODE=copy
EOF
fi

# 6. Configurar autocompletado (Bash siempre; Zsh si existe ~/.zshrc)
echo "ℹ️ [5/5] Generando autocompletados para Bash (y Zsh si existe ~/.zshrc)..."
COMPLETIONS_DIR="$USER_HOME/.local/share/bash-completion/completions"
run_as_user mkdir -p "$COMPLETIONS_DIR"

if command -v mise &>/dev/null; then
    # uv autocompletion (Bash)
    run_as_user mise exec uv@latest -- uv generate-shell-completion bash > "$COMPLETIONS_DIR/uv" 2>/dev/null || true

    # uvx autocompletion (Bash)
    run_as_user mise exec uv@latest -- uvx --generate-shell-completion bash > "$COMPLETIONS_DIR/uvx" 2>/dev/null || true

    # pip autocompletion (Bash)
    python3 -m pip completion --bash > "$COMPLETIONS_DIR/pip" 2>/dev/null || true

    # Zsh autocompletions (condicional)
    if [ -f "$USER_HOME/.zshrc" ]; then
        ZSH_COMPLETIONS_DIR="$USER_HOME/.local/share/zsh/site-functions"
        ZFUNC_DIR="$USER_HOME/.zfunc"
        run_as_user mkdir -p "$ZSH_COMPLETIONS_DIR" "$ZFUNC_DIR"

        run_as_user mise exec uv@latest -- uv generate-shell-completion zsh > "$ZSH_COMPLETIONS_DIR/_uv" 2>/dev/null || true
        run_as_user mise exec uv@latest -- uv generate-shell-completion zsh > "$ZFUNC_DIR/_uv" 2>/dev/null || true

        run_as_user mise exec uv@latest -- uvx --generate-shell-completion zsh > "$ZSH_COMPLETIONS_DIR/_uvx" 2>/dev/null || true
        run_as_user mise exec uv@latest -- uvx --generate-shell-completion zsh > "$ZFUNC_DIR/_uvx" 2>/dev/null || true

        python3 -m pip completion --zsh > "$ZSH_COMPLETIONS_DIR/_pip" 2>/dev/null || true
        python3 -m pip completion --zsh > "$ZFUNC_DIR/_pip" 2>/dev/null || true
    fi
fi

# Obtener versiones instaladas
PYTHON_VER=$(python3 --version 2>/dev/null || echo "Python nativo del sistema")
UV_VER=$(run_as_user mise exec uv@latest -- uv --version 2>/dev/null || echo "uv instalado")
PIP_VER=$(python3 -m pip --version 2>/dev/null | awk '{print $2}' || echo "pip del sistema")

echo "================================================================="
echo "✅ Python & uv configurados con éxito para CachyOS y GNOME:"
echo "  • Python:      $PYTHON_VER"
echo "  • uv:          $UV_VER (Gestor ultrarrápido en Rust)"
echo "  • pip:         v$PIP_VER (setuptools + wheel actualizados)"
echo "  • GNOME:       ~/.config/environment.d/10-python.conf"
echo "  • Shells:      Bash (predeterminada)$([ -f "$USER_HOME/.zshrc" ] && echo " & Zsh (compatible)") con autocompletado nativo"
echo "================================================================="
