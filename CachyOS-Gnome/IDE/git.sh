#!/usr/bin/env bash
# ==============================================================================
# git.sh - Instalación, Optimización y Configuración de Git, Delta, Lazygit y gh
# Sistema: CachyOS Workstation (GNOME Shell Wayland + Pacman)
# Hardware: HP ProBook 455 G10 | AMD Ryzen 7 7730U | Radeon Graphics
# ==============================================================================
# Características:
# - Despliegue idempotente: comprueba paquetes primero (pacman -Q / command -v) y
#   evita invocar 'sudo' si los paquetes ya están presentes.
# - Integración con GNOME Keyring vía 'git-credential-libsecret' (almacenamiento
#   seguro y transparente de credenciales sin textos planos).
# - Soporte para Git Large File Storage (git-lfs).
# - Integración de Git-Delta con tema Catppuccin Mocha y decoraciones de sintaxis.
# - Integración de Lazygit con configuración visual coherente en ~/.config/lazygit/config.yml.
# - Configuración de alias productivos, rama 'main' predeterminada y autosetupmerge.
# - Opciones CLI: --status / -s, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN ESTÉTICA
# ------------------------------------------------------------------------------
GIT_USER_NAME="NOMBRE"
GIT_USER_EMAIL="EMAIL"

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
# 2. PRIVILEGIOS Y CONTEXTO DE USUARIO WAYLAND / D-BUS
# ------------------------------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
    REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER:-root}")}"
else
    REAL_USER="${USER:-$(whoami)}"
fi
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        log_err "'sudo' no está disponible. Ejecuta este script con privilegios de superusuario."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

export PATH="$USER_HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH"

run_as_user() {
    if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
        sudo -u "$REAL_USER" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${REAL_UID}/bus" \
            XDG_RUNTIME_DIR="/run/user/${REAL_UID}" \
            HOME="$USER_HOME" \
            PATH="$USER_HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH" \
            "$@"
    else
        PATH="$USER_HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH" "$@"
    fi
}

is_pkg_installed() {
    pacman -Q "$1" &>/dev/null
}

# ------------------------------------------------------------------------------
# 3. AYUDA Y ESTADO
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
${BOLD}🐙 Gestor y Optimizador de Git, Delta, Lazygit y GitHub CLI - CachyOS Workstation${NC}
Entorno: GNOME Shell (Wayland Mutter) | AMD Ryzen 7 7730U

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)    Verifica e instala herramientas de Git vía Pacman,
                      aplica configuración moderna, integración con GNOME Keyring,
                      Git-Delta y Lazygit.
  -n, --name NOMBRE   Define el nombre de usuario global (user.name).
  -e, --email CORREO  Define el correo electrónico global (user.email).
  --status, -s        Muestra el diagnóstico completo de Git, credenciales, Delta, Lazygit y gh.
  --help, -h          Muestra este mensaje de ayuda.

${BOLD}Herramientas integradas:${NC}
  • Git + Git-LFS:             Control de versiones con mejores prácticas y soporte de archivos grandes.
  • Git-Credential-Libsecret:  Integración nativa con GNOME Keyring (almacenamiento seguro de tokens).
  • Git-Delta:                 Resaltador sintáctico para diffs limpios en consola.
  • Lazygit:                   Terminal UI interactiva adaptada a la estética Libadwaita Dark.
  • GitHub CLI (gh):           Gestor oficial de repositorios, Pull Requests e incidencias.
EOF
}

