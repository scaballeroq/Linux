#!/bin/bash
# mise.sh - Instalador y configurador de Mise (Polyglot Tool & Runtime Version Manager) para Fedora 44 + KDE Plasma
#
# Uso:
#   ./mise.sh                        -> Instala Mise vía RPM oficial DNF5, configura autocompletado, sesión KDE y shell
#   ./mise.sh --status               -> Muestra el estado de instalación, herramientas activas y variables de entorno
#   ./mise.sh --update               -> Actualiza Mise y todos los runtimes/herramientas instaladas
#   ./mise.sh --help                 -> Muestra la ayuda interactiva

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
🚀 Instalador y Gestor de Mise - Fedora 44 (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)       Instala Mise vía DNF5, configura autocompletado, soporte modular bashrc y variables de sesión KDE/Wayland.
  --status, -s           Muestra el estado de Mise, herramientas instaladas y rutas de shims.
  --update, -u           Actualiza Mise y todos los runtimes/lenguajes instalados.
  --help, -h             Muestra este mensaje de ayuda.

Características configuradas:
  • Repositorio oficial RPM firmado con GPG para Fedora/DNF5.
  • Integración modular en ~/.bashrc.d/mise.sh y ~/.bashrc.
  • Autocompletado nativo en Bash para comandos de mise (mise use, ls, install, etc.).
  • Variables de sesión Wayland/KDE Plasma vía ~/.config/environment.d/10-mise.conf para que los IDEs (VSCode, JetBrains) reconozcan Node/Python/Rust automáticamente.
  • Configuración predeterminada (~/.config/mise/config.toml) con soporte para archivos heredados (.nvmrc, .node-version, etc.).
EOF
}

# 1. Mostrar estado de Mise
show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE MISE (VERSION MANAGER) - FEDORA 44"
    echo "================================================================="
    if command -v mise &>/dev/null; then
        echo "• Mise instalado:     $(mise --version 2>/dev/null || which mise)"
        echo "• Ruta del binario:   $(which mise)"
        echo "• Ruta de shims:      $USER_HOME/.local/share/mise/shims"
        echo "• Configuración:      $USER_HOME/.config/mise/config.toml"
        echo ""
        echo "📦 Herramientas y versiones instaladas:"
        mise ls 2>/dev/null || echo "  (Sin herramientas instaladas aún. Ejecuta ./nodejs.sh, ./python.sh, etc.)"
    else
        echo "• Mise instalado:     No"
    fi
    echo "================================================================="
}

# 2. Actualizar Mise y runtimes
update_mise() {
    echo "🔄 Actualizando Mise y herramientas instaladas..."
    if command -v dnf5 &>/dev/null && [ -f /etc/yum.repos.d/mise.repo ]; then
        $SUDO dnf5 upgrade --refresh -y mise 2>/dev/null || true
    fi
    if command -v mise &>/dev/null; then
        mise upgrade 2>/dev/null || true
        mise reshim 2>/dev/null || true
        echo "✅ Mise y todos sus runtimes han sido actualizados con éxito."
    fi
}

# 3. Instalación de Mise mediante repositorio oficial RPM
install_mise() {
    if ! command -v mise &> /dev/null; then
        echo "📦 [1/4] Configurando repositorio RPM oficial de Mise para DNF5..."
        $SUDO rpm --import https://mise.jdx.dev/gpg-key.pub 2>/dev/null || true
        $SUDO tee /etc/yum.repos.d/mise.repo > /dev/null << 'EOF'
[mise]
name=Mise
baseurl=https://mise.jdx.dev/rpm
enabled=1
gpgcheck=1
gpgkey=https://mise.jdx.dev/gpg-key.pub
EOF

        echo "📦 [2/4] Instalando Mise vía DNF5..."
        $SUDO dnf5 check-update --refresh || true
        $SUDO dnf5 install -y mise 2>/dev/null || {
            echo "⚠️ Falló la instalación por DNF5. Instalando vía script standalone oficial..."
            curl -fsSL https://mise.run | sh
        }
    else
        echo "📦 [1/4] Mise ya se encuentra instalado en el sistema ($(mise --version 2>/dev/null || echo 'OK'))."
    fi
}

# 4. Configuración global de Mise (~/.config/mise/config.toml)
configure_mise_settings() {
    echo "⚙️ [3/4] Generando configuración global de Mise..."
    mkdir -p "$USER_HOME/.config/mise"
    cat <<'EOF' > "$USER_HOME/.config/mise/config.toml"
[settings]
# Soporte para archivos de versiones heredados (.nvmrc, .node-version, .python-version, .tool-versions)
legacy_version_file = true

# Instalación asistida si no encuentra una versión
not_found_auto_install = true

# Características avanzadas
experimental = true
EOF
    chown -R "$REAL_USER:" "$USER_HOME/.config/mise" 2>/dev/null || true
}

# 5. Integración con Shell (Bash), Autocompletado y Sesión KDE Plasma
configure_shell_and_kde() {
    echo "🔗 [4/4] Configurando integración con Shell, autocompletado y sesión de KDE Plasma..."
    
    # 5.1. Variables de entorno de sesión KDE Plasma / Wayland (environment.d)
    # Permite que VS Code, PyCharm, KRunner y Dolphin hereden el PATH de shims de Mise
    mkdir -p "$USER_HOME/.config/environment.d"
    cat <<'EOF' > "$USER_HOME/.config/environment.d/10-mise.conf"
PATH=$HOME/.local/share/mise/shims:$PATH
EOF

    # 5.2. Configuración modular en ~/.bashrc.d/mise.sh (estándar Fedora)
    mkdir -p "$USER_HOME/.bashrc.d"
    cat <<'EOF' > "$USER_HOME/.bashrc.d/mise.sh"
# Mise (Language & Tool Version Manager)
export PATH="$HOME/.local/share/mise/shims:$PATH"
if command -v mise &>/dev/null; then
    eval "$(mise activate bash)"
fi
EOF

    # 5.3. Fallback directo en ~/.bashrc si .bashrc.d no es cargado automáticamente
    if ! grep -q "mise activate bash" "$USER_HOME/.bashrc" 2>/dev/null; then
        cat <<'EOF' >> "$USER_HOME/.bashrc"

# Mise (Language & Tool Version Manager)
export PATH="$HOME/.local/share/mise/shims:$PATH"
if command -v mise &>/dev/null; then
    eval "$(mise activate bash)"
fi
EOF
    fi

    # 5.4. Autocompletado nativo de Bash para comandos Mise
    mkdir -p "$USER_HOME/.local/share/bash-completion/completions"
    if command -v mise &>/dev/null; then
        mise completion bash > "$USER_HOME/.local/share/bash-completion/completions/mise" 2>/dev/null || true
    fi

    chown -R "$REAL_USER:" "$USER_HOME/.config" "$USER_HOME/.bashrc.d" "$USER_HOME/.local" 2>/dev/null || true
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
        update_mise
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🚀 CONFIGURADOR DE MISE - FEDORA 44 (KDE PLASMA 6)"
        echo "================================================================="
        install_mise
        configure_mise_settings
        configure_shell_and_kde
        echo ""
        echo "================================================================="
        echo "✅ Mise configurado correctamente para Fedora 44 y KDE Plasma."
        echo "💡 Para cargar el entorno en la sesión actual ejecuta:"
        echo "   source ~/.bashrc"
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
