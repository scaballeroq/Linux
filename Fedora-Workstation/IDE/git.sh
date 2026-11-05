#!/usr/bin/env bash
# ==============================================================================
# git.sh - Instalación, Optimización y Configuración de Git, Delta, Lazygit y gh
# Sistema: Fedora 45 Workstation (GNOME Shell 51 Wayland + DNF5)
# Hardware: HP ProBook 455 G10 | AMD Ryzen 7 7730U | Radeon Graphics
# ==============================================================================
# Características:
# - Despliegue idempotente: comprueba paquetes primero (rpm -q / command -v) y
#   evita invocar 'sudo' o DNF5 si los paquetes ya están presentes.
# - Integración con GNOME Keyring vía 'git-credential-libsecret' (almacenamiento
#   seguro y transparente de credenciales sin textos planos).
# - Soporte para Git Large File Storage (git-lfs).
# - Configuración global recomendada: pull rebase, autoStash, autoSetupRemote,
#   zdiff3, rerere y ordenación cronológica de ramas y etiquetas.
# - Integración de Git-Delta con resaltado de sintaxis adaptado al tema de GNOME.
# - Integración de Lazygit con delta pager y tema GNOME Libadwaita Dark.
# - Detección inteligente del editor preferido (gnome-text-editor, nvim, micro, etc.).
# - Preservación de la identidad Git existente (~/.gitconfig).
# - Comandos CLI: --status / -s, --help / -h.
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
# 2. DETECCIÓN DE USUARIO Y PRIVILEGIOS
# ------------------------------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
    REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER:-root}")}"
else
    REAL_USER="${USER:-$(whoami)}"
fi
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
REAL_UID=$(id -u "$REAL_USER")

if [[ $EUID -ne 0 ]]; then
    if ! command -v sudo &>/dev/null; then
        log_err "Error: 'sudo' no está disponible. Ejecuta este script con permisos suficientes."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

export PATH="$USER_HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH"

if command -v dnf5 &>/dev/null; then
    DNF_BIN="dnf5"
else
    DNF_BIN="dnf"
fi

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
    rpm -q "$1" &>/dev/null
}

