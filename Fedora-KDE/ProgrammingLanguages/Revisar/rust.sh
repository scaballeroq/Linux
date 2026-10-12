#!/usr/bin/env bash
# ==============================================================================
# rust.sh - Instalación de Rust (Canal Stable / Producción) y Cargo-Binstall
# Optimizado para Fedora 44, KDE Plasma 6 y Bash / Zsh
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U / 32 GB RAM)
# ==============================================================================

set -euo pipefail

# Colores ANSI para terminal
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO Y PRIVILEGIOS
# ------------------------------------------------------------------------------
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
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

check_pkg() {
    rpm -q "$1" &>/dev/null
}

show_help() {
    cat <<EOF
🦀 Gestor e Instalador de Rust (Canal Estable) - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala Rustup (Stable), componentes de desarrollo (rust-analyzer, clippy, rustfmt),
                      cargo-binstall y variables de sesión KDE Plasma 6.
  --status, -s        Muestra el estado del compilador rustc, cargo, rust-analyzer y componentes.
  --update, -u        Actualiza la cadena de herramientas de Rust (rustup update) a la última versión estable.
  --help, -h          Muestra este mensaje de ayuda.

Características configuradas:
  • Canal Estable:       Instala y fija el canal oficial 'stable' vía rustup.
  • Componentes IDE:     rust-analyzer (LSP), clippy, rustfmt y rust-src instalados nativamente.
  • Binarios Rápidos:    Instala cargo-binstall para descargas precompiladas sin consumir CPU/tiempo.
  • Integración KDE/IDE: Variables en ~/.config/environment.d/10-rust.conf para VS Code y RustRover.
EOF
}

show_status() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔍 ESTADO DE RUST Y HERRAMIENTAS - FEDORA 44 (KDE PLASMA 6)${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    if [ -f "$USER_HOME/.cargo/env" ]; then
        # shellcheck disable=SC1091
        . "$USER_HOME/.cargo/env"
    fi

    if command -v rustc &>/dev/null || [ -x "$USER_HOME/.cargo/bin/rustc" ]; then
        local rustc_ver cargo_ver analyzer_ver binstall_ver
        rustc_ver=$(run_as_user rustc --version 2>/dev/null || echo "Instalado")
        cargo_ver=$(run_as_user cargo --version 2>/dev/null || echo "Instalado")
        analyzer_ver=$(run_as_user rust-analyzer --version 2>/dev/null | awk '{print $1, $2}' || echo "No instalado")
        binstall_ver=$(run_as_user cargo-binstall --version 2>/dev/null || echo "No instalado")

        echo -e "• ${BOLD}Compilador rustc:${NC}    ${GREEN}✅ $rustc_ver${NC}"
        echo -e "• ${BOLD}Gestor cargo:${NC}        ${GREEN}✅ $cargo_ver${NC}"
        echo -e "• ${BOLD}LSP rust-analyzer:${NC}   $([ "$analyzer_ver" != "No instalado" ] && echo -e "${GREEN}✅ $analyzer_ver${NC}" || echo -e "${YELLOW}ℹ️ $analyzer_ver${NC}")"
        echo -e "• ${BOLD}cargo-binstall:${NC}      $([ "$binstall_ver" != "No instalado" ] && echo -e "${GREEN}✅ $binstall_ver${NC}" || echo -e "${YELLOW}ℹ️ $binstall_ver${NC}")"
        echo -e "• ${BOLD}Entorno KDE Plasma:${NC}  $([ -f "$USER_HOME/.config/environment.d/10-rust.conf" ] && echo -e "${GREEN}✅ Configurado${NC}" || echo -e "${YELLOW}ℹ️ Pendiente${NC}")"
        echo -e "• ${BOLD}Autocompletado Bash:${NC} $([ -f "$USER_HOME/.local/share/bash-completion/completions/cargo" ] && echo -e "${GREEN}✅ Activo${NC}" || echo -e "${YELLOW}ℹ️ Pendiente${NC}")"
        echo ""
        echo "📦 Toolchains activas:"
        run_as_user rustup toolchain list 2>/dev/null | sed 's/^/  • /' || echo "  (Ninguna registrada)"
    else
        echo -e "• ${BOLD}Rust Toolchain:${NC}      ${RED}❌ No instalado en el sistema${NC}"
    fi
    echo -e "${CYAN}=================================================================${NC}"
}

install_dependencies() {
    echo -e "${BLUE}ℹ️ [1/5] Verificando dependencias de compilación para Rust en Fedora...${NC}"
    local missing=()
    for pkg in cmake openssl-devel pkgconf-pkg-config curl git lld clang-devel; do
        if ! check_pkg "$pkg"; then missing+=("$pkg"); fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${BLUE}  📦 Instalando paquetes (${missing[*]}) vía DNF5...${NC}"
        if ! command -v sudo &>/dev/null && [ "$EUID" -ne 0 ]; then
            echo -e "${RED}❌ Error: Se requieren permisos de sudo para instalar dependencias.${NC}"
            exit 1
        fi
        $SUDO dnf5 install -y "${missing[@]}"
        echo -e "${GREEN}  ✅ Dependencias de compilación preparadas.${NC}"
    else
        echo -e "${GREEN}  ✅ Dependencias de compilación para Rust ya satisfechas.${NC}"
    fi
}

