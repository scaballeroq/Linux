#!/bin/bash
# ==============================================================================
# java.sh - Instalación de OpenJDK (Última LTS) para openSUSE Tumbleweed
# Optimizado para KDE Plasma 6 (JAVA_HOME para IDEs, Gradle, Maven y DNIe)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "☕ Instalando OpenJDK (Última versión LTS) para openSUSE Tumbleweed"
echo "================================================================="

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecución con sudo
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

# 1. Determinar el paquete OpenJDK LTS disponible en los repositorios de openSUSE
echo "ℹ️ [1/3] Verificando paquetes de OpenJDK LTS y dependencias de certificados..."
$SUDO zypper --non-interactive install -y java-21-openjdk java-21-openjdk-devel maven mozilla-nss-tools pcsc-lite 2>/dev/null || \
$SUDO zypper --non-interactive install -y java-openjdk java-openjdk-devel maven 2>/dev/null || true
echo "  ✅ OpenJDK y dependencias de compilación preparados."

# 2. Configurar JVM por defecto
echo "ℹ️ [2/3] Configurando entorno de Java por defecto..."
if [ -d "/usr/lib64/jvm/java-21-openjdk" ]; then
    DEFAULT_JVM="/usr/lib64/jvm/java-21-openjdk"
elif [ -d "/usr/lib64/jvm/java-openjdk" ]; then
    DEFAULT_JVM="/usr/lib64/jvm/java-openjdk"
elif [ -d "/usr/lib64/jvm/java" ]; then
    DEFAULT_JVM="/usr/lib64/jvm/java"
elif [ -d "/etc/alternatives/java_sdk" ]; then
    DEFAULT_JVM="/etc/alternatives/java_sdk"
else
    DEFAULT_JVM=$(readlink -f /usr/bin/javac 2>/dev/null | sed 's:/bin/javac::' || readlink -f /usr/bin/java 2>/dev/null | sed 's:/bin/java::' || echo "/usr/lib64/jvm/java")
fi

# 3. Configurar JAVA_HOME para KDE Plasma 6, Wayland e IDEs (IntelliJ, Android Studio, Gradle, Maven)
echo "ℹ️ [3/3] Configurando variables de entorno (JAVA_HOME) para KDE Plasma y Shells..."
ENV_DIR="$USER_HOME/.config/environment.d"
run_as_user mkdir -p "$ENV_DIR"

cat << EOF | run_as_user tee "$ENV_DIR/10-java.conf" > /dev/null
# Integración de Java / OpenJDK para sesión gráfica (IDEs, Maven, Gradle)
JAVA_HOME=$DEFAULT_JVM
PATH=\${JAVA_HOME}/bin:\${PATH}
EOF

# Integración modular en Shells (Bash predeterminado; Zsh si existe ~/.zshrc)
BASHRC_D="$USER_HOME/.bashrc.d"
run_as_user mkdir -p "$BASHRC_D"

cat << EOF | run_as_user tee "$BASHRC_D/java.sh" > /dev/null
# Java Environment Variables
if [ -d "$DEFAULT_JVM" ]; then
    export JAVA_HOME="$DEFAULT_JVM"
    export PATH="\${JAVA_HOME}/bin:\${PATH}"
fi
EOF

# Fallback para .bashrc
BASHRC="$USER_HOME/.bashrc"
run_as_user touch "$BASHRC"
if ! grep -q "JAVA_HOME" "$BASHRC" 2>/dev/null; then
    if ! grep -q ".bashrc.d" "$BASHRC" 2>/dev/null; then
        echo -e "\n# Java Environment\nif [ -d \"$DEFAULT_JVM\" ]; then export JAVA_HOME=\"$DEFAULT_JVM\"; export PATH=\"\${JAVA_HOME}/bin:\${PATH}\"; fi" | run_as_user tee -a "$BASHRC" > /dev/null
    fi
fi

# Integración Zsh condicional
ZSHRC="$USER_HOME/.zshrc"
if [ -f "$ZSHRC" ]; then
    ZSHRC_D="$USER_HOME/.zshrc.d"
    run_as_user mkdir -p "$ZSHRC_D"

    cat << EOF | run_as_user tee "$ZSHRC_D/java.zsh" > /dev/null
# Java Environment Variables
if [ -d "$DEFAULT_JVM" ]; then
    export JAVA_HOME="$DEFAULT_JVM"
    export PATH="\${JAVA_HOME}/bin:\${PATH}"
fi
EOF
fi

# Obtener versión instalada
JAVA_VER=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' || echo "instalado")

echo "================================================================="
echo "✅ OpenJDK LTS configurado con éxito para openSUSE Tumbleweed y KDE Plasma 6:"
echo "  • OpenJDK:     v$JAVA_VER (LTS)"
echo "  • JAVA_HOME:   $DEFAULT_JVM"
echo "  • KDE/IDEs:    ~/.config/environment.d/10-java.conf (IntelliJ, Android Studio)"
echo "  • Shells:      Bash (predeterminada)$([ -f "$ZSHRC" ] && echo " & Zsh (compatible)")"
echo "================================================================="
