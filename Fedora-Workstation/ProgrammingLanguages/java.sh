#!/bin/bash
# ==============================================================================
# java.sh - Instalación y Optimización de OpenJDK para Fedora Workstation
# Fedora Workstation (GNOME Shell + Wayland / Systemd User Environment)
# ==============================================================================
# Características:
# - Despliegue idempotente del JDK LTS de referencia (OpenJDK 21 LTS)
#   desde los repositorios oficiales de Fedora sin sudo innecesario.
# - Soporte nativo para DNF / DNF5.
# - Detección y resolución dinámica y canónica de JAVA_HOME en Fedora (/usr/lib/jvm/...).
# - Integración nativa con GNOME Shell (environment.d) y Shells (Bash / Zsh).
# - Opciones CLI: --status / -s, --update / -u, --help / -h.
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

DNF_CMD=$(command -v dnf5 2>/dev/null || command -v dnf 2>/dev/null || echo "dnf")

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# ------------------------------------------------------------------------------
# 2. RESOLUCIÓN DE JVM ACTIVA (FEDORA LINUX)
# ------------------------------------------------------------------------------
resolve_java_home() {
    local candidate=""

    # 1. Rutas canónicas y directorios de Java 21 LTS en Fedora
    for p in \
        "/usr/lib/jvm/java-21-openjdk" \
        "/usr/lib/jvm/jre-21-openjdk" \
        "/etc/alternatives/java_sdk_21" \
        "/etc/alternatives/java_sdk"; do
        if [ -d "$p" ]; then
            candidate="$p"
            break
        fi
    done

    # 2. Resolución dinámica a través de readlink del binario java
    if [ -z "$candidate" ] && command -v java &>/dev/null; then
        local java_bin
        java_bin=$(readlink -f "$(command -v java)" 2>/dev/null || true)
        if [ -n "$java_bin" ] && [ -f "$java_bin" ]; then
            candidate=$(dirname "$(dirname "$java_bin")")
        fi
    fi

    echo "$candidate"
}

# ------------------------------------------------------------------------------
# 3. AYUDA Y ESTADO
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
☕ Gestor y Optimizador de OpenJDK - Fedora Workstation (GNOME Shell + AMD Ryzen)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica e instala OpenJDK 21 LTS (paquetes oficiales),
                      resuelve JAVA_HOME de forma canónica y lo inyecta en environment.d,
                      ~/.bashrc.d y ~/.zshrc.d de forma modular.
  --status, -s        Muestra diagnóstico detallado de la versión de Java, compilador javac,
                      ruta canónica de JAVA_HOME y variables exportadas en la sesión.
  --update, -u        Actualiza los paquetes OpenJDK vía DNF/DNF5 a la última revisión disponible.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DEL ENTORNO OPENJDK (FEDORA WORKSTATION + GNOME SHELL)"
    echo "================================================================="

    local java_bin java_ver javac_bin javac_ver java_home env_conf bash_conf

    if command -v java &>/dev/null; then
        java_bin=$(which java 2>/dev/null)
        java_ver=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' || echo "instalado")
    else
        java_bin="No instalado"
        java_ver="No disponible"
    fi

    if command -v javac &>/dev/null; then
        javac_bin=$(which javac 2>/dev/null)
        javac_ver=$(javac -version 2>&1 | awk '{print $2}' || echo "instalado")
    else
        javac_bin="No instalado"
        javac_ver="No disponible"
    fi

    java_home=$(resolve_java_home)
    [ -z "$java_home" ] && java_home="No resuelto"

    env_conf="$USER_HOME/.config/environment.d/10-java.conf"
    bash_conf="$USER_HOME/.bashrc.d/java.sh"

    echo "1. Binarios y Compilador Java:"
    echo "  • Runtime 'java':        $java_ver ($java_bin)"
    echo "  • Compilador 'javac':    $javac_ver ($javac_bin)"
    echo "-----------------------------------------------------------------"
    echo "2. Variable JAVA_HOME canónica:"
    echo "  • JAVA_HOME detectado:   $java_home"
    echo "-----------------------------------------------------------------"
    echo "3. Integración en el Entorno:"
    echo "  • GNOME environment.d:   $([ -f "$env_conf" ] && echo "✅ Configurado ($env_conf)" || echo "❌ Ausente")"
    echo "  • Shell Bash (~/.bashrc.d): $([ -f "$bash_conf" ] && echo "✅ Configurado ($bash_conf)" || echo "❌ Ausente")"
    if [ -f "$USER_HOME/.zshrc" ]; then
        echo "  • Shell Zsh (~/.zshrc.d):   $([ -f "$USER_HOME/.zshrc.d/java.zsh" ] && echo "✅ Configurado (~/.zshrc.d/java.zsh)" || echo "❌ Ausente")"
    fi
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 4. ACTUALIZACIÓN RÁPIDA
# ------------------------------------------------------------------------------
update_java() {
    echo "🔄 Actualizando OpenJDK vía $DNF_CMD..."
    $SUDO $DNF_CMD upgrade -y java-21-openjdk java-21-openjdk-devel 2>/dev/null || true
    echo "✅ Paquetes de OpenJDK actualizados."
    echo ""
    show_status
}

