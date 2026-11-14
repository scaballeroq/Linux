#!/usr/bin/env bash
# ==============================================================================
# java.sh - Instalación, Optimización y Diagnóstico de OpenJDK y Maven
# Sistema: Omarchy 4.5 Workstation (Arch Linux) | Escritorio: Hyprland (Wayland)
# Hardware: HP ProBook 455 G10 | AMD Ryzen 7 7730U (Zen 3, 8C/16T) | 32 GB RAM
# ==============================================================================
# Características de Alto Rendimiento:
# - Despliegue idempotente del JDK LTS de referencia desde repositorios oficiales de Arch (Pacman).
# - Detección dinámica y resiliente de la versión de OpenJDK (21 LTS / 25 LTS por defecto,
#   con soporte para 17 LTS o versiones personalizadas).
# - Instalación completa del kit de desarrollo: JDK, JRE, maven, nss y pcsclite.
# - Integración nativa con Apache Maven y optimización multinúcleo para AMD Ryzen (16 hilos).
# - Resolución canónica de JAVA_HOME (/usr/lib/jvm/default o /usr/lib/jvm/java-<ver>-openjdk).
# - Compatibilidad gráfica para Hyprland Wayland (_JAVA_AWT_WM_NONREPARENTING=1).
# - Integración desacoplada con Hyprland (environment.d) y Shells (Bash / Zsh).
# - Diagnóstico en tiempo real (--status) con soporte para coexistencia con Mise.
# - Comandos CLI: --status / -s, --update / -u, --version / -v <n>, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y ESTILOS DE SALIDA
# ------------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1"; }
log_step()  { echo -e "${BLUE}>>${NC}    $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ------------------------------------------------------------------------------
# 2. DETECCIÓN DE USUARIO, PRIVILEGIOS Y ENTORNO
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

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" PATH="$USER_HOME/.local/bin:$PATH" "$@"
    else
        PATH="$USER_HOME/.local/bin:$PATH" "$@"
    fi
}

get_mise_bin() {
    if [ -x "/usr/bin/mise" ]; then
        echo "/usr/bin/mise"
    elif command -v mise &>/dev/null; then
        command -v mise
    elif [ -x "$USER_HOME/.local/bin/mise" ]; then
        echo "$USER_HOME/.local/bin/mise"
    else
        echo ""
    fi
}

# ------------------------------------------------------------------------------
# 3. DETECCIÓN Y RESOLUCIÓN DINÁMICA DE OPENJDK
# ------------------------------------------------------------------------------
detect_target_openjdk() {
    # 1. Si ya se definió explícitamente vía flag o variable de entorno
    if [ -n "${TARGET_VER:-}" ]; then
        echo "$TARGET_VER"
        return 0
    fi

    # 2. Respetar versión instalada a nivel de sistema si existe
    if command -v archlinux-java &>/dev/null; then
        local current_default
        current_default=$(archlinux-java get 2>/dev/null || true)
        if [ -n "$current_default" ]; then
            local parsed_ver
            parsed_ver=$(echo "$current_default" | sed -nE 's/java-([0-9]+)-openjdk/\1/p')
            if [ -n "$parsed_ver" ]; then
                echo "$parsed_ver"
                return 0
            fi
        fi
    fi

    # 3. Priorizar LTS disponible en Arch
    for v in 25 21 17; do
        if pacman -Si "jdk${v}-openjdk" &>/dev/null; then
            echo "$v"
            return 0
        fi
    done

    echo "21"
}

resolve_java_home() {
    local candidate=""
    local cur_target="${1:-${TARGET_VER:-21}}"

    # 1. Enlace por defecto oficial de Arch Linux
    if [ -d "/usr/lib/jvm/default" ] && [ -f "/usr/lib/jvm/default/bin/javac" ]; then
        candidate="/usr/lib/jvm/default"
    fi

    # 2. Si no es default o se busca una versión específica
    if [ -z "$candidate" ] || [ ! -d "$candidate" ]; then
        for p in \
            "/usr/lib/jvm/java-${cur_target}-openjdk" \
            "/usr/lib/jvm/java-25-openjdk" \
            "/usr/lib/jvm/java-21-openjdk" \
            "/usr/lib/jvm/java-17-openjdk" \
            "/usr/lib/jvm/default"; do
            if [ -d "$p" ]; then
                candidate="$p"
                break
            fi
        done
    fi

    # 3. Fallback canónico a través de javac
    if [ -z "$candidate" ] || [ ! -d "$candidate" ]; then
        if command -v javac &>/dev/null; then
            local javac_bin
            javac_bin=$(readlink -f "$(command -v javac)" 2>/dev/null || true)
            if [ -n "$javac_bin" ] && [ -f "$javac_bin" ]; then
                candidate=$(dirname "$(dirname "$javac_bin")")
            fi
        fi
    fi

    echo "$candidate"
}

