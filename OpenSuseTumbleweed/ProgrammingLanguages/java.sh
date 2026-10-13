#!/usr/bin/env bash
# ==============================================================================
# java.sh - Instalación y Optimización de OpenJDK para openSUSE Tumbleweed
# Arquitectura: AMD Ryzen 7 PRO 4750U (16 hilos) | 32 GB RAM | KDE Plasma 6 Wayland
# ==============================================================================
# Características:
# - Despliegue idempotente de OpenJDK (java-21-openjdk y java-21-openjdk-devel LTS)
#   desde los repositorios oficiales de openSUSE Tumbleweed sin sudo innecesario.
# - Dependencias esenciales: ca-certificates-cacerts (almacén para HTTPS, DNIe y
#   AutoFirma), Maven y herramientas de tarjetas inteligentes (pcscd, NSS).
# - Detección y resolución dinámica y canónica de JAVA_HOME en openSUSE (/usr/lib64/jvm/java).
# - Optimización de compilación multinúcleo para Ryzen 7 PRO (16 hilos paralelos):
#   * Maven: MAVEN_ARGS="-T 1C" (1 hilo por núcleo), MAVEN_OPTS con G1GC y heap escalado a 4GB.
#   * Gradle: Generación de ~/.gradle/gradle.properties con parallel, caching,
#     daemon, 16 workers y vfs.watch (inotify en Btrfs/ext4).
# - Integración gráfica con KDE Plasma 6 sobre Wayland:
#   * _JAVA_AWT_WM_NONREPARENTING=1 (previene ventanas grises en Swing/AWT en KWin Wayland).
#   * Renderizado de fuentes subpixel LCD antialiasing (-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true).
# - Integración modular con KDE Plasma 6 (environment.d) y Shells (Bash / Zsh).
# - Comandos CLI: --status / -s, --update / -u, --alternatives / -a, --help / -h.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO Y PRIVILEGIOS
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

# Topología de CPU para optimización paralela (AMD Ryzen 7 PRO 4750U: 8C/16T)
NPROC=$(nproc 2>/dev/null || echo 16)

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# Comprobar si un paquete está instalado vía RPM
check_pkg() {
    rpm -q "$1" &>/dev/null
}

# ------------------------------------------------------------------------------
# 2. RESOLUCIÓN DE JVM ACTIVA (OPENSUSE TUMBLEWEED)
# ------------------------------------------------------------------------------
resolve_default_jvm() {
    local jvm_path=""

    # 1. Enlaces canónicos predeterminados en openSUSE
    if [ -d "/usr/lib64/jvm/java-21-openjdk" ]; then
        jvm_path="/usr/lib64/jvm/java-21-openjdk"
    elif [ -d "/usr/lib64/jvm/java" ]; then
        jvm_path="/usr/lib64/jvm/java"
    elif [ -d "/usr/lib64/jvm/java-openjdk" ]; then
        jvm_path="/usr/lib64/jvm/java-openjdk"
    elif [ -d "/usr/lib/jvm/java-21-openjdk" ]; then
        jvm_path="/usr/lib/jvm/java-21-openjdk"
    elif [ -d "/usr/lib/jvm/java" ]; then
        jvm_path="/usr/lib/jvm/java"
    # 2. Ruta canónica a partir del binario javac activo en PATH
    elif command -v javac &>/dev/null; then
        local javac_bin
        javac_bin=$(readlink -f "$(command -v javac)" 2>/dev/null || true)
        if [ -n "$javac_bin" ] && [ -f "$javac_bin" ]; then
            local resolved_dir
            resolved_dir=$(dirname "$(dirname "$javac_bin")")
            if [ -d "$resolved_dir" ]; then
                jvm_path="$resolved_dir"
            fi
        fi
    # 3. Ruta canónica a partir de java activo
    elif command -v java &>/dev/null; then
        local java_bin
        java_bin=$(readlink -f "$(command -v java)" 2>/dev/null || true)
        if [ -n "$java_bin" ] && [ -f "$java_bin" ]; then
            local resolved_dir
            resolved_dir=$(dirname "$(dirname "$java_bin")")
            if [ -d "$resolved_dir" ]; then
                jvm_path="$resolved_dir"
            fi
        fi
    fi

    echo "$jvm_path"
}

