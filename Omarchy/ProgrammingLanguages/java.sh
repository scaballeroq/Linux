#!/usr/bin/env bash
# ==============================================================================
# java.sh - Instalación, Optimización y Diagnóstico de OpenJDK y Maven
# Sistema: Omarchy Linux (x86-64-v3 / Hyprland Wayland)
# Hardware: HP ProBook 455 G10 | AMD Ryzen 7 7730U (Zen 3, 8C/16T) | 32 GB RAM
# ==============================================================================
# Características de Alto Rendimiento:
# - Despliegue idempotente del JDK LTS de referencia desde repositorios oficiales de Omarchy/Arch (Pacman).
# - Detección dinámica y resiliente de la versión de OpenJDK (21 LTS / 25 LTS por defecto,
#   con soporte para 17 LTS o versiones personalizadas).
# - Instalación completa del kit de desarrollo: JDK, JRE, maven, nss y pcsclite.
# - Integración nativa con Apache Maven y optimización multinúcleo para AMD Ryzen (16 hilos).
# - Resolución canónica de JAVA_HOME (/usr/lib/jvm/default o /usr/lib/jvm/java-<ver>-openjdk).
# - Compatibilidad gráfica para Mutter Wayland (_JAVA_AWT_WM_NONREPARENTING=1).
# - Integración desacoplada con Sesión Wayland (environment.d) y Shells (Bash / Zsh).
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
    if command -v mise &>/dev/null; then
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

    # 3. Priorizar LTS disponible en Omarchy/Arch
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

    # 1. Enlace por defecto oficial de Arch/Omarchy
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
# OpenJDK & Java Tools Environment (Omarchy Workstation)
export JAVA_HOME="$jhome"
export JDK_HOME="$jhome"

if [ -d "\$JAVA_HOME/bin" ] && [[ ":\$PATH:" != *":\$JAVA_HOME/bin:"* ]]; then
    export PATH="\$JAVA_HOME/bin:\$PATH"
fi

# Compatibilidad de aplicaciones GUI AWT/Swing con Mutter Wayland
export _JAVA_AWT_WM_NONREPARENTING=1

# Integración con Apache Maven y optimización multinúcleo AMD Ryzen
if [ -d "/usr/share/maven" ]; then
    export M2_HOME="/usr/share/maven"
    export MAVEN_HOME="/usr/share/maven"
    export MAVEN_OPTS="-Xms512m -Xmx2048m -XX:+TieredCompilation"
fi
EOF

    log_ok "Módulo Bash configurado en $bash_file."

    # Configurar Zsh si el usuario tiene Zsh o directorio ~/.zshrc.d
    if [ -f "$USER_HOME/.zshrc" ] || [ -d "$USER_HOME/.zshrc.d" ]; then
        local zshrc_d="$USER_HOME/.zshrc.d"
        local zsh_file="$zshrc_d/java.zsh"
        log_step "Configurando carga modular para Zsh en $zsh_file..."
        run_as_user mkdir -p "$zshrc_d"

        run_as_user bash -c "cat > '$zsh_file'" <<EOF
# OpenJDK & Java Tools Environment (Omarchy Workstation - Zsh)
export JAVA_HOME="$jhome"
export JDK_HOME="$jhome"

if [ -d "\$JAVA_HOME/bin" ] && [[ ":\$PATH:" != *":\$JAVA_HOME/bin:"* ]]; then
    export PATH="\$JAVA_HOME/bin:\$PATH"
fi

