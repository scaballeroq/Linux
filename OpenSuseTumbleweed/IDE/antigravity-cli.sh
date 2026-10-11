#!/usr/bin/env bash
# ==============================================================================
# antigravity-cli.sh - Gestor e Instalador de Google Antigravity CLI (agy)
# Optimizado para openSUSE Tumbleweed (KDE Plasma 6 Wayland)
# ==============================================================================
# Características:
#  - Instalación y gestión 100% rootless en ~/.local/bin/agy.
#  - Comprobación de estado (--status) e inspección de versión instantánea.
#  - Consulta directa al manifiesto oficial sin scripts intermedios innecesarios.
#  - Prevención de descargas redundantes si la versión local ya está al día.
#  - Actualización rápida mediante 'agy update' nativo o reinstalación limpia.
#  - Integración modular en ~/.bashrc.d/ y ~/.config/environment.d/.
#  - Opciones completas de CLI: --status, --check, --update, --force, --uninstall y --help.
# ==============================================================================

set -euo pipefail

# Colores de salida
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m"

# Detección de usuario real
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

LOCAL_BIN="$USER_HOME/.local/bin"
AGY_BIN="$LOCAL_BIN/agy"
HELPER_PATH="$LOCAL_BIN/update-antigravity-cli"
MARKER_FILE="$LOCAL_BIN/.linuxcapable-antigravity-cli"
MARKER_VALUE="google-antigravity-cli-v1"
BASHRC_D="$USER_HOME/.bashrc.d"
BASHRC_FILE="$BASHRC_D/antigravity-cli.sh"
ENV_D="$USER_HOME/.config/environment.d"
ENV_FILE="$ENV_D/10-antigravity-cli.conf"

MANIFEST_BASE_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app"
OFFICIAL_INSTALLER_URL="https://antigravity.google/cli/install.sh"

case "$(uname -m)" in
x86_64 | amd64)
    ARCH="amd64"
    PLATFORM="linux_amd64"
    ;;
aarch64 | arm64)
    ARCH="arm64"
    PLATFORM="linux_arm64"
    ;;
*)
    echo -e "${RED}❌ Arquitectura no soportada: $(uname -m)${NC}" >&2
    exit 1
    ;;