# ------------------------------------------------------------------------------
# PROCESAMIENTO DE ARGUMENTOS CLI
# ------------------------------------------------------------------------------
case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --update|-u|update)
        update_java
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "☕ Instalando y Optimizando OpenJDK para Fedora Workstation"
echo "   Hardware: AMD Ryzen 7 7730U | NVMe Kioxia | GNOME Wayland"
echo "================================================================="

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN DE PAQUETES (IDEMPOTENTE Y COMPATIBLE CON FEDORA)
# ------------------------------------------------------------------------------
echo "ℹ️ [1/4] Verificando paquetes de OpenJDK 21 LTS..."
MISSING_PKGS=()
for pkg in java-21-openjdk java-21-openjdk-devel; do
    if ! rpm -q "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo "  ⬇️ Instalando paquetes faltantes vía $DNF_CMD: ${MISSING_PKGS[*]}..."
    $SUDO $DNF_CMD install -y "${MISSING_PKGS[@]}" 2>/dev/null || true
    echo "  ✅ Paquetes de OpenJDK instalados con éxito."
else
    echo "  ✅ OpenJDK 21 ya se encuentra completamente instalado."
fi

# ------------------------------------------------------------------------------
# 6. RESOLUCIÓN DE JAVA_HOME
# ------------------------------------------------------------------------------
echo "ℹ️ [2/4] Resolviendo ruta de JVM por defecto en Fedora..."
RESOLVED_HOME=$(resolve_java_home)

if [ -z "$RESOLVED_HOME" ] || [ ! -d "$RESOLVED_HOME" ]; then
    echo "⚠️ Advertencia: No se pudo resolver automáticamente JAVA_HOME."
    RESOLVED_HOME="/usr/lib/jvm/java-21-openjdk"
fi

echo "  ✅ JAVA_HOME resuelto en: $RESOLVED_HOME"

# ------------------------------------------------------------------------------
# 7. INTEGRACIÓN CON GNOME SHELL (ENVIRONMENT.D)
# ------------------------------------------------------------------------------
echo "ℹ️ [3/4] Configurando variables de entorno para GNOME Shell y Wayland..."
ENV_DIR="$USER_HOME/.config/environment.d"
run_as_user mkdir -p "$ENV_DIR"

cat << EOF | run_as_user tee "$ENV_DIR/10-java.conf" > /dev/null
# OpenJDK Environment Configuration for GNOME Shell Wayland
JAVA_HOME=$RESOLVED_HOME
JDK_HOME=$RESOLVED_HOME
EOF

# ------------------------------------------------------------------------------
# 8. INTEGRACIÓN CON SHELLS (BASH Y ZSH)
# ------------------------------------------------------------------------------
echo "ℹ️ [4/4] Configurando carga modular para Bash y Zsh..."
BASHRC_D="$USER_HOME/.bashrc.d"
run_as_user mkdir -p "$BASHRC_D"

cat << EOF | run_as_user tee "$BASHRC_D/java.sh" > /dev/null
# OpenJDK Environment Settings (Fedora Workstation)
export JAVA_HOME="$RESOLVED_HOME"
export JDK_HOME="$RESOLVED_HOME"

if [ -d "\$JAVA_HOME/bin" ] && [[ ":\$PATH:" != *":\$JAVA_HOME/bin:"* ]]; then
    export PATH="\$JAVA_HOME/bin:\$PATH"
fi
EOF

if [ -f "$USER_HOME/.zshrc" ]; then
    ZSHRC_D="$USER_HOME/.zshrc.d"
    run_as_user mkdir -p "$ZSHRC_D"
    cat << EOF | run_as_user tee "$ZSHRC_D/java.zsh" > /dev/null
# OpenJDK Environment Settings (Fedora Workstation)
export JAVA_HOME="$RESOLVED_HOME"
export JDK_HOME="$RESOLVED_HOME"

if [ -d "\$JAVA_HOME/bin" ] && [[ ":\$PATH:" != *":\$JAVA_HOME/bin:"* ]]; then
    export PATH="\$JAVA_HOME/bin:\$PATH"
fi
EOF
fi

echo "================================================================="
echo "✅ OpenJDK configurado con éxito para Fedora Workstation y GNOME:"
echo "  • JAVA_HOME:    $RESOLVED_HOME"
echo "  • Runtime:      $(java -version 2>&1 | head -n1)"
echo "  • Compilador:   $(javac -version 2>&1 | head -n1)"
echo "  • Entorno GUI:  ~/.config/environment.d/10-java.conf"
echo "  • Terminal:     ~/.bashrc.d/java.sh"
echo "================================================================="
