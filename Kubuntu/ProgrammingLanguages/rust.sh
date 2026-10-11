#!/bin/bash
# =============================================================================
# rust.sh - Instalador y Configurador de Rust y Cargo para Kubuntu
# =============================================================================
# - Instala dependencias de compilación del sistema (GCC, CMake, OpenSSL, LLD)
# - Instala la cadena de herramientas Rust estable vía rustup
# - Añade componentes esenciales para IDEs: rust-analyzer, clippy, rustfmt, rust-src
# - Instala cargo-binstall para descargas binarias rápidas de crates
# - Configura ~/.bashrc.d/rust.sh y ~/.config/environment.d/30-rust.conf para KDE Plasma
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "Error: Este script requiere privilegios de superusuario."
        exit 1
    fi
else
    SUDO=""
fi

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
Instalador de Rust (Rustup, Cargo, Rust-Analyzer) - Kubuntu

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Instala dependencias, Rust estable, componentes de IDE y cargo-binstall.
  --status, -s           Muestra la versión de rustc, cargo, rust-analyzer y componentes instalados.
  --update, -u           Actualiza la cadena de herramientas de Rust vía rustup.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE RUST Y HERRAMIENTAS - KUBUNTU"
    echo "================================================================="
    echo "Rustc (Compilador):            $(run_as_user rustc --version 2>/dev/null || echo 'No instalado')"
    echo "Cargo (Gestor de paquetes):    $(run_as_user cargo --version 2>/dev/null || echo 'No instalado')"
    echo "Rust-Analyzer (LSP para IDEs): $(run_as_user rust-analyzer --version 2>/dev/null || echo 'No instalado')"
    echo "Cargo-Binstall:                $(run_as_user cargo-binstall --version 2>/dev/null || echo 'No instalado')"
    echo "Directorio Cargo:              $USER_HOME/.cargo/bin"
    echo "================================================================="
    if [ -d "$USER_HOME/.cargo/bin" ]; then
        echo ""
        echo "Cadenas de herramientas (Rustup):"
        run_as_user rustup show 2>/dev/null || true
    fi
}

install_rust() {
    echo "================================================================="
    echo "INSTALANDO RUST Y ENTORNO DE DESARROLLO - KUBUNTU"
    echo "================================================================="

    # 1. Dependencias del sistema
    echo "ℹ️ [1/5] Instalando dependencias del sistema (build-essential, cmake, libssl, pkg-config, lld)..."
    $SUDO apt update
    $SUDO apt install -y \
        build-essential \
        cmake \
        libssl-dev \
        pkg-config \
        curl \
        git \
        lld \
        clang \
        2>/dev/null || true

    # 2. Instalar o actualizar Rust vía rustup bajo la identidad del usuario real
    if [ ! -f "$USER_HOME/.cargo/bin/rustup" ] && ! command -v rustup &>/dev/null; then
        echo "ℹ️ [2/5] Descargando e instalando Rust (rustup stable)..."
        run_as_user curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | run_as_user sh -s -- -y --no-modify-path --default-toolchain stable
    else
        echo "ℹ️ [2/5] Rust ya está instalado. Actualizando a la última versión estable..."
        run_as_user rustup update stable || true
    fi

    # 3. Componentes esenciales para IDEs y desarrollo profesional
    echo "ℹ️ [3/5] Añadiendo componentes (rust-analyzer, clippy, rustfmt, rust-src)..."
    run_as_user rustup component add rust-analyzer clippy rustfmt rust-src 2>/dev/null || true

    # 4. Instalar cargo-binstall (permite instalar crates binarios en segundos sin compilar de cero)
    echo "ℹ️ [4/5] Configurando cargo-binstall..."
    if ! run_as_user cargo-binstall --version &>/dev/null; then
        run_as_user curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | run_as_user bash 2>/dev/null || true
    fi

    # 5. Integración modular con Bash y KDE Plasma
    echo "ℹ️ [5/5] Configurando integración con Bash (.bashrc.d) y KDE Plasma (environment.d)..."
    run_as_user mkdir -p "$USER_HOME/.bashrc.d" "$USER_HOME/.config/environment.d"

    cat <<'EOF' > "$USER_HOME/.bashrc.d/rust.sh"
# Rust & Cargo Environment
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
EOF
    chown "$REAL_USER:$REAL_USER" "$USER_HOME/.bashrc.d/rust.sh" 2>/dev/null || true

    cat <<'EOF' > "$USER_HOME/.config/environment.d/30-rust.conf"
PATH=$HOME/.cargo/bin:$PATH
EOF
    chown "$REAL_USER:$REAL_USER" "$USER_HOME/.config/environment.d/30-rust.conf" 2>/dev/null || true

    echo ""
    echo "================================================================="
    echo "✅ Rust instalado y configurado con éxito para '$REAL_USER'."
    echo "   - Rustc         : $(run_as_user rustc --version 2>/dev/null || echo 'stable')"
    echo "   - Cargo         : $(run_as_user cargo --version 2>/dev/null || echo 'stable')"
    echo "   - Rust-Analyzer : $(run_as_user rust-analyzer --version 2>/dev/null || echo 'disponible')"
    echo "================================================================="
}

case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --update|-u)
        echo "Actualizando cadena de herramientas Rust..."
        run_as_user rustup update stable
        ;;
    "")
        install_rust
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
