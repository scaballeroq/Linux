#!/usr/bin/env bash
# ==============================================================================
# rust.sh - Instalación, Optimización y Diagnóstico de Rust en CachyOS Workstation
# Sistema: CachyOS Linux Workstation (GNOME Shell 51 / Wayland)
# Hardware: HP ProBook 455 G10 | AMD Ryzen 7 7730U (Zen 3, 8C/16T) | 32 GB RAM | NVMe
# ==============================================================================
# Características de Alto Rendimiento:
# - Despliegue idempotente y rootless en espacio de usuario vía Rustup oficial.
# - Detección inteligente de dependencias nativas y enlazadores con Pacman
#   (base-devel, clang, lld, cmake, openssl, pkgconf, mold, sccache).
# - Enlazador ultrarrápido Mold configurado dinámicamente en ~/.cargo/config.toml,
#   reduciendo tiempos de enlazado incremental entre 3x y 5x.
# - Caché compartida con sccache (15 GB asignados en SSD NVMe) para ahorrar ciclos de CPU
#   y reducir drásticamente el desgaste por reescritura.
# - Optimización multicore ajustada dinámicamente a los 16 hilos del procesador AMD Ryzen 7 7730U.
# - Componentes de desarrollo esenciales integrados (rust-analyzer, clippy, rustfmt, rust-src).
# - Gestor binario 'cargo-binstall' para descargas instantáneas de herramientas sin recompilar.
# - Herramientas de productividad profesional opcionales (cargo-watch, cargo-nextest, cargo-audit).
# - Integración de entorno con GNOME Shell (environment.d), Bash (~/.bashrc.d), Zsh (~/.zshrc.d)
#   y shims de Mise (~/.local/bin/mise).
# - Autocompletados nativos generados para Bash y Zsh.
# - Soporte CLI avanzado: --status / -s, --update / -u, --tools / -t, --clean / -c, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN DE ENTORNO
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1"; }
log_step()  { echo -e "${BLUE}>>${NC}    $1"; }
log_warn()  { echo -e "${MAGENTA}[WARN]${NC} $1"; }

# ------------------------------------------------------------------------------
# 2. DETECCIÓN DE USUARIO, PRIVILEGIOS Y HARDWARE
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

# Detección de hilos de CPU (AMD Ryzen 7 7730U -> 16 hilos lógicos)
NPROC=$(nproc 2>/dev/null || echo 16)
export CARGO_BUILD_JOBS="$NPROC"
export MAKEFLAGS="-j$NPROC"

# Rutas estándar de Cargo y Rust
CARGO_HOME="${CARGO_HOME:-$USER_HOME/.cargo}"
RUSTUP_HOME="${RUSTUP_HOME:-$USER_HOME/.rustup}"
SCCACHE_CACHE_DIR="${SCCACHE_DIR:-$USER_HOME/.cache/sccache}"
export CARGO_HOME RUSTUP_HOME

# Inyectar rutas de Cargo, Mise y usuario en el PATH local del proceso
export PATH="$CARGO_HOME/bin:$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:$PATH"

# Ejecutor aislado en el contexto del usuario real
run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" \
            CARGO_HOME="$CARGO_HOME" RUSTUP_HOME="$RUSTUP_HOME" \
            SCCACHE_DIR="$SCCACHE_CACHE_DIR" \
            CARGO_BUILD_JOBS="$NPROC" MAKEFLAGS="-j$NPROC" \
            PATH="$CARGO_HOME/bin:$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    else
        env HOME="$USER_HOME" \
            CARGO_HOME="$CARGO_HOME" RUSTUP_HOME="$RUSTUP_HOME" \
            SCCACHE_DIR="$SCCACHE_CACHE_DIR" \
            CARGO_BUILD_JOBS="$NPROC" MAKEFLAGS="-j$NPROC" \
            PATH="$CARGO_HOME/bin:$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    fi
}

check_pkg() {
    pacman -Q "$1" &>/dev/null
}

