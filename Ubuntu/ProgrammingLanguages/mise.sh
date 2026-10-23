#!/usr/bin/env bash
# ==============================================================================
# mise.sh - Instalador, Optimizador y Diagnóstico de Mise (Runtime Manager)
# Sistema: Ubuntu Linux Workstation | Escritorio: GNOME Shell 51 (Wayland)
# ==============================================================================
# Características:
# - Despliegue idempotente y soporte rootless en espacio de usuario (~/.local/bin).
# - Soporte tanto para instalación Standalone (recomendada) como paquete DEB oficial.
# - Integración nativa con la sesión gráfica GNOME Shell vía systemd environment.d.
# - Propagación en caliente de variables PATH a la sesión activa (systemctl / dbus).
# - Activación modular para terminales Bash (~/.bashrc.d) y Zsh (~/.zshrc.d).
# - Generación automática de autocompletados nativos.
# - Diagnóstico integral del estado de Mise y runtimes globales (--status).
# - Actualización centralizada del gestor y sus runtimes (--update).
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN
# ------------------------------------------------------------------------------
REPO_KEY_URL="https://mise.jdx.dev/gpg-key.pub"
KEYRING_PATH="/etc/apt/keyrings/mise-archive-keyring.gpg"
SOURCES_PATH="/etc/apt/sources.list.d/mise.list"
STANDALONE_INSTALL_URL="https://mise.run"

# Colores ANSI para terminal
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
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

USER_BIN="$USER_HOME/.local/bin"
USER_BIN_MISE="$USER_BIN/mise"
MISE_DATA_DIR="$USER_HOME/.local/share/mise"
MISE_SHIMS_DIR="$MISE_DATA_DIR/shims"
ENV_CONF_DIR="$USER_HOME/.config/environment.d"
ENV_CONF_FILE="$ENV_CONF_DIR/10-mise.conf"

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

require_root() {
    if [ "$EUID" -ne 0 ]; then
        if ! command -v sudo &>/dev/null; then
            echo -e "${RED}❌ Error:${NC} Esta operación requiere privilegios de administrador ('sudo')." >&2
            exit 1
        fi
    fi
}

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" USER="$REAL_USER" "$@"
    else
        "$@"
    fi
}

# ------------------------------------------------------------------------------
# 3. FUNCIONES DE DETECCIÓN Y UTILIDAD
# ------------------------------------------------------------------------------
get_mise_bin() {
    if [ -x "$USER_BIN_MISE" ]; then
        echo "$USER_BIN_MISE"
    elif command -v mise &>/dev/null; then
        command -v mise
    elif [ -x "/usr/bin/mise" ]; then
        echo "/usr/bin/mise"
    else
        echo ""
    fi
}

is_mise_installed() {
    local bin
    bin=$(get_mise_bin)
    [ -n "$bin" ] && [ -x "$bin" ]
}

get_mise_version() {
    local bin
    bin=$(get_mise_bin)
    if [ -n "$bin" ] && [ -x "$bin" ]; then
        run_as_user "$bin" --version 2>/dev/null || echo "Desconocida"
    else
        echo "No instalado"
    fi
}

get_install_type() {
    local bin
    bin=$(get_mise_bin)
    if [ "$bin" = "$USER_BIN_MISE" ]; then
        echo "Standalone de usuario ($USER_BIN_MISE)"
    elif [ "$bin" = "/usr/bin/mise" ] || dpkg -s mise &>/dev/null; then
        echo "Paquete DEB de sistema (/usr/bin/mise)"
    elif [ -n "$bin" ]; then
        echo "Personalizada ($bin)"
    else
        echo "Ninguna"
    fi
}

is_repo_configured() {
    [ -f "$SOURCES_PATH" ] && grep -q "mise.jdx.dev" "$SOURCES_PATH" 2>/dev/null
}

# ------------------------------------------------------------------------------
# 4. DIAGNÓSTICO Y AYUDA
# ------------------------------------------------------------------------------
show_help() {
    echo -e "${BOLD}⚡ Gestor de Runtimes Mise - Ubuntu Workstation${NC}

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)    Instala y configura Mise de forma idempotente con integración GNOME y Shells.
  -i, --install       Fuerza la comprobación e instalación de Mise.
  -s, --status        Muestra diagnóstico completo del entorno de Mise, shims y runtimes activos.
  -u, --update        Actualiza el binario de Mise y todos los runtimes gestionados.
      --standalone    Instala Mise en espacio de usuario (~/.local/bin/mise) sin requerir root.
      --deb           Instala Mise mediante repositorio oficial DEB y APT (requiere root).
  -r, --uninstall     Desinstala Mise, shims y configuraciones de shell del sistema.
  -h, --help          Muestra este mensaje de ayuda.