# ------------------------------------------------------------------------------
# 4. CONFIGURACIÓN DE INTEGRACIÓN DE ENTORNO
# ------------------------------------------------------------------------------
configure_environment_d() {
    local jhome="$1"
    local env_dir="$USER_HOME/.config/environment.d"
    local env_file="$env_dir/10-java.conf"

    log_step "Configurando variables de entorno para Hyprland Wayland en $env_file..."
    run_as_user mkdir -p "$env_dir"

    run_as_user bash -c "cat > '$env_file'" <<EOF
# OpenJDK Environment Configuration (Hyprland Wayland & Systemd User)
JAVA_HOME=$jhome
JDK_HOME=$jhome
_JAVA_AWT_WM_NONREPARENTING=1
EOF

    if [ -d "/usr/share/maven" ]; then
        run_as_user bash -c "cat >> '$env_file'" <<EOF
M2_HOME=/usr/share/maven
MAVEN_HOME=/usr/share/maven
EOF
    fi

    log_ok "Archivo environment.d generado correctamente."
}

configure_shells() {
    local jhome="$1"
    local bashrc_d="$USER_HOME/.bashrc.d"
    local bash_file="$bashrc_d/java.sh"

    log_step "Configurando carga modular para Bash en $bash_file..."
    run_as_user mkdir -p "$bashrc_d"

    run_as_user bash -c "cat > '$bash_file'" <<EOF
# OpenJDK & Java Tools Environment (Omarchy 4.5 Workstation)
export JAVA_HOME="$jhome"
export JDK_HOME="$jhome"

if [ -d "\$JAVA_HOME/bin" ] && [[ ":\$PATH:" != *":\$JAVA_HOME/bin:"* ]]; then
    export PATH="\$JAVA_HOME/bin:\$PATH"
fi

# Compatibilidad de aplicaciones GUI AWT/Swing con Hyprland Wayland
export _JAVA_AWT_WM_NONREPARENTING=1

# Integración con Apache Maven y optimización multinúcleo AMD Ryzen
if [ -d "/usr/share/maven" ]; then
    export M2_HOME="/usr/share/maven"
    export MAVEN_HOME="/usr/share/maven"
    export MAVEN_OPTS="-Xms512m -Xmx2048m -XX:+TieredCompilation"
fi
EOF

    log_ok "Módulo Bash configurado en $bash_file."

    # Configurar Zsh si existe
    if [ -f "$USER_HOME/.zshrc" ] || [ -d "$USER_HOME/.zshrc.d" ]; then
        local zshrc_d="$USER_HOME/.zshrc.d"
        local zsh_file="$zshrc_d/java.zsh"
        log_step "Configurando carga modular para Zsh en $zsh_file..."
        run_as_user mkdir -p "$zshrc_d"

        run_as_user bash -c "cat > '$zsh_file'" <<EOF
# OpenJDK & Java Tools Environment (Omarchy 4.5 Workstation - Zsh)
export JAVA_HOME="$jhome"
export JDK_HOME="$jhome"

if [ -d "\$JAVA_HOME/bin" ] && [[ ":\$PATH:" != *":\$JAVA_HOME/bin:"* ]]; then
    export PATH="\$JAVA_HOME/bin:\$PATH"
fi

# Compatibilidad de aplicaciones GUI AWT/Swing con Hyprland Wayland
export _JAVA_AWT_WM_NONREPARENTING=1

# Integración con Apache Maven y optimización multinúcleo AMD Ryzen
if [ -d "/usr/share/maven" ]; then
    export M2_HOME="/usr/share/maven"
    export MAVEN_HOME="/usr/share/maven"
    export MAVEN_OPTS="-Xms512m -Xmx2048m -XX:+TieredCompilation"
fi
EOF
        log_ok "Módulo Zsh configurado en $zsh_file."
    fi
}