esac

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# Obtener versión instalada
get_installed_version() {
    if [ -x "$AGY_BIN" ]; then
        "$AGY_BIN" --version 2>/dev/null || echo ""
    elif command -v agy &>/dev/null; then
        agy --version 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Obtener última versión remota oficial desde el manifiesto
get_remote_version() {
    local manifest_url="$MANIFEST_BASE_URL/manifests/$PLATFORM.json"
    local json version
    json=$(curl -fsSL --retry 2 "$manifest_url" 2>/dev/null || true)
    version=$(echo "$json" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1 || true)
    if [ -n "$version" ]; then
        echo "$version"
    else
        # Fallback si no hay conexión
        echo "1.2.10"
    fi
}

# Valida que el binario agy sea auténtico y funcional
validate_agy() {
    local bin="$1"
    if [ ! -x "$bin" ]; then
        return 1
    fi
    local ver help_out
    ver=$("$bin" --version 2>/dev/null || true)
    help_out=$("$bin" --help 2>&1 || true)
    if [[ ! "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
       ! grep -Fq 'Usage of agy:' <<<"$help_out" ||
       ! grep -Fq 'Available subcommands:' <<<"$help_out" ||
       ! grep -Fq 'update          Update CLI' <<<"$help_out"; then
        return 1
    fi
    return 0
}

# ------------------------------------------------------------------------------
# Verificación idempotente de dependencias
# ------------------------------------------------------------------------------
check_dependencies() {
    local missing=()
    command -v curl &>/dev/null || missing+=("curl")
    command -v tar &>/dev/null || missing+=("tar")

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "ℹ️  ${YELLOW}Instalando herramientas requeridas: ${missing[*]}...${NC}"
        if [ "$EUID" -ne 0 ]; then
            if ! command -v sudo &>/dev/null; then
                echo -e "${RED}❌ Error: Se requiere 'sudo' para instalar ${missing[*]}${NC}" >&2
                exit 1
            fi
            sudo zypper --non-interactive install -y "${missing[@]}"
        else
            zypper --non-interactive install -y "${missing[@]}"
        fi
    fi
}

# ------------------------------------------------------------------------------
# Configuración del Entorno y Shells Modulares
# ------------------------------------------------------------------------------
configure_environment() {
    run_as_user mkdir -p "$LOCAL_BIN" "$BASHRC_D" "$ENV_D"

    # Shell modular Bash (~/.bashrc.d)
    if [ -d "$BASHRC_D" ]; then
        run_as_user tee "$BASHRC_FILE" > /dev/null << 'EOF'
# Antigravity CLI (agy)
if [ -d "$HOME/.local/bin" ] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
EOF
    fi

    # Sesión KDE Plasma 6 Wayland (~/.config/environment.d)
    run_as_user tee "$ENV_FILE" > /dev/null << 'EOF'
# Antigravity CLI Environment
PATH=$HOME/.local/bin:$PATH
EOF
}

# ------------------------------------------------------------------------------
# Visualización del estado del sistema (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🛸 ${BOLD}Estado de Google Antigravity CLI (agy) en openSUSE Tumbleweed${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    local installed_v
    installed_v=$(get_installed_version)
    local remote_v
    remote_v=$(get_remote_version)

    echo -e "👤 ${BOLD}Usuario objetivo:${NC} $REAL_USER ($USER_HOME)"

    if [ -n "$installed_v" ] && validate_agy "$AGY_BIN"; then
        echo -e "📦 ${BOLD}Estado CLI:${NC}       ${GREEN}Instalado y validado${NC}"
        echo -e "🏷️  ${BOLD}Versión actual:${NC}   ${CYAN}v$installed_v${NC}"
    else
        echo -e "📦 ${BOLD}Estado CLI:${NC}       ${RED}No instalado o no válido${NC}"
        echo -e "🏷️  ${BOLD}Versión actual:${NC}   ${YELLOW}Ninguna${NC}"
    fi

    echo -e "🌐 ${BOLD}Última remota:${NC}    ${CYAN}v$remote_v${NC}"

    if [ -n "$installed_v" ]; then
        if [ "$installed_v" = "$remote_v" ]; then
            echo -e "✨ ${BOLD}Actualización:${NC}    ${GREEN}Al día con la versión más reciente${NC}"
        else
            echo -e "⚡ ${BOLD}Actualización:${NC}    ${YELLOW}Actualización disponible (v$installed_v -> v$remote_v)${NC}"
        fi
    fi

    echo ""
    echo -e "${BOLD}📁 Rutas y Binarios:${NC}"
    if [ -x "$AGY_BIN" ]; then
        echo -e "  • Binario ejecutable: ${GREEN}$AGY_BIN${NC} ($(du -h "$AGY_BIN" | cut -f1))"
    else
        echo -e "  • Binario ejecutable: ${RED}No presente ($AGY_BIN)${NC}"
    fi

    if [ -x "$HELPER_PATH" ]; then
        echo -e "  • Script helper:      ${GREEN}$HELPER_PATH${NC}"
    else
        echo -e "  • Script helper:      ${YELLOW}No presente${NC}"
    fi

    if [ -f "$MARKER_FILE" ]; then
        echo -e "  • Archivo marcador:   ${GREEN}$MARKER_FILE${NC}"
    fi

    echo ""
    echo -e "${BOLD}⚙️  Integración de Entorno y PATH:${NC}"
    if [ -f "$BASHRC_FILE" ]; then
        echo -e "  • Bash (~/.bashrc.d):   ${GREEN}Configurado ($BASHRC_FILE)${NC}"
    else
        echo -e "  • Bash (~/.bashrc.d):   ${YELLOW}No presente${NC}"
    fi

    if [ -f "$ENV_FILE" ]; then
        echo -e "  • Sesión Wayland/KDE:   ${GREEN}Configurado ($ENV_FILE)${NC}"
    else
        echo -e "  • Sesión Wayland/KDE:   ${YELLOW}No presente${NC}"
    fi

    if command -v agy &>/dev/null; then
        echo -e "  • Resolución PATH:     ${GREEN}$(command -v agy)${NC}"
    else
        echo -e "  • Resolución PATH:     ${YELLOW}No visible en el PATH de la sesión actual${NC}"
    fi

    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# Generación / Actualización del Helper (~/.local/bin/update-antigravity-cli)
# ------------------------------------------------------------------------------
generate_helper() {
    local helper_tmp
    helper_tmp=$(mktemp "${TMPDIR:-/tmp}/update-antigravity-cli.XXXXXX")

    cat >"$helper_tmp" <<'HELPER_EOF'
#!/usr/bin/env bash
# LinuxCapable-Managed: google-antigravity-cli-helper-v1
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
agy_file="$HOME/.local/bin/agy"
marker_file="$HOME/.local/bin/.linuxcapable-antigravity-cli"
marker_value='google-antigravity-cli-v1'

action="update"
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            echo "Uso: $0 [-s|--status] [-c|--check] [-u|--update]"
            exit 0
            ;;
        -s|--status)
            action="status"
            shift
            ;;
        -c|--check)
            action="check"
            shift
            ;;
        -u|--update)
            action="update"
            shift
            ;;
        *)
            echo "Opción desconocida: $1" >&2
            exit 1
            ;;
    esac
