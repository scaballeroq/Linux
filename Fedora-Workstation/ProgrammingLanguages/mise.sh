#!/usr/bin/env bash
# ==============================================================================
# mise.sh - Instalador, Optimizador y Diagnóstico de Mise (Language Runtime Manager)
# Sistema: Fedora Linux Workstation | Escritorio: GNOME Shell (Wayland)
# Hardware: HP ProBook 455 G10 | AMD Ryzen 7 7730U (Zen 3, 8C/16T) | 32 GB RAM
# ==============================================================================
# Características:
# - Instalación idempotente mediante repositorio RPM oficial firmado (DNF/DNF5).
# - Despliegue de shims y activación nativa en Bash (~/.bashrc.d) y Zsh (~/.zshrc.d).
# - Integración nativa con la sesión gráfica Wayland de GNOME Shell (~/.config/environment.d).
# - Generación automática de autocompletados para Bash y Zsh.
# - Diagnóstico integral del gestor, herramientas y shims en tiempo real (--status).
# - Comandos CLI: --status / -s, --update / -u, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y RUTAS
# ------------------------------------------------------------------------------
MISE_INSTALL_URL="https://mise.run"
MISE_BIN_DEFAULT="$HOME/.local/bin/mise"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# 2. DETECCIÓN DE USUARIO Y ELEVACIÓN DE PRIVILEGIOS
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

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" PATH="$USER_HOME/.local/bin:$PATH" "$@"
    else
        PATH="$USER_HOME/.local/bin:$PATH" "$@"
    fi
}

get_mise_bin() {
    if command -v mise &>/dev/null; then
        command -v mise
    elif [ -x "$USER_HOME/.local/bin/mise" ]; then
        echo "$USER_HOME/.local/bin/mise"
    else
        echo ""
    fi
}

# ------------------------------------------------------------------------------
# 3. AYUDA Y ESTADO
# ------------------------------------------------------------------------------
show_help() {
    echo -e "${BOLD}⚡ Gestor de Runtimes Mise - Fedora Workstation${NC}

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)    Instala/actualiza Mise, configura shims, genera integración con GNOME,
                      Bash, Zsh y crea los autocompletados.
  -s, --status        Muestra diagnóstico detallado del estado de Mise, herramientas y shims.
  -u, --update        Actualiza el binario de Mise y todos los runtimes gestionados.
  -h, --help          Muestra este mensaje de ayuda."
}

