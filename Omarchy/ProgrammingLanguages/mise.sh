#!/usr/bin/env bash
# ==============================================================================
# mise.sh - Instalador, Optimizador y Diagnóstico de Mise (Language Runtime Manager)
# Sistema: Arch Linux | Escritorio: Hyprland (Wayland)
# Hardware: HP ProBook 455 G10 | AMD Ryzen 7 7730U (Zen 3, 8C/16T) | 32 GB RAM
# ==============================================================================
# Características:
# - Despliegue idempotente y rootless en espacio de usuario (~/.local/bin/mise).
# - Optimización multinúcleo para AMD Ryzen 7 7730U (jobs = 16) en ~/.config/mise/config.toml.
# - Despliegue de shims y activación nativa en Bash (~/.bashrc.d) y Zsh (~/.zshrc.d).
# - Integración nativa con la sesión gráfica Wayland de Hyprland (~/.config/environment.d).
# - Generación automática de autocompletados nativos para Bash y Zsh.
# - Diagnóstico integral del gestor, herramientas, shims y 'mise doctor' (--status).
# - Comandos CLI: --status / -s, --update / -u, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y RUTAS
# ------------------------------------------------------------------------------
MISE_INSTALL_URL="https://mise.run"

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

# Detección de hilos CPU (AMD Ryzen 7 7730U -> 16 hilos)
NPROC=$(nproc 2>/dev/null || echo 16)

export PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:/usr/local/bin:/usr/bin:$PATH"

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" \
            PATH="$USER_HOME/.local/bin:$USER_HOME/.local/share/mise/shims:$PATH" "$@"
    else
        env HOME="$USER_HOME" \
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

# ------------------------------------------------------------------------------
# 3. AYUDA Y ESTADO
# ------------------------------------------------------------------------------
show_help() {
    echo -e "${BOLD}⚡ Gestor de Runtimes Mise - Omarchy Workstation${NC}"
    echo -e "Hardware objetivo: AMD Ryzen 7 7730U (${NPROC} hilos) | Hyprland Wayland"
    echo ""
    echo -e "${BOLD}Uso:${NC}"
    echo -e "  $0 [OPCIÓN]"
    echo ""
    echo -e "${BOLD}Opciones:${NC}"
    echo -e "  (sin argumentos)    Instala Mise en espacio de usuario, optimiza hilos (-j$NPROC),"
    echo -e "                      configura shims e integración con Hyprland, Bash y Zsh."
    echo -e "  -s, --status        Muestra diagnóstico detallado del estado de Mise, herramientas,"
    echo -e "                      shims y diagnóstico de integridad ('mise doctor')."
    echo -e "  -u, --update        Actualiza el binario de Mise (self-update) y herramientas gestionadas."
    echo -e "  -h, --help          Muestra este mensaje de ayuda."
}

