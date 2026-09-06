#!/bin/bash
# ==============================================================================
# java.sh - Instalación de OpenJDK (Última LTS) y soporte AutoFirma en CachyOS
# Optimizado para KDE Plasma 6 (JAVA_HOME para IDEs, Gradle, Maven y DNIe)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "☕ Instalando OpenJDK (Última versión LTS) para CachyOS"
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

# 1. Determinar el paquete OpenJDK LTS más moderno disponible en los repositorios de CachyOS
echo "ℹ️ [1/3] Verificando paquetes de OpenJDK LTS y dependencias de certificados..."

# Prioridad: JDK 25 LTS -> JDK 21 LTS -> OpenJDK general
if pacman -Si jdk25-openjdk &>/dev/null; then
    JAVA_JDK_PKG="jdk25-openjdk"
    JAVA_JRE_PKG="jre25-openjdk"
elif pacman -Si jdk21-openjdk &>/dev/null; then
    JAVA_JDK_PKG="jdk21-openjdk"
    JAVA_JRE_PKG="jre21-openjdk"
else
    JAVA_JDK_PKG="jdk-openjdk"
    JAVA_JRE_PKG="jre-openjdk"
fi

# Dependencias para AutoFirma / Smartcards / DNIe y GUI AWT/Swing
SECURITY_PKGS="nss pcsclite"

REQUIRED_PKGS="$JAVA_JDK_PKG $JAVA_JRE_PKG $SECURITY_PKGS"
MISSING_PKGS=$(pacman -T $REQUIRED_PKGS 2>/dev/null || true)

if [ -n "$MISSING_PKGS" ]; then
    echo "  ⬇️ Instalando OpenJDK y librerías del sistema: $MISSING_PKGS..."
    $SUDO pacman -S --needed --noconfirm $MISSING_PKGS
else
    echo "  ✅ OpenJDK y dependencias ya instaladas."
fi

# 2. Configurar JVM por defecto con archlinux-java
echo "ℹ️ [2/3] Configurando entorno de Java por defecto..."
if command -v archlinux-java &>/dev/null; then
    # Buscar el JVM LTS instalado más reciente
    LTS_JVM=$(archlinux-java status 2>/dev/null | grep -E "java-(25|21|26)-openjdk" | tail -n1 | awk '{print $1}' || true)
    if [ -n "$LTS_JVM" ]; then
        $SUDO archlinux-java set "$LTS_JVM" 2>/dev/null || true
    fi
fi

# 3. Configurar JAVA_HOME para KDE Plasma 6, Wayland e IDEs (IntelliJ, Android Studio, Gradle, Maven)
echo "ℹ️ [3/3] Configurando variables de entorno (JAVA_HOME) para KDE Plasma 6 y Shells..."
ENV_DIR="$USER_HOME/.config/environment.d"
run_as_user mkdir -p "$ENV_DIR"

cat << 'EOF' | run_as_user tee "$ENV_DIR/10-java.conf" > /dev/null
# Integración de Java / OpenJDK para KDE Plasma 6 y aplicaciones gráficas (IDEs, Maven, Gradle)
JAVA_HOME=/usr/lib/jvm/default
PATH=${JAVA_HOME}/bin:${PATH}
EOF

# Integración modular en Shells (Bash y Zsh)
BASHRC_D="$USER_HOME/.bashrc.d"
ZSHRC_D="$USER_HOME/.zshrc.d"
run_as_user mkdir -p "$BASHRC_D" "$ZSHRC_D"

cat << 'EOF' | run_as_user tee "$BASHRC_D/java.sh" > /dev/null
# Java Environment Variables
if [ -d "/usr/lib/jvm/default" ]; then
    export JAVA_HOME="/usr/lib/jvm/default"
    export PATH="${JAVA_HOME}/bin:${PATH}"
fi
EOF

cat << 'EOF' | run_as_user tee "$ZSHRC_D/java.zsh" > /dev/null
# Java Environment Variables
if [ -d "/usr/lib/jvm/default" ]; then
    export JAVA_HOME="/usr/lib/jvm/default"
    export PATH="${JAVA_HOME}/bin:${PATH}"
fi
EOF

# Fallback para .bashrc y .zshrc
if [ -f "$USER_HOME/.bashrc" ] && ! grep -q "JAVA_HOME" "$USER_HOME/.bashrc" 2>/dev/null; then
    if ! grep -q ".bashrc.d" "$USER_HOME/.bashrc" 2>/dev/null; then
        echo -e '\n# Java Environment\nif [ -d "/usr/lib/jvm/default" ]; then export JAVA_HOME="/usr/lib/jvm/default"; export PATH="${JAVA_HOME}/bin:${PATH}"; fi' | run_as_user tee -a "$USER_HOME/.bashrc" > /dev/null
    fi
fi

# Obtener versión instalada
JAVA_VER=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' || echo "instalado")

echo "================================================================="
echo "✅ OpenJDK LTS configurado con éxito para CachyOS y KDE Plasma 6:"
echo "  • OpenJDK:     v$JAVA_VER (LTS)"
echo "  • JAVA_HOME:   /usr/lib/jvm/default"
echo "  • KDE/IDEs:    ~/.config/environment.d/10-java.conf (IntelliJ, Android Studio)"
echo "  • AutoFirma:   Soporte DNIe y Smartcards habilitado (nss, pcsclite)"
echo "  • Shells:      Bash & Zsh"
echo "================================================================="