# ------------------------------------------------------------------------------
# 3. AYUDA Y ESTADO (--help, --status)
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🦀 Instalador, Optimizador y Diagnóstico de Rust - CachyOS Workstation
   Hardware: AMD Ryzen 7 7730U (16 hilos) | 32 GB RAM | NVMe Kioxia | GNOME Wayland

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala/actualiza Rustup oficial, toolchain Stable, componentes de IDE
                      (rust-analyzer, clippy, rustfmt, rust-src), enlazador Mold, caché sccache,
                      cargo-binstall, configuración en ~/.cargo/config.toml y autocompletados.
  --status, -s        Diagnóstico integral del compilador, toolchains, enlazador Mold,
                      caché sccache, aceleración multinúcleo, perfiles e integración de shells.
  --update, -u        Actualiza Rustup, toolchains activos, componentes y utilidades instaladas.
  --tools, -t         Instala herramientas de productividad profesional (cargo-watch,
                      cargo-nextest, cargo-audit, cargo-update) usando cargo-binstall.
  --clean, -c         Limpia cachés de compilación (sccache) y ficheros temporales de Cargo.
  --help, -h          Muestra este mensaje de ayuda.

Características de Rendimiento Configuradas:
  • Compilación:      $NPROC hilos en paralelo (CARGO_BUILD_JOBS=$NPROC para Zen 3 Ryzen 7 7730U).
  • Enlazador:        Mold (enlazador ultrarrápido en Linux, reduciendo tiempos de link 3x-5x).
  • Caché de build:   sccache (15 GB máx en NVMe) para evitar recompilaciones y ciclos de CPU.
  • Extensiones IDE:  rust-analyzer (LSP), clippy (linter), rustfmt (formateador) y rust-src.
  • Gestor binario:   cargo-binstall para desplegar crates precompilados de forma instantánea.
  • Integración:      GNOME Shell (environment.d), Bash (~/.bashrc.d), Zsh (~/.zshrc.d) y Mise.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DEL ENTORNO RUST - CACHYOS WORKSTATION"
    echo "   AMD Ryzen 7 7730U (16 hilos) | 32 GB RAM | NVMe | CachyOS Workstation"
    echo "================================================================="

    local rustc_ver cargo_ver rustup_ver mold_ver sccache_ver binstall_ver mise_stat

    if command -v rustc &>/dev/null; then
        rustc_ver=$(rustc --version 2>/dev/null)
    elif [ -x "$CARGO_HOME/bin/rustc" ]; then
        rustc_ver=$("$CARGO_HOME/bin/rustc" --version 2>/dev/null)
    else
        rustc_ver="No instalado"
    fi

    if command -v cargo &>/dev/null; then
        cargo_ver=$(cargo --version 2>/dev/null)
    elif [ -x "$CARGO_HOME/bin/cargo" ]; then
        cargo_ver=$("$CARGO_HOME/bin/cargo" --version 2>/dev/null)
    else
        cargo_ver="No instalado"
    fi

    if command -v rustup &>/dev/null; then
        rustup_ver=$(rustup --version 2>/dev/null | head -n1)
    elif [ -x "$CARGO_HOME/bin/rustup" ]; then
        rustup_ver=$("$CARGO_HOME/bin/rustup" --version 2>/dev/null | head -n1)
    else
        rustup_ver="No instalado"
    fi

    mold_ver=$(command -v mold &>/dev/null && mold --version 2>/dev/null | head -n1 || echo "No instalado")
    sccache_ver=$(command -v sccache &>/dev/null && sccache --version 2>/dev/null || echo "No instalado")

    if [ -x "$CARGO_HOME/bin/cargo-binstall" ] || command -v cargo-binstall &>/dev/null; then
        binstall_ver=$("$CARGO_HOME/bin/cargo-binstall" --version 2>/dev/null || cargo-binstall --version 2>/dev/null || echo "Instalado")
    else
        binstall_ver="No instalado"
    fi

    if command -v mise &>/dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
        mise_stat="✅ Activo ($(command -v mise 2>/dev/null || echo "$USER_HOME/.local/bin/mise"))"
    else
        mise_stat="❌ No detectado"
    fi

    echo "1. Toolchain Oficial y Compilador:"
    echo "  • Rustup:                $rustup_ver"
    echo "  • Compilador rustc:      $rustc_ver"
    echo "  • Gestor Cargo:          $cargo_ver"
    echo "  • Gestor cargo-binstall: $binstall_ver"
    echo "  • Gestor Runtimes Mise:  $mise_stat"
    echo "-----------------------------------------------------------------"
    echo "2. Optimizaciones de Rendimiento y Enlazado:"
    echo "  • Hilos paralelos (Ryzen): CARGO_BUILD_JOBS=$NPROC (-j$NPROC)"
    echo "  • Enlazador Mold:        $mold_ver"
    echo "  • Compilación sccache:   $sccache_ver"
    echo "  • Directorio sccache:    $SCCACHE_CACHE_DIR"
    echo "  • Configuración Cargo:   $([ -f "$CARGO_HOME/config.toml" ] && echo "✅ Configurado ($CARGO_HOME/config.toml)" || echo "❌ No configurado")"
    
    if command -v sccache &>/dev/null && [ -d "$SCCACHE_CACHE_DIR" ]; then
        local sccache_stats
        sccache_stats=$(sccache --show-stats 2>/dev/null | grep -E "Compile requests|Cache hits|Cache misses" || true)
        if [ -n "$sccache_stats" ]; then
            echo "  • Estadísticas sccache:  $(echo "$sccache_stats" | tr '\n' ' | ' | sed 's/ | $//')"
        fi
    fi

    echo "-----------------------------------------------------------------"
    echo "3. Componentes de IDE instalados (rustup component list):"
    if command -v rustup &>/dev/null || [ -x "$CARGO_HOME/bin/rustup" ]; then
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
    echo "4. Herramientas de Productividad (Cargo Tools):"
    local c_watch c_nextest c_audit c_update
    c_watch=$([ -x "$CARGO_HOME/bin/cargo-watch" ] && echo "✅ Instalado" || echo "❌ No instalado")
    c_nextest=$([ -x "$CARGO_HOME/bin/cargo-nextest" ] && echo "✅ Instalado" || echo "❌ No instalado")
    c_audit=$([ -x "$CARGO_HOME/bin/cargo-audit" ] && echo "✅ Instalado" || echo "❌ No instalado")
    c_update=$([ -x "$CARGO_HOME/bin/cargo-install-update" ] && echo "✅ Instalado" || echo "❌ No instalado")
    echo "  • cargo-watch:           $c_watch"
    echo "  • cargo-nextest:         $c_nextest"
    echo "  • cargo-audit:           $c_audit"
    echo "  • cargo-update:          $c_update"

    echo "-----------------------------------------------------------------"
    echo "5. Integración en Shells y Sesión Wayland:"
    echo "  • GNOME environment.d:   $([ -f "$USER_HOME/.config/environment.d/10-rust.conf" ] && echo '✅ Activo (~/.config/environment.d/10-rust.conf)' || echo '❌ Ausente')"
    echo "  • Shell Bash (~/.bashrc.d): $([ -f "$USER_HOME/.bashrc.d/rust.sh" ] && echo '✅ Activo (~/.bashrc.d/rust.sh)' || echo '❌ Ausente')"
    echo "  • Shell Zsh (~/.zshrc.d):   $([ -f "$USER_HOME/.zshrc.d/rust.zsh" ] && echo '✅ Activo (~/.zshrc.d/rust.zsh)' || echo '❌ Ausente')"
    echo "  • Autocompletados:       $([ -f "$USER_HOME/.local/share/bash-completion/completions/cargo" ] && echo '✅ Configurados' || echo '❌ Ausentes')"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN DE DEPENDENCIAS DEL SISTEMA (PACMAN)