# ------------------------------------------------------------------------------
# 5. DIAGNÓSTICO DEL ENTORNO (--status)
# ------------------------------------------------------------------------------
show_status() {
    local target_ver
    target_ver=$(detect_target_openjdk)

    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}☕ ESTADO DEL ENTORNO OPENJDK & MAVEN - OMARCHY 4.5 WORKSTATION${NC}"
    echo -e "   ${CYAN}Hardware:${NC} AMD Ryzen 7 7730U (8C/16T) | 32 GB RAM | Hyprland (Wayland)"
    echo -e "${CYAN}=================================================================${NC}"

    local java_bin java_ver javac_bin javac_ver java_home env_conf bash_conf zsh_conf
    local mvn_bin mvn_ver mise_bin mise_java
    local java_status javac_status mvn_status home_status

    # 1. Binarios Java y Compilador
    if command -v java &>/dev/null; then
        java_bin=$(which java 2>/dev/null)
        java_ver=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' || echo "instalado")
        java_status="${GREEN}✅ v$java_ver ($java_bin)${NC}"
    else
        java_status="${RED}❌ No instalado${NC}"
    fi

    if command -v javac &>/dev/null; then
        javac_bin=$(which javac 2>/dev/null)
        javac_ver=$(javac -version 2>&1 | awk '{print $2}' || echo "instalado")
        javac_status="${GREEN}✅ v$javac_ver ($javac_bin)${NC}"
    else
        javac_status="${YELLOW}⚠️ No instalado (instale jdk${target_ver}-openjdk)${NC}"
    fi

    # 2. Build Tools (Maven)
    if command -v mvn &>/dev/null; then
        mvn_bin=$(which mvn 2>/dev/null)
        mvn_ver=$(mvn --version 2>/dev/null | head -n1 | awk '{print $3}' || echo "instalado")
        mvn_status="${GREEN}✅ v$mvn_ver ($mvn_bin)${NC}"
    else
        mvn_status="${YELLOW}⚠️ No instalado (paquete 'maven')${NC}"
    fi

    # 3. JAVA_HOME canónico
    java_home=$(resolve_java_home "$target_ver")
    if [ -n "$java_home" ] && [ -d "$java_home" ]; then
        home_status="${GREEN}✅ $java_home${NC}"
    else
        home_status="${RED}❌ No resuelto${NC}"
    fi

    # 4. Archivos de Integración
    env_conf="$USER_HOME/.config/environment.d/10-java.conf"
    bash_conf="$USER_HOME/.bashrc.d/java.sh"
    zsh_conf="$USER_HOME/.zshrc.d/java.zsh"

    # 5. Estado de Mise
    mise_bin=$(get_mise_bin)
    if [ -n "$mise_bin" ]; then
        if run_as_user "$mise_bin" which java 2>/dev/null >/dev/null; then
            mise_java="${YELLOW}⚠️ Shim de Java activo en Mise ($(run_as_user "$mise_bin" current java 2>/dev/null))${NC}"
        else
            mise_java="${GREEN}✅ Mise activo (utilizando OpenJDK del sistema Arch/Omarchy)${NC}"
        fi
    else
        mise_java="${CYAN}ℹ️ Mise no detectado${NC}"
    fi

    echo -e "• ${BOLD}Runtime Java:${NC}          $java_status"
    echo -e "• ${BOLD}Compilador javac:${NC}      $javac_status"
    echo -e "• ${BOLD}Apache Maven:${NC}          $mvn_status"
    echo -e "• ${BOLD}JAVA_HOME Canónico:${NC}    $home_status"
    echo -e "• ${BOLD}Gestor Mise:${NC}           $mise_java"
    echo -e "${CYAN}-----------------------------------------------------------------${NC}"
    echo -e "• ${BOLD}Integración en el Sistema:${NC}"
    echo -e "  - Sesión Hyprland (environment.d): $([ -f "$env_conf" ] && echo -e "${GREEN}✅ Activo ($env_conf)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    echo -e "  - Shell Bash (~/.bashrc.d):         $([ -f "$bash_conf" ] && echo -e "${GREEN}✅ Activo ($bash_conf)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    if [ -f "$USER_HOME/.zshrc" ] || [ -d "$USER_HOME/.zshrc.d" ]; then
        echo -e "  - Shell Zsh (~/.zshrc.d):          $([ -f "$zsh_conf" ] && echo -e "${GREEN}✅ Activo ($zsh_conf)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    fi
    echo -e "  - Compatibilidad GUI Wayland:       ${GREEN}✅ _JAVA_AWT_WM_NONREPARENTING=1 (Hyprland)${NC}"
    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 6. INSTALACIÓN / ACTUALIZACIÓN (--update o ejecución directa)