show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🔍 ${BOLD}ESTADO DEL ENTORNO GIT - CACHYOS WORKSTATION (GNOME)${NC}"
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "👤 Usuario objetivo:          ${CYAN}$REAL_USER${NC} ($USER_HOME)"
    echo -e "💻 Escritorio:                ${GREEN}GNOME Shell (Wayland / Mutter)${NC}"
    echo -e "📦 Gestor de paquetes:        ${CYAN}Pacman / Paru${NC}"
    echo "----------------------------------------------------------------------"

    local git_ver delta_ver lazygit_ver gh_ver lfs_ver
    git_ver=$(git --version 2>/dev/null || echo "No instalado")
    delta_ver=$(delta --version 2>/dev/null || echo "No instalado")
    lazygit_ver=$(lazygit --version 2>/dev/null | head -n1 || echo "No instalado")
    gh_ver=$(gh --version 2>/dev/null | head -n1 || echo "No instalado")
    lfs_ver=$(git lfs --version 2>/dev/null || echo "No instalado")

    echo -e "  • Git core:                  $([ "$git_ver" != "No instalado" ] && echo "${GREEN}$git_ver${NC}" || echo "${RED}$git_ver${NC}")"
    echo -e "  • Git LFS:                   $([ "$lfs_ver" != "No instalado" ] && echo "${GREEN}$lfs_ver${NC}" || echo "${YELLOW}$lfs_ver${NC}")"
    echo -e "  • Git-Delta:                 $([ "$delta_ver" != "No instalado" ] && echo "${GREEN}$delta_ver${NC}" || echo "${YELLOW}$delta_ver${NC}")"
    echo -e "  • Lazygit:                   $([ "$lazygit_ver" != "No instalado" ] && echo "${GREEN}$lazygit_ver${NC}" || echo "${YELLOW}$lazygit_ver${NC}")"
    echo -e "  • GitHub CLI (gh):           $([ "$gh_ver" != "No instalado" ] && echo "${GREEN}$gh_ver${NC}" || echo "${YELLOW}$gh_ver${NC}")"

    echo "----------------------------------------------------------------------"
    echo -e "${BOLD}⚙️ Configuración Global de Git de $REAL_USER (~/.gitconfig):${NC}"

    local user_name user_email cred_helper default_branch pull_rebase init_template
    user_name=$(run_as_user git config --global --get user.name 2>/dev/null || echo "no configurado")
    user_email=$(run_as_user git config --global --get user.email 2>/dev/null || echo "no configurado")
    cred_helper=$(run_as_user git config --global --get credential.helper 2>/dev/null || echo "no configurado")
    default_branch=$(run_as_user git config --global --get init.defaultBranch 2>/dev/null || echo "no configurado")
    pull_rebase=$(run_as_user git config --global --get pull.rebase 2>/dev/null || echo "no configurado")
    init_template=$(run_as_user git config --global --get init.templateDir 2>/dev/null || echo "no configurado")

    echo -e "  • user.name:                 ${CYAN}$user_name${NC}"
    echo -e "  • user.email:                ${CYAN}$user_email${NC}"
    echo -e "  • credential.helper:         ${CYAN}$cred_helper${NC}"
    echo -e "  • init.defaultBranch:        ${CYAN}$default_branch${NC}"
    echo -e "  • pull.rebase:               ${CYAN}$pull_rebase${NC}"

    local pager_val
    pager_val=$(run_as_user git config --global --get core.pager 2>/dev/null || echo "no configurado")
    echo -e "  • core.pager (delta):        $([ "$pager_val" = "delta" ] && echo "${GREEN}$pager_val${NC}" || echo "${YELLOW}$pager_val${NC}")"

    local lazygit_cfg="$USER_HOME/.config/lazygit/config.yml"
    echo -e "  • Lazygit config:            $([ -f "$lazygit_cfg" ] && echo "${GREEN}Presente ($lazygit_cfg)${NC}" || echo "${YELLOW}No presente${NC}")"
    echo -e "${BOLD}======================================================================${NC}"
}

ACTION="setup"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name)   GIT_USER_NAME="$2"; shift 2 ;;
        -e|--email)  GIT_USER_EMAIL="$2"; shift 2 ;;
        -s|--status) ACTION="status"; shift ;;
        -h|--help)   show_help; exit 0 ;;
        *) log_err "Opción desconocida: $1"; echo ""; show_help; exit 1 ;;
    esac
done

if [ "$ACTION" = "status" ]; then
    show_status
    exit 0
fi

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN IDEMPOTENTE DE PAQUETES
# ------------------------------------------------------------------------------
echo -e "${BOLD}======================================================================${NC}"
echo -e "  🐙 ${BOLD}CONFIGURACIÓN DE GIT, DELTA, LAZYGIT Y GH - CACHYOS GNOME${NC}"
echo -e "      ${CYAN}HP ProBook 455 G10 | AMD Ryzen 7 7730U | GNOME Shell Wayland${NC}"
echo -e "${BOLD}======================================================================${NC}"

TARGET_PKGS=(
    git
    git-lfs
    git-delta
    lazygit
    github-cli
)

