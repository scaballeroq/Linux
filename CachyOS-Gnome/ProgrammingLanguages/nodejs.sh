#!/usr/bin/env bash
# ==============================================================================
# nodejs.sh - Instalación y Optimización de Node.js (Última LTS) vía Mise
# Sistema: Fedora Linux Workstation | Escritorio: GNOME Shell (Wayland)
# Hardware: HP ProBook 455 G10 | AMD Ryzen 7 7730U (Zen 3, 8C/16T) | 32 GB RAM
# ==============================================================================
# Características:
# - Despliegue idempotente y rootless en espacio de usuario vía Mise.
# - Detección inteligente de dependencias del sistema (make, gcc-c++, curl, python3)
#   para compilación de módulos nativos C++ (node-gyp).
# - Optimización multinúcleo para AMD Ryzen 7 7730U (-j16, JOBS=16, npm_config_jobs=16).
# - Habilitación de Corepack (pnpm, yarn) con descargas desatendidas (COREPACK_ENABLE_DOWNLOAD_PROMPT=0).
# - Integración nativa con GNOME Shell (~/.config/environment.d) y Shells (Bash / Zsh).
# - Generación automática de autocompletados nativos para npm y pnpm (Bash / Zsh).
# - Comandos CLI: --status / -s, --update / -u, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y RUTAS
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1"; }
log_step()  { echo -e "${BLUE}>>${NC}    $1"; }

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

DNF_CMD=$(command -v dnf5 2>/dev/null || command -v dnf 2>/dev/null || echo "dnf")

# Flags de optimización multinúcleo (AMD Ryzen 7 7730U -> 16 hilos) para node-gyp
NPROC=$(nproc 2>/dev/null || echo 16)
export MAKEFLAGS="-j$NPROC"
export JOBS="$NPROC"
export npm_config_jobs="$NPROC"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

# Exportar rutas de Mise y usuario
export PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/local/bin:/usr/bin:$PATH"

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" \
            MAKEFLAGS="-j$NPROC" JOBS="$NPROC" npm_config_jobs="$NPROC" \
            COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
            PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    else
        env HOME="$USER_HOME" \
            MAKEFLAGS="-j$NPROC" JOBS="$NPROC" npm_config_jobs="$NPROC" \
            COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
            PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    fi
}

get_mise_bin() {
    if [ -x "$USER_HOME/.local/bin/mise" ]; then
        echo "$USER_HOME/.local/bin/mise"
    elif command -v mise &>/dev/null; then
        command -v mise
    elif [ -x "/usr/bin/mise" ]; then
        echo "/usr/bin/mise"
    elif [ -x "/usr/local/bin/mise" ]; then
        echo "/usr/local/bin/mise"
    else
        echo ""
    fi
}

run_mise() {
    local mise_bin
    mise_bin=$(get_mise_bin)
    if [ -z "$mise_bin" ]; then
        log_error "Mise no está disponible en el sistema."
        return 1
    fi
    run_as_user "$mise_bin" "$@"
}

# ------------------------------------------------------------------------------
# 3. AYUDA Y ESTADO
# ------------------------------------------------------------------------------
show_help() {
    echo -e "${BOLD}🟢 Instalador y Optimizador de Node.js (LTS) - Fedora Workstation (Mise)${NC}"
    echo -e "Hardware objetivo: AMD Ryzen 7 7730U (${NPROC} hilos) | GNOME 51 Wayland"
    echo ""
    echo -e "${BOLD}Uso:${NC}"
    echo -e "  $0 [OPCIÓN]"
    echo ""
    echo -e "${BOLD}Opciones:${NC}"
    echo -e "  (sin argumentos)    Instala la última versión LTS de Node.js vía Mise, activa Corepack"
    echo -e "                      (pnpm/yarn), configura optimizaciones multinúcleo (-j$NPROC) y autocompletados."
    echo -e "  -s, --status        Muestra diagnóstico detallado del entorno Node.js, npm, pnpm,"
    echo -e "                      Corepack y variables de compilación nativa C++ (node-gyp)."
    echo -e "  -u, --update        Actualiza Node.js a la última versión LTS disponible, Corepack y shims."
    echo -e "  -h, --help          Muestra este mensaje de ayuda."
}