# ------------------------------------------------------------------------------
# 3. AYUDA Y ESTADO
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
${BOLD}🐙 Gestor y Optimizador de Git, Delta, Lazygit y GitHub CLI - Fedora 45 Workstation${NC}
Entorno: GNOME Shell 51 (Wayland Mutter) | AMD Ryzen 7 7730U

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)    Verifica e instala herramientas de Git vía $DNF_BIN,
                      aplica configuración moderna, integración con GNOME Keyring,
                      Git-Delta y Lazygit.
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
    echo -e "🔍 ${BOLD}ESTADO DEL ENTORNO GIT - FEDORA 45 WORKSTATION (GNOME 51)${NC}"
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "👤 Usuario objetivo:          ${CYAN}$REAL_USER${NC} ($USER_HOME)"
    echo -e "💻 Escritorio:                ${GREEN}GNOME Shell 51 (Wayland / Mutter 51)${NC}"
    echo -e "📦 Gestor de paquetes:        ${CYAN}$DNF_BIN${NC}"
    echo "----------------------------------------------------------------------"

    local git_ver delta_ver lazygit_ver gh_ver lfs_ver
    local user_name user_email default_branch core_editor core_pager cred_helper gh_auth

    git_ver=$(git --version 2>/dev/null || echo "No instalado")
    delta_ver=$(command -v delta &>/dev/null && delta --version 2>/dev/null || echo "No instalado")
    lazygit_ver=$(command -v lazygit &>/dev/null && lazygit --version 2>/dev/null | head -n1 || echo "No instalado")
    gh_ver=$(command -v gh &>/dev/null && gh --version 2>/dev/null | head -n1 || echo "No instalado")
    lfs_ver=$(git lfs version 2>/dev/null | head -n1 || echo "No instalado")

    user_name=$(run_as_user git config --global user.name 2>/dev/null || echo "")
    user_email=$(run_as_user git config --global user.email 2>/dev/null || echo "")
    default_branch=$(run_as_user git config --global init.defaultBranch 2>/dev/null || echo "main")
    core_editor=$(run_as_user git config --global core.editor 2>/dev/null || echo "Predeterminado")
    core_pager=$(run_as_user git config --global core.pager 2>/dev/null || echo "less")
    cred_helper=$(run_as_user git config --global credential.helper 2>/dev/null || echo "No configurado")

    if command -v gh &>/dev/null; then
        local gh_user
        gh_user=$(run_as_user gh auth status 2>&1 | grep -oP 'account \K[^ ]+' | head -n1 || true)
        if [ -n "$gh_user" ]; then
            gh_auth="✅ Autenticado como $gh_user"
        else
            gh_auth="ℹ️ Sesión no iniciada (ejecuta: gh auth login)"
        fi
    else
        gh_auth="No disponible"
    fi

    echo -e "• Git Engine:                 $([ "$git_ver" != "No instalado" ] && echo -e "${GREEN}✅ $git_ver${NC}" || echo -e "${RED}❌ No instalado${NC}")"
    echo -e "• Git LFS:                    $([ "$lfs_ver" != "No instalado" ] && echo -e "${GREEN}✅ $lfs_ver${NC}" || echo -e "${YELLOW}⚠️ No instalado${NC}")"
    echo -e "• Identidad Git:              $([ -n "$user_name" ] && echo -e "${GREEN}$user_name <$user_email>${NC}" || echo -e "${YELLOW}⚠️ No configurada (user.name / user.email)${NC}")"
    echo -e "• Rama por defecto:           ${CYAN}$default_branch${NC}"
    echo -e "• Editor Git:                 ${CYAN}$core_editor${NC}"
    echo -e "• Credential Helper (GNOME):  $([ "$cred_helper" != "No configurado" ] && echo -e "${GREEN}✅ $cred_helper${NC}" || echo -e "${YELLOW}⚠️ No configurado${NC}")"
    echo -e "• Pager / Diff:               $core_pager $([ "$core_pager" = "delta" ] && echo -e "${GREEN}✅ (Git-Delta activo)${NC}" || echo "")"
    echo -e "• Git-Delta:                  $([ "$delta_ver" != "No instalado" ] && echo -e "${GREEN}✅ $delta_ver${NC}" || echo -e "${RED}❌ $delta_ver${NC}")"
    echo -e "• Lazygit TUI:                $([ "$lazygit_ver" != "No instalado" ] && echo -e "${GREEN}✅ $lazygit_ver${NC}" || echo -e "${RED}❌ $lazygit_ver${NC}")"
    echo -e "• Configuración Lazygit:      $(if [ -f "$USER_HOME/.config/lazygit/config.yml" ]; then echo -e "${GREEN}✅ Integrado con Delta & GNOME Dark${NC}"; else echo -e "${YELLOW}ℹ️ No configurado${NC}"; fi)"
    echo -e "• GitHub CLI (gh):            $([ "$gh_ver" != "No instalado" ] && echo -e "${GREEN}✅ $gh_ver${NC}" || echo -e "${RED}❌ $gh_ver${NC}")"
    echo -e "• Estado Auth GitHub:         $gh_auth"
    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 4. CONTROL DE ARGUMENTOS CLI
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
esac

echo -e "${BOLD}======================================================================${NC}"
echo -e "🐙 ${BOLD}CONFIGURACIÓN DE GIT, DELTA, LAZYGIT Y GH - FEDORA 45 GNOME${NC}"
echo -e "${BOLD}======================================================================${NC}"

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN DE PAQUETES (IDEMPOTENTE Y SIN SUDO INNECESARIO)
# ------------------------------------------------------------------------------
log_info "[1/4] Verificando paquetes del ecosistema Git en el sistema..."

MISSING_PKGS=()
for pkg in git git-delta gh git-lfs git-credential-libsecret; do
    if ! is_pkg_installed "$pkg" && ! command -v "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if ! is_pkg_installed lazygit && ! command -v lazygit &>/dev/null; then
    MISSING_PKGS+=("lazygit")
