#!/bin/bash
# ==============================================================================
# rust.sh - Instalación de Rust (Canal Stable / Producción) y Cargo-Binstall
# Optimizado para openSUSE Tumbleweed, KDE Plasma 6 y Zsh / Bash
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🦀 Instalando Rust (Canal Stable / Producción) para openSUSE Tumbleweed"
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
        sudo -u "$REAL_USER" env HOME="$USER_HOME" PATH="$USER_HOME/.cargo/bin:$USER_HOME/.local/bin:$PATH" "$@"
    else
        PATH="$USER_HOME/.cargo/bin:$USER_HOME/.local/bin:$PATH" "$@"
    fi
}

# Exportar PATH para este proceso
export PATH="$USER_HOME/.cargo/bin:$USER_HOME/.local/bin:/usr/bin:$PATH"

# 1. Dependencias de compilación para Rust y módulos nativos en openSUSE
echo "ℹ️ [1/4] Verificando dependencias de compilación para Rust..."
$SUDO zypper --non-interactive install -y -t pattern devel_basis 2>/dev/null || true
$SUDO zypper --non-interactive install -y cmake libopenssl-devel pkg-config curl git 2>/dev/null || true
echo "  ✅ Dependencias de compilación preparadas."

# 2. Instalación / Actualización de Rust vía Rustup (Canal Stable)
echo "ℹ️ [2/4] Configurando Rustup y canal Stable..."
if [ ! -x "$USER_HOME/.cargo/bin/rustup" ] && ! command -v rustup &> /dev/null; then
    echo "  ⬇️ Descargando e instalando Rustup..."
    run_as_user curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | run_as_user sh -s -- -y --default-toolchain stable --profile default --no-modify-path
else
    echo "  🔄 Actualizando toolchain Rust Stable..."
    run_as_user rustup default stable 2>/dev/null || true
    run_as_user rustup update stable 2>/dev/null || true
fi

# 3. Componentes esenciales para desarrollo e IDEs (rust-analyzer, clippy, rustfmt, rust-src)
echo "ℹ️ [3/4] Instalando componentes para IDEs (rust-analyzer, clippy, rustfmt)..."
run_as_user rustup component add rust-src rust-analyzer clippy rustfmt 2>/dev/null || true

# 4. Instalación de cargo-binstall (descargas binarias ultra-rápidas sin compilar)
if [ ! -x "$USER_HOME/.cargo/bin/cargo-binstall" ] && ! command -v cargo-binstall &> /dev/null; then
    echo "  ⬇️ Instalando cargo-binstall para descargas precompiladas..."
    run_as_user curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | run_as_user bash 2>/dev/null || true
else
    echo "  ✅ cargo-binstall ya está instalado."
fi

# 5. Integración con el entorno gráfico y Shells (Bash predeterminado / Zsh condicional)
echo "ℹ️ [4/4] Configurando integración de Cargo y Rust en terminales..."
ENV_DIR="$USER_HOME/.config/environment.d"
BASHRC_D="$USER_HOME/.bashrc.d"
run_as_user mkdir -p "$ENV_DIR" "$BASHRC_D"

# 5.1. Sesión gráfica (environment.d)
cat << 'EOF' | run_as_user tee "$ENV_DIR/10-rust.conf" > /dev/null
# Integración de Cargo/Rust con la sesión gráfica
PATH=${HOME}/.cargo/bin:${PATH}
EOF

# 5.2. Shell Bash
cat << 'EOF' | run_as_user tee "$BASHRC_D/rust.sh" > /dev/null
# Rust & Cargo Environment
if [ -d "$HOME/.cargo/bin" ] && [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi
EOF

# Fallback si no se procesa .bashrc.d
BASHRC="$USER_HOME/.bashrc"
if [ -f "$BASHRC" ] && ! grep -q "cargo/bin" "$BASHRC" 2>/dev/null; then
    if ! grep -q ".bashrc.d" "$BASHRC" 2>/dev/null; then
        echo -e '\n# Rust & Cargo\nexport PATH="$HOME/.cargo/bin:$PATH"' | run_as_user tee -a "$BASHRC" > /dev/null
    fi
fi

# 5.3. Shell Zsh (condicional)
if [ -f "$USER_HOME/.zshrc" ]; then
    ZSHRC_D="$USER_HOME/.zshrc.d"
    run_as_user mkdir -p "$ZSHRC_D"
    cat << 'EOF' | run_as_user tee "$ZSHRC_D/rust.zsh" > /dev/null
# Rust & Cargo Environment
if [ -d "$HOME/.cargo/bin" ] && [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi
EOF
fi

# 6. Autocompletados de Cargo y Rustup
COMPLETIONS_DIR="$USER_HOME/.local/share/bash-completion/completions"
run_as_user mkdir -p "$COMPLETIONS_DIR"
run_as_user rustup completions bash > "$COMPLETIONS_DIR/rustup" 2>/dev/null || true
run_as_user rustup completions bash cargo > "$COMPLETIONS_DIR/cargo" 2>/dev/null || true

# Obtener versiones instaladas
RUSTC_VER=$(run_as_user rustc --version 2>/dev/null || echo "instalado")
CARGO_VER=$(run_as_user cargo --version 2>/dev/null || echo "instalado")
ANALYZER_VER=$(run_as_user rust-analyzer --version 2>/dev/null | awk '{print $1, $2}' || echo "disponible")

echo "================================================================="
echo "✅ Rust Toolchain configurado con éxito para openSUSE Tumbleweed:"
echo "  • Rustc:         $RUSTC_VER"
echo "  • Cargo:         $CARGO_VER"
echo "  • rust-analyzer: $ANALYZER_VER"
echo "  • Herramientas:  clippy, rustfmt, cargo-binstall"
echo "  • Entorno:       ~/.cargo/bin (enlazado a environment.d y Shells)"
echo "================================================================="
