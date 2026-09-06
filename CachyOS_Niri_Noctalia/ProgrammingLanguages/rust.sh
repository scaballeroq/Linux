#!/bin/bash
# ==============================================================================
# rust.sh - Instalación de Rust (Canal Stable / Producción) y Cargo-Binstall
# Optimizado para CachyOS, KDE Plasma 6 (Wayland) y Zsh / Bash (IDEs y CLI)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🦀 Instalando Rust (Canal Stable / Producción) para CachyOS"
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

# 1. Dependencias de compilación para Rust y módulos nativos en CachyOS
echo "ℹ️ [1/4] Verificando dependencias de compilación para Rust (CachyOS toolchain)..."
MISSING_PKGS=$(pacman -T base-devel cmake openssl pkgconf curl git 2>/dev/null || true)
if [ -n "$MISSING_PKGS" ]; then
    echo "  ⬇️ Instalando librerías de compilación: $MISSING_PKGS..."
    $SUDO pacman -S --needed --noconfirm $MISSING_PKGS
else
    echo "  ✅ Dependencias de compilación ya instaladas."
fi

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

# 5. Integración con KDE Plasma 6 (environment.d) y Shells (Zsh / Bash)
echo "ℹ️ [4/4] Configurando integración con KDE Plasma 6 y Shells..."
ENV_DIR="$USER_HOME/.config/environment.d"
run_as_user mkdir -p "$ENV_DIR"

cat << 'EOF' | run_as_user tee "$ENV_DIR/10-rust.conf" > /dev/null
# Integración de Rust / Cargo para KDE Plasma 6 y entornos gráficos (IDEs, KRunner)
PATH=${HOME}/.cargo/bin:${PATH}
EOF

# Integración modular en Shells (Bash y Zsh)
BASHRC_D="$USER_HOME/.bashrc.d"
ZSHRC_D="$USER_HOME/.zshrc.d"
run_as_user mkdir -p "$BASHRC_D" "$ZSHRC_D"

cat << 'EOF' | run_as_user tee "$BASHRC_D/rust.sh" > /dev/null
# Rust & Cargo Environment
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
EOF

cat << 'EOF' | run_as_user tee "$ZSHRC_D/rust.zsh" > /dev/null
# Rust & Cargo Environment
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
EOF

# Fallback para .bashrc
if [ -f "$USER_HOME/.bashrc" ] && ! grep -q ".cargo/env" "$USER_HOME/.bashrc" 2>/dev/null; then
    if ! grep -q ".bashrc.d" "$USER_HOME/.bashrc" 2>/dev/null; then
        echo -e '\n# Rust Environment\nif [ -f "$HOME/.cargo/env" ]; then . "$HOME/.cargo/env"; fi' | run_as_user tee -a "$USER_HOME/.bashrc" > /dev/null
    fi
fi

# Autocompletados de Rustup y Cargo
COMPLETIONS_DIR="$USER_HOME/.local/share/bash-completion/completions"
ZSH_COMPLETIONS_DIR="$USER_HOME/.local/share/zsh/site-functions"
ZFUNC_DIR="$USER_HOME/.zfunc"
run_as_user mkdir -p "$COMPLETIONS_DIR" "$ZSH_COMPLETIONS_DIR" "$ZFUNC_DIR"

if command -v rustup &>/dev/null || [ -x "$USER_HOME/.cargo/bin/rustup" ]; then
    run_as_user rustup completions bash > "$COMPLETIONS_DIR/rustup" 2>/dev/null || true
    run_as_user rustup completions bash cargo > "$COMPLETIONS_DIR/cargo" 2>/dev/null || true
    run_as_user rustup completions zsh > "$ZSH_COMPLETIONS_DIR/_rustup" 2>/dev/null || true
    run_as_user rustup completions zsh cargo > "$ZSH_COMPLETIONS_DIR/_cargo" 2>/dev/null || true
    run_as_user rustup completions zsh > "$ZFUNC_DIR/_rustup" 2>/dev/null || true
    run_as_user rustup completions zsh cargo > "$ZFUNC_DIR/_cargo" 2>/dev/null || true
fi

# Obtener versiones instaladas
RUSTC_VER=$(run_as_user rustc --version 2>/dev/null || echo "instalado")
CARGO_VER=$(run_as_user cargo --version 2>/dev/null || echo "instalado")
BINSTALL_VER=$(run_as_user cargo-binstall --version 2>/dev/null || echo "disponible")

echo "================================================================="
echo "✅ Rust (Stable) configurado con éxito para CachyOS y KDE Plasma 6:"
echo "  • Rustc:       $RUSTC_VER"
echo "  • Cargo:       $CARGO_VER"
echo "  • Binstall:    $BINSTALL_VER"
echo "  • IDE Tools:   rust-analyzer, clippy, rustfmt, rust-src"
echo "  • KDE Plasma:  ~/.config/environment.d/10-rust.conf"
echo "  • Shells:      Autocompletado Bash & Zsh (_cargo, _rustup)"
echo "================================================================="