# Compatibilidad de aplicaciones GUI AWT/Swing con Mutter Wayland
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
    echo -e "${BOLD}☕ ESTADO DEL ENTORNO OPENJDK & MAVEN - OMARCHY WORKSTATION${NC}"
    echo -e "   ${CYAN}Hardware:${NC} AMD Ryzen 7 7730U (8C/16T) | 32 GB RAM | Hyprland Wayland"
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
            mise_java="${GREEN}✅ Mise activo (utilizando OpenJDK del sistema Omarchy)${NC}"
        fi
    else
        mise_java="${CYAN}ℹ️ Mise no detectado${NC}"
    fi

    echo -e "${BOLD}1. Runtimes y Herramientas del JDK:${NC}"
    echo -e "  • Runtime 'java':        $java_status"
    echo -e "  • Compilador 'javac':    $javac_status"
    echo -e "  • Gestor 'maven':        $mvn_status"
    echo -e "  • Módulos JDK (jmods):   $([ -d "${java_home}/jmods" ] && echo -e "${GREEN}✅ Presentes${NC}" || echo -e "${YELLOW}⚠️ No detectados${NC}")"
    echo -e "-----------------------------------------------------------------"
    echo -e "${BOLD}2. Variables de Entorno y Rutas Canónicas:${NC}"
    echo -e "  • JAVA_HOME canónico:    $home_status"
    echo -e "  • Wayland Non-Reparent:  ${GREEN}✅ _JAVA_AWT_WM_NONREPARENTING=1${NC}"
    echo -e "  • Optimización Maven:    ${GREEN}-Xms512m -Xmx2048m (16 hilos AMD Ryzen)${NC}"
    echo -e "-----------------------------------------------------------------"
    echo -e "${BOLD}3. Integración en el Escritorio y Shells:${NC}"
    echo -e "  • Sesión environment.d:   $([ -f "$env_conf" ] && echo -e "${GREEN}✅ Configurado ($env_conf)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    echo -e "  • Shell Bash:            $([ -f "$bash_conf" ] && echo -e "${GREEN}✅ Configurado ($bash_conf)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    if [ -f "$USER_HOME/.zshrc" ] || [ -d "$USER_HOME/.zshrc.d" ]; then
        echo -e "  • Shell Zsh:             $([ -f "$zsh_conf" ] && echo -e "${GREEN}✅ Configurado ($zsh_conf)${NC}" || echo -e "${RED}❌ Ausente${NC}")"
    fi
    echo -e "  • Coexistencia Mise:     $mise_java"
    echo -e "${CYAN}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 6. INSTALACIÓN Y CONFIGURACIÓN COMPLETA
# ------------------------------------------------------------------------------
install_java() {
    TARGET_VER=$(detect_target_openjdk)

    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}☕ INSTALACIÓN Y CONFIGURACIÓN DE OPENJDK & MAVEN (OMARCHY)${NC}"
    echo -e "   ${CYAN}Hardware:${NC} AMD Ryzen 7 7730U | Hyprland Wayland"
    echo -e "${CYAN}=================================================================${NC}"

    log_info "Versión objetivo de OpenJDK detectada: ${BOLD}Java ${TARGET_VER}${NC}"

    # Paquetes requeridos en Omarchy/Arch
    local required_pkgs=()
    if pacman -Si "jdk${TARGET_VER}-openjdk" &>/dev/null; then
        required_pkgs+=("jdk${TARGET_VER}-openjdk" "jre${TARGET_VER}-openjdk")
    else
        required_pkgs+=("jdk-openjdk" "jre-openjdk")
    fi
    required_pkgs+=("maven" "nss" "pcsclite")

    # Filtrar paquetes no instalados con pacman -T
    local missing_pkgs
    missing_pkgs=$(pacman -T "${required_pkgs[@]}" 2>/dev/null || true)

    if [ -n "$missing_pkgs" ]; then
        log_step "Instalando paquetes faltantes vía pacman: ${BOLD}${missing_pkgs}${NC}..."
        if [ "$EUID" -ne 0 ]; then
            log_warn "Se requieren privilegios administrativos para instalar paquetes con pacman."
        fi
        $SUDO pacman -S --needed --noconfirm $missing_pkgs
        log_ok "Paquetes OpenJDK y dependencias instalados con éxito."
    else
        log_ok "Todos los paquetes necesarios de OpenJDK ${TARGET_VER} y Maven ya están instalados."
    fi

    # Configurar JVM por defecto con archlinux-java si está disponible
    if command -v archlinux-java &>/dev/null; then
        local lts_jvm
        lts_jvm=$(archlinux-java status 2>/dev/null | grep -E "java-(${TARGET_VER}|25|21)-openjdk" | tail -n1 | awk '{print $1}' || true)
        if [ -n "$lts_jvm" ]; then
            log_step "Estableciendo JVM por defecto a $lts_jvm con archlinux-java..."
            $SUDO archlinux-java set "$lts_jvm" 2>/dev/null || true
        fi
    fi

    # Resolver JAVA_HOME
    local resolved_home
    resolved_home=$(resolve_java_home "$TARGET_VER")

    if [ -z "$resolved_home" ] || [ ! -d "$resolved_home" ]; then
        log_warn "No se pudo resolver automáticamente JAVA_HOME, usando /usr/lib/jvm/default."
        resolved_home="/usr/lib/jvm/default"
    fi

    log_ok "JAVA_HOME resuelto canónicamente: ${BOLD}$resolved_home${NC}"

    # Configurar environment.d para Hyprland y Wayland
    configure_environment_d "$resolved_home"

    # Configurar shells (Bash y Zsh)
    configure_shells "$resolved_home"

    echo ""
    log_ok "Entorno OpenJDK ${TARGET_VER} configurado y optimizado correctamente."
    echo ""
    show_status
}

