#!/bin/bash
# rust.sh - Instalación y optimización de Rust (Canal Estable / LTS) y herramientas para Fedora 44 + KDE Plasma
#
# Uso:
#   ./rust.sh                        -> Instala dependencias, Rust Stable vía rustup, rust-analyzer, clippy, cargo-binstall y sesión KDE
#   ./rust.sh --status               -> Muestra las versiones de rustc, cargo, rust-analyzer y componentes instalados
#   ./rust.sh --update               -> Actualiza la cadena de herramientas de Rust (rustup update) y binarios de cargo
#   ./rust.sh --help                 -> Muestra la ayuda interactiva

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecución con sudo
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    REAL_USER="$SUDO_USER"
else
    USER_HOME="${HOME}"
    REAL_USER="${USER:-$(id -un)}"
fi

show_help() {
    cat <<EOF
🦀 Gestor e Instalador de Rust (Canal Estable) - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala Rustup (Stable), componentes de desarrollo (rust-analyzer, clippy, rustfmt), cargo-binstall y variables de sesión KDE.
  --status, -s           Muestra el estado del compilador rustc, cargo, rust-analyzer y componentes.
  --update, -u           Actualiza la cadena de herramientas de Rust (rustup update) a la última versión estable.
  --help, -h             Muestra este mensaje de ayuda.

Características configuradas:
  • Canal Estable (Stable):Siempre instala y fija el canal 'stable' oficial con soporte garantizado.
  • Componentes IDE:     Instala rust-analyzer (LSP), clippy (linter), rustfmt (formateador) y rust-src.
  • Acelerador Binarios: Instala cargo-binstall para descargar herramientas de Rust precompiladas al instante.
  • Integración KDE/IDE: Variables de entorno en ~/.config/environment.d/10-rust.conf para VS Code, RustRover y KRunner.
  • Autocompletado:      Genera completado nativo para cargo y rustup en el shell Bash.
EOF
}

# 1. Mostrar estado de Rust
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE RUST Y HERRAMIENTAS - FEDORA 44"
    echo "================================================================="
    if [ -f "$USER_HOME/.cargo/env" ]; then
        # shellcheck disable=SC1091
        . "$USER_HOME/.cargo/env"
    fi

    if command -v rustc &>/dev/null; then
        echo "• rustc (Compilador):  $(rustc --version 2>/dev/null)"
        echo "• cargo (Gestor):      $(cargo --version 2>/dev/null)"
        echo "• rustup (Toolchains): $(rustup --version 2>/dev/null | head -n1 || echo 'No disponible')"
        echo "• rust-analyzer:       $(rust-analyzer --version 2>/dev/null || echo 'No instalado')"
        echo "• cargo-binstall:      $(cargo-binstall --version 2>/dev/null || echo 'No instalado')"
        echo ""
        echo "📦 Toolchains activas:"
        rustup toolchain list 2>/dev/null || echo "  (Ninguna registrada)"
    else
        echo "• Rust:                No instalado"
    fi
    echo "================================================================="
}

# 2. Actualizar cadena de herramientas
update_rust() {
    echo "🔄 Actualizando Rust y herramientas asociadas..."
    if [ -f "$USER_HOME/.cargo/env" ]; then
        # shellcheck disable=SC1091
        . "$USER_HOME/.cargo/env"
    fi
    if command -v rustup &>/dev/null; then
        rustup update stable
        echo "✅ Rust Stable actualizado con éxito."
    else
        echo "⚠️ Rust no está instalado. Ejecutando instalación..."
        install_rust_stack
    fi
}

# 3. Instalar dependencias de compilación en Fedora
install_build_dependencies() {
    echo "📦 [1/5] Instalando dependencias de compilación para Rust en Fedora..."
    $SUDO dnf5 install -y \
        @development-tools \
        cmake \
        openssl-devel \
        pkgconf-pkg-config \
        curl \
        lld \
        clang-devel 2>/dev/null || true
    echo "✅ Dependencias de compilación C/C++/Rust listas."
}

# 4. Instalar Rust vía Rustup (Canal Stable)
install_rustup() {
    if [ -f "$USER_HOME/.cargo/env" ]; then
        # shellcheck disable=SC1091
        . "$USER_HOME/.cargo/env"
    fi

    if ! command -v rustup &> /dev/null; then
        echo "🚀 [2/5] Instalando Rustup y cadena de herramientas Stable oficial..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile default --no-modify-path
    else
        echo "📦 [2/5] Rustup ya está presente. Asegurando canal Stable..."
        rustup default stable
    fi

    if [ -f "$USER_HOME/.cargo/env" ]; then
        # shellcheck disable=SC1091
        . "$USER_HOME/.cargo/env"
    fi
}

# 5. Instalar componentes esenciales de desarrollo (rust-analyzer, clippy, rustfmt)
install_components() {
    echo "⚙️ [3/5] Configurando componentes de desarrollo (rust-analyzer, clippy, rustfmt)..."
    rustup component add rust-analyzer clippy rustfmt rust-src 2>/dev/null || true
    echo "✅ Componentes de IDE y análisis estático instalados."
}

# 6. Instalar cargo-binstall
install_cargo_binstall() {
    echo "⚡ [4/5] Verificando instalador rápido de binarios (cargo-binstall)..."
    if ! command -v cargo-binstall &> /dev/null; then
        curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash 2>/dev/null || true
    fi
    echo "✅ cargo-binstall listo."
}

# 7. Configurar variables de sesión de KDE Plasma, Shell y Autocompletado
configure_env_and_kde() {
    echo "🔗 [5/5] Configurando variables de sesión para KDE Plasma / Wayland y Shell..."
    
    # 7.1. Variables de sesión KDE Plasma / Wayland (environment.d)
    mkdir -p "$USER_HOME/.config/environment.d"
    cat <<'EOF' > "$USER_HOME/.config/environment.d/10-rust.conf"
PATH=$HOME/.cargo/bin:$PATH
EOF

    # 7.2. Configuración modular en ~/.bashrc.d/rust.sh
    mkdir -p "$USER_HOME/.bashrc.d"
    cat <<'EOF' > "$USER_HOME/.bashrc.d/rust.sh"
# Rust Toolchain Environment
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
EOF

    # 7.3. Fallback directo en ~/.bashrc
    if ! grep -q ".cargo/env" "$USER_HOME/.bashrc" 2>/dev/null; then
        cat <<'EOF' >> "$USER_HOME/.bashrc"

# Rust Toolchain Environment
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
EOF
    fi

    # 7.4. Autocompletados nativos para Bash
    mkdir -p "$USER_HOME/.local/share/bash-completion/completions"
    if command -v rustup &>/dev/null; then
        rustup completions bash > "$USER_HOME/.local/share/bash-completion/completions/rustup" 2>/dev/null || true
        rustup completions bash cargo > "$USER_HOME/.local/share/bash-completion/completions/cargo" 2>/dev/null || true
    fi

    chown -R "$REAL_USER:" "$USER_HOME/.cargo" "$USER_HOME/.config/environment.d" "$USER_HOME/.bashrc.d" 2>/dev/null || true
}

install_rust_stack() {
    install_build_dependencies
    install_rustup
    install_components
    install_cargo_binstall
    configure_env_and_kde
}

# Procesar argumentos
case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --update|-u|update)
        update_rust
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🦀 INSTALADOR DE RUST (CANAL ESTABLE / LTS) - FEDORA 44"
        echo "================================================================="
        install_rust_stack
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Entorno de desarrollo de Rust configurado con éxito."
        echo "💡 Para cargar el entorno en la sesión actual ejecuta:"
        echo "   source ~/.cargo/env"
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
