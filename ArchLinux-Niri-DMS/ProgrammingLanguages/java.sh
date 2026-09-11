#!/bin/bash
# ==============================================================================
# java.sh - Instalación de OpenJDK (Última LTS) y soporte AutoFirma en Arch Linux
# Optimizado para Niri / Wayland (JAVA_HOME para IDEs, Gradle, Maven y DNIe)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "☕ Instalando OpenJDK (Última versión LTS) para Arch Linux"
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

# 1. Determinar el paquete OpenJDK LTS más moderno disponible en los repositorios de Arch Linux
echo "ℹ️ [1/4] Verificando paquetes de OpenJDK LTS y dependencias de certificados..."

# Prioridad: JDK 25 LTS -> JDK 21 LTS -> JDK 17 LTS -> OpenJDK general
if pacman -Si jdk25-openjdk &>/dev/null; then
    JAVA_JDK_PKG="jdk25-openjdk"
    JAVA_JRE_PKG="jre25-openjdk"
elif pacman -Si jdk21-openjdk &>/dev/null; then
    JAVA_JDK_PKG="jdk21-openjdk"
    JAVA_JRE_PKG="jre21-openjdk"
elif pacman -Si jdk17-openjdk &>/dev/null; then
    JAVA_JDK_PKG="jdk17-openjdk"
    JAVA_JRE_PKG="jre17-openjdk"
else
    JAVA_JDK_PKG="jdk-openjdk"
    JAVA_JRE_PKG="jre-openjdk"
fi

# Dependencias para AutoFirma / Smartcards / DNIe y GUI AWT/Swing
SECURITY_PKGS="nss pcsclite"

REQUIRED_PKGS="$JAVA_JDK_PKG $JAVA_JRE_PKG $SECURITY_PKGS"
MISSING_PKGS=$(pacman -T $REQUIRED_PKGS 2>/dev/null || true)

if [ -n "$MISSING_PKGS" ]; then
    echo "  ⬇️ Instalando OpenJDK LTS y librerías del sistema: $MISSING_PKGS..."
    $SUDO pacman -S --needed --noconfirm $MISSING_PKGS
else
    echo "  ✅ OpenJDK LTS y dependencias ya instaladas."
fi

# Habilitar socket de pcscd para lectores de Smartcards/DNIe (AutoFirma)
$SUDO systemctl enable --now pcscd.socket 2>/dev/null || true

# 2. Configurar JVM LTS por defecto con archlinux-java
echo "ℹ️ [2/4] Configurando entorno de Java LTS por defecto..."
if command -v archlinux-java &>/dev/null; then
    # Buscar el JVM LTS instalado más reciente (25 -> 21 -> 17)
    LTS_JVM=$(archlinux-java status 2>/dev/null | grep -E "java-(25|21|17)-openjdk" | tail -n1 | awk '{print $1}' || true)
    if [ -n "$LTS_JVM" ]; then
        $SUDO archlinux-java set "$LTS_JVM" 2>/dev/null || true
    fi
fi

# 3. Vincular Java con Mise si está disponible
echo "ℹ️ [3/4] Vinculando OpenJDK del sistema con Mise..."
if command -v mise &>/dev/null || [ -x "$USER_HOME/.local/bin/mise" ]; then
    run_as_user mise use --global java@system 2>/dev/null || true
    run_as_user mise reshim 2>/dev/null || true
fi

# 4. Configurar JAVA_HOME para Niri, Wayland e IDEs (IntelliJ, Android Studio, Gradle, Maven)
echo "ℹ️ [4/4] Configurando variables de entorno (JAVA_HOME) para Niri y Shells..."
ENV_DIR="$USER_HOME/.config/environment.d"
run_as_user mkdir -p "$ENV_DIR"

cat << 'EOF' | run_as_user tee "$ENV_DIR/10-java.conf" > /dev/null
# Integración de Java / OpenJDK para Niri / Wayland y aplicaciones gráficas (IDEs, Maven, Gradle)
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

echo "✅ OpenJDK LTS configurado con éxito para Arch Linux y Niri / Wayland:"
echo "  • OpenJDK:      v$JAVA_VER (LTS)"
echo "  • JAVA_HOME:    /usr/lib/jvm/default"
echo "  • Gestor Mise:  Vinculado como runtime java@system"
echo "  • IDEs/Wayland: ~/.config/environment.d/10-java.conf (IntelliJ, Android Studio)"
echo "  • AutoFirma:   Soporte DNIe y Smartcards habilitado (nss, pcsclite)"
echo "  • Shells:      Bash & Zsh"
echo "================================================================="
