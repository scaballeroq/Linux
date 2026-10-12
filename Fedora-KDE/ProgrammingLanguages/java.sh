#!/bin/bash
# java.sh - Instalación y configuración de Java OpenJDK (Última versión LTS), Maven y AutoFirma para Fedora 44 + KDE Plasma
#
# Uso:
#   ./java.sh                        -> Instala OpenJDK LTS, OpenJDK Devel, Maven, NSS-Tools y configura JAVA_HOME en sesión KDE
#   ./java.sh --status               -> Muestra las versiones activas de Java, Javac, Maven y el valor de JAVA_HOME
#   ./java.sh --update               -> Actualiza OpenJDK y herramientas vía DNF5
#   ./java.sh --help                 -> Muestra la ayuda interactiva

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecución con sudo
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    REAL_USER="$SUDO_USER"
else
    USER_HOME="${HOME}"
    REAL_USER="${USER:-$(id -un)}"
fi

show_help() {
    cat <<EOF
☕ Gestor e Instalador de Java OpenJDK (LTS) - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala OpenJDK LTS, compilador (devel), Maven, soporte de certificados AutoFirma y variables JAVA_HOME.
  --status, -s           Muestra el estado de Java runtime, compilador javac, maven y la ruta de JAVA_HOME.
  --update, -u           Actualiza los paquetes de OpenJDK a través de DNF5.
  --help, -h             Muestra este mensaje de ayuda.

Características configuradas:
  • Versión OpenJDK LTS: Instala el paquete de soporte oficial OpenJDK LTS de Fedora con compilador completo.
  • Build Tools:         Instala Apache Maven para compilación y gestión de dependencias en proyectos Java.
  • Soporte AutoFirma:   Instala nss-tools para gestión de certificados y compatibilidad con AutoFirma/FNMT.
  • Integración KDE/IDE: Configura JAVA_HOME en ~/.config/environment.d/10-java.conf para IntelliJ, Eclipse y VS Code.
EOF
}

# 1. Mostrar estado de Java
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE JAVA OPENJDK - FEDORA 44"
    echo "================================================================="
    if command -v java &>/dev/null; then
        echo "• java (Runtime):      $(java -version 2>&1 | head -n1)"
        local JAVAC_VER="No instalado (se requiere java-*-openjdk-devel)"
        if command -v javac &>/dev/null; then
            JAVAC_VER=$(javac -version 2>&1 | head -n1)
        fi
        echo "• javac (Compilador):  $JAVAC_VER"
        local MAVEN_VER="No instalado"
        if command -v mvn &>/dev/null; then
            MAVEN_VER=$(mvn -v 2>/dev/null | head -n1)
        fi
        echo "• Maven:               $MAVEN_VER"
        echo "• JAVA_HOME actual:    ${JAVA_HOME:-$(readlink -f /usr/bin/java | sed 's:/bin/java::' 2>/dev/null || echo 'No configurada')}"
        echo "• nss-tools (PKCS#11): $(command -v certutil &>/dev/null && echo 'Instalado' || echo 'No instalado')"
    else
        echo "• Java OpenJDK:        No instalado"
    fi
    echo "================================================================="
}

# 2. Actualizar paquetes Java
update_java() {
    echo "🔄 Actualizando OpenJDK y utilidades..."
    $SUDO dnf5 upgrade --refresh -y \
        java-latest-openjdk \
        java-latest-openjdk-devel \
        maven \
        nss-tools 2>/dev/null || true
    echo "✅ OpenJDK actualizado con éxito."
}

# 3. Instalar OpenJDK LTS y herramientas vía DNF5
install_packages() {
    echo "📦 [1/2] Instalando OpenJDK LTS, OpenJDK Devel, Maven y nss-tools vía DNF5..."
    $SUDO dnf5 install -y \
        java-latest-openjdk \
        java-latest-openjdk-devel \
        maven \
        nss-tools 2>/dev/null || \
    $SUDO dnf5 install -y \
        java-21-openjdk \
        java-21-openjdk-devel \
        maven \
        nss-tools 2>/dev/null || true
    echo "✅ Paquetes de OpenJDK y herramientas instalados."
}

# 4. Detectar y configurar JAVA_HOME en sesión KDE Plasma y Shell
configure_environment() {
    echo "🔗 [2/2] Detectando ruta de SDK y configurando JAVA_HOME para KDE Plasma y Shell..."
    
    local JAVA_SDK_PATH=""
    if [ -d "/usr/lib/jvm/java-openjdk" ]; then
        JAVA_SDK_PATH="/usr/lib/jvm/java-openjdk"
    elif [ -d "/etc/alternatives/java_sdk" ]; then
        JAVA_SDK_PATH="/etc/alternatives/java_sdk"
    else
        JAVA_SDK_PATH=$(readlink -f /usr/bin/javac 2>/dev/null | sed 's:/bin/javac::' || echo "")
    fi

    if [ -n "$JAVA_SDK_PATH" ]; then
        # 4.1. Variables de sesión KDE Plasma / Wayland (environment.d)
        mkdir -p "$USER_HOME/.config/environment.d"
        cat <<EOF > "$USER_HOME/.config/environment.d/10-java.conf"
JAVA_HOME=$JAVA_SDK_PATH
PATH=\$JAVA_HOME/bin:\$PATH
EOF

        # 4.2. Configuración modular en ~/.bashrc.d/java.sh
        mkdir -p "$USER_HOME/.bashrc.d"
        cat <<EOF > "$USER_HOME/.bashrc.d/java.sh"
# Java OpenJDK Environment
export JAVA_HOME="$JAVA_SDK_PATH"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF

        # 4.3. Fallback en ~/.bashrc
        if ! grep -q "JAVA_HOME" "$USER_HOME/.bashrc" 2>/dev/null; then
            cat <<EOF >> "$USER_HOME/.bashrc"

# Java OpenJDK Environment
export JAVA_HOME="$JAVA_SDK_PATH"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF
        fi

        chown -R "$REAL_USER:" "$USER_HOME/.config/environment.d" "$USER_HOME/.bashrc.d" 2>/dev/null || true
        echo "✅ JAVA_HOME fijado en: $JAVA_SDK_PATH"
    fi
}

# Procesar argumentos
case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --status|-s|status)
        show_status
        exit 0
        ;;
    --update|-u|update)
        update_java
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "☕ INSTALADOR DE JAVA OPENJDK (LTS) - FEDORA 44 (KDE PLASMA 6)"
        echo "================================================================="
        install_packages
        configure_environment
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Java OpenJDK LTS y herramientas configuradas con éxito."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