show_status() {
    local mise_cmd
    mise_cmd=$(get_mise_bin)

    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔍 DIAGNÓSTICO DE MISE (RUNTIME MANAGER) - OMARCHY WORKSTATION${NC}"
    echo -e "   Hardware: AMD Ryzen 7 7730U (${NPROC} hilos) | Hyprland Wayland"
    echo -e "${CYAN}=================================================================${NC}"

    if [ -n "$mise_cmd" ] && [ -x "$mise_cmd" ]; then
        local version_str
        version_str=$(run_as_user "$mise_cmd" --version 2>/dev/null | head -n 1 || echo "Desconocida")
        echo -e "• ${BOLD}Binario Mise:${NC}          ${GREEN}✅ Instalado ($mise_cmd)${NC}"
        echo -e "• ${BOLD}Versión activa:${NC}        ${GREEN}${version_str}${NC}"
    else
        echo -e "• ${BOLD}Binario Mise:${NC}          ${RED}❌ No instalado${NC}"
    fi

    local data_dir="$USER_HOME/.local/share/mise"
    local config_dir="$USER_HOME/.config/mise"
    local shims_dir="$data_dir/shims"

    echo -e "• ${BOLD}Directorio Shims:${NC}      $([ -d "$shims_dir" ] && echo -e "${GREEN}✅ Activo ($shims_dir)${NC}" || echo -e "${YELLOW}ℹ️ No inicializado aún${NC}")"
    echo -e "• ${BOLD}Configuración Global:${NC}  $([ -f "$config_dir/config.toml" ] && echo -e "${GREEN}✅ Configurado ($config_dir/config.toml)${NC}" || echo -e "${YELLOW}ℹ️ Por defecto / Sin config.toml manual${NC}")"

    local env_d_file="$USER_HOME/.config/environment.d/10-mise.conf"
    echo -e "• ${BOLD}Sesión environment.d:${NC}   $([ -f "$env_d_file" ] && echo -e "${GREEN}✅ Activo ($env_d_file)${NC}" || echo -e "${RED}❌ Ausente${NC}")"

    local bashrc_d_file="$USER_HOME/.bashrc.d/mise.sh"
    echo -e "• ${BOLD}Shell Bash (~/.bashrc.d):${NC} $([ -f "$bashrc_d_file" ] && echo -e "${GREEN}✅ Activo ($bashrc_d_file)${NC}" || echo -e "${RED}❌ Ausente${NC}")"

    if [ -f "$USER_HOME/.zshrc" ]; then
        local zshrc_d_file="$USER_HOME/.zshrc.d/mise.zsh"
        echo -e "• ${BOLD}Shell Zsh (~/.zshrc.d):${NC}   $([ -f "$zshrc_d_file" ] && echo -e "${GREEN}✅ Activo ($zshrc_d_file)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    fi

    echo -e "• ${BOLD}Autocompletado Bash:${NC}   $([ -f "$USER_HOME/.local/share/bash-completion/completions/mise" ] && echo -e "${GREEN}✅ Configurado${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    if [ -f "$USER_HOME/.zshrc" ]; then
        echo -e "• ${BOLD}Autocompletado Zsh:${NC}    $([ -f "$USER_HOME/.local/share/zsh/site-functions/_mise" ] || [ -f "$USER_HOME/.zfunc/_mise" ] && echo -e "${GREEN}✅ Configurado${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    fi

    if [ -n "$mise_cmd" ] && [ -x "$mise_cmd" ]; then
        echo -e "${CYAN}-----------------------------------------------------------------${NC}"
        echo -e "• ${BOLD}Herramientas y versiones gestionadas globalmente:${NC}"
        local tool_list
        tool_list=$(run_as_user "$mise_cmd" list 2>/dev/null || true)
        if [ -n "$tool_list" ]; then
            echo "$tool_list" | sed 's/^/  /'
        else
            echo -e "  ${YELLOW}ℹ️ Ninguna herramienta instalada aún.${NC}"
        fi

        echo -e "${CYAN}-----------------------------------------------------------------${NC}"
        echo -e "• ${BOLD}Diagnóstico de Salud (mise doctor):${NC}"
        local doctor_out
        doctor_out=$(run_as_user "$mise_cmd" doctor 2>&1 || true)
        if echo "$doctor_out" | grep -qi "No problems found"; then
            echo -e "  ${GREEN}✅ Estado óptimo: Sin problemas detectados en el entorno Mise.${NC}"
        else
            echo "$doctor_out" | grep -E -i "problem|warning|error" | head -n 5 | sed 's/^/  /' || echo -e "  ${GREEN}✅ Mise operativo.${NC}"
        fi
    fi

    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN ROOTLESS DE MISE
# ------------------------------------------------------------------------------
install_mise() {
    local existing_bin
    existing_bin=$(get_mise_bin)

    if [ -n "$existing_bin" ] && [ -x "$existing_bin" ]; then
        log_ok "Mise ya está instalado en el sistema ($("$existing_bin" --version | head -n 1))."
        return 0
    fi

    log_info "Instalando Mise en espacio de usuario rootless (~/.local/bin/mise)..."
    run_as_user mkdir -p "$USER_HOME/.local/bin"

    # Instalación oficial rootless vía curl hacia ~/.local/bin/mise
    if command -v curl &>/dev/null; then
        MISE_INSTALL_PATH="$USER_HOME/.local/bin/mise" curl -fsSL "$MISE_INSTALL_URL" | run_as_user sh
    else
        log_error "Curl no está instalado en el sistema. Es necesario para descargar Mise."
        exit 1
    fi

    existing_bin=$(get_mise_bin)
    if [ -n "$existing_bin" ] && [ -x "$existing_bin" ]; then
        log_ok "Mise instalado con éxito ($("$existing_bin" --version | head -n 1))."
    else
        log_error "Error al verificar la instalación de Mise en $USER_HOME/.local/bin/mise."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# 5. CONFIGURACIÓN ÓPTIMA Y HARDWARE (~/.config/mise/config.toml)
# ------------------------------------------------------------------------------
configure_mise_hardware() {
    local config_dir="$USER_HOME/.config/mise"
    local config_file="$config_dir/config.toml"

    log_step "Optimizando configuración de Mise para AMD Ryzen 7 7730U (${NPROC} hilos)..."
    run_as_user mkdir -p "$config_dir"

    # Si no existe el config.toml o no tiene bloque settings, creamos/actualizamos
    if [ ! -f "$config_file" ]; then
        cat <<EOF | run_as_user tee "$config_file" > /dev/null
# ==============================================================================
# Mise Configuration - Omarchy Workstation (Hyprland Wayland)
# Hardware: AMD Ryzen 7 7730U (8C/16T) | 32 GB RAM | SSD NVMe Kioxia
# ==============================================================================

[settings]
# Paralelismo adaptado a los ${NPROC} hilos lógicos del procesador
jobs = ${NPROC}
raw = false
idiomatic_version_file = true
legacy_version_file = true
not_found_auto_install = false

[tools]
EOF
        log_ok "Archivo de configuración global creado: $config_file"
    else
        # Asegurar que jobs esté configurado de forma óptima
        if ! grep -q "^jobs =" "$config_file" 2>/dev/null; then
            if grep -q "\[settings\]" "$config_file" 2>/dev/null; then
                sed -i "/\[settings\]/a jobs = ${NPROC}" "$config_file"
            else
                cat <<EOF >> "$config_file"

[settings]
jobs = ${NPROC}
idiomatic_version_file = true
legacy_version_file = true
EOF
            fi
            log_ok "Parámetro 'jobs = ${NPROC}' inyectado en $config_file."
        fi
    fi
}

# ------------------------------------------------------------------------------
# 6. INTEGRACIÓN CON EL ENTORNO (HYPRLAND, BASH, ZSH Y AUTOCOMPLETADOS)
# ------------------------------------------------------------------------------
configure_environment() {
    local mise_cmd
    mise_cmd=$(get_mise_bin)

    if [ -z "$mise_cmd" ]; then
        log_error "Error: Mise no está disponible para configurar el entorno."
        return 1
    fi

    log_step "Configurando integración con Hyprland, Bash y Zsh..."

    local env_dir="$USER_HOME/.config/environment.d"
    local bashrc_d="$USER_HOME/.bashrc.d"
    local bash_comp_dir="$USER_HOME/.local/share/bash-completion/completions"

    run_as_user mkdir -p "$env_dir" "$bashrc_d" "$bash_comp_dir"

    # 6.1. Sesión gráfica Wayland / Hyprland (systemd --user)
    cat << 'EOF' | run_as_user tee "$env_dir/10-mise.conf" > /dev/null
# Mise Runtime Manager Environment (Omarchy Workstation - Hyprland Wayland)
PATH=${HOME}/.local/share/mise/shims:${HOME}/.local/bin:${PATH}
EOF

    # 6.2. Shell Bash (~/.bashrc.d/mise.sh)
    cat << 'EOF' | run_as_user tee "$bashrc_d/mise.sh" > /dev/null
# Mise Runtime Manager Environment (Bash)
if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/.local/share/mise/shims" ] && [[ ":$PATH:" != *":$HOME/.local/share/mise/shims:"* ]]; then
    export PATH="$HOME/.local/share/mise/shims:$PATH"
fi

if command -v mise &>/dev/null; then
    eval "$(mise activate bash --shims)"
elif [ -x "$HOME/.local/bin/mise" ]; then
    eval "$("$HOME/.local/bin/mise" activate bash --shims)"
fi
EOF

    # 6.3. Shell Zsh (~/.zshrc.d/mise.zsh si existe ~/.zshrc)
    if [ -f "$USER_HOME/.zshrc" ]; then
        local zshrc_d="$USER_HOME/.zshrc.d"
        local zsh_comp_dir="$USER_HOME/.local/share/zsh/site-functions"
        local zfunc_dir="$USER_HOME/.zfunc"
        run_as_user mkdir -p "$zshrc_d" "$zsh_comp_dir" "$zfunc_dir"

        cat << 'EOF' | run_as_user tee "$zshrc_d/mise.zsh" > /dev/null
# Mise Runtime Manager Environment (Zsh)
if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

if [ -d "$HOME/.local/share/mise/shims" ] && [[ ":$PATH:" != *":$HOME/.local/share/mise/shims:"* ]]; then
    export PATH="$HOME/.local/share/mise/shims:$PATH"
fi

if command -v mise &>/dev/null; then
    eval "$(mise activate zsh --shims)"
elif [ -x "$HOME/.local/bin/mise" ]; then
    eval "$("$HOME/.local/bin/mise" activate zsh --shims)"
fi
EOF
    fi

    # 6.4. Generación de Autocompletados Nativos
    log_step "Generando autocompletados para Bash y Zsh..."
    run_as_user "$mise_cmd" completion bash > "$bash_comp_dir/mise" 2>/dev/null || true

    if [ -f "$USER_HOME/.zshrc" ]; then
        run_as_user "$mise_cmd" completion zsh > "$USER_HOME/.local/share/zsh/site-functions/_mise" 2>/dev/null || true
        run_as_user "$mise_cmd" completion zsh > "$USER_HOME/.zfunc/_mise" 2>/dev/null || true
    fi

    # 6.5. Refrescar shims
    run_as_user "$mise_cmd" reshim 2>/dev/null || true

    log_ok "Integración del entorno completada con éxito."
}

# ------------------------------------------------------------------------------
# 7. ACTUALIZACIÓN RÁPIDA
# ------------------------------------------------------------------------------
update_mise() {
    local mise_cmd
    mise_cmd=$(get_mise_bin)

    if [ -z "$mise_cmd" ]; then
        log_error "Error: Mise no está instalado. Ejecuta '$0' primero."
        return 1
    fi

    log_info "Actualizando binario de Mise (self-update) y herramientas gestionadas..."
    run_as_user "$mise_cmd" self-update -y 2>/dev/null || true
    run_as_user "$mise_cmd" upgrade -y 2>/dev/null || true
    run_as_user "$mise_cmd" reshim 2>/dev/null || true
    log_ok "Actualización completada."
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
        echo -e "${BOLD}⚡ CONFIGURACIÓN DE MISE (RUNTIME MANAGER) - OMARCHY WORKSTATION${NC}"
        echo -e "   Hardware: AMD Ryzen 7 7730U (${NPROC} hilos) | Hyprland Wayland"
        echo -e "${CYAN}=================================================================${NC}"
        install_mise
        configure_mise_hardware
        configure_environment
        echo ""
        show_status
        echo -e "${BOLD}=================================================================${NC}"
        echo -e "${GREEN}✅ Mise está listo para su uso en Omarchy Workstation y Hyprland.${NC}"
        echo -e "💡 Abre una nueva terminal o ejecuta: ${CYAN}source ~/.bashrc${NC}"
        echo -e "${BOLD}=================================================================${NC}"
        ;;
    *)
        log_error "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