show_status() {
    local mise_cmd
    mise_cmd=$(get_mise_bin)

    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔍 DIAGNÓSTICO DE MISE (RUNTIME MANAGER) - FEDORA WORKSTATION${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    if [ -n "$mise_cmd" ] && [ -x "$mise_cmd" ]; then
        local version_str
        version_str=$(run_as_user "$mise_cmd" --version 2>/dev/null || echo "Desconocida")
        echo -e "• ${BOLD}Binario Mise:${NC}          ${GREEN}✅ Instalado ($mise_cmd)${NC}"
        echo -e "• ${BOLD}Versión activa:${NC}        ${GREEN}v${version_str}${NC}"
    else
        echo -e "• ${BOLD}Binario Mise:${NC}          ${RED}❌ No instalado${NC}"
    fi

    local data_dir="$USER_HOME/.local/share/mise"
    local config_dir="$USER_HOME/.config/mise"
    local shims_dir="$data_dir/shims"

    echo -e "• ${BOLD}Directorio Shims:${NC}      $([ -d "$shims_dir" ] && echo -e "${GREEN}✅ Presente ($shims_dir)${NC}" || echo -e "${YELLOW}ℹ️ No inicializado aún${NC}")"
    echo -e "• ${BOLD}Configuración Global:${NC}  $([ -f "$config_dir/config.toml" ] && echo -e "${GREEN}✅ Configurado ($config_dir/config.toml)${NC}" || echo -e "${YELLOW}ℹ️ Por defecto / Sin config.toml manual${NC}")"

    local env_d_file="$USER_HOME/.config/environment.d/10-mise.conf"
    echo -e "• ${BOLD}GNOME environment.d:${NC}   $([ -f "$env_d_file" ] && echo -e "${GREEN}✅ Activo ($env_d_file)${NC}" || echo -e "${RED}❌ Ausente${NC}")"

    local bashrc_d_file="$USER_HOME/.bashrc.d/mise.sh"
    echo -e "• ${BOLD}Shell Bash (~/.bashrc.d):${NC} $([ -f "$bashrc_d_file" ] && echo -e "${GREEN}✅ Activo ($bashrc_d_file)${NC}" || echo -e "${RED}❌ Ausente${NC}")"

    if [ -f "$USER_HOME/.zshrc" ]; then
        local zshrc_d_file="$USER_HOME/.zshrc.d/mise.zsh"
        echo -e "• ${BOLD}Shell Zsh (~/.zshrc.d):${NC}   $([ -f "$zshrc_d_file" ] && echo -e "${GREEN}✅ Activo ($zshrc_d_file)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    fi

    echo -e "• ${BOLD}Autocompletado Bash:${NC}   $([ -f "$USER_HOME/.local/share/bash-completion/completions/mise" ] && echo -e "${GREEN}✅ Configurado${NC}" || echo -e "${RED}❌ Ausente${NC}")"

    if [ -n "$mise_cmd" ] && [ -x "$mise_cmd" ]; then
        echo -e "-----------------------------------------------------------------"
        echo -e "• ${BOLD}Herramientas y versiones gestionadas globalmente:${NC}"
        run_as_user "$mise_cmd" list 2>/dev/null || echo -e "  ${YELLOW}ℹ️ Ninguna herramienta instalada aún.${NC}"
    fi

    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN DE MISE
# ------------------------------------------------------------------------------
install_mise() {
    local existing_bin
    existing_bin=$(get_mise_bin)

    if [ -n "$existing_bin" ] && [ -x "$existing_bin" ]; then
        echo -e "${GREEN}✅ Mise ya está instalado ($("$existing_bin" --version)).${NC}"
        return 0
    fi

    echo -e "${BLUE}⬇️ Instalando Mise...${NC}"
    
    # 1. Intentar instalación vía repositorio RPM oficial si hay sudo disponible
    if [ "$EUID" -eq 0 ] || command -v sudo &>/dev/null; then
        echo -e "${BLUE}📦 Configurando repositorio oficial RPM de Mise para Fedora...${NC}"
        $SUDO rpm --import https://mise.jdx.dev/gpg-key.pub 2>/dev/null || true
        cat << 'EOF' | $SUDO tee /etc/yum.repos.d/mise.repo > /dev/null
[mise]
name=Mise
baseurl=https://mise.jdx.dev/rpm
enabled=1
gpgcheck=1
gpgkey=https://mise.jdx.dev/gpg-key.pub
EOF
        $SUDO $DNF_CMD install -y mise 2>/dev/null || true
    fi

    # 2. Fallback a instalación en espacio de usuario vía script oficial
    if ! command -v mise &>/dev/null; then
        echo -e "${BLUE}⬇️ Ejecutando instalador en espacio de usuario (~/.local/bin)...${NC}"
        run_as_user mkdir -p "$USER_HOME/.local/bin"
        curl -fsSL "$MISE_INSTALL_URL" | run_as_user sh 2>/dev/null || true
    fi

    existing_bin=$(get_mise_bin)
    if [ -n "$existing_bin" ] && [ -x "$existing_bin" ]; then
        echo -e "${GREEN}✅ Mise instalado correctamente ($("$existing_bin" --version)).${NC}"
    else
        echo -e "${RED}❌ Error al instalar Mise.${NC}"
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# 5. INTEGRACIÓN CON EL ENTORNO
# ------------------------------------------------------------------------------
configure_environment() {
    local mise_cmd
    mise_cmd=$(get_mise_bin)

    if [ -z "$mise_cmd" ]; then
        echo -e "${RED}❌ Error: Mise no está disponible para configurar el entorno.${NC}"
        return 1
    fi

    echo -e "${BLUE}⚙️ Configurando integración con GNOME Shell, Bash y Zsh...${NC}"

    local env_dir="$USER_HOME/.config/environment.d"
    local bashrc_d="$USER_HOME/.bashrc.d"
    local bash_comp_dir="$USER_HOME/.local/share/bash-completion/completions"

    run_as_user mkdir -p "$env_dir" "$bashrc_d" "$bash_comp_dir"

    # 5.1. Sesión gráfica Wayland (GNOME)
    cat << EOF | run_as_user tee "$env_dir/10-mise.conf" > /dev/null
PATH=$USER_HOME/.local/share/mise/shims:$USER_HOME/.local/bin:\$PATH
EOF

    # 5.2. Shell Bash
    cat << 'EOF' | run_as_user tee "$bashrc_d/mise.sh" > /dev/null
# Mise Runtime Manager Environment
if [ -d "$HOME/.local/share/mise/shims" ] && [[ ":$PATH:" != *":$HOME/.local/share/mise/shims:"* ]]; then
    export PATH="$HOME/.local/share/mise/shims:$PATH"
fi

if command -v mise &>/dev/null; then
    eval "$(mise activate bash --shims)"
fi
EOF

    # 5.3. Shell Zsh (si existe)
    if [ -f "$USER_HOME/.zshrc" ]; then
        local zshrc_d="$USER_HOME/.zshrc.d"
        local zsh_comp_dir="$USER_HOME/.local/share/zsh/site-functions"
        local zfunc_dir="$USER_HOME/.zfunc"
        run_as_user mkdir -p "$zshrc_d" "$zsh_comp_dir" "$zfunc_dir"

        cat << 'EOF' | run_as_user tee "$zshrc_d/mise.zsh" > /dev/null
# Mise Runtime Manager Environment
if [ -d "$HOME/.local/share/mise/shims" ] && [[ ":$PATH:" != *":$HOME/.local/share/mise/shims:"* ]]; then
    export PATH="$HOME/.local/share/mise/shims:$PATH"
fi

if command -v mise &>/dev/null; then
    eval "$(mise activate zsh --shims)"
fi
EOF
    fi

    # 5.4. Autocompletados
    run_as_user "$mise_cmd" completion bash > "$bash_comp_dir/mise" 2>/dev/null || true
    if [ -f "$USER_HOME/.zshrc" ]; then
        run_as_user "$mise_cmd" completion zsh > "$USER_HOME/.local/share/zsh/site-functions/_mise" 2>/dev/null || true
        run_as_user "$mise_cmd" completion zsh > "$USER_HOME/.zfunc/_mise" 2>/dev/null || true
    fi

    # 5.5. Regenerar shims
    run_as_user "$mise_cmd" reshim 2>/dev/null || true

    echo -e "${GREEN}✅ Integración de entorno completada.${NC}"
}

# ------------------------------------------------------------------------------
# 6. ACTUALIZACIÓN RÁPIDA
# ------------------------------------------------------------------------------
update_mise() {
    local mise_cmd
    mise_cmd=$(get_mise_bin)

    if [ -z "$mise_cmd" ]; then
        echo -e "${RED}❌ Error: Mise no está instalado. Ejecuta '$0' primero.${NC}"
        return 1
    fi

    echo -e "${BLUE}🔄 Actualizando binario de Mise y herramientas gestionadas...${NC}"
    run_as_user "$mise_cmd" self-update -y 2>/dev/null || true
    run_as_user "$mise_cmd" upgrade -y 2>/dev/null || true
    run_as_user "$mise_cmd" reshim 2>/dev/null || true
    echo -e "${GREEN}✅ Actualización finalizada.${NC}"
}

# ------------------------------------------------------------------------------
# FLUJO PRINCIPAL
# ------------------------------------------------------------------------------
case "${1:-}" in
    -s|--status|status)
        show_status
        exit 0
        ;;
    -u|--update|update)
        update_mise
        echo ""
        show_status
        exit 0
        ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
    "")
        echo -e "${CYAN}=================================================================${NC}"
        echo -e "${BOLD}⚡ CONFIGURACIÓN DE MISE (RUNTIME MANAGER) - FEDORA WORKSTATION${NC}"
        echo -e "${CYAN}=================================================================${NC}"
        install_mise
        configure_environment
        echo ""
        show_status
        echo -e "${BOLD}=================================================================${NC}"
        echo -e "${GREEN}✅ Mise está listo para su uso en Fedora Workstation y GNOME Shell.${NC}"
        echo -e "💡 Abre una nueva terminal o ejecuta: ${CYAN}source ~/.bashrc${NC}"
        echo -e "${BOLD}=================================================================${NC}"
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida: $1${NC}"
        show_help
        exit 1
        ;;
esac