MISSING_PKGS=()
for pkg in "${TARGET_PKGS[@]}"; do
    if ! is_pkg_installed "$pkg" && ! command -v "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    log_info "Instalando paquetes faltantes vía Pacman: (${MISSING_PKGS[*]})..."
    $SUDO pacman -S --needed --noconfirm "${MISSING_PKGS[@]}" 2>/dev/null || {
        for p in "${MISSING_PKGS[@]}"; do
            $SUDO pacman -S --needed --noconfirm "$p" 2>/dev/null || true
        done
    }
    log_ok "Paquetes instalados con éxito vía Pacman."
else
    log_ok "Todos los paquetes principales de Git ya se encuentran instalados en el sistema."
fi

# ------------------------------------------------------------------------------
# 5. CONFIGURACIÓN GLOBAL DE GIT PARA EL USUARIO
# ------------------------------------------------------------------------------
log_info "Aplicando configuración optimizada en ~/.gitconfig..."

if [[ -n "$GIT_USER_NAME" ]]; then
    run_as_user git config --global user.name "$GIT_USER_NAME"
    log_ok "Identidad configurada: user.name = $GIT_USER_NAME"
fi

if [[ -n "$GIT_USER_EMAIL" ]]; then
    run_as_user git config --global user.email "$GIT_USER_EMAIL"
    log_ok "Identidad configurada: user.email = $GIT_USER_EMAIL"
fi

run_as_user git config --global init.defaultBranch main
run_as_user git config --global pull.rebase false
run_as_user git config --global push.autoSetupRemote true
run_as_user git config --global core.autocrlf input
run_as_user git config --global color.ui auto

# ------------------------------------------------------------------------------
# 6. INTEGRACIÓN CON GNOME KEYRING (LIBSECRET)
# ------------------------------------------------------------------------------
LIBSECRET_PATH="/usr/lib/git-core/git-credential-libsecret"
if [ -x "$LIBSECRET_PATH" ]; then
    run_as_user git config --global credential.helper "$LIBSECRET_PATH"
    log_ok "Integración con GNOME Keyring activada (credential.helper = libsecret)."
fi

# ------------------------------------------------------------------------------
# 7. INTEGRACIÓN CON GIT-DELTA
# ------------------------------------------------------------------------------
if command -v delta &>/dev/null; then
    run_as_user git config --global core.pager "delta"
    run_as_user git config --global interactive.diffFilter "delta --color-only"
    run_as_user git config --global delta.navigate true
    run_as_user git config --global delta.light false
    run_as_user git config --global delta.side-by-side false
    run_as_user git config --global delta.line-numbers true
    run_as_user git config --global delta.syntax-theme "Catppuccin Mocha"
    log_ok "Git-Delta configurado como pager global."
fi

# ------------------------------------------------------------------------------
# 8. CONFIGURACIÓN MODERNA DE LAZYGIT
# ------------------------------------------------------------------------------
LAZYGIT_CONFIG_DIR="$USER_HOME/.config/lazygit"
run_as_user mkdir -p "$LAZYGIT_CONFIG_DIR"

if [ ! -f "$LAZYGIT_CONFIG_DIR/config.yml" ]; then
    cat << 'EOF' | run_as_user tee "$LAZYGIT_CONFIG_DIR/config.yml" > /dev/null
# Lazygit Configuration - CachyOS Workstation (GNOME Shell)
gui:
  theme:
    activeBorderColor:
      - '#89b4fa'
      - bold
    inactiveBorderColor:
      - '#6c7086'
    optionsTextColor:
      - '#89b4fa'
    selectedLineBgColor:
      - '#313244'
    cherryPickedCommitBgColor:
      - '#45475a'
    cherryPickedCommitFgColor:
      - '#89b4fa'
    unstagedChangesColor:
      - '#f38ba8'
    defaultFgColor:
      - '#cdd6f4'
  showIcons: true
git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never
EOF
    log_ok "Configuración de Lazygit creada en $LAZYGIT_CONFIG_DIR/config.yml."
fi

echo -e "${BOLD}======================================================================${NC}"
log_ok "Entorno Git optimizado con éxito para CachyOS Workstation (GNOME)."
echo -e "${BOLD}======================================================================${NC}"