${BOLD}Ejemplos:${NC}
  $0                 # Configuración estándar idempotente
  $0 --status        # Diagnóstico y estado de herramientas
  $0 --update        # Actualiza Mise y los SDKs instalados"
}

show_status() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔍 DIAGNÓSTICO DE MISE (RUNTIME MANAGER) - UBUNTU WORKSTATION${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    local bin
    bin=$(get_mise_bin)

    # 1. Estado del binario
    if [ -n "$bin" ] && [ -x "$bin" ]; then
        echo -e "• ${BOLD}Estado de Mise:${NC}        ${GREEN}✅ Instalado y disponible${NC}"
        echo -e "  - Binario:             $bin"
        echo -e "  - Versión:             $(get_mise_version)"
        echo -e "  - Tipo de instalación: $(get_install_type)"
    else
        echo -e "• ${BOLD}Estado de Mise:${NC}        ${RED}❌ No instalado en el sistema${NC}"
    fi

    # 2. Repositorio APT
    if is_repo_configured; then
        echo -e "• ${BOLD}Repositorio APT:${NC}       ${GREEN}✅ Configurado${NC} ($SOURCES_PATH)"
    else
        echo -e "• ${BOLD}Repositorio APT:${NC}       ${CYAN}ℹ️ No registrado (Modo Standalone preferente)${NC}"
    fi

    # 3. Integración con GNOME Shell (systemd environment.d)
    if [ -f "$ENV_CONF_FILE" ]; then
        echo -e "• ${BOLD}Sesión GNOME / GUI:${NC}   ${GREEN}✅ Configurada${NC} ($ENV_CONF_FILE)"
    else
        echo -e "• ${BOLD}Sesión GNOME / GUI:${NC}   ${YELLOW}⚠️ No configurada en environment.d${NC}"
    fi

    # 4. Integración en Shells
    local bash_ok=false
    local zsh_ok=false

    if [ -f "$USER_HOME/.bashrc.d/mise.sh" ] || grep -q "mise activate" "$USER_HOME/.bashrc" 2>/dev/null; then
        bash_ok=true
    fi
    if [ -f "$USER_HOME/.zshrc" ]; then
        if [ -f "$USER_HOME/.zshrc.d/mise.zsh" ] || grep -q "mise activate" "$USER_HOME/.zshrc" 2>/dev/null; then
            zsh_ok=true
        fi
    fi

    echo -e "• ${BOLD}Integración en Bash:${NC}   $([ "$bash_ok" = true ] && echo -e "${GREEN}✅ Activa (~/.bashrc.d/mise.sh)${NC}" || echo -e "${YELLOW}❌ Inactiva${NC}")"
    if [ -f "$USER_HOME/.zshrc" ]; then
        echo -e "• ${BOLD}Integración en Zsh:${NC}    $([ "$zsh_ok" = true ] && echo -e "${GREEN}✅ Activa (~/.zshrc.d/mise.zsh)${NC}" || echo -e "${YELLOW}❌ Inactiva${NC}")"
    fi

    # 5. Shims y PATH actual
    if [ -d "$MISE_SHIMS_DIR" ]; then
        local num_shims
        num_shims=$(find "$MISE_SHIMS_DIR" -maxdepth 1 -type f -o -type l 2>/dev/null | wc -l)
        echo -e "• ${BOLD}Shims de Runtimes:${NC}     ${GREEN}✅ Presentes${NC} ($MISE_SHIMS_DIR, $num_shims shims registrados)"
    else
        echo -e "• ${BOLD}Shims de Runtimes:${NC}     ${CYAN}ℹ️ Directorio de shims vacío o pendiente${NC}"
    fi

    # 6. Runtimes globales gestionados actualmente
    if [ -n "$bin" ] && [ -x "$bin" ]; then
        echo -e "-----------------------------------------------------------------"
        echo -e "📦 ${BOLD}Herramientas y Runtimes Globales (mise ls):${NC}"
        local runtimes
        runtimes=$(run_as_user "$bin" ls 2>/dev/null || echo "")
        if [ -n "$runtimes" ]; then
            echo "$runtimes" | sed 's/^/   /'
        else
            echo "   (Ningún runtime instalado todavía. Ejemplos: 'just node', 'just python')"
        fi
    fi

    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 5. MÉTODOS DE INSTALACIÓN
# ------------------------------------------------------------------------------
install_standalone() {
    echo -e "${BLUE}⬇️ Instalando Mise en espacio de usuario (~/.local/bin/mise)...${NC}"
    run_as_user mkdir -p "$USER_BIN"

    local temp_script
    temp_script=$(mktemp /tmp/mise-install-XXXXXX.sh)

    if curl -fsSL "$STANDALONE_INSTALL_URL" -o "$temp_script"; then
        run_as_user sh "$temp_script"
        rm -f "$temp_script"
        echo -e "${GREEN}✔${NC} Binario standalone de Mise instalado exitosamente en $USER_BIN_MISE."
    else
        rm -f "$temp_script"
        echo -e "${RED}❌ Error:${NC} No se pudo descargar el instalador standalone de Mise."
        exit 1
    fi
}

install_deb() {
    require_root
    echo -e "${BLUE}📦 Configurando repositorio oficial DEB de Mise para Ubuntu...${NC}"

    $SUDO apt-get update -qq
    $SUDO apt-get install -y curl gpg

    $SUDO mkdir -p -m 755 /etc/apt/keyrings
    if [ ! -f "$KEYRING_PATH" ]; then
        curl -fsSL "$REPO_KEY_URL" | $SUDO gpg --dearmor -o "$KEYRING_PATH"
        echo -e "${GREEN}✔${NC} Clave GPG de Mise importada."
    fi

    local arch
    arch=$(dpkg --print-architecture)
    echo "deb [signed-by=$KEYRING_PATH arch=$arch] https://mise.jdx.dev/deb stable main" | $SUDO tee "$SOURCES_PATH" > /dev/null

    $SUDO apt-get update -qq
    $SUDO apt-get install -y mise
    echo -e "${GREEN}✔${NC} Paquete DEB de Mise instalado exitosamente."
}

# ------------------------------------------------------------------------------
# 6. CONFIGURACIÓN DEL ENTORNO Y SHELLS
# ------------------------------------------------------------------------------
configure_environment() {
    echo -e "${BLUE}⚙️ Configurando variables de entorno para la sesión gráfica de GNOME...${NC}"
    run_as_user mkdir -p "$ENV_CONF_DIR"

    cat << 'EOF' | run_as_user tee "$ENV_CONF_FILE" > /dev/null
# Integración de Mise con la sesión gráfica / Wayland (GNOME Shell)
PATH=${HOME}/.local/share/mise/shims:${HOME}/.local/bin:${PATH}
MISE_SHELL=bash
COREPACK_ENABLE_DOWNLOAD_PROMPT=0
EOF

    # Propagar variables en caliente a la sesión activa de systemd y DBus
    if command -v systemctl &>/dev/null; then
        run_as_user systemctl --user import-environment PATH 2>/dev/null || true
    fi
    if command -v dbus-update-activation-environment &>/dev/null; then
        run_as_user dbus-update-activation-environment --systemd PATH 2>/dev/null || true
    fi

    echo -e "${GREEN}✔${NC} Archivo de sesión configurado: $ENV_CONF_FILE"
}

configure_shells() {
    echo -e "${BLUE}⚙️ Configurando integración en terminales (Bash y Zsh)...${NC}"

    # 1. Bash
    local bashrc_d="$USER_HOME/.bashrc.d"
    run_as_user mkdir -p "$bashrc_d"

    cat << 'EOF' | run_as_user tee "$bashrc_d/mise.sh" > /dev/null
# =============================================================================
# MISE VERSION MANAGER (Bash Shell Activation)
# =============================================================================
if [ -x "$HOME/.local/bin/mise" ] || command -v mise &>/dev/null; then
    eval "$(mise activate bash)"
fi
EOF

    # Respaldo en .bashrc si .bashrc.d no se lee
    local bashrc="$USER_HOME/.bashrc"
    if [ -f "$bashrc" ] && ! grep -q "mise activate" "$bashrc" 2>/dev/null; then
        if ! grep -q "\.bashrc\.d" "$bashrc" 2>/dev/null; then
            echo -e '\n# Mise (Language Version Manager)\nif command -v mise &>/dev/null || [ -x "$HOME/.local/bin/mise" ]; then eval "$(mise activate bash)"; fi' | run_as_user tee -a "$bashrc" > /dev/null
        fi
    fi

    # 2. Zsh (condicional)
    if [ -f "$USER_HOME/.zshrc" ]; then
        local zshrc_d="$USER_HOME/.zshrc.d"
        run_as_user mkdir -p "$zshrc_d"

        cat << 'EOF' | run_as_user tee "$zshrc_d/mise.zsh" > /dev/null
# =============================================================================
# MISE VERSION MANAGER (Zsh Shell Activation)
# =============================================================================
if [ -x "$HOME/.local/bin/mise" ] || command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi
EOF

        if ! grep -q "mise activate" "$USER_HOME/.zshrc" 2>/dev/null; then
            if ! grep -q "\.zshrc\.d" "$USER_HOME/.zshrc" 2>/dev/null; then
                echo -e '\n# Mise (Language Version Manager)\nif command -v mise &>/dev/null || [ -x "$HOME/.local/bin/mise" ]; then eval "$(mise activate zsh)"; fi' | run_as_user tee -a "$USER_HOME/.zshrc" > /dev/null
            fi
        fi
    fi

    echo -e "${GREEN}✔${NC} Integración en shells configurada con éxito."
}

configure_completions() {
    local bin
    bin=$(get_mise_bin)
    if [ -z "$bin" ] || [ ! -x "$bin" ]; then
        return 0
    fi

    echo -e "${BLUE}⚙️ Generando autocompletado nativo para Bash y Zsh...${NC}"

    local bash_comp_dir="$USER_HOME/.local/share/bash-completion/completions"
    run_as_user mkdir -p "$bash_comp_dir"
    run_as_user "$bin" completion bash > "$bash_comp_dir/mise" 2>/dev/null || true

    if [ -f "$USER_HOME/.zshrc" ]; then
        local zsh_comp_dir="$USER_HOME/.local/share/zsh/site-functions"
        run_as_user mkdir -p "$zsh_comp_dir"
        run_as_user "$bin" completion zsh > "$zsh_comp_dir/_mise" 2>/dev/null || true
    fi

    echo -e "${GREEN}✔${NC} Autocompletados actualizados."
}

# ------------------------------------------------------------------------------
# 7. INSTALACIÓN PRINCIPAL Y ACTUALIZACIONES
# ------------------------------------------------------------------------------
install_mise() {
    local force="${1:-false}"

    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}⚡ CONFIGURACIÓN DE MISE (RUNTIME MANAGER) - UBUNTU${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    export PATH="$USER_BIN:$MISE_SHIMS_DIR:/usr/bin:$PATH"

    if is_mise_installed && [ "$force" != "true" ]; then
        echo -e "${GREEN}✔${NC} Mise ya está instalado ($(get_mise_version)) - $(get_install_type)."
        echo -e "   Para actualizar Mise y sus runtimes, ejecuta: ${BOLD}$0 --update${NC} (o 'just mise -u')"
    else
        if [ "$EUID" -ne 0 ] && [ -z "${SUDO_USER:-}" ]; then
            install_standalone
        else
            install_deb
        fi
    fi

    configure_environment
    configure_shells
    configure_completions

    local final_bin
    final_bin=$(get_mise_bin)
    if [ -n "$final_bin" ]; then
        run_as_user "$final_bin" reshim 2>/dev/null || true
    fi

    echo -e "\n${GREEN}✅ Mise se ha configurado exitosamente.${NC}"
    show_status
}

update_mise() {
    echo -e "${BLUE}🔄 Actualizando Mise y runtimes instalados...${NC}"
    local bin
    bin=$(get_mise_bin)

    if [ -z "$bin" ] || [ ! -x "$bin" ]; then
        echo -e "${RED}❌ Error:${NC} Mise no está instalado. Ejecuta $0 para instalarlo."
        exit 1
    fi

    if [ "$bin" = "$USER_BIN_MISE" ]; then
        echo -e "• Actualizando binario standalone..."
        run_as_user "$bin" self-update --yes 2>/dev/null || run_as_user "$bin" self-update || true
    elif dpkg -s mise &>/dev/null; then
        echo -e "• Actualizando paquete DEB..."
        $SUDO apt-get update -qq
        $SUDO apt-get install --only-upgrade -y mise || true
    fi

    echo -e "• Actualizando plugins y runtimes de Mise..."
    run_as_user "$bin" plugins update || true
    run_as_user "$bin" upgrade || true
    run_as_user "$bin" reshim || true

    configure_completions

    echo -e "${GREEN}✔${NC} Actualización completada."
    show_status
}

# ------------------------------------------------------------------------------
# 8. PROCESAR ARGUMENTOS CLI
# ------------------------------------------------------------------------------
case "${1:-}" in
    -h|--help|help)
        show_help
        exit 0
        ;;
    -s|--status|status)
        show_status
        exit 0
        ;;
    -u|--update|update)
        update_mise
        exit 0
        ;;
    -i|--install|install)
        install_mise true
        exit 0
        ;;
    --standalone)
        install_standalone
        configure_environment
        configure_shells
        configure_completions
        show_status
        exit 0
        ;;
    --deb)
        install_deb
        configure_environment
        configure_shells
        configure_completions
        show_status
        exit 0
        ;;
    "")
        install_mise false
        ;;
    *)
        echo -e "${RED}❌ Opción desconocida: $1${NC}"
        show_help
        exit 1
        ;;
esac