install_rust() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🦀 INSTALANDO RUST (CANAL ESTABLE) - FEDORA 44 (KDE PLASMA 6)${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    install_dependencies

    # 1. Configurar Rustup y canal Stable
    echo -e "${BLUE}ℹ️ [2/5] Configurando Rustup y canal Stable...${NC}"
    if [ ! -x "$USER_HOME/.cargo/bin/rustup" ] && ! command -v rustup &> /dev/null; then
        echo -e "${BLUE}  ⬇️ Descargando e instalando Rustup oficial...${NC}"
        run_as_user curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | run_as_user sh -s -- -y --default-toolchain stable --profile default --no-modify-path
    else
        echo -e "${BLUE}  🔄 Asegurando canal Rust Stable...${NC}"
        run_as_user rustup default stable 2>/dev/null || true
    fi

    # 2. Instalar componentes esenciales para desarrollo e IDEs
    echo -e "${BLUE}ℹ️ [3/5] Instalando componentes para IDEs (rust-analyzer, clippy, rustfmt, rust-src)...${NC}"
    run_as_user rustup component add rust-src rust-analyzer clippy rustfmt 2>/dev/null || true

    # 3. Instalación de cargo-binstall
    echo -e "${BLUE}ℹ️ [4/5] Verificando instalador rápido de binarios (cargo-binstall)...${NC}"
    if [ ! -x "$USER_HOME/.cargo/bin/cargo-binstall" ] && ! command -v cargo-binstall &> /dev/null; then
        echo -e "${BLUE}  ⬇️ Instalando cargo-binstall...${NC}"
        run_as_user curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | run_as_user bash 2>/dev/null || true
    else
        echo -e "${GREEN}  ✅ cargo-binstall ya está instalado.${NC}"
    fi

    # 4. Integración con el entorno gráfico y Shells
    echo -e "${BLUE}ℹ️ [5/5] Configurando integración de Cargo y Rust en KDE Plasma y Shells...${NC}"
    local env_dir="$USER_HOME/.config/environment.d"
    local bashrc_d="$USER_HOME/.bashrc.d"
    run_as_user mkdir -p "$env_dir" "$bashrc_d"

    # Sesión gráfica (environment.d)
    cat << 'EOF' | run_as_user tee "$env_dir/10-rust.conf" > /dev/null
# Integración de Cargo/Rust con la sesión gráfica (KDE Plasma 6 + Wayland)
PATH=${HOME}/.cargo/bin:${PATH}
EOF

    # Shell Bash
    cat << 'EOF' | run_as_user tee "$bashrc_d/rust.sh" > /dev/null
# Rust & Cargo Environment
if [ -d "$HOME/.cargo/bin" ] && [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi
EOF

    # Fallback si no se procesa .bashrc.d
    local bashrc="$USER_HOME/.bashrc"
    if [ -f "$bashrc" ] && ! grep -q "cargo/bin" "$bashrc" 2>/dev/null; then
        if ! grep -q "\.bashrc\.d" "$bashrc" 2>/dev/null; then
            echo -e '\n# Rust & Cargo\nexport PATH="$HOME/.cargo/bin:$PATH"' | run_as_user tee -a "$bashrc" > /dev/null
        fi
    fi

    # Shell Zsh (si existe ~/.zshrc)
    if [ -f "$USER_HOME/.zshrc" ]; then
        local zshrc_d="$USER_HOME/.zshrc.d"
        run_as_user mkdir -p "$zshrc_d"
        cat << 'EOF' | run_as_user tee "$zshrc_d/rust.zsh" > /dev/null
# Rust & Cargo Environment
if [ -d "$HOME/.cargo/bin" ] && [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi
EOF
    fi

    # Autocompletados de Cargo y Rustup
    local comp_dir="$USER_HOME/.local/share/bash-completion/completions"
    run_as_user mkdir -p "$comp_dir"
    run_as_user rustup completions bash > "$comp_dir/rustup" 2>/dev/null || true
    run_as_user rustup completions bash cargo > "$comp_dir/cargo" 2>/dev/null || true

    local rustc_ver cargo_ver analyzer_ver
    rustc_ver=$(run_as_user rustc --version 2>/dev/null || echo "instalado")
    cargo_ver=$(run_as_user cargo --version 2>/dev/null || echo "instalado")
    analyzer_ver=$(run_as_user rust-analyzer --version 2>/dev/null | awk '{print $1, $2}' || echo "disponible")

    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${GREEN}✅ Rust Toolchain configurado con éxito para Fedora 44:${NC}"
    echo -e "  • Rustc:         $rustc_ver"
    echo -e "  • Cargo:         $cargo_ver"
    echo -e "  • rust-analyzer: $analyzer_ver"
    echo -e "  • Herramientas:  clippy, rustfmt, cargo-binstall"
    echo -e "  • Entorno:       ~/.cargo/bin (enlazado a environment.d y Shells)"
    echo -e "${CYAN}=================================================================${NC}"
}

update_rust() {
    echo -e "${BLUE}🔄 Actualizando Rust toolchain (rustup update stable)...${NC}"
    if [ -f "$USER_HOME/.cargo/env" ]; then
        # shellcheck disable=SC1091
        . "$USER_HOME/.cargo/env"
    fi
    if command -v rustup &>/dev/null || [ -x "$USER_HOME/.cargo/bin/rustup" ]; then
        run_as_user rustup update stable
        echo -e "${GREEN}✅ Rust Stable actualizado con éxito.${NC}"
        show_status
    else
        echo -e "${YELLOW}⚠️ Rust no está instalado. Ejecutando instalación...${NC}"
        install_rust
    fi
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    --update|-u|update)
        update_rust
        exit 0
        ;;
    "")
        install_rust
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida:${NC} ${1}"
        show_help
        exit 1
        ;;
esac