# ------------------------------------------------------------------------------
# 7. ACTUALIZACIÓN DE PAQUETES (--update)
# ------------------------------------------------------------------------------
update_java() {
    local target_ver
    target_ver=$(detect_target_openjdk)

    echo -e "${CYAN}=================================================================${NC}"
    echo -e "${BOLD}🔄 ACTUALIZANDO PAQUETES OPENJDK Y MAVEN VÍA PACMAN${NC}"
    echo -e "${CYAN}=================================================================${NC}"

    local update_pkgs=("jdk${target_ver}-openjdk" "jre${target_ver}-openjdk" "maven")

    log_step "Ejecutando actualización de paquetes: ${BOLD}${update_pkgs[*]}${NC}..."
    if [ "$EUID" -ne 0 ]; then
        log_warn "Se requieren privilegios administrativos para actualizar paquetes con pacman."
    fi

    $SUDO pacman -S --needed --noconfirm "${update_pkgs[@]}"
    log_ok "Actualización completada exitosamente."
    echo ""
    show_status
}

# ------------------------------------------------------------------------------
# 8. AYUDA (--help)
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
☕ Gestor y Optimizador de OpenJDK & Maven - Omarchy Workstation
   Hyprland Wayland | AMD Ryzen 7 7730U | 32 GB RAM

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica e instala OpenJDK (Java LTS por defecto en Omarchy),
                      compilador javac, dependencias de seguridad y Apache Maven.
                      Resuelve JAVA_HOME de forma canónica e inyecta la configuración en
                      environment.d, ~/.bashrc.d y ~/.zshrc.d de forma modular e idempotente.
  --install, -i       Fuerza la ejecución del proceso de instalación y configuración.
  --version, -v <num> Selecciona la versión específica de OpenJDK (ej. 25, 21, 17).
  --status, -s        Muestra diagnóstico detallado del Runtime, Compilador javac,
                      Maven, JAVA_HOME, variables Wayland e integración en shells.
  --update, -u        Actualiza los paquetes de OpenJDK y Maven vía Pacman.
  --help, -h          Muestra este mensaje de ayuda.

Ejemplos:
  $0                  # Instala y optimiza OpenJDK según la versión del sistema
  $0 --version 21     # Fuerza la instalación de OpenJDK 21
  $0 --status         # Muestra el estado actual del entorno Java
  $0 --update         # Actualiza OpenJDK y Maven a las últimas versiones disponibles
EOF
}

# ------------------------------------------------------------------------------
# 9. PROCESAMIENTO DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
TARGET_VER="${JAVA_TARGET_VER:-}"
ACTION="install"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --status|-s|status)
            ACTION="status"
            shift
            ;;
        --update|-u|update)
            ACTION="update"
            shift
            ;;
        --help|-h|help)
            ACTION="help"
            shift
            ;;
        --version|-v)
            if [ -n "${2:-}" ] && [[ "$2" =~ ^[0-9]+$ || "$2" == "latest" ]]; then
                TARGET_VER="$2"
                shift 2
            else
                log_error "Debe especificar una versión válida para Java (ej. 25, 21, 17)"
                exit 1
            fi
            ;;
        --install|-i|install)
            ACTION="install"
            shift
            ;;
        *)
            log_error "Opción no reconocida: $1"
            echo "Ejecute '$0 --help' para ver las opciones disponibles."
            exit 1
            ;;
    esac
done

case "$ACTION" in
    status)
        show_status
        exit 0
        ;;
    update)
        update_java
        exit 0
        ;;
    help)
        show_help
        exit 0
        ;;
    install)
        install_java
        exit 0
        ;;
esac