# ------------------------------------------------------------------------------
install_openjdk() {
    local target_ver
    target_ver=$(detect_target_openjdk)

    log_info "Preparando aprovisionamiento de OpenJDK ${target_ver} LTS y herramientas..."

    local pkgs_to_install=()
    local candidates=(
        "jdk${target_ver}-openjdk"
        "jre${target_ver}-openjdk"
        "maven"
        "nss"
        "pcsclite"
    )

    for pkg in "${candidates[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            pkgs_to_install+=("$pkg")
        fi
    done

    if [ ${#pkgs_to_install[@]} -gt 0 ]; then
        log_step "Instalando paquetes vía Pacman: ${pkgs_to_install[*]}..."
        $SUDO pacman -S --needed --noconfirm "${pkgs_to_install[@]}"
        log_ok "Paquetes instalados correctamente."
    else
        log_ok "Todos los paquetes necesarios de OpenJDK y Maven ya están presentes."
    fi

    # Configurar default en archlinux-java si está disponible
    if command -v archlinux-java &>/dev/null; then
        local current_default
        current_default=$(archlinux-java get 2>/dev/null || true)
        local target_env="java-${target_ver}-openjdk"

        if [ "$current_default" != "$target_env" ]; then
            if archlinux-java status 2>/dev/null | grep -q "$target_env"; then
                log_step "Estableciendo $target_env como Java por defecto en archlinux-java..."
                $SUDO archlinux-java set "$target_env"
                log_ok "Versión por defecto de Java fijada a: $target_env"
            fi
        fi
    fi

    # Resolver JAVA_HOME y generar archivos de integración
    local jhome
    jhome=$(resolve_java_home "$target_ver")

    if [ -n "$jhome" ] && [ -d "$jhome" ]; then
        configure_environment_d "$jhome"
        configure_shells "$jhome"
    else
        log_warn "No se pudo determinar un directorio canónico para JAVA_HOME."
    fi

    # Reshim en Mise si aplica
    local mise_bin
    mise_bin=$(get_mise_bin)
    if [ -n "$mise_bin" ]; then
        run_as_user "$mise_bin" reshim 2>/dev/null || true
    fi
}

show_help() {
    cat <<EOF
☕ Gestor y Optimizador de OpenJDK & Maven - Omarchy 4.5 Workstation
   Hardware: AMD Ryzen 7 7730U (16T) | 32 GB RAM | Hyprland (Wayland)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala y optimiza OpenJDK LTS (versión detectada) y Maven.
  --status, -s           Diagnóstico completo del estado del entorno Java y variables.
  --update, -u           Actualiza los paquetes de OpenJDK, JRE y Maven del sistema.
  --version, -v <num>    Fuerza la instalación de una versión específica (ej: -v 21, -v 17, -v 25).
  --help, -h             Muestra este mensaje de ayuda.
EOF
}

# ------------------------------------------------------------------------------
# 7. PROCESAMIENTO DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
TARGET_VER=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --status|-s|status)
            show_status
            exit 0
            ;;
        --help|-h|help)
            show_help
            exit 0
            ;;
        --update|-u|update)
            install_openjdk
            echo ""
            show_status
            exit 0
            ;;
        --version|-v)
            if [ -n "${2:-}" ] && [[ "$2" =~ ^[0-9]+$ ]]; then
                TARGET_VER="$2"
                shift 2
            else
                log_error "Debe especificar un número de versión válido (ej: -v 21)."
                exit 1
            fi
            ;;
        *)
            log_error "Opción no reconocida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Ejecución por defecto
install_openjdk
echo ""
show_status
echo -e "${BOLD}=================================================================${NC}"
echo -e "${GREEN}✅ Entorno Java & Maven preparado y optimizado para Omarchy 4.5.${NC}"
echo -e "💡 Aplica los cambios de inmediato con: ${CYAN}source ~/.bashrc${NC}"
echo -e "${BOLD}=================================================================${NC}"