fi

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    log_info "Paquetes faltantes detectados: (${MISSING_PKGS[*]}). Instalando..."
    DNF_PKGS=()
    NEED_LAZYGIT=false

    for pkg in "${MISSING_PKGS[@]}"; do
        if [ "$pkg" = "lazygit" ]; then
            NEED_LAZYGIT=true
        else
            DNF_PKGS+=("$pkg")
        fi
    done

    if [ ${#DNF_PKGS[@]} -gt 0 ]; then
        if ! $SUDO "$DNF_BIN" install -y "${DNF_PKGS[@]}"; then
            log_warn "Falló instalación grupal con $DNF_BIN, intentando paquete a paquete..."
            for pkg in "${DNF_PKGS[@]}"; do
                $SUDO "$DNF_BIN" install -y "$pkg" || log_warn "No se pudo instalar $pkg vía $DNF_BIN"
            done
        else
            log_ok "Paquetes (${DNF_PKGS[*]}) instalados con éxito vía $DNF_BIN."
        fi
    fi

    if [ "$NEED_LAZYGIT" = true ]; then
        if ! $SUDO "$DNF_BIN" install -y lazygit 2>/dev/null; then
            if $SUDO "$DNF_BIN" copr enable -y dejan/lazygit 2>/dev/null && $SUDO "$DNF_BIN" install -y lazygit 2>/dev/null; then
                log_ok "Lazygit instalado vía COPR dejan/lazygit."
            else
                log_info "Lazygit no disponible en repositorios oficiales/copr; recurriendo a binario oficial..."
            fi
        else
            log_ok "Lazygit instalado vía $DNF_BIN."
        fi
    fi
else
    log_ok "Todos los paquetes principales de Git ya se encuentran instalados en el sistema."
fi

# Fallback para Lazygit: Descarga directa desde Releases oficiales de GitHub
if ! command -v lazygit &>/dev/null; then
    log_info "Descargando Lazygit desde binario oficial de GitHub..."
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  LAZYGIT_ARCH="x86_64" ;;
        aarch64) LAZYGIT_ARCH="arm64" ;;
        *) log_err "Arquitectura no soportada para Lazygit: $ARCH"; exit 1 ;;
    esac
    LAZYGIT_TAG=$(basename "$(curl -fsSLI -o /dev/null -w "%{url_effective}" https://github.com/jesseduffield/lazygit/releases/latest 2>/dev/null)" || true)
    LAZYGIT_VERSION="${LAZYGIT_TAG#v}"
    if [ -n "$LAZYGIT_VERSION" ] && [ "$LAZYGIT_VERSION" != "latest" ]; then
        run_as_user mkdir -p "$USER_HOME/.local/bin"
        local_tar="/tmp/lazygit.tar.gz"
        if curl -fsSLo "$local_tar" "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"; then
            tar -xzf "$local_tar" -C "/tmp" lazygit
            run_as_user install -m 755 "/tmp/lazygit" "$USER_HOME/.local/bin/lazygit"
            rm -f "/tmp/lazygit" "$local_tar"
            log_ok "Lazygit instalado correctamente en $USER_HOME/.local/bin/lazygit"
        else
            log_err "Error al descargar el binario de Lazygit desde GitHub."
        fi
    else
        log_warn "No se pudo determinar la última versión de Lazygit en GitHub."
    fi
fi

# ------------------------------------------------------------------------------
# 6. CONFIGURACIÓN GLOBAL DE GIT Y DELTA
# ------------------------------------------------------------------------------
log_info "[2/4] Aplicando configuración moderna de Git y soporte GNOME Keyring..."

# Identidad Git (solo se define si vienen por variables de entorno y no existen ya)
CURRENT_NAME=$(run_as_user git config --global user.name 2>/dev/null || true)
CURRENT_EMAIL=$(run_as_user git config --global user.email 2>/dev/null || true)

if [ -n "${GIT_USER_NAME:-}" ]; then
    run_as_user git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then
    run_as_user git config --global user.email "$GIT_USER_EMAIL"
fi

# Flujo de trabajo, ramas y mejores prácticas modernas
run_as_user git config --global init.defaultBranch main
run_as_user git config --global pull.rebase true
run_as_user git config --global rebase.autoStash true
run_as_user git config --global push.autoSetupRemote true
run_as_user git config --global fetch.prune true
run_as_user git config --global merge.conflictstyle zdiff3
run_as_user git config --global diff.colorMoved default
run_as_user git config --global branch.sort -committerdate
run_as_user git config --global tag.sort -version:refname
run_as_user git config --global column.ui auto
run_as_user git config --global rerere.enabled true
run_as_user git config --global rerere.autoupdate true
run_as_user git config --global commit.verbose true

# Integración con GNOME Keyring (git-credential-libsecret)
LIBSECRET_BIN="/usr/libexec/git-core/git-credential-libsecret"
if [ -x "$LIBSECRET_BIN" ]; then
    run_as_user git config --global credential.helper "$LIBSECRET_BIN"
    log_ok "Integración con GNOME Keyring activada (credential.helper = $LIBSECRET_BIN)."
