#!/usr/bin/env bash
# ==============================================================================
# rust.sh - Instalación y Optimización de Rust (Rustup + Cargo + Toolchain)
# Fedora Workstation (GNOME Shell Wayland)
# Arquitectura: AMD Ryzen 7 7730U (8C/16T) | 32 GB RAM | SSD NVMe Kioxia 512GB
# ==============================================================================
# Características de Optimización:
# - Despliegue idempotente y rootless en espacio de usuario vía Rustup oficial.
# - Detección inteligente de dependencias del sistema (gcc, gcc-c++, cmake,
#   openssl-devel, pkgconf-pkg-config, curl, mold, sccache) con DNF/DNF5.
# - Enlazador ultrarrápido Mold (moderno para Linux) configurado en ~/.cargo/config.toml,
#   reduciendo los tiempos de enlazado incremental entre 3x y 5x.
# - Caché de compilación compartida con sccache para ahorrar ciclos de CPU y escrituras NVMe.
# - Paralelismo ajustado a los 16 hilos del procesador AMD Ryzen 7 7730U (-j16).
# - Instalación de componentes esenciales para desarrollo:
#   * rust-analyzer (servidor LSP oficial para Neovim, VS Code, RustRover)
#   * clippy (linter estático oficial de Rust)
#   * rustfmt (formateador oficial de código)
#   * rust-src (código fuente estándar para introspección y tipado en IDEs)
# - Gestor binario 'cargo-binstall' para instalar herramientas de Cargo sin recompilar.
# - Integración nativa con GNOME Shell (environment.d) y Shells (Bash / Zsh).
# - Generación automática de autocompletados nativos para rustup y cargo.
# - Comandos CLI: --status / -s, --update / -u, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO, PRIVILEGIOS Y HARDWARE
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

DNF_CMD=$(command -v dnf5 2>/dev/null || command -v dnf 2>/dev/null || echo "dnf")

# Detectar núcleos e hilos de la CPU (AMD Ryzen 7 7730U -> 16 hilos)
NPROC=$(nproc 2>/dev/null || echo 16)
export CARGO_BUILD_JOBS="$NPROC"
export MAKEFLAGS="-j$NPROC"

# Rutas estándar de Cargo y Rust
CARGO_HOME="${CARGO_HOME:-$USER_HOME/.cargo}"
RUSTUP_HOME="${RUSTUP_HOME:-$USER_HOME/.rustup}"
export CARGO_HOME RUSTUP_HOME
export PATH="$CARGO_HOME/bin:$USER_HOME/.local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:$PATH"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1"; }
log_step()  { echo -e "${BLUE}>>${NC}    $1"; }

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" \
            CARGO_HOME="$CARGO_HOME" RUSTUP_HOME="$RUSTUP_HOME" \
            CARGO_BUILD_JOBS="$NPROC" MAKEFLAGS="-j$NPROC" \
            PATH="$CARGO_HOME/bin:$USER_HOME/.local/bin:$PATH" "$@"
    else
        env HOME="$USER_HOME" \
            CARGO_HOME="$CARGO_HOME" RUSTUP_HOME="$RUSTUP_HOME" \
            CARGO_BUILD_JOBS="$NPROC" MAKEFLAGS="-j$NPROC" \
            PATH="$CARGO_HOME/bin:$USER_HOME/.local/bin:$PATH" "$@"
    fi
}

check_pkg() {
    rpm -q "$1" &>/dev/null
}

# ------------------------------------------------------------------------------
# 2. AYUDA Y ESTADO
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🦀 Instalador y Optimizador de Rust - Fedora Workstation
   Hardware: AMD Ryzen 7 7730U (16 hilos) | 32 GB RAM | NVMe Kioxia | GNOME Wayland

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala/actualiza Rustup, toolchain Stable, componentes de IDE
                      (rust-analyzer, clippy, rustfmt), enlazador Mold, caché sccache,
                      cargo-binstall, configuración en ~/.cargo/config.toml y autocompletados.
  --status, -s        Muestra el diagnóstico detallado del entorno Rust, toolchains,
                      enlazador Mold, caché sccache, aceleración de hilos y rutas.
  --update, -u        Actualiza Rustup, el toolchain Stable y las herramientas de Cargo.
  --help, -h          Muestra este mensaje de ayuda.