done

if [ "$action" = "status" ]; then
    if [ -x "$agy_file" ]; then
        echo "Antigravity CLI instalada: $("$agy_file" --version)"
    else
        echo "Antigravity CLI no está instalada en $agy_file"
    fi
    exit 0
fi

if [ "$action" = "check" ]; then
    if [ -x "$agy_file" ]; then
        current=$("$agy_file" --version)
        echo "Versión instalada: $current"
    else
        echo "No instalada"
        exit 1
    fi
    exit 0
fi

if [ -x "$agy_file" ]; then
    echo "⟳ Ejecutando actualización de Antigravity CLI..."
    "$agy_file" update || true
    echo "✅ Antigravity CLI: $("$agy_file" --version)"
else
    echo "ℹ️  Antigravity CLI no está instalada. Ejecute el instalador principal: ./IDE/antigravity-cli.sh"
    exit 1
fi
HELPER_EOF

    bash -n "$helper_tmp"
    run_as_user install -m 0755 "$helper_tmp" "$HELPER_PATH"
    rm -f "$helper_tmp"
}

# ------------------------------------------------------------------------------
# Desinstalación limpia
# ------------------------------------------------------------------------------
uninstall_cli() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🗑️  ${YELLOW}Desinstalando Google Antigravity CLI (agy)...${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    if [ -f "$AGY_BIN" ] || [ -L "$AGY_BIN" ]; then
        run_as_user rm -f "$AGY_BIN"
        echo -e "  • Eliminado binario: $AGY_BIN"
    fi

    # Eliminar posibles respaldos dejados por agy update
    run_as_user rm -f "$LOCAL_BIN"/agy.*.old 2>/dev/null || true

    if [ -f "$HELPER_PATH" ]; then
        run_as_user rm -f "$HELPER_PATH"
        echo -e "  • Eliminado helper: $HELPER_PATH"
    fi

    if [ -f "$MARKER_FILE" ]; then
        run_as_user rm -f "$MARKER_FILE"
        echo -e "  • Eliminado marcador: $MARKER_FILE"
    fi

    if [ -f "$BASHRC_FILE" ]; then
        run_as_user rm -f "$BASHRC_FILE"
        echo -e "  • Eliminada integración Bash: $BASHRC_FILE"
    fi

    if [ -f "$ENV_FILE" ]; then
        run_as_user rm -f "$ENV_FILE"
        echo -e "  • Eliminada configuración Wayland: $ENV_FILE"
    fi

    echo -e "${GREEN}✅ Antigravity CLI ha sido desinstalada correctamente.${NC}"
    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# Instalación / Actualización
# ------------------------------------------------------------------------------
install_or_update() {
    local force_flag="${1:-no}"

    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🛸 ${BOLD}Gestor de Instalación de Google Antigravity CLI (agy)${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    # 1. Dependencias idempotentes (rootless si están presentes)
    echo -e "ℹ️  [1/4] Comprobando dependencias..."
    check_dependencies

    # 2. Entorno y rutas
    echo -e "ℹ️  [2/4] Configurando variables de entorno e integración de shells..."
    configure_environment

    # 3. Comprobación de versión
    local installed_v
    installed_v=$(get_installed_version)
    local remote_v
    remote_v=$(get_remote_version)

    echo -e "ℹ️  [3/4] Comprobando versiones (Local: ${CYAN}v${installed_v:-ninguna}${NC} | Remota: ${CYAN}v$remote_v${NC})..."

    if [ "$force_flag" != "yes" ] && [ -n "$installed_v" ] && [ "$installed_v" = "$remote_v" ] && validate_agy "$AGY_BIN"; then
        echo -e "${GREEN}✨ Antigravity CLI v$installed_v ya se encuentra en su versión más reciente y validada.${NC}"
        echo -e "💡 No se requiere descarga ni cambios adicionales."
        echo -e "💡 Usa ${CYAN}--force${NC} para forzar la reinstalación completa."
    elif [ "$force_flag" != "yes" ] && [ -n "$installed_v" ] && validate_agy "$AGY_BIN"; then
        echo -e "⚡ [4/4] Actualizando CLI de v$installed_v a v$remote_v mediante actualizador nativo..."
        run_as_user "$AGY_BIN" update || true
    else
        echo -e "⬇️  [4/4] Descargando e instalando Antigravity CLI v$remote_v..."
        local tmp_installer
        tmp_installer=$(mktemp "${TMPDIR:-/tmp}/antigravity-cli-installer.XXXXXX")
        curl -fsSL --proto '=https' --proto-redir '=https' --retry 3 -o "$tmp_installer" "$OFFICIAL_INSTALLER_URL"
        bash -n "$tmp_installer"
        run_as_user bash "$tmp_installer" --dir "$LOCAL_BIN"
        rm -f "$tmp_installer"
    fi

    # Generar o sincronizar helper
    generate_helper

    # Crear marcador de control
    umask 077
    printf '%s\n' "$MARKER_VALUE" > "$MARKER_FILE"

    echo -e "${BOLD}=================================================================${NC}"
    if validate_agy "$AGY_BIN"; then
        local current_v
        current_v=$("$AGY_BIN" --version 2>/dev/null || echo "$remote_v")
        echo -e "${GREEN}✅ Antigravity CLI (v$current_v) verificado y listo en:${NC} $AGY_BIN"
        echo -e "💡 Ejecutable: ${BOLD}agy${NC}"
        echo -e "💡 Para recargar variables en la terminal actual: ${BOLD}source ~/.bashrc${NC}"
    else
        echo -e "${RED}❌ Error: La verificación del binario agy no fue exitosa.${NC}" >&2
        exit 1
    fi
    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# Ayuda
# ------------------------------------------------------------------------------
show_help() {
    echo -e "${BOLD}Uso:${NC} $0 [opción]"
    echo ""
    echo -e "${BOLD}Opciones:${NC}"
    echo -e "  ${CYAN}-s, --status${NC}        Muestra el estado completo de la instalación e integración"
    echo -e "  ${CYAN}-c, --check${NC}         Comprueba si hay actualizaciones disponibles (exit code)"
    echo -e "  ${CYAN}-u, --update${NC}        Actualiza agy a la última versión disponible"
    echo -e "  ${CYAN}-f, --force${NC}         Fuerza la descarga y reinstalación desde cero"
    echo -e "  ${CYAN}--uninstall${NC}         Desinstala agy y limpia archivos de entorno"
    echo -e "  ${CYAN}-h, --help${NC}          Muestra este mensaje de ayuda"
    echo ""
    echo -e "${BOLD}Ejemplos:${NC}"
    echo -e "  $0                  # Verifica e instala/actualiza si es necesario"
    echo -e "  $0 --status         # Comprobación de estado rápida y 100% rootless"
    echo -e "  $0 --update         # Ejecuta la actualización a la última versión"
}

# ------------------------------------------------------------------------------
# Procesamiento de Parámetros
# ------------------------------------------------------------------------------
ACTION="install"
FORCE="no"

while [ $# -gt 0 ]; do
    case "$1" in
        -s|--status)
            ACTION="status"
            shift
            ;;
        -c|--check)
            ACTION="check"
            shift
            ;;
        -u|--update)
            ACTION="update"
            shift
            ;;
        -f|--force)
            ACTION="install"
            FORCE="yes"
            shift
            ;;
        --uninstall)
            ACTION="uninstall"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opción desconocida: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

case "$ACTION" in
    status)
        show_status
        ;;
    check)
        installed_v=$(get_installed_version)
        remote_v=$(get_remote_version)
        if [ -n "$installed_v" ] && [ "$installed_v" = "$remote_v" ]; then
            echo "Antigravity CLI está al día (v$installed_v)"
            exit 0
        else
            echo "Actualización disponible: ${installed_v:-ninguna} -> $remote_v"
            exit 1
        fi
        ;;
    update)
        if [ -x "$AGY_BIN" ]; then
            "$AGY_BIN" update
        else
            install_or_update "no"
        fi
        ;;
    uninstall)
        uninstall_cli
        ;;
    install)
        install_or_update "$FORCE"
        ;;
esac