elif command -v git-credential-libsecret &>/dev/null; then
    run_as_user git config --global credential.helper "libsecret"
    log_ok "Integración con GNOME Keyring activada (credential.helper = libsecret)."
fi

# Detección inteligente del editor preferido en Fedora Workstation
DEFAULT_EDITOR="nano"
if command -v nvim &>/dev/null; then
    DEFAULT_EDITOR="nvim"
elif command -v gnome-text-editor &>/dev/null; then
    DEFAULT_EDITOR="gnome-text-editor"
elif command -v code &>/dev/null; then
    DEFAULT_EDITOR="code --wait"
elif command -v micro &>/dev/null; then
    DEFAULT_EDITOR="micro"
elif command -v vim &>/dev/null; then
    DEFAULT_EDITOR="vim"
fi
run_as_user git config --global core.editor "$DEFAULT_EDITOR"

# Configuración de Git-Delta
if command -v delta &>/dev/null; then
    run_as_user git config --global core.pager "delta"
    run_as_user git config --global interactive.diffFilter "delta --color-only"
    run_as_user git config --global delta.navigate true
    run_as_user git config --global delta.light false
    run_as_user git config --global delta.side-by-side false
    run_as_user git config --global delta.line-numbers true
    run_as_user git config --global delta.hyperlinks true
    log_ok "Git-Delta configurado como visualizador y paginador por defecto."
fi

# Git LFS
if command -v git-lfs &>/dev/null; then
    run_as_user git lfs install --skip-repo &>/dev/null || true
fi

# Atajos útiles y productivos para Git
run_as_user git config --global alias.st "status -sb"
run_as_user git config --global alias.co "checkout"
run_as_user git config --global alias.br "branch"
run_as_user git config --global alias.cm "commit -m"
run_as_user git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# ------------------------------------------------------------------------------
# 7. CONFIGURACIÓN DE LAZYGIT (INTEGRACIÓN CON DELTA Y TEMA GNOME LIBADWAITA DARK)
# ------------------------------------------------------------------------------
log_info "[3/4] Configurando Lazygit con soporte para Git-Delta y estética GNOME..."
LAZYGIT_CONFIG_DIR="$USER_HOME/.config/lazygit"
run_as_user mkdir -p "$LAZYGIT_CONFIG_DIR"

if [ ! -f "$LAZYGIT_CONFIG_DIR/config.yml" ]; then
    cat << 'EOF' | run_as_user tee "$LAZYGIT_CONFIG_DIR/config.yml" > /dev/null
# Lazygit Configuration - Fedora 45 Workstation (GNOME Shell 51)
gui:
  theme:
    activeBorderColor:
      - '#3584e4'
      - bold
    inactiveBorderColor:
      - '#5e5c64'
    selectedLineBgColor:
      - '#2c2c2c'
git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never
EOF
    log_ok "Archivo de configuración de Lazygit generado (~/.config/lazygit/config.yml)."
else
    log_info "Configuración previa de Lazygit conservada."
fi

# ------------------------------------------------------------------------------
# 8. CONFIGURACIÓN DE GITHUB CLI (gh)
# ------------------------------------------------------------------------------
log_info "[4/4] Configurando opciones predeterminadas de GitHub CLI (gh)..."
if command -v gh &>/dev/null; then
    run_as_user gh config set editor "$DEFAULT_EDITOR" 2>/dev/null || true
    log_ok "Editor predeterminado de GitHub CLI configurado a '$DEFAULT_EDITOR'."
fi

# ------------------------------------------------------------------------------
# 9. RESUMEN FINAL
# ------------------------------------------------------------------------------
echo ""
show_status

if [ -z "$(run_as_user git config --global user.name 2>/dev/null || true)" ]; then
    echo ""
    log_warn "Nota: Configura tu identidad de Git ejecutando:"
    echo "  git config --global user.name \"Tu Nombre\""
    echo "  git config --global user.email \"tu_email@ejemplo.com\""
fi

echo -e "${BOLD}======================================================================${NC}"
log_ok "Entorno Git optimizado con éxito para Fedora 45 Workstation (GNOME 51)."
echo "💡 Tip: Lanza 'lazygit' en cualquier repositorio para una TUI interactiva rápida."
echo -e "${BOLD}======================================================================${NC}"
