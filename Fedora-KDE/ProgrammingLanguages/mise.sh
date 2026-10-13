#!/usr/bin/env bash
# ==============================================================================
# mise.sh - Instalador, Optimizador y Diagnóstico de Mise (Runtime Manager)
# Sistema: Fedora 44 Workstation | Escritorio: KDE Plasma 6 (Wayland)
# Hardware: HP EliteBook 855 G7 (AMD Ryzen 7 PRO 4750U / 32 GB RAM / Btrfs)
# ==============================================================================
# Características:
# - Despliegue idempotente y soporte rootless en espacio de usuario (~/.local/bin).
# - Soporte tanto para instalación Standalone (recomendada) como paquete RPM oficial vía DNF5.
# - Integración nativa con la sesión gráfica KDE Plasma 6 vía systemd environment.d.
# - Propagación en caliente de variables PATH a la sesión activa (systemctl / dbus).
# - Activación modular para terminales Bash (~/.bashrc.d) y Zsh (~/.zshrc.d).
# - Generación automática de autocompletados nativos para Bash y Zsh.
# - Diagnóstico integral del estado de Mise y runtimes globales (--status).
# - Actualización centralizada del gestor y sus runtimes (--update).
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN
# ------------------------------------------------------------------------------
REPO_ALIAS="mise"
REPO_NAME="Mise CLI"
REPO_URL="https://mise.jdx.dev/rpm"
GPG_KEY_URL="https://mise.jdx.dev/gpg-key.pub"
REPO_FILE="/etc/yum.repos.d/mise.repo"
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
    elif [ "$bin" = "/usr/bin/mise" ] || rpm -q mise &>/dev/null; then
        echo "Paquete RPM oficial de Fedora (/usr/bin/mise)"
    elif [ -n "$bin" ]; then
        echo "Personalizada ($bin)"
    else
        echo "Ninguna"
    fi
}

is_repo_configured() {
    [ -f "$REPO_FILE" ] && grep -qE "mise\.jdx\.dev" "$REPO_FILE" 2>/dev/null
}

is_repo_enabled() {
    is_repo_configured && grep -qE "^enabled=1" "$REPO_FILE" 2>/dev/null
}

# ------------------------------------------------------------------------------
# 4. DIAGNÓSTICO Y AYUDA
# ------------------------------------------------------------------------------
show_help() {
    echo -e "${BOLD}⚡ Gestor de Runtimes Mise - Fedora 44 (KDE Plasma 6)${NC}

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)    Instala y configura Mise de forma idempotente con integración KDE y Shells.
  -i, --install       Fuerza la comprobación e instalación de Mise.
  -s, --status        Muestra diagnóstico completo del entorno de Mise, shims y runtimes activos.
  -u, --update        Actualiza el binario de Mise y todos los runtimes gestionados.
      --standalone    Instala Mise en espacio de usuario (~/.local/bin/mise) sin requerir root.
      --rpm           Instala Mise mediante repositorio oficial RPM vía DNF5 (requiere root).
  -r, --uninstall     Desinstala Mise, shims y configuraciones de shell del sistema.
  -h, --help          Muestra este mensaje de ayuda.

${BOLD}Ejemplos:${NC}
  $0                 # Configuración estándar idempotente
  $0 --status        # Diagnóstico y estado de herramientas
  $0 --update        # Actualiza Mise y los SDKs instalados"
}

show_status() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔍 DIAGNÓSTICO DE MISE (RUNTIME MANAGER) - FEDORA 44 (KDE PLASMA 6)${NC}"
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

    # 2. Repositorio DNF5 / RPM (si aplica)
    if is_repo_configured; then
        if is_repo_enabled; then
            echo -e "• ${BOLD}Repositorio DNF5:${NC}      ${GREEN}✅ Activo${NC} ($REPO_FILE)"
        else
            echo -e "• ${BOLD}Repositorio DNF5:${NC}      ${YELLOW}⚠️ Deshabilitado${NC} ($REPO_FILE)"
        fi
    else
        echo -e "• ${BOLD}Repositorio DNF5:${NC}      ${CYAN}ℹ️ No registrado (Modo Standalone preferente)${NC}"
    fi

    # 3. Integración con KDE Plasma 6 (systemd environment.d)
    if [ -f "$ENV_CONF_FILE" ]; then
        echo -e "• ${BOLD}Sesión Gráfica KDE:${NC}    ${GREEN}✅ Configurada${NC} ($ENV_CONF_FILE)"
    else
        echo -e "• ${BOLD}Sesión Gráfica KDE:${NC}    ${YELLOW}⚠️ No configurada en environment.d${NC}"
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

install_rpm() {
    require_root
    echo -e "${BLUE}📦 Configurando repositorio oficial RPM de Mise para Fedora / DNF5...${NC}"

    # Importar clave GPG oficial
    if ! rpm -q gpg-pubkey --qf '%{SUMMARY}\n' 2>/dev/null | grep -qi "mise"; then
        echo -e "${BLUE}🔑 Importando clave GPG de Mise...${NC}"
        $SUDO rpm --import "$GPG_KEY_URL" 2>/dev/null || true
    fi

    # Configurar archivo de repositorio RPM para DNF5
    cat << 'EOF' | $SUDO tee "$REPO_FILE" > /dev/null
[mise]
name=Mise CLI
baseurl=https://mise.jdx.dev/rpm
enabled=1
gpgcheck=1
gpgkey=https://mise.jdx.dev/gpg-key.pub
EOF
    echo -e "${GREEN}✔${NC} Repositorio registrado en $REPO_FILE."

    echo -e "${BLUE}⬇️ Instalando paquete de Mise vía DNF5...${NC}"
    $SUDO dnf5 install -y mise
    echo -e "${GREEN}✔${NC} Paquete Mise instalado exitosamente."
}

# ------------------------------------------------------------------------------
# 6. CONFIGURACIÓN DEL ENTORNO Y SHELLS
# ------------------------------------------------------------------------------
configure_environment() {
    echo -e "${BLUE}⚙️ Configurando variables de entorno para la sesión gráfica de KDE Plasma...${NC}"
    run_as_user mkdir -p "$ENV_CONF_DIR"

    cat << 'EOF' | run_as_user tee "$ENV_CONF_FILE" > /dev/null
# Integración de Mise con la sesión gráfica / Wayland (KDE Plasma 6)
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

    # 1. Bash (predeterminado en Fedora)
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

    # 2. Zsh (condicional si existe)
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

    # 3. Configuración global Mise settings (~/.config/mise/config.toml)
    run_as_user mkdir -p "$USER_HOME/.config/mise"
    if [ ! -f "$USER_HOME/.config/mise/config.toml" ]; then
        cat << 'EOF' | run_as_user tee "$USER_HOME/.config/mise/config.toml" > /dev/null
[settings]
legacy_version_file = true
not_found_auto_install = true
experimental = true
EOF
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
    echo -e "${BOLD}⚡ CONFIGURACIÓN DE MISE (RUNTIME MANAGER) - FEDORA 44${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    # Añadir rutas temporales para la ejecución de este script
    export PATH="$USER_BIN:$MISE_SHIMS_DIR:/usr/bin:$PATH"

    if is_mise_installed && [ "$force" != "true" ]; then
        echo -e "${GREEN}✔${NC} Mise ya está instalado ($(get_mise_version)) - $(get_install_type)."
        echo -e "   Para actualizar Mise y sus runtimes, ejecuta: ${BOLD}$0 --update${NC} (o 'just mise -u')"
    else
        # Si el usuario ejecuta sin sudo o prefiere espacio de usuario: standalone
        if [ "$EUID" -ne 0 ] && [ -z "${SUDO_USER:-}" ]; then
            install_standalone
        else
            # Intentar RPM si se ejecuta con sudo, o recurrir a standalone
            install_rpm || {
                echo -e "${YELLOW}⚠️ Fallo en instalación RPM. Recurriendo a instalación standalone...${NC}"
                install_standalone
            }
        fi
    fi

    # Asegurar que el PATH del script reconozca el nuevo binario
    export PATH="$USER_BIN:$MISE_SHIMS_DIR:/usr/bin:$PATH"

    configure_environment
    configure_shells
    configure_completions

    show_final_summary
}

update_mise() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔄 ACTUALIZACIÓN DE MISE Y RUNTIMES${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    local bin
    bin=$(get_mise_bin)

    if [ -z "$bin" ] || [ ! -x "$bin" ]; then
        echo -e "${YELLOW}⚠️ Mise no está instalado. Instalándolo primero...${NC}"
        install_mise "false"
        return 0
    fi

    # 1. Actualizar el binario de Mise
    echo -e "${BLUE}⬇️ Comprobando actualizaciones del ejecutable de Mise...${NC}"
    if [ "$bin" = "$USER_BIN_MISE" ]; then
        run_as_user "$bin" self-update || true
    elif rpm -q mise &>/dev/null; then
        require_root
        $SUDO dnf5 upgrade --refresh -y mise || true
    else
        run_as_user "$bin" self-update 2>/dev/null || true
    fi

    # 2. Actualizar los runtimes instalados globalmente
    echo -e "${BLUE}📦 Actualizando runtimes gestionados por Mise (mise upgrade)...${NC}"
    run_as_user "$bin" upgrade || true

    # 3. Regenerar shims y autocompletados
    run_as_user "$bin" reshim 2>/dev/null || true
    configure_completions

    echo -e "${GREEN}✅ Mise y runtimes actualizados con éxito.${NC}"
    echo -e "   Versión actual: $(get_mise_version)"
}

uninstall_mise() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🗑️ DESINSTALACIÓN DE MISE${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    # 1. Eliminar binario standalone
    if [ -f "$USER_BIN_MISE" ]; then
        echo -e "${BLUE}🗑️ Eliminando binario standalone ($USER_BIN_MISE)...${NC}"
        rm -f "$USER_BIN_MISE"
    fi

    # 2. Eliminar paquete RPM si existe
    if rpm -q mise &>/dev/null; then
        require_root
        echo -e "${BLUE}📦 Eliminando paquete mise vía DNF5...${NC}"
        $SUDO dnf5 remove -y mise
    fi

    # 3. Eliminar configuraciones de entorno y shells
    rm -f "$ENV_CONF_FILE" 2>/dev/null || true
    rm -f "$USER_HOME/.bashrc.d/mise.sh" 2>/dev/null || true
    rm -f "$USER_HOME/.zshrc.d/mise.zsh" 2>/dev/null || true
    rm -f "$USER_HOME/.local/share/bash-completion/completions/mise" 2>/dev/null || true
    rm -f "$USER_HOME/.local/share/zsh/site-functions/_mise" 2>/dev/null || true

    echo -e "${GREEN}✅ Mise y sus integraciones han sido desinstalados.${NC}"
    echo -e "   (Nota: Si deseas eliminar los SDKs descargados en caché, borra: $MISE_DATA_DIR)"
}

show_final_summary() {
    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${GREEN}✅ Mise configurado correctamente para Fedora 44 y KDE Plasma 6:${NC}"
    echo -e "   - Binario:   $(get_mise_bin)"
    echo -e "   - Versión:   $(get_mise_version)"
    echo -e "   - Entorno:   $ENV_CONF_FILE"
    echo -e "   - Terminal:  Bash (~/.bashrc.d/mise.sh)$([ -f "$USER_HOME/.zshrc" ] && echo " & Zsh (~/.zshrc.d/mise.zsh)")"
    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 8. PARSER DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
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
        update_mise
        exit 0
        ;;
    --standalone)
        install_standalone
        configure_environment
        configure_shells
        configure_completions
        show_final_summary
        exit 0
        ;;
    --rpm)
        install_rpm
        configure_environment
        configure_shells
        configure_completions
        show_final_summary
        exit 0
        ;;
    --install|-i|install)
        install_mise "true"
        exit 0
        ;;
    --uninstall|-r|remove|uninstall)
        uninstall_mise
        exit 0
        ;;
    "")
        install_mise "false"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Opción desconocida:${NC} ${1}"
        echo "Ejecuta '$0 --help' para ver las opciones disponibles."
        exit 1
        ;;
esac