# ------------------------------------------------------------------------------
# 3. AYUDA, ESTADO Y ALTERNATIVAS
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
☕ Gestor y Optimizador de OpenJDK - openSUSE Tumbleweed (KDE Plasma 6 + AMD Ryzen)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala y optimiza OpenJDK (java-21-openjdk y java-21-openjdk-devel LTS),
                      Maven, certificados para AutoFirma/DNIe e integración con KDE Plasma 6.
  --status, -s        Muestra el diagnóstico completo del entorno Java, Maven, variables y JVMs.
  --alternatives, -a  Lista las JVMs instaladas y muestra las alternativas del sistema.
  --update, -u        Actualiza los paquetes de OpenJDK, Maven y certificados desde Zypper.
  --help, -h          Muestra este mensaje de ayuda.

EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DEL ENTORNO OPENJDK (OPENSUSE TUMBLEWEED + KDE PLASMA 6)"
    echo "================================================================="

    local java_ver javac_ver mvn_ver jvm_active cacerts_status
    local env_conf="$USER_HOME/.config/environment.d/10-java.conf"
    local bashrc_file="$USER_HOME/.bashrc.d/java.sh"
    local gradle_file="$USER_HOME/.gradle/gradle.properties"

    if command -v java &>/dev/null; then
        java_ver=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' || echo "Instalado")
    else
        java_ver="❌ No instalado"
    fi

    if command -v javac &>/dev/null; then
        javac_ver=$(javac -version 2>&1 | awk '{print $2}' || echo "Instalado")
    else
        javac_ver="❌ No disponible"
    fi

    if command -v mvn &>/dev/null; then
        mvn_ver=$(mvn -v 2>/dev/null | head -n 1 | awk '{print $3}' || echo "Instalado")
    else
        mvn_ver="ℹ️ No instalado"
    fi

    jvm_active=$(resolve_default_jvm)
    [ -z "$jvm_active" ] && jvm_active="No detectado"

    if [ -f "/var/lib/ca-certificates/java-cacerts" ] || [ -f "/etc/ssl/certs/java/cacerts" ]; then
        cacerts_status="✅ Sincronizado"
    else
        cacerts_status="⚠️ No encontrado (verificar ca-certificates)"
    fi

    echo "• Runtime Java:            $java_ver"
    echo "• Compilador Javac:        $javac_ver"
    echo "• Apache Maven:            $mvn_ver"
    echo "• JAVA_HOME detectado:     $jvm_active"
    echo "• Almacén CA (cacerts):    $cacerts_status"
    echo "• Hilos de compilación:    $NPROC hilos paralelos (Ryzen 7 PRO)"
    echo "• Entorno KDE Plasma 6:    $(if [ -f "$env_conf" ]; then echo "✅ Configurado ($env_conf)"; else echo "ℹ️ No presente"; fi)"
    echo "• Integración Bash:        $(if [ -f "$bashrc_file" ]; then echo "✅ Activo ($bashrc_file)"; else echo "ℹ️ No presente"; fi)"
    echo "• Aceleración Gradle:      $(if [ -f "$gradle_file" ]; then echo "✅ Optimizado ($gradle_file)"; else echo "ℹ️ No presente"; fi)"

    echo ""
    echo "📂 JVMs detectadas en el sistema:"
    for jdir in /usr/lib64/jvm /usr/lib/jvm; do
        if [ -d "$jdir" ]; then
            ls -d "$jdir"/* 2>/dev/null | sed 's/^/  • /' || true
        fi
    done
    echo "================================================================="
}

show_alternatives() {
    echo "================================================================="
    echo "🔄 ALTERNATIVAS DE JAVA EN OPENSUSE TUMBLEWEED"
    echo "================================================================="
    if command -v update-alternatives &>/dev/null; then
        echo "JVMs y enlaces gestionados por update-alternatives:"
        update-alternatives --display java 2>/dev/null || true
        echo ""
        echo "💡 Para seleccionar otra versión interactivamente, ejecuta:"
        echo "   sudo update-alternatives --config java"
    fi
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 4. CONTROL DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --alternatives|-a|alternatives)
        show_alternatives
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    --update|-u|update)
        echo "🔄 Actualizando OpenJDK y herramientas Java vía Zypper..."
        $SUDO zypper --non-interactive update -y \
            java-21-openjdk java-21-openjdk-devel maven 2>/dev/null || true
        echo "✅ Paquetes de Java actualizados con éxito."
        show_status
        exit 0
        ;;
esac

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN DE PAQUETES (IDEMPOTENTE Y COMPATIBLE CON OPENSUSE)
# ------------------------------------------------------------------------------
echo "================================================================="
echo "☕ Instalando y Optimizando OpenJDK para openSUSE Tumbleweed"
echo "================================================================="

REQUIRED_PKGS=(
    "java-21-openjdk"
    "java-21-openjdk-devel"
    "ca-certificates-cacerts"
    "maven"
    "curl"
    "pcsc-lite"
    "mozilla-nss-tools"
)

echo "ℹ️ [1/4] Verificando paquetes de OpenJDK y dependencias en Zypper..."
MISSING_PKGS=()
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! check_pkg "$pkg"; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "  📦 Paquetes a instalar desde repositorios oficiales: ${MISSING_PKGS[*]}"
    if ! command -v sudo &>/dev/null && [ "$EUID" -ne 0 ]; then
        echo "❌ Error: Se requieren permisos administrativos (sudo) para instalar: ${MISSING_PKGS[*]}"
        exit 1
    fi
    $SUDO zypper --non-interactive install -y "${MISSING_PKGS[@]}"
    echo "  ✅ Paquetes de OpenJDK y dependencias instalados."
else
    echo "  ✅ Todos los paquetes de OpenJDK y dependencias ya están instalados."
fi

# ------------------------------------------------------------------------------
# 6. CONFIGURACIÓN DE JVM POR DEFECTO
# ------------------------------------------------------------------------------
echo "ℹ️ [2/4] Resolviendo ruta de JVM por defecto en openSUSE..."
DEFAULT_JVM=$(resolve_default_jvm)

if [ -z "$DEFAULT_JVM" ] || [ ! -d "$DEFAULT_JVM" ]; then
    echo "❌ Error: No se pudo determinar el directorio de la JVM instalada."
    exit 1
fi
echo "  ✅ JAVA_HOME resuelto: $DEFAULT_JVM"

# ------------------------------------------------------------------------------
# 7. INTEGRACIÓN CON KDE PLASMA 6, WAYLAND Y SHELLS
# ------------------------------------------------------------------------------
echo "ℹ️ [3/4] Configurando variables de entorno para KDE Plasma 6 y Shells..."

ENV_DIR="$USER_HOME/.config/environment.d"
BASHRC_D="$USER_HOME/.bashrc.d"
run_as_user mkdir -p "$ENV_DIR" "$BASHRC_D"

# 7.1. Sesión gráfica KDE Plasma 6 (systemd user environment)
cat << EOF | run_as_user tee "$ENV_DIR/10-java.conf" > /dev/null
# OpenJDK Environment (KDE Plasma 6 + Wayland)
JAVA_HOME=$DEFAULT_JVM
PATH=\${JAVA_HOME}/bin:\${PATH}

# Integración gráfica Wayland KWin (evita ventanas grises en aplicaciones AWT/Swing)
_JAVA_AWT_WM_NONREPARENTING=1

# Suavizado de tipografías subpixel para pantallas 1080p
_JAVA_OPTIONS="-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true"

# Optimización multihilo para Apache Maven (AMD Ryzen 7 PRO 4750U: 16 hilos)
MAVEN_ARGS="-T 1C"
MAVEN_OPTS="-Xms512m -Xmx4096m -XX:+UseG1GC"
EOF

# 7.2. Shell Bash (predeterminada)
cat << EOF | run_as_user tee "$BASHRC_D/java.sh" > /dev/null
# OpenJDK Environment & Optimizations
if [ -d "$DEFAULT_JVM" ]; then
    export JAVA_HOME="$DEFAULT_JVM"
elif [ -d "/usr/lib64/jvm/java" ]; then
    export JAVA_HOME="/usr/lib64/jvm/java"
fi

if [ -n "\${JAVA_HOME:-}" ] && [ -d "\${JAVA_HOME}/bin" ]; then
    [[ ":\$PATH:" != *":\${JAVA_HOME}/bin:"* ]] && export PATH="\${JAVA_HOME}/bin:\$PATH"
fi

export _JAVA_AWT_WM_NONREPARENTING=1
export _JAVA_OPTIONS="-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true"
export MAVEN_ARGS="-T 1C"
export MAVEN_OPTS="-Xms512m -Xmx4096m -XX:+UseG1GC"
EOF

# 7.3. Shell Zsh (modular si existe ~/.zshrc)
if [ -f "$USER_HOME/.zshrc" ]; then
    ZSHRC_D="$USER_HOME/.zshrc.d"
    run_as_user mkdir -p "$ZSHRC_D"

    cat << EOF | run_as_user tee "$ZSHRC_D/java.zsh" > /dev/null
# OpenJDK Environment & Optimizations
if [ -d "$DEFAULT_JVM" ]; then
    export JAVA_HOME="$DEFAULT_JVM"
elif [ -d "/usr/lib64/jvm/java" ]; then
    export JAVA_HOME="/usr/lib64/jvm/java"
fi

if [ -n "\${JAVA_HOME:-}" ] && [ -d "\${JAVA_HOME}/bin" ]; then
    [[ ":\$PATH:" != *":\${JAVA_HOME}/bin:"* ]] && export PATH="\${JAVA_HOME}/bin:\$PATH"
fi

export _JAVA_AWT_WM_NONREPARENTING=1
export _JAVA_OPTIONS="-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true"
export MAVEN_ARGS="-T 1C"
export MAVEN_OPTS="-Xms512m -Xmx4096m -XX:+UseG1GC"
EOF
fi

# ------------------------------------------------------------------------------
# 8. ACELERACIÓN DE GRADLE PARA AMD RYZEN (16 HILOS / 32 GB RAM)
# ------------------------------------------------------------------------------
echo "ℹ️ [4/4] Configurando aceleración multinúcleo para Gradle..."
GRADLE_DIR="$USER_HOME/.gradle"
GRADLE_PROPS="$GRADLE_DIR/gradle.properties"
run_as_user mkdir -p "$GRADLE_DIR"

if [ ! -f "$GRADLE_PROPS" ] || ! grep -q "org.gradle.parallel" "$GRADLE_PROPS" 2>/dev/null; then
    cat << EOF | run_as_user tee "$GRADLE_PROPS" > /dev/null
# Optimizaciones de Gradle para AMD Ryzen 7 PRO (16 hilos) y 32 GB RAM
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.workers.max=$NPROC
org.gradle.caching=true
org.gradle.vfs.watch=true
org.gradle.jvmargs=-Xmx4g -XX:+UseG1GC -XX:+TieredCompilation -XX:TieredStopAtLevel=4
EOF
    echo "  ✅ Archivo ~/.gradle/gradle.properties optimizado con 16 workers y VFS watch."
else
    echo "  ✅ Archivo ~/.gradle/gradle.properties ya configurado."
fi

# ------------------------------------------------------------------------------
# 9. RESUMEN FINAL
# ------------------------------------------------------------------------------
JAVA_VER=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' || echo "Instalado")

echo "================================================================="
echo "✅ OpenJDK configurado con éxito para openSUSE Tumbleweed y KDE Plasma 6:"
echo "  • OpenJDK:        v$JAVA_VER"
echo "  • JAVA_HOME:      $DEFAULT_JVM"
echo "  • Compilación:    Maven y Gradle optimizados para $NPROC hilos paralelos"
echo "  • Memoria Heap:   Hasta 4 GB con recolector G1GC"
echo "  • KDE Plasma 6:   ~/.config/environment.d/10-java.conf (IDEs y Wayland)"
echo "  • Shells:         Bash (~/.bashrc.d/java.sh)$([ -f "$USER_HOME/.zshrc" ] && echo " & Zsh (~/.zshrc.d/java.zsh)")"
echo "================================================================="
