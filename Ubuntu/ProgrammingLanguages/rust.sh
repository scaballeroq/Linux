#!/usr/bin/env bash
# ==============================================================================
# rust.sh - Instalación y Optimización de Rust (Rustup + Cargo + Toolchain)
# Ubuntu Workstation (Ubuntu 26.10 / GNOME Shell Wayland)
# Arquitectura: AMD Ryzen 7 7730U (8C/16T) | 32 GB RAM | SSD NVMe Kioxia 512GB
# ==============================================================================
# Características de Optimización:
# - Despliegue idempotente y rootless en espacio de usuario vía Rustup oficial.
# - Detección inteligente de dependencias del sistema (build-essential, cmake,
#   libssl-dev, pkg-config, curl, mold, sccache) sin llamadas innecesarias a sudo.
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
    dpkg -s "$1" &>/dev/null
}

# ------------------------------------------------------------------------------
# 2. AYUDA Y ESTADO
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🦀 Instalador y Optimizador de Rust - Ubuntu Workstation (Ubuntu 26.10)
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
  • Caché OCI/Rust:   sccache para evitar recompilaciones recurrentes en el SSD NVMe.
  • Componentes IDE:  rust-analyzer, clippy, rustfmt y rust-src.
  • Binarios rápidos: cargo-binstall para instalar herramientas sin compilar.
  • Integración GUI:  ~/.config/environment.d/10-rust.conf (detectado por GNOME e IDEs).
  • Shells:           ~/.bashrc.d/rust.sh y autocompletados para Bash y Zsh.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DEL ENTORNO RUST - UBUNTU WORKSTATION (UBUNTU 26.10)"
    echo "   AMD Ryzen 7 7730U (16 hilos) | 32 GB RAM | NVMe | GNOME Wayland"
    echo "================================================================="

    local rustc_ver cargo_ver rustup_ver analyzer_ver clippy_ver binstall_ver
    local mold_status sccache_status config_status env_status

    rustc_ver=$(run_as_user rustc --version 2>/dev/null || echo "No instalado")
    cargo_ver=$(run_as_user cargo --version 2>/dev/null || echo "No instalado")
    rustup_ver=$(run_as_user rustup --version 2>/dev/null | head -n1 || echo "No instalado")

    # Componentes de Toolchain
    if command -v rust-analyzer &>/dev/null || [ -f "$CARGO_HOME/bin/rust-analyzer" ]; then
        analyzer_ver="✅ Disponible ($(run_as_user rust-analyzer --version 2>/dev/null | head -n1 || echo "presente"))"
    elif run_as_user rustup which rust-analyzer &>/dev/null; then
        analyzer_ver="✅ Instalado vía rustup"
    else
        analyzer_ver="ℹ️ No instalado"
    fi

    if run_as_user cargo clippy --version &>/dev/null; then
        clippy_ver="✅ Disponible ($(run_as_user cargo clippy --version 2>/dev/null | head -n1 || echo "presente"))"
    else
        clippy_ver="ℹ️ No instalado"
    fi

    if command -v cargo-binstall &>/dev/null || [ -f "$CARGO_HOME/bin/cargo-binstall" ]; then
        binstall_ver="✅ Disponible ($(run_as_user cargo-binstall --version 2>/dev/null | head -n1 || echo "presente"))"
    else
        binstall_ver="ℹ️ No instalado"
    fi

    # Enlazador Mold
    if command -v mold &>/dev/null; then
        mold_status="✅ Activo ($(mold --version 2>&1 | head -n1))"
    else
        mold_status="ℹ️ No instalado en el sistema (usando enlazador del sistema)"
    fi

    # Sccache
    if command -v sccache &>/dev/null; then
        sccache_status="✅ Activo ($(sccache --version 2>&1 | head -n1))"
    else
        sccache_status="ℹ️ No instalado"
    fi

    # Configuración de Cargo
    if [ -f "$CARGO_HOME/config.toml" ]; then
        config_status="✅ Configurado ($CARGO_HOME/config.toml)"
    else
        config_status="ℹ️ No presente (predeterminado)"
    fi

    # Entorno GNOME
    if [ -f "$USER_HOME/.config/environment.d/10-rust.conf" ]; then
        env_status="✅ Configurado (~/.config/environment.d/10-rust.conf)"
    else
        env_status="ℹ️ No presente"
    fi

    if [ "$rustc_ver" != "No instalado" ]; then
        echo "• Compilador rustc:     ✅ $rustc_ver"
        echo "• Gestor Cargo:         ✅ $cargo_ver"
        echo "• Gestor Rustup:        ✅ $rustup_ver"
        echo "• Servidor LSP:         $analyzer_ver"
        echo "• Linter Clippy:        $clippy_ver"
        echo "• Binarios binstall:    $binstall_ver"
        echo "• Enlazador rápido:     $mold_status"
        echo "• Caché sccache:        $sccache_status"
        echo "• Hilos de compilación: ✅ $NPROC hilos paralelos (Ryzen 7 7730U)"
        echo "• Configuración Cargo:  $config_status"
        echo "• Entorno GNOME Shell:  $env_status"
        echo "• Directorio CARGO_HOME: $CARGO_HOME"
        echo "• Directorio RUSTUP:    $RUSTUP_HOME"
        echo "-----------------------------------------------------------------"
        echo "📋 Toolchains instalados en rustup:"
        run_as_user rustup toolchain list 2>/dev/null | sed 's/^/  • /' || echo "  (Ninguno)"
    else
        echo "• Compilador rustc:     ❌ No instalado en el sistema"
        echo "• Gestor Cargo:         ❌ No instalado"
        echo "• Gestor Rustup:        ❌ No instalado"
        echo "• Enlazador rápido:     $mold_status"
        echo "• Caché sccache:        $sccache_status"
        echo "• Hilos de compilación: ✅ $NPROC hilos disponibles (Ryzen 7 7730U)"
        echo "• Configuración Cargo:  $config_status"
        echo "• Entorno GNOME Shell:  $env_status"
        echo "-----------------------------------------------------------------"
        echo "💡 Para instalar Rust optimizado para Ubuntu 26.10 y este hardware:"
        echo "   Ejecuta: $0"
    fi
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. VERIFICACIÓN E INSTALACIÓN DE DEPENDENCIAS DEL SISTEMA
# ------------------------------------------------------------------------------
install_system_deps() {
    log_info "Comprobando dependencias de compilación y enlazado en Ubuntu 26.10..."
    local missing_pkgs=()

    # build-essential, cmake, libssl-dev, pkg-config, curl son imprescindibles para compilar crates C/C++
    # mold es el enlazador ultrarrápido moderno para Linux
    # sccache es el compilador caché para Rust
    for pkg in build-essential cmake libssl-dev pkg-config curl mold sccache; do
        if ! check_pkg "$pkg"; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        log_step "Instalando paquetes faltantes (${missing_pkgs[*]}) vía APT..."
        if ! command -v sudo &>/dev/null && [ "$EUID" -ne 0 ]; then
            log_error "Se requieren permisos administrativos (sudo) para instalar: ${missing_pkgs[*]}"
            exit 1
        fi
        $SUDO apt-get update -qq
        $SUDO apt-get install -y "${missing_pkgs[@]}"
        log_ok "Dependencias del sistema instaladas correctamente."
    else
        log_ok "Todas las dependencias del sistema ya están presentes."
    fi
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN / ACTUALIZACIÓN DE RUST VIA RUSTUP
# ------------------------------------------------------------------------------
install_rustup() {
    log_info "Configurando Rustup y Toolchain Stable..."

    run_as_user mkdir -p "$CARGO_HOME" "$RUSTUP_HOME"

    if ! command -v rustup &>/dev/null && [ ! -f "$CARGO_HOME/bin/rustup" ]; then
        log_step "Instalando Rustup oficial (versión Stable)..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | run_as_user sh -s -- -y \
            --default-toolchain stable \
            --profile default \
            --no-modify-path
        log_ok "Rustup instalado correctamente."
    else
        log_info "Rustup ya está instalado. Comprobando actualizaciones del toolchain..."
        run_as_user rustup update stable
    fi

    # Asegurar que el entorno de Cargo esté cargado para los siguientes pasos
    if [ -f "$CARGO_HOME/env" ]; then
        # shellcheck disable=SC1091
        . "$CARGO_HOME/env"
    fi

    # Añadir componentes esenciales para desarrollo e IDEs
    log_step "Verificando componentes oficiales (rust-analyzer, clippy, rustfmt, rust-src)..."
    run_as_user rustup component add rust-analyzer clippy rustfmt rust-src 2>/dev/null || true
    log_ok "Componentes de desarrollo configurados."
}

# ------------------------------------------------------------------------------
# 5. OPTIMIZACIÓN DE CARGO (CONFIG.TOML - ENLAZADOR MOLD Y MULTINÚCLEO)
# ------------------------------------------------------------------------------
configure_cargo_optimizations() {
    log_info "Configurando optimizaciones de compilación en ~/.cargo/config.toml..."
    local config_file="$CARGO_HOME/config.toml"
    run_as_user mkdir -p "$CARGO_HOME"

    local use_mold=0
    if command -v mold &>/dev/null; then
        use_mold=1
    fi

    local use_sccache=0
    if command -v sccache &>/dev/null; then
        use_sccache=1
    fi

    cat <<EOF | run_as_user tee "$config_file" > /dev/null
# ==============================================================================
# Cargo Configuration - Ubuntu Workstation 26.10
# Hardware: AMD Ryzen 7 7730U (16 hilos) | 32 GB RAM | NVMe SSD Kioxia
# ==============================================================================

[build]
# Paralelismo optimizado para los 16 hilos del Ryzen 7 7730U
jobs = $NPROC
$(if [ "$use_sccache" -eq 1 ]; then echo 'rustc-wrapper = "sccache"'; fi)

# Enlazador ultrarrápido Mold para sistemas Linux x86_64
$(if [ "$use_mold" -eq 1 ]; then cat <<'MOLDEOF'
[target.x86_64-unknown-linux-gnu]
rustflags = ["-C", "link-arg=-fuse-ld=mold"]
MOLDEOF
fi)
EOF

    log_ok "Archivo ~/.cargo/config.toml configurado (jobs=$NPROC$(if [ "$use_mold" -eq 1 ]; then echo ", mold linker activo"; fi)$(if [ "$use_sccache" -eq 1 ]; then echo ", sccache activo"; fi))."
}

# ------------------------------------------------------------------------------
# 6. INSTALACIÓN DE CARGO-BINSTALL Y HERRAMIENTAS ESENCIALES
# ------------------------------------------------------------------------------
install_cargo_tools() {
    log_info "Verificando instalador binario cargo-binstall..."

    if ! command -v cargo-binstall &>/dev/null && [ ! -f "$CARGO_HOME/bin/cargo-binstall" ]; then
        log_step "Instalando cargo-binstall (permite descargar binarios de crates sin compilar)..."
        curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | run_as_user bash 2>/dev/null || true
        if [ -f "$CARGO_HOME/bin/cargo-binstall" ]; then
            log_ok "cargo-binstall instalado correctamente."
        fi
    else
        log_ok "cargo-binstall ya está disponible."
    fi

    # Herramientas de productividad recomendadas si binstall está disponible
    if command -v cargo-binstall &>/dev/null || [ -f "$CARGO_HOME/bin/cargo-binstall" ]; then
        log_info "Comprobando utilidades de desarrollo (cargo-update, cargo-watch)..."
        for tool in cargo-update cargo-watch; do
            local bin_name="$tool"
            [ "$tool" = "cargo-update" ] && bin_name="cargo-install-update"
            if ! command -v "$bin_name" &>/dev/null && [ ! -f "$CARGO_HOME/bin/$bin_name" ]; then
                log_step "Instalando $tool vía cargo-binstall..."
                run_as_user cargo binstall -y --no-confirm "$tool" 2>/dev/null || true
            fi
        done
        log_ok "Utilidades de desarrollo verificadas."
    fi
}

# ------------------------------------------------------------------------------
# 7. INTEGRACIÓN CON GNOME SHELL, SHELLS Y AUTOCOMPLETADOS
# ------------------------------------------------------------------------------
configure_environment() {
    log_info "Configurando integración con sesión GNOME, Shells y autocompletados..."

    local env_dir="$USER_HOME/.config/environment.d"
    local bashrc_d="$USER_HOME/.bashrc.d"
    local bash_comp_dir="$USER_HOME/.local/share/bash-completion/completions"

    run_as_user mkdir -p "$env_dir" "$bashrc_d" "$bash_comp_dir"

    # 7.1. Sesión gráfica Wayland / GNOME Shell (systemd user environment)
    cat <<EOF | run_as_user tee "$env_dir/10-rust.conf" > /dev/null
# Rust Environment Settings (GNOME Shell + Wayland)
CARGO_HOME=$CARGO_HOME
RUSTUP_HOME=$RUSTUP_HOME
PATH=$CARGO_HOME/bin:\${PATH}
CARGO_BUILD_JOBS=$NPROC
EOF

    # 7.2. Integración modular Bash (~/.bashrc.d/rust.sh) - PREDETERMINADO
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

    # 7.3. Fallback directo en ~/.bashrc solo si no procesa ~/.bashrc.d
    if [ -f "$USER_HOME/.bashrc" ] && ! grep -q "bashrc.d" "$USER_HOME/.bashrc" 2>/dev/null; then
        if ! grep -q ".cargo/env" "$USER_HOME/.bashrc" 2>/dev/null; then
            cat <<EOF | run_as_user tee -a "$USER_HOME/.bashrc" > /dev/null

# Rust Environment
if [ -f "$CARGO_HOME/env" ]; then . "$CARGO_HOME/env"; fi
export CARGO_BUILD_JOBS=$NPROC
EOF
        fi
    fi

    # 7.4. Shell Zsh (modular si existe ~/.zshrc)
    if [ -f "$USER_HOME/.zshrc" ]; then
        local zshrc_d="$USER_HOME/.zshrc.d"
        local zsh_comp_dir="$USER_HOME/.local/share/zsh/site-functions"
        local zfunc_dir="$USER_HOME/.zfunc"
        run_as_user mkdir -p "$zshrc_d" "$zsh_comp_dir" "$zfunc_dir"

        cat <<EOF | run_as_user tee "$zshrc_d/rust.zsh" > /dev/null
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
    fi

    # 7.5. Autocompletados para Bash y Zsh
    if command -v rustup &>/dev/null || [ -f "$CARGO_HOME/bin/rustup" ]; then
        run_as_user rustup completions bash > "$bash_comp_dir/rustup" 2>/dev/null || true
        run_as_user rustup completions bash cargo > "$bash_comp_dir/cargo" 2>/dev/null || true

        if [ -f "$USER_HOME/.zshrc" ]; then
            local zsh_comp_dir="$USER_HOME/.local/share/zsh/site-functions"
            local zfunc_dir="$USER_HOME/.zfunc"
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

    if command -v cargo-install-update &>/dev/null || [ -f "$CARGO_HOME/bin/cargo-install-update" ]; then
        log_step "Comprobando actualizaciones de binarios instalados con Cargo..."
        run_as_user cargo install-update -a 2>/dev/null || true
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
        echo "🦀 OPTIMIZADOR Y CONFIGURADOR DE RUST - UBUNTU WORKSTATION"
        echo "   AMD Ryzen 7 7730U (16 hilos) | 32 GB RAM | NVMe | Ubuntu 26.10"
        echo "================================================================="
        install_system_deps
        install_rustup
        configure_cargo_optimizations
        install_cargo_tools
        configure_environment
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Rust configurado y optimizado con éxito para Ubuntu 26.10."
        echo "💡 Inicia una nueva terminal o ejecuta: source ~/.bashrc"
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
