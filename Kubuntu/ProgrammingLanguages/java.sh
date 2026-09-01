#!/bin/bash
# =============================================================================
# java.sh - Instalador de OpenJDK LTS y Configuración JAVA_HOME para Kubuntu
# =============================================================================
# - Instala OpenJDK (LTS por defecto), OpenJRE y dependencias de certificados (libnss3-tools / AutoFirma)
# - Detecta y configura automáticamente JAVA_HOME en ~/.bashrc.d/java.sh
# - Integra JAVA_HOME en ~/.config/environment.d/40-java.conf para IDEs de KDE Plasma
# =============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "Error: Este script requiere privilegios de superusuario."
        exit 1
    fi
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

show_help() {
    cat <<EOF
Instalador de Java OpenJDK - Kubuntu

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Instala OpenJDK LTS, libnss3-tools y configura JAVA_HOME.
  --status, -s           Muestra la versión de Java, ruta de JAVA_HOME y binarios.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE JAVA (OPENJDK) - KUBUNTU"
    echo "================================================================="
    echo "Java Runtime (java):           $(if command -v java &>/dev/null; then java -version 2>&1 | head -n1; else echo 'No instalado'; fi)"
    echo "Java Compiler (javac):         $(if command -v javac &>/dev/null; then javac -version 2>&1 | head -n1; else echo 'No instalado'; fi)"
    echo "JAVA_HOME detectado:           $(readlink -f /usr/bin/javac 2>/dev/null | sed 's:/bin/javac::' || echo 'n/a')"
    echo "Soporte NSS3 / AutoFirma:      $(if command -v certutil &>/dev/null; then echo 'Instalado (libnss3-tools)'; else echo 'No instalado'; fi)"
    echo "================================================================="
}

install_java() {
    echo "================================================================="
    echo "INSTALANDO OPENJDK LTS Y HERRAMIENTAS - KUBUNTU"
    echo "================================================================="

    echo "ℹ️ [1/3] Instalando OpenJDK, OpenJRE y herramientas de certificados..."
    $SUDO apt update
    $SUDO apt install -y \
        default-jdk \
        default-jre \
        libnss3-tools \
        2>/dev/null || true

    # 2. Detectar ruta real de JAVA_HOME
    echo "ℹ️ [2/3] Detectando ruta de instalación de JAVA_HOME..."
    JAVA_PATH=$(readlink -f /usr/bin/javac 2>/dev/null | sed 's:/bin/javac::' || true)
    if [ -z "$JAVA_PATH" ] && [ -d "/usr/lib/jvm/default-java" ]; then
        JAVA_PATH="/usr/lib/jvm/default-java"
    fi

    # 3. Configuración de variables de entorno para Bash y KDE Plasma
    echo "ℹ️ [3/3] Configurando variables de entorno para '$REAL_USER'..."
    run_as_user mkdir -p "$USER_HOME/.bashrc.d" "$USER_HOME/.config/environment.d"

    if [ -n "$JAVA_PATH" ]; then
        cat <<EOF > "$USER_HOME/.bashrc.d/java.sh"
# Java OpenJDK Environment
export JAVA_HOME="$JAVA_PATH"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF
        chown "$REAL_USER:$REAL_USER" "$USER_HOME/.bashrc.d/java.sh" 2>/dev/null || true

        cat <<EOF > "$USER_HOME/.config/environment.d/40-java.conf"
JAVA_HOME=$JAVA_PATH
PATH=$JAVA_PATH/bin:\$PATH
EOF
        chown "$REAL_USER:$REAL_USER" "$USER_HOME/.config/environment.d/40-java.conf" 2>/dev/null || true
    fi

    echo ""
    echo "================================================================="
    echo "✅ OpenJDK y dependencias de AutoFirma instaladas con éxito."
    echo "   - Versión   : $(java -version 2>&1 | head -n1 || echo 'OpenJDK')"
    echo "   - JAVA_HOME : ${JAVA_PATH:-Auto-detectado}"
    echo "================================================================="
}

case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    "")
        install_java
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