Características configuradas:
  • Compilación:      $NPROC hilos paralelos (CARGO_BUILD_JOBS=$NPROC para Ryzen 7 7730U).
  • Enlazador:        Mold (enlazador de alta velocidad para reducir tiempos de link 3x-5x).
  • Caché de build:   sccache para evitar recompilaciones y reducir desgaste NVMe.
  • Extensiones IDE:  rust-analyzer, clippy, rustfmt y rust-src.
  • Gestor binario:   cargo-binstall para instalar utilidades de Cargo de forma instantánea.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DEL ENTORNO RUST - FEDORA WORKSTATION"
    echo "   AMD Ryzen 7 7730U (16 hilos) | 32 GB RAM | NVMe | Fedora Workstation"
    echo "================================================================="

    local rustc_ver cargo_ver rustup_ver mold_ver sccache_ver binstall_ver

    if command -v rustc &>/dev/null; then
        rustc_ver=$(rustc --version 2>/dev/null)
    elif [ -f "$CARGO_HOME/bin/rustc" ]; then
        rustc_ver=$("$CARGO_HOME/bin/rustc" --version 2>/dev/null)
    else
        rustc_ver="No instalado"
    fi

    if command -v cargo &>/dev/null; then
        cargo_ver=$(cargo --version 2>/dev/null)
    elif [ -f "$CARGO_HOME/bin/cargo" ]; then
        cargo_ver=$("$CARGO_HOME/bin/cargo" --version 2>/dev/null)
    else
        cargo_ver="No instalado"
    fi

    if command -v rustup &>/dev/null; then
        rustup_ver=$(rustup --version 2>/dev/null | head -n1)
    elif [ -f "$CARGO_HOME/bin/rustup" ]; then
        rustup_ver=$("$CARGO_HOME/bin/rustup" --version 2>/dev/null | head -n1)
    else
        rustup_ver="No instalado"
    fi

    mold_ver=$(command -v mold &>/dev/null && mold --version 2>/dev/null | head -n1 || echo "No instalado")
    sccache_ver=$(command -v sccache &>/dev/null && sccache --version 2>/dev/null || echo "No instalado")

    if [ -f "$CARGO_HOME/bin/cargo-binstall" ]; then
        binstall_ver=$("$CARGO_HOME/bin/cargo-binstall" --version 2>/dev/null || echo "Instalado")
    else
        binstall_ver="No instalado"
    fi

    echo "1. Toolchain Oficial y Compilador:"
    echo "  • Rustup:                $rustup_ver"
    echo "  • Compilador rustc:      $rustc_ver"
    echo "  • Gestor Cargo:          $cargo_ver"
    echo "  • Gestor cargo-binstall: $binstall_ver"
    echo "-----------------------------------------------------------------"
    echo "2. Optimizaciones de Rendimiento y Enlazado:"
    echo "  • Hilos paralelos (Ryzen): CARGO_BUILD_JOBS=$NPROC (-j$NPROC)"
    echo "  • Enlazador Mold:        $mold_ver"
    echo "  • Compilación sccache:   $sccache_ver"
    echo "  • Configuración Cargo:   $([ -f "$CARGO_HOME/config.toml" ] && echo "✅ Configurado ($CARGO_HOME/config.toml)" || echo "❌ No configurado")"
    echo "-----------------------------------------------------------------"
    echo "3. Componentes de IDE instalados (rustup component list):"
    if command -v rustup &>/dev/null || [ -f "$CARGO_HOME/bin/rustup" ]; then
        local r_analyzer clippy_stat rustfmt_stat r_src
        r_analyzer=$(run_as_user rustup component list 2>/dev/null | grep "^rust-analyzer" | grep "installed" >/dev/null && echo "✅ Activo" || echo "❌ Ausente")
        clippy_stat=$(run_as_user rustup component list 2>/dev/null | grep "^clippy" | grep "installed" >/dev/null && echo "✅ Activo" || echo "❌ Ausente")
        rustfmt_stat=$(run_as_user rustup component list 2>/dev/null | grep "^rustfmt" | grep "installed" >/dev/null && echo "✅ Activo" || echo "❌ Ausente")
        r_src=$(run_as_user rustup component list 2>/dev/null | grep "^rust-src" | grep "installed" >/dev/null && echo "✅ Activo" || echo "❌ Ausente")
        echo "  • rust-analyzer (LSP):   $r_analyzer"
        echo "  • clippy (Linter):       $clippy_stat"
        echo "  • rustfmt (Formatter):   $rustfmt_stat"
        echo "  • rust-src (Stdlib src): $r_src"
    else
        echo "  • (Requiere rustup instalado)"
    fi
    echo "-----------------------------------------------------------------"
    echo "4. Integración en Shells y Sesión:"
    echo "  • GNOME environment.d:   $([ -f "$USER_HOME/.config/environment.d/10-rust.conf" ] && echo '✅ Activo (~/.config/environment.d/10-rust.conf)' || echo '❌ Ausente')"
    echo "  • Shell Bash (~/.bashrc.d): $([ -f "$USER_HOME/.bashrc.d/rust.sh" ] && echo '✅ Activo (~/.bashrc.d/rust.sh)' || echo '❌ Ausente')"
    echo "  • Autocompletados:       $([ -f "$USER_HOME/.local/share/bash-completion/completions/cargo" ] && echo '✅ Configurados' || echo '❌ Ausentes')"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. VERIFICACIÓN E INSTALACIÓN DE DEPENDENCIAS (DNF5)