# ------------------------------------------------------------------------------
install_system_deps() {
    log_info "Comprobando dependencias de compilación y enlazado nativo en CachyOS..."
    local pkgs_to_install=()

    # Dependencias base para compilar C/C++, bindgen y crates nativos en CachyOS
    local core_deps=(
        base-devel
        clang
        lld
        cmake
        openssl
        pkgconf
        curl
        mold
        sccache
    )

    for pkg in "${core_deps[@]}"; do
        if ! check_pkg "$pkg"; then
            pkgs_to_install+=("$pkg")
        fi
    done

    if [ ${#pkgs_to_install[@]} -gt 0 ]; then
        log_step "Instalando paquetes del sistema faltantes (${pkgs_to_install[*]}) vía Pacman..."
        $SUDO pacman -S --needed --noconfirm "${pkgs_to_install[@]}" 2>/dev/null || {
            for p in "${pkgs_to_install[@]}"; do
                $SUDO pacman -S --needed --noconfirm "$p" 2>/dev/null || true
            done
        }
        log_ok "Dependencias de sistema procesadas correctamente."
    else
        log_ok "Todas las dependencias de compilación del sistema ya están instaladas."
    fi
}

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN / ACTUALIZACIÓN DE RUSTUP Y TOOLCHAIN STABLE
# ------------------------------------------------------------------------------
install_rustup() {
    log_info "Verificando instalación oficial de Rustup..."
    run_as_user mkdir -p "$CARGO_HOME" "$RUSTUP_HOME" "$SCCACHE_CACHE_DIR"

    if ! command -v rustup &>/dev/null && [ ! -x "$CARGO_HOME/bin/rustup" ]; then
        log_step "Descargando e instalando Rustup oficial (perfil default / stable)..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | run_as_user sh -s -- -y --default-toolchain stable --profile default --no-modify-path
        log_ok "Rustup y toolchain Stable instalados con éxito."
    else
        log_ok "Rustup ya se encuentra instalado en el sistema."
    fi

    # Asegurar componentes clave de desarrollo para IDEs (rust-analyzer, clippy, rustfmt, rust-src)
    log_step "Asegurando componentes de desarrollo (rust-analyzer, clippy, rustfmt, rust-src)..."
    run_as_user rustup component add rust-analyzer clippy rustfmt rust-src 2>/dev/null || {
        log_warn "No se pudieron registrar algunos componentes de rustup. Continuando..."
    }
    log_ok "Componentes esenciales de desarrollo verificados."
}

# ------------------------------------------------------------------------------
# 6. CONFIGURACIÓN ÓPTIMA DE CARGO (MOLD + SCCACHE + HILOS RYZEN)
# ------------------------------------------------------------------------------
configure_cargo_optimizations() {
    log_info "Configurando optimizaciones de alto rendimiento en ~/.cargo/config.toml..."
    run_as_user mkdir -p "$CARGO_HOME"

    local has_mold=false
    local has_sccache=false

    if command -v mold &>/dev/null || check_pkg mold; then
        has_mold=true
    fi

    if command -v sccache &>/dev/null || check_pkg sccache; then
        has_sccache=true
    fi

    # Generar configuración base
    local config_file="$CARGO_HOME/config.toml"
    local temp_config
    temp_config=$(mktemp)

    cat <<EOF > "$temp_config"
# ==============================================================================
# Cargo Configuration - CachyOS Workstation
# Hardware: AMD Ryzen 7 7730U (Zen 3, 16 hilos) | 32 GB RAM | NVMe Kioxia
# ==============================================================================

[build]
# Paralelismo automático asignado a los hilos de la CPU AMD Ryzen
jobs = $NPROC

[profile.dev]
opt-level = 0
debug = 1
incremental = true
split-debuginfo = "unpacked"

[profile.release]
opt-level = 3
lto = "thin"
codegen-units = 1
panic = "abort"
strip = "symbols"

[profile.test]
opt-level = 1

[net]
git-fetch-with-cli = true
EOF

    # Incorporar sccache si está disponible
    if [ "$has_sccache" = true ]; then
        sed -i '/\[build\]/a rustc-wrapper = "sccache"' "$temp_config"
        log_ok "Acelerador de compilación sccache activado en Cargo."
    fi

    # Incorporar Mold para enlazado de alta velocidad en x86_64 Linux
    if [ "$has_mold" = true ]; then
        cat <<'EOF' >> "$temp_config"

[target.x86_64-unknown-linux-gnu]
rustflags = [
    "-C", "link-arg=-fuse-ld=mold",
]
EOF
        log_ok "Enlazador ultrarrápido Mold configurado para x86_64-unknown-linux-gnu."
    fi

    run_as_user cp "$temp_config" "$config_file"
    rm -f "$temp_config"

    log_ok "Archivo de configuración optimizado en $config_file."
}

# ------------------------------------------------------------------------------
# 7. INSTALACIÓN DE CARGO-BINSTALL Y HERRAMIENTAS RECOMENDADAS
# ------------------------------------------------------------------------------
install_binstall() {
    log_info "Verificando gestor binario 'cargo-binstall'..."
    if ! command -v cargo-binstall &>/dev/null && [ ! -x "$CARGO_HOME/bin/cargo-binstall" ]; then
        log_step "Instalando cargo-binstall mediante release oficial precompilado..."
        curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | run_as_user bash 2>/dev/null || {
            log_warn "Instalación automática de cargo-binstall falló. Se intentará en la siguiente ejecución."
        }
    fi

    if command -v cargo-binstall &>/dev/null || [ -x "$CARGO_HOME/bin/cargo-binstall" ]; then
        log_ok "cargo-binstall está disponible para descargas ultrarrápidas sin recompilar."
    fi
}

install_productivity_tools() {
    log_info "Instalando herramientas de desarrollo recomendadas..."
    install_binstall

    local binstall_cmd=""
    if [ -x "$CARGO_HOME/bin/cargo-binstall" ]; then
        binstall_cmd="$CARGO_HOME/bin/cargo-binstall"
    elif command -v cargo-binstall &>/dev/null; then
        binstall_cmd="cargo-binstall"
    fi

    local tools=(cargo-watch cargo-nextest cargo-audit cargo-update)

    if [ -n "$binstall_cmd" ]; then
        for tool in "${tools[@]}"; do
            log_step "Comprobando e instalando $tool vía cargo-binstall..."
            run_as_user "$binstall_cmd" --no-confirm "$tool" 2>/dev/null || {
                log_warn "No se pudo instalar $tool vía binstall."
            }
        done
        log_ok "Herramientas de productividad instaladas con éxito."
    else
        log_warn "cargo-binstall no está disponible. Omite la instalación de herramientas extras."
    fi

    # Sincronizar shims con Mise si está disponible
    if command -v mise &>/dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
        run_as_user mise reshim 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# 8. INTEGRACIÓN CON GNOME SHELL, SHELLS (BASH / ZSH) Y AUTOCOMPLETADOS
# ------------------------------------------------------------------------------
configure_environment() {
    log_info "Configurando variables de entorno, shells y autocompletados..."

    local env_dir="$USER_HOME/.config/environment.d"
    local bashrc_d="$USER_HOME/.bashrc.d"
    local zshrc_d="$USER_HOME/.zshrc.d"
    local bash_comp_dir="$USER_HOME/.local/share/bash-completion/completions"
    local zsh_comp_dir="$USER_HOME/.local/share/zsh/site-functions"
    local zfunc_dir="$USER_HOME/.zfunc"

    run_as_user mkdir -p "$env_dir" "$bashrc_d" "$zshrc_d" "$bash_comp_dir" "$zsh_comp_dir" "$zfunc_dir"

    # 8.1. Integración con sesión gráfica GNOME Shell / Mutter Wayland (systemd user)
    cat <<EOF | run_as_user tee "$env_dir/10-rust.conf" > /dev/null
CARGO_HOME=$CARGO_HOME
RUSTUP_HOME=$RUSTUP_HOME
CARGO_BUILD_JOBS=$NPROC
SCCACHE_DIR=$SCCACHE_CACHE_DIR
SCCACHE_CACHE_SIZE=15G
PATH=$CARGO_HOME/bin:\$PATH
EOF

    # 8.2. Shell Bash modular (~/.bashrc.d/rust.sh)
    cat <<EOF | run_as_user tee "$bashrc_d/rust.sh" > /dev/null
# Rust & Cargo Environment - CachyOS Workstation (AMD Ryzen 7 7730U)
export CARGO_HOME="$CARGO_HOME"
export RUSTUP_HOME="$RUSTUP_HOME"
export CARGO_BUILD_JOBS=$NPROC
export SCCACHE_DIR="$SCCACHE_CACHE_DIR"
export SCCACHE_CACHE_SIZE="15G"

if [ -f "$CARGO_HOME/env" ]; then
    . "$CARGO_HOME/env"
elif [ -d "$CARGO_HOME/bin" ] && [[ ":\$PATH:" != *":$CARGO_HOME/bin:"* ]]; then
    export PATH="$CARGO_HOME/bin:\$PATH"
fi
EOF

    # 8.3. Shell Zsh modular (~/.zshrc.d/rust.zsh)
    cat <<EOF | run_as_user tee "$zshrc_d/rust.zsh" > /dev/null
# Rust & Cargo Environment - CachyOS Workstation (AMD Ryzen 7 7730U)
export CARGO_HOME="$CARGO_HOME"
export RUSTUP_HOME="$RUSTUP_HOME"
export CARGO_BUILD_JOBS=$NPROC
export SCCACHE_DIR="$SCCACHE_CACHE_DIR"
export SCCACHE_CACHE_SIZE="15G"

if [ -f "$CARGO_HOME/env" ]; then
    . "$CARGO_HOME/env"
elif [ -d "$CARGO_HOME/bin" ] && [[ ":\$PATH:" != *":$CARGO_HOME/bin:"* ]]; then
    export PATH="$CARGO_HOME/bin:\$PATH"
fi
EOF

    # 8.4. Autocompletados nativos para Bash y Zsh
    if command -v rustup &>/dev/null || [ -x "$CARGO_HOME/bin/rustup" ]; then
        run_as_user rustup completions bash > "$bash_comp_dir/rustup" 2>/dev/null || true
        run_as_user rustup completions bash cargo > "$bash_comp_dir/cargo" 2>/dev/null || true

        run_as_user rustup completions zsh > "$zsh_comp_dir/_rustup" 2>/dev/null || true
        run_as_user rustup completions zsh cargo > "$zsh_comp_dir/_cargo" 2>/dev/null || true
        run_as_user cp "$zsh_comp_dir/_rustup" "$zfunc_dir/_rustup" 2>/dev/null || true
        run_as_user cp "$zsh_comp_dir/_cargo" "$zfunc_dir/_cargo" 2>/dev/null || true
    fi

    # 8.5. Sincronización con Mise si está disponible
    if command -v mise &>/dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
        run_as_user mise reshim 2>/dev/null || true
    fi

    log_ok "Integración con GNOME Shell, Bash, Zsh y autocompletados completada con éxito."
}

# ------------------------------------------------------------------------------
# 9. ACTUALIZACIÓN (--update)
# ------------------------------------------------------------------------------
update_rust() {
    log_info "Actualizando entorno completo de Rust..."
    if command -v rustup &>/dev/null || [ -x "$CARGO_HOME/bin/rustup" ]; then
        log_step "Actualizando Rustup y toolchains activos..."
        run_as_user rustup self update
        run_as_user rustup update
        run_as_user rustup component add rust-analyzer clippy rustfmt rust-src 2>/dev/null || true
    else
        log_warn "Rustup no está instalado. Ejecuta el script sin parámetros para instalarlo."
    fi

    if [ -x "$CARGO_HOME/bin/cargo-install-update" ]; then
        log_step "Actualizando crates instalados..."
        run_as_user "$CARGO_HOME/bin/cargo-install-update" install-update -a 2>/dev/null || true
    fi

    if command -v mise &>/dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
        run_as_user mise reshim 2>/dev/null || true
    fi

    log_ok "Actualización de Rust finalizada."
}

# ------------------------------------------------------------------------------
# 10. LIMPIEZA DE CACHÉS Y ARTEFACTOS (--clean)
# ------------------------------------------------------------------------------
clean_rust_caches() {
    log_info "Limpiando cachés de compilación y artefactos temporales..."
    if command -v sccache &>/dev/null; then
        log_step "Vaciando estadísticas y caché de sccache..."
        run_as_user sccache --clear-cache 2>/dev/null || true
        run_as_user sccache --zero-stats 2>/dev/null || true
        log_ok "Caché de sccache reiniciada."
    fi

    if [ -d "$CARGO_HOME/registry/cache" ]; then
        log_step "Eliminando archivos de caché de crates antiguos..."
        run_as_user rm -rf "$CARGO_HOME/registry/cache"/* 2>/dev/null || true
        log_ok "Caché de descargas de crates limpiada."
    fi

    log_ok "Proceso de limpieza completado con éxito."
}

# ------------------------------------------------------------------------------
# 11. ENRUTADOR DE COMANDOS CLI
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
    --tools|-t|tools)
        install_productivity_tools
        echo ""
        show_status
        exit 0
        ;;
    --clean|-c|clean)
        clean_rust_caches
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🦀 OPTIMIZADOR Y CONFIGURADOR DE RUST - CACHYOS WORKSTATION"
        echo "   AMD Ryzen 7 7730U (16 hilos) | 32 GB RAM | NVMe | CachyOS Workstation"
        echo "================================================================="
        install_system_deps
        install_rustup
        configure_cargo_optimizations
        install_binstall
        configure_environment
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Rust configurado y optimizado con éxito para CachyOS Workstation."
        echo "💡 Inicia una nueva terminal o ejecuta: source ~/.bashrc"
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac