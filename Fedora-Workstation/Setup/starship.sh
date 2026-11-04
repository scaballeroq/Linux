#!/usr/bin/env bash
# ==============================================================================
# starship.sh - Instalador y Gestor de Starship Prompt para Fedora 45
# Sistema: Fedora 45 Workstation | Escritorio: GNOME Shell (Wayland)
# ==============================================================================
# Características:
#   - Instalación nativa mediante DNF5 con fallback al instalador oficial de Starship.
#   - Arquitectura modular desacoplada: ~/.bashrc.d/starship.sh y ~/.zshrc.d/starship.zsh.
#   - Despliegue seguro de starship.toml con soporte para Nerd Fonts y contenedores.
#   - Opciones CLI: --status / -s, --enable / -e, --disable / -d, --update / -u, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN ESTÉTICA
# ------------------------------------------------------------------------------
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

# ------------------------------------------------------------------------------
# 2. PRIVILEGIOS Y DETECCIÓN DE USUARIO
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo -e "${RED}❌ Error: 'sudo' no está disponible.${NC}" >&2
        exit 1
    fi
    SUDO="sudo"
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

if command -v dnf5 &>/dev/null; then
    DNF_BIN="dnf5"
else
    DNF_BIN="dnf"
fi

BASHRC="$USER_HOME/.bashrc"
BASHRC_D="$USER_HOME/.bashrc.d"
ZSHRC="$USER_HOME/.zshrc"
ZSHRC_D="$USER_HOME/.zshrc.d"
CONFIG_DIR="$USER_HOME/.config"
STARSHIP_CONFIG="$CONFIG_DIR/starship.toml"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_CONFIG="$SCRIPT_DIR/starship.toml"

# ------------------------------------------------------------------------------
# 3. AYUDA Y DIAGNÓSTICO
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}🚀 Gestor de Starship Prompt - Fedora 45 Workstation (GNOME Shell Wayland)${NC}

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala Starship, despliega la configuración y lo activa en Bash y Zsh.
  --enable, -e        Activa Starship en ~/.bashrc.d/ y ~/.zshrc.d/.
  --disable, -d       Desactiva Starship y restaura el prompt predeterminado.
  --update, -u        Actualiza el binario de Starship mediante DNF5 o instalador oficial.
  --status, -s        Muestra el estado del binario, archivo de configuración y perfiles de shell.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

deploy_config() {
    log_info "Desplegando configuración en $STARSHIP_CONFIG..."
    run_as_user mkdir -p "$CONFIG_DIR"

    if [ -f "$SOURCE_CONFIG" ]; then
        if [ -f "$STARSHIP_CONFIG" ]; then
            if ! cmp -s "$SOURCE_CONFIG" "$STARSHIP_CONFIG"; then
                run_as_user cp "$STARSHIP_CONFIG" "${STARSHIP_CONFIG}.bak"
                log_ok "Copia de seguridad creada en ${STARSHIP_CONFIG}.bak"
                run_as_user cp "$SOURCE_CONFIG" "$STARSHIP_CONFIG"
                log_ok "Configuración actualizada desde Setup/starship.toml"
            else
                log_ok "Configuración ya sincronizada con Setup/starship.toml"
            fi
        else
            run_as_user cp "$SOURCE_CONFIG" "$STARSHIP_CONFIG"
            log_ok "Archivo starship.toml desplegado con éxito"
        fi
    fi
}

enable_starship() {
    log_info "Activando Starship en perfiles de shell..."

    # 1. Integración en Bash (~/.bashrc.d/starship.sh)
    run_as_user mkdir -p "$BASHRC_D"
    cat << 'EOF' | run_as_user tee "$BASHRC_D/starship.sh" > /dev/null
# =============================================================================
# STARSHIP PROMPT (Fedora 45 Workstation)
# =============================================================================
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi
EOF
    log_ok "Starship activado en ~/.bashrc.d/starship.sh"

    run_as_user touch "$BASHRC"
    if ! grep -q "\.bashrc\.d" "$BASHRC" 2>/dev/null; then
        cat << 'EOF' | run_as_user tee -a "$BASHRC" > /dev/null

# Carga modular de configuraciones y aliases (~/.bashrc.d)
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
EOF
        log_ok "Cargador modular asegurado en ~/.bashrc"
    fi

    # Limpiar posibles entradas duplicadas inline en ~/.bashrc
    if grep -q "starship init bash" "$BASHRC" 2>/dev/null; then
        run_as_user sed -i '/starship init bash/d' "$BASHRC" 2>/dev/null || true
    fi

    # 2. Integración en Zsh (~/.zshrc.d/starship.zsh) si existe ~/.zshrc o Zsh instalado
    if [ -f "$ZSHRC" ] || command -v zsh &>/dev/null; then
        run_as_user mkdir -p "$ZSHRC_D"
        cat << 'EOF' | run_as_user tee "$ZSHRC_D/starship.zsh" > /dev/null
# =============================================================================
# STARSHIP PROMPT (Fedora 45 Workstation - Zsh)
# =============================================================================
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi
EOF
        log_ok "Starship activado en ~/.zshrc.d/starship.zsh"

        if [ -f "$ZSHRC" ] && ! grep -q "\.zshrc\.d" "$ZSHRC" 2>/dev/null; then
            cat << 'EOF' | run_as_user tee -a "$ZSHRC" > /dev/null

# Carga modular de configuraciones y aliases (~/.zshrc.d)
if [ -d "$HOME/.zshrc.d" ]; then
    for script in "$HOME/.zshrc.d"/*.{sh,zsh}(N); do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
EOF
            log_ok "Cargador modular asegurado en ~/.zshrc"
        fi

        if [ -f "$ZSHRC" ] && grep -q "starship init zsh" "$ZSHRC" 2>/dev/null; then
            run_as_user sed -i '/starship init zsh/d' "$ZSHRC" 2>/dev/null || true
        fi
    fi
}

disable_starship() {
    echo -e "${BOLD}======================================================================${NC}"
    log_info "Desactivando Starship en perfiles de shell..."
    echo -e "${BOLD}======================================================================${NC}"

    if [ -f "$BASHRC_D/starship.sh" ]; then
        run_as_user rm -f "$BASHRC_D/starship.sh"
        log_ok "Eliminado: ~/.bashrc.d/starship.sh"
    fi

    if [ -f "$BASHRC" ] && grep -q "starship init bash" "$BASHRC" 2>/dev/null; then
        run_as_user sed -i '/starship init bash/d' "$BASHRC" 2>/dev/null || true
        log_ok "Limpiadas referencias inline en ~/.bashrc"
    fi

    if [ -f "$ZSHRC_D/starship.zsh" ]; then
        run_as_user rm -f "$ZSHRC_D/starship.zsh"
        log_ok "Eliminado: ~/.zshrc.d/starship.zsh"
    fi

    if [ -f "$ZSHRC" ] && grep -q "starship init zsh" "$ZSHRC" 2>/dev/null; then
        run_as_user sed -i '/starship init zsh/d' "$ZSHRC" 2>/dev/null || true
        log_ok "Limpiadas referencias inline en ~/.zshrc"
    fi

    log_ok "Starship desactivado. Abre una nueva terminal para volver al prompt nativo."
    echo -e "${BOLD}======================================================================${NC}"
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🚀 ${BOLD}ESTADO DE STARSHIP PROMPT - FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    if command -v starship &>/dev/null; then
        echo -e "  • Binario Starship:   ${GREEN}✅ $(command -v starship) ($(starship --version 2>/dev/null | head -n1))${NC}"
    else
        echo -e "  • Binario Starship:   ${RED}❌ No instalado${NC}"
    fi

    if [ -f "$STARSHIP_CONFIG" ]; then
        local sync_status="${GREEN}✅ Sincronizado${NC}"
        if [ -f "$SOURCE_CONFIG" ] && ! cmp -s "$SOURCE_CONFIG" "$STARSHIP_CONFIG"; then
            sync_status="${YELLOW}⚠️ Modificado localmente (difiere de Setup/starship.toml)${NC}"
        fi
        echo -e "  • Configuración:      ${GREEN}✅ Presente${NC} ($STARSHIP_CONFIG) [$sync_status]"
    else
        echo -e "  • Configuración:      ${RED}❌ Ausente${NC} ($STARSHIP_CONFIG)"
    fi

    local bash_active="${RED}❌ Inactivo${NC}"
    if [ -f "$BASHRC_D/starship.sh" ]; then
        bash_active="${GREEN}✅ Activo (~/.bashrc.d/starship.sh)${NC}"
    elif [ -f "$BASHRC" ] && grep -q "starship init bash" "$BASHRC" 2>/dev/null; then
        bash_active="${GREEN}✅ Activo (inline en ~/.bashrc)${NC}"
    fi
    echo -e "  • Integración Bash:   $bash_active"

    if [ -f "$ZSHRC" ] || command -v zsh &>/dev/null; then
        local zsh_active="${RED}❌ Inactivo${NC}"
        if [ -f "$ZSHRC_D/starship.zsh" ]; then
            zsh_active="${GREEN}✅ Activo (~/.zshrc.d/starship.zsh)${NC}"
        elif [ -f "$ZSHRC" ] && grep -q "starship init zsh" "$ZSHRC" 2>/dev/null; then
            zsh_active="${GREEN}✅ Activo (inline en ~/.zshrc)${NC}"
        fi
        echo -e "  • Integración Zsh:    $zsh_active"
    fi
    echo -e "${BOLD}======================================================================${NC}"
}

install_starship() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🚀 ${BOLD}CONFIGURANDO STARSHIP PROMPT EN FEDORA 45 WORKSTATION${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    # 1. Instalar binario de Starship vía DNF5 o instalador oficial
    if ! command -v starship &> /dev/null; then
        log_info "[1/3] Instalando Starship mediante $DNF_BIN..."
        if ! $SUDO "$DNF_BIN" install -y starship 2>/dev/null; then
            log_warn "$DNF_BIN no encontró el paquete; instalando mediante instalador oficial de Starship..."
            curl -sS https://starship.rs/install.sh | $SUDO sh -s -- -y -b /usr/local/bin
        fi
    else
        log_ok "[1/3] Binario de Starship disponible: $(starship --version 2>/dev/null | head -n1)"
    fi

    # 2. Configurar starship.toml
    log_info "[2/3] Configurando archivo starship.toml..."
    deploy_config

    # 3. Activar en perfiles de shell
    log_info "[3/3] Activando en perfiles de inicio (~/.bashrc.d y ~/.zshrc.d)..."
    enable_starship

    echo -e "${BOLD}======================================================================${NC}"
    log_ok "Starship Prompt instalado y configurado con éxito."
    echo -e "💡 Para ver los cambios en esta sesión ejecuta: ${CYAN}eval \"\$(starship init bash)\"${NC}"
    echo -e "${BOLD}======================================================================${NC}"
}

case "${1:-}" in
    --disable|-d|disable)
        disable_starship
        ;;
    --enable|-e|enable)
        enable_starship
        deploy_config
        log_ok "Starship activado en tus archivos de inicio de shell."
        ;;
    --update|-u|update)
        log_info "Actualizando Starship..."
        if rpm -q starship &>/dev/null; then
            $SUDO "$DNF_BIN" upgrade --refresh -y starship
        else
            curl -sS https://starship.rs/install.sh | $SUDO sh -s -- -y -b /usr/local/bin
        fi
        log_ok "Starship actualizado."
        ;;
    --status|-s|status)
        show_status
        ;;
    --help|-h|help)
        show_help
        ;;
    "")
        install_starship
        ;;
    *)
        log_err "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