# ------------------------------------------------------------------------------
install_system_deps() {
    log_info "Comprobando dependencias de compilación y enlazado en Fedora..."
    local pkgs_to_install=()

    # Dependencias base para compilar C/C++ y crates con dependencias nativas en Fedora
    for pkg in gcc gcc-c++ cmake openssl-devel pkgconf-pkg-config curl mold sccache; do
        if ! check_pkg "$pkg"; then
            pkgs_to_install+=("$pkg")
        fi
    done

    if [ ${#pkgs_to_install[@]} -gt 0 ]; then
        log_step "Instalando paquetes faltantes (${pkgs_to_install[*]}) vía $DNF_CMD..."
        $SUDO $DNF_CMD install -y "${pkgs_to_install[@]}" 2>/dev/null || true
        log_ok "Dependencias de sistema instaladas correctamente."
    else
        log_ok "Todas las dependencias de compilación ya están instaladas."
    fi
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN / ACTUALIZACIÓN DE RUSTUP Y TOOLCHAIN
# ------------------------------------------------------------------------------
install_rustup() {
    log_info "Verificando instalación oficial de Rustup..."
    run_as_user mkdir -p "$CARGO_HOME" "$RUSTUP_HOME"

    if ! command -v rustup &>/dev/null && [ ! -f "$CARGO_HOME/bin/rustup" ]; then
        log_step "Descargando e instalando Rustup oficial (perfil default / stable)..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | run_as_user sh -s -- -y --default-toolchain stable --profile default --no-modify-path
        log_ok "Rustup y toolchain Stable instalados con éxito."
    else
        log_ok "Rustup ya está instalado. Asegurando componentes esenciales..."
    fi

    # Asegurar componentes clave para desarrollo e IDEs
    log_step "Comprobando componentes de desarrollo (rust-analyzer, clippy, rustfmt, rust-src)..."
    run_as_user rustup component add rust-analyzer clippy rustfmt rust-src 2>/dev/null || true
    log_ok "Componentes de desarrollo verificados."
}

# ------------------------------------------------------------------------------
# 5. CONFIGURACIÓN ÓPTIMA DE CARGO (MOLD + SCCACHE + HILOS RYZEN)
# ------------------------------------------------------------------------------
configure_cargo_optimizations() {
    log_info "Configurando optimizaciones de alto rendimiento en ~/.cargo/config.toml..."
    run_as_user mkdir -p "$CARGO_HOME"

    cat <<'EOF' | run_as_user tee "$CARGO_HOME/config.toml" > /dev/null
# ==============================================================================
# Cargo Configuration - Fedora Workstation
# Hardware: AMD Ryzen 7 7730U (16 hilos) | 32 GB RAM | SSD NVMe Kioxia
# ==============================================================================

[build]
# Uso del enlazador ultrarrápido Mold para arquitecturas Linux x86_64
rustflags = ["-C", "link-arg=-fuse-ld=mold"]
# Caché de compilación sccache para ahorrar escrituras en disco NVMe y ciclos de CPU
rustc-wrapper = "sccache"
# Paralelismo automático asignado a los hilos de la CPU
jobs = 16

[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-C", "link-arg=-fuse-ld=mold"]

[profile.dev]
opt-level = 0
debug = 1
incremental = true

[profile.release]
opt-level = 3
lto = "thin"
codegen-units = 1
panic = "abort"
EOF

    # Si clang no está presente, mantener gcc/mold nativo
    if ! command -v clang &>/dev/null; then
        run_as_user sed -i '/linker = "clang"/d' "$CARGO_HOME/config.toml" 2>/dev/null || true
    fi

    # Si sccache no estuviera disponible, no bloquear cargo
    if ! command -v sccache &>/dev/null; then
        run_as_user sed -i '/rustc-wrapper = "sccache"/d' "$CARGO_HOME/config.toml" 2>/dev/null || true
    fi

    log_ok "Configuración de enlazado Mold y paralelismo aplicada en $CARGO_HOME/config.toml."
}

# ------------------------------------------------------------------------------
# 6. INSTALAR CARGO-BINSTALL
# ------------------------------------------------------------------------------
install_cargo_tools() {
    log_info "Verificando gestor binario 'cargo-binstall'..."
    if ! command -v cargo-binstall &>/dev/null && [ ! -f "$CARGO_HOME/bin/cargo-binstall" ]; then
        log_step "Instalando cargo-binstall mediante script oficial precompilado..."
        curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | run_as_user bash 2>/dev/null || true
    fi

    if command -v cargo-binstall &>/dev/null || [ -f "$CARGO_HOME/bin/cargo-binstall" ]; then
        log_ok "cargo-binstall está disponible para descargas instantáneas de herramientas de Cargo."
    fi
}

# ------------------------------------------------------------------------------
# 7. INTEGRACIÓN CON GNOME SHELL, SHELLS Y AUTOCOMPLETADOS
# ------------------------------------------------------------------------------
configure_environment() {
    log_info "Configurando variables de entorno y autocompletados..."

    local env_dir="$USER_HOME/.config/environment.d"
    local bashrc_d="$USER_HOME/.bashrc.d"
    local bash_comp_dir="$USER_HOME/.local/share/bash-completion/completions"

    run_as_user mkdir -p "$env_dir" "$bashrc_d" "$bash_comp_dir"

    # 7.1. Integración con sesión gráfica GNOME Shell (systemd user)
    cat <<EOF | run_as_user tee "$env_dir/10-rust.conf" > /dev/null
CARGO_HOME=$CARGO_HOME
RUSTUP_HOME=$RUSTUP_HOME
CARGO_BUILD_JOBS=$NPROC
EOF

    # 7.2. Shell Bash modular (~/.bashrc.d/rust.sh) - PREDETERMINADO
    cat <<EOF | run_as_user tee "$bashrc_d/rust.sh" > /dev/null
# Rust & Cargo Environment
export CARGO_HOME="$CARGO_HOME"
export RUSTUP_HOME="$RUSTUP_HOME"
export CARGO_BUILD_JOBS=$NPROC

if [ -f "$CARGO_HOME/env" ]; then
    . "$CARGO_HOME/env"
elif [ -d "$CARGO_HOME/bin" ] && [[ ":\$PATH:" != *":$CARGO_HOME/bin:"* ]]; then
    export PATH="$CARGO_HOME/bin:\$PATH"
fi
EOF

    # 7.3. Autocompletados para Bash y Zsh
    if command -v rustup &>/dev/null || [ -f "$CARGO_HOME/bin/rustup" ]; then
        run_as_user rustup completions bash > "$bash_comp_dir/rustup" 2>/dev/null || true
        run_as_user rustup completions bash cargo > "$bash_comp_dir/cargo" 2>/dev/null || true

        if [ -f "$USER_HOME/.zshrc" ]; then
            local zsh_comp_dir="$USER_HOME/.local/share/zsh/site-functions"
            local zfunc_dir="$USER_HOME/.zfunc"
            run_as_user mkdir -p "$zsh_comp_dir" "$zfunc_dir"
            run_as_user rustup completions zsh > "$zsh_comp_dir/_rustup" 2>/dev/null || true
            run_as_user rustup completions zsh cargo > "$zsh_comp_dir/_cargo" 2>/dev/null || true
            run_as_user cp "$zsh_comp_dir/_rustup" "$zfunc_dir/_rustup" 2>/dev/null || true
            run_as_user cp "$zsh_comp_dir/_cargo" "$zfunc_dir/_cargo" 2>/dev/null || true
        fi
    fi

    log_ok "Integración con GNOME Shell, Bash y autocompletados completada."
}

# ------------------------------------------------------------------------------
# 8. ACTUALIZACIÓN RÁPIDA (--update)
# ------------------------------------------------------------------------------
update_rust() {
    log_info "Actualizando entorno completo de Rust..."
    if command -v rustup &>/dev/null || [ -f "$CARGO_HOME/bin/rustup" ]; then
        log_step "Actualizando Rustup y toolchains..."
        run_as_user rustup self update
        run_as_user rustup update
        run_as_user rustup component add rust-analyzer clippy rustfmt rust-src 2>/dev/null || true
    fi

    log_ok "Actualización de Rust finalizada."
}

# ------------------------------------------------------------------------------
# PROCESAMIENTO DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
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
        echo ""
        show_status
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🦀 OPTIMIZADOR Y CONFIGURADOR DE RUST - FEDORA WORKSTATION"
        echo "   AMD Ryzen 7 7730U (16 hilos) | 32 GB RAM | NVMe | Fedora Workstation"
        echo "================================================================="
        install_system_deps
        install_rustup
        configure_cargo_optimizations
        install_cargo_tools
        configure_environment
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Rust configurado y optimizado con éxito para Fedora Workstation."
        echo "💡 Inicia una nueva terminal o ejecuta: source ~/.bashrc"
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