show_status() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔍 DIAGNÓSTICO DE NODE.JS & GESTORES DE PAQUETES (MISE + FEDORA)${NC}"
    echo -e "   Hardware: AMD Ryzen 7 7730U (${NPROC} hilos) | GNOME Shell Wayland"
    echo -e "${CYAN}=================================================================${NC}"

    local node_path node_ver npm_ver pnpm_ver yarn_ver corepack_status

    if [ -x "$USER_HOME/.local/share/mise/shims/node" ]; then
        node_path="$USER_HOME/.local/share/mise/shims/node"
        node_ver=$(run_as_user "$node_path" --version 2>/dev/null || echo "No disponible")
    elif command -v node &>/dev/null; then
        node_path=$(command -v node)
        node_ver=$(node --version 2>/dev/null || echo "No disponible")
    else
        node_path="No instalado"
        node_ver="No disponible"
    fi

    local npm_bin pnpm_bin yarn_bin corepack_bin
    npm_bin="$USER_HOME/.local/share/mise/shims/npm"
    pnpm_bin="$USER_HOME/.local/share/mise/shims/pnpm"
    yarn_bin="$USER_HOME/.local/share/mise/shims/yarn"
    corepack_bin="$USER_HOME/.local/share/mise/shims/corepack"

    if [ -x "$npm_bin" ]; then
        npm_ver="v$(run_as_user "$npm_bin" --version 2>/dev/null || echo "Desconocida")"
    elif command -v npm &>/dev/null; then
        npm_ver="v$(npm --version 2>/dev/null || echo "Desconocida")"
    else
        npm_ver="No disponible"
    fi

    if [ -x "$pnpm_bin" ]; then
        pnpm_ver="v$(run_as_user "$pnpm_bin" --version 2>/dev/null || echo "Desconocida")"
    elif command -v pnpm &>/dev/null; then
        pnpm_ver="v$(pnpm --version 2>/dev/null || echo "Desconocida")"
    else
        pnpm_ver="No disponible"
    fi

    if [ -x "$yarn_bin" ]; then
        yarn_ver="v$(run_as_user "$yarn_bin" --version 2>/dev/null || echo "Desconocida")"
    elif command -v yarn &>/dev/null; then
        yarn_ver="v$(yarn --version 2>/dev/null || echo "Desconocida")"
    else
        yarn_ver="No disponible"
    fi

    if [ -x "$corepack_bin" ]; then
        corepack_status="${GREEN}✅ Habilitado (v$(run_as_user "$corepack_bin" --version 2>/dev/null || echo "activo"))${NC}"
    elif command -v corepack &>/dev/null; then
        corepack_status="${GREEN}✅ Habilitado (v$(corepack --version 2>/dev/null || echo "activo"))${NC}"
    else
        corepack_status="${YELLOW}ℹ️ No instalado / Deshabilitado${NC}"
    fi

    echo -e "• ${BOLD}Node.js:${NC}                $([ "$node_ver" != "No disponible" ] && echo -e "${GREEN}✅ $node_ver ($node_path)${NC}" || echo -e "${RED}❌ $node_ver${NC}")"
    echo -e "• ${BOLD}npm:${NC}                    $([ "$npm_ver" != "No disponible" ] && echo -e "${GREEN}✅ $npm_ver${NC}" || echo -e "${RED}❌ $npm_ver${NC}")"
    echo -e "• ${BOLD}pnpm (Corepack):${NC}        $([ "$pnpm_ver" != "No disponible" ] && echo -e "${GREEN}✅ $pnpm_ver${NC}" || echo -e "${YELLOW}ℹ️ $pnpm_ver${NC}")"
    echo -e "• ${BOLD}yarn (Corepack):${NC}        $([ "$yarn_ver" != "No disponible" ] && echo -e "${GREEN}✅ $yarn_ver${NC}" || echo -e "${YELLOW}ℹ️ $yarn_ver${NC}")"
    echo -e "• ${BOLD}Corepack:${NC}               $corepack_status"
    echo -e "${CYAN}-----------------------------------------------------------------${NC}"
    echo -e "• ${BOLD}Optimizaciones de Compilación C++ (node-gyp / AMD Ryzen):${NC}"
    echo -e "  - MAKEFLAGS:             -j$NPROC (Hilos de CPU detectados)"
    echo -e "  - JOBS / npm_config_jobs: $NPROC"
    echo -e "  - Corepack Downloads:    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 (Desatendido)"
    echo -e "${CYAN}-----------------------------------------------------------------${NC}"
    echo -e "• ${BOLD}Integración en el Entorno:${NC}"
    echo -e "  - GNOME environment.d:   $([ -f "$USER_HOME/.config/environment.d/10-nodejs.conf" ] && echo -e "${GREEN}✅ Activo (~/.config/environment.d/10-nodejs.conf)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    echo -e "  - Shell Bash (~/.bashrc.d): $([ -f "$USER_HOME/.bashrc.d/nodejs.sh" ] && echo -e "${GREEN}✅ Activo (~/.bashrc.d/nodejs.sh)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    echo -e "  - Autocompletado npm:    $([ -f "$USER_HOME/.local/share/bash-completion/completions/npm" ] && echo -e "${GREEN}✅ Configurado${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    echo -e "  - Autocompletado pnpm:   $([ -f "$USER_HOME/.local/share/bash-completion/completions/pnpm" ] && echo -e "${GREEN}✅ Configurado${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    if [ -f "$USER_HOME/.zshrc" ]; then
        echo -e "  - Shell Zsh (~/.zshrc.d):   $([ -f "$USER_HOME/.zshrc.d/nodejs.zsh" ] && echo -e "${GREEN}✅ Activo (~/.zshrc.d/nodejs.zsh)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
        echo -e "  - Autocompletado Zsh:    $([ -f "$USER_HOME/.local/share/zsh/site-functions/_pnpm" ] || [ -f "$USER_HOME/.zfunc/_pnpm" ] && echo -e "${GREEN}✅ Configurado${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    fi
    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 4. ACTUALIZACIÓN DE NODE.JS
# ------------------------------------------------------------------------------
update_nodejs() {
    log_info "Comprobando actualizaciones de Node.js LTS vía Mise..."
    local mise_cmd
    mise_cmd=$(get_mise_bin)

    if [ -n "$mise_cmd" ] && [ -x "$mise_cmd" ]; then
        run_mise use --global node@lts
        
        # Actualizar corepack y pnpm
        if run_mise exec node@lts -- command -v corepack &>/dev/null; then
            log_step "Actualizando pnpm a la última versión vía Corepack..."
            COREPACK_ENABLE_DOWNLOAD_PROMPT=0 run_mise exec node@lts -- corepack prepare pnpm@latest --activate 2>/dev/null || true
        fi

        run_mise reshim 2>/dev/null || true
        log_ok "Node.js y gestores de paquetes actualizados con éxito."
    else
        log_error "'mise' no está instalado. Ejecuta '$0' primero."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# 5. DEPENDENCIAS DE COMPILACIÓN NATIVA (node-gyp / DNF5)
# ------------------------------------------------------------------------------
ensure_native_build_deps() {
    log_info "[1/5] Verificando dependencias del sistema para módulos C++ nativos (node-gyp)..."
    local missing_pkgs=()
    for pkg in make gcc-c++ curl python3; do
        if ! rpm -q "$pkg" &>/dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        if [ "$EUID" -eq 0 ] || sudo -n true 2>/dev/null; then
            log_step "Instalando paquetes faltantes vía $DNF_CMD: ${missing_pkgs[*]}..."
            $SUDO $DNF_CMD install -y "${missing_pkgs[@]}" 2>/dev/null || {
                log_warn "No se pudieron instalar automáticamente: ${missing_pkgs[*]}."
            }
        else
            log_warn "Faltan paquetes de compilación C++ nativos en el sistema: ${missing_pkgs[*]}."
            log_warn "Para compilar módulos node-gyp nativos en C++, ejecuta cuando puedas: sudo $DNF_CMD install -y ${missing_pkgs[*]}"
        fi
    else
        log_ok "Todas las dependencias nativas del sistema ya están presentes."
    fi
}

# ------------------------------------------------------------------------------
# 6. INSTALAR / VERIFICAR MISE
# ------------------------------------------------------------------------------
ensure_mise() {
    log_info "[2/5] Asegurando gestor de runtimes Mise..."
    local mise_cmd
    mise_cmd=$(get_mise_bin)

    if [ -z "$mise_cmd" ] || [ ! -x "$mise_cmd" ]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [ -f "$script_dir/mise.sh" ]; then
            log_step "Mise no encontrado. Ejecutando $script_dir/mise.sh..."
            bash "$script_dir/mise.sh"
        else
            log_error "'mise' no está instalado y no se encontró $script_dir/mise.sh."
            exit 1
        fi
    else
        log_ok "Mise disponible en $mise_cmd."
    fi
}

# ------------------------------------------------------------------------------
# 7. INSTALACIÓN DE NODE.JS LTS VÍA MISE
# ------------------------------------------------------------------------------
install_nodejs_lts() {
    log_info "[3/5] Desplegando Node.js LTS de forma rootless vía Mise..."
    run_mise use --global node@lts
    run_mise reshim 2>/dev/null || true
    log_ok "Node.js LTS activo."
}

# ------------------------------------------------------------------------------
# 8. ACTIVACIÓN DE COREPACK (PNPM & YARN)
# ------------------------------------------------------------------------------
configure_package_managers() {
    log_info "[4/5] Configurando gestores de paquetes modernos (Corepack, pnpm, yarn)..."

    # En Node.js 22/24/26+, Corepack puede no venir preempaquetado.
    # Verificamos si corepack existe en el entorno Node activo; si no, lo instalamos limpiamente en Node.
    if ! run_mise exec node@lts -- command -v corepack &>/dev/null; then
        log_step "Instalando Corepack en el entorno Node.js global..."
        run_mise exec node@lts -- npm install -g corepack 2>/dev/null || true
        run_mise reshim 2>/dev/null || true
    fi

    # Activar Corepack y preparar pnpm / yarn de forma desatendida sin bloqueos interactivos
    if run_mise exec node@lts -- command -v corepack &>/dev/null; then
        log_step "Habilitando Corepack y activando pnpm / yarn..."
        COREPACK_ENABLE_DOWNLOAD_PROMPT=0 run_mise exec node@lts -- corepack enable pnpm yarn 2>/dev/null || true
        COREPACK_ENABLE_DOWNLOAD_PROMPT=0 run_mise exec node@lts -- corepack prepare pnpm@latest --activate 2>/dev/null || true
        run_mise reshim 2>/dev/null || true
        log_ok "Corepack y pnpm activados correctamente."
    else
        # Fallback alternativo: instalación directa de pnpm en Mise si Corepack falla
        log_step "Configurando pnpm global en Mise..."
        run_mise use --global pnpm@latest 2>/dev/null || true
        run_mise reshim 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# 9. INTEGRACIÓN CON GNOME SHELL, SHELLS Y AUTOCOMPLETADOS
# ------------------------------------------------------------------------------
configure_environment() {
    log_info "[5/5] Configurando variables de entorno de alto rendimiento y autocompletados..."

    local env_dir="$USER_HOME/.config/environment.d"
    local bashrc_d="$USER_HOME/.bashrc.d"
    local bash_comp_dir="$USER_HOME/.local/share/bash-completion/completions"

    run_as_user mkdir -p "$env_dir" "$bashrc_d" "$bash_comp_dir"

    # 9.1. Integración con sesión gráfica GNOME Shell (systemd --user)
    cat << EOF | run_as_user tee "$env_dir/10-nodejs.conf" > /dev/null
# Integración de Node.js & Corepack para Wayland / GNOME Shell (AMD Ryzen 7 7730U)
MAKEFLAGS="-j$NPROC"
JOBS="$NPROC"
npm_config_jobs="$NPROC"
COREPACK_ENABLE_DOWNLOAD_PROMPT=0
EOF

    # 9.2. Shell Bash (~/.bashrc.d/nodejs.sh)
    cat << EOF | run_as_user tee "$bashrc_d/nodejs.sh" > /dev/null
# Node.js & npm/pnpm Multithreaded Build Settings (Fedora Workstation - AMD Ryzen 7 7730U)
export MAKEFLAGS="-j$NPROC"
export JOBS="$NPROC"
export npm_config_jobs="$NPROC"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
EOF

    # 9.3. Shell Zsh (~/.zshrc.d/nodejs.zsh si existe ~/.zshrc)
    if [ -f "$USER_HOME/.zshrc" ]; then
        local zshrc_d="$USER_HOME/.zshrc.d"
        run_as_user mkdir -p "$zshrc_d"
        cat << EOF | run_as_user tee "$zshrc_d/nodejs.zsh" > /dev/null
# Node.js & npm/pnpm Multithreaded Build Settings (Fedora Workstation - AMD Ryzen 7 7730U)
export MAKEFLAGS="-j$NPROC"
export JOBS="$NPROC"
export npm_config_jobs="$NPROC"
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
EOF
    fi

    # 9.4. Autocompletados para Bash (npm y pnpm)
    log_step "Generando autocompletados para Bash..."
    local npm_bin pnpm_bin
    npm_bin="$USER_HOME/.local/share/mise/shims/npm"
    pnpm_bin="$USER_HOME/.local/share/mise/shims/pnpm"

    if [ -x "$npm_bin" ]; then
        run_as_user "$npm_bin" completion > "$bash_comp_dir/npm" 2>/dev/null || true
    fi

    if [ -x "$pnpm_bin" ]; then
        COREPACK_ENABLE_DOWNLOAD_PROMPT=0 run_as_user "$pnpm_bin" completion bash > "$bash_comp_dir/pnpm" 2>/dev/null || true
    fi

    # 9.5. Autocompletados para Zsh (si existe ~/.zshrc)
    if [ -f "$USER_HOME/.zshrc" ]; then
        log_step "Generando autocompletados para Zsh..."
        local zsh_comp_dir="$USER_HOME/.local/share/zsh/site-functions"
        local zfunc_dir="$USER_HOME/.zfunc"
        run_as_user mkdir -p "$zsh_comp_dir" "$zfunc_dir"

        if [ -x "$pnpm_bin" ]; then
            COREPACK_ENABLE_DOWNLOAD_PROMPT=0 run_as_user "$pnpm_bin" completion zsh > "$zsh_comp_dir/_pnpm" 2>/dev/null || true
            COREPACK_ENABLE_DOWNLOAD_PROMPT=0 run_as_user "$pnpm_bin" completion zsh > "$zfunc_dir/_pnpm" 2>/dev/null || true
        fi
    fi

    log_ok "Integración del entorno y autocompletados completados."
}

# ------------------------------------------------------------------------------
# FLUJO PRINCIPAL
# ------------------------------------------------------------------------------
case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --update|-u|update)
        update_nodejs
        echo ""
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        echo -e "${CYAN}=================================================================${NC}"
        echo -e "${BOLD}🟢 CONFIGURACIÓN DE NODE.JS LTS & PNPM - FEDORA WORKSTATION${NC}"
        echo -e "   Hardware: AMD Ryzen 7 7730U (${NPROC} hilos) | GNOME Shell Wayland"
        echo -e "${CYAN}=================================================================${NC}"
        ensure_native_build_deps
        ensure_mise
        install_nodejs_lts
        configure_package_managers
        configure_environment
        echo ""
        show_status
        echo -e "${BOLD}=================================================================${NC}"
        echo -e "${GREEN}✅ Node.js LTS y pnpm configurados con éxito para Fedora Workstation.${NC}"
        echo -e "💡 Abre una nueva terminal o ejecuta: ${CYAN}source ~/.bashrc${NC}"
        echo -e "${BOLD}=================================================================${NC}"
        ;;
    *)
        log_error "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
