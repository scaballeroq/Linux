#!/bin/bash
# =============================================================================
# mise.sh - Instalador y Configurador de Mise para Kubuntu (KDE Plasma 6)
# =============================================================================
# - Añade el repositorio oficial APT de Mise con clave GPG
# - Instala el binario mise y dependencias
# - Configura la activación automática en ~/.bashrc.d/mise.sh
# - Integra shims en KDE Plasma vía environment.d para IDEs gráficos (VS Code, Antigravity)
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
Instalador y Configurador de Mise - Kubuntu

Uso:
  $0 [OPCION]

Opciones:
  (sin argumentos)       Instala Mise, configura ~/.bashrc.d y la integración con KDE Plasma.
  --status, -s           Muestra la versión de Mise, herramientas instaladas y estado de integración.
  --help, -h             Muestra esta ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "ESTADO DE MISE (LANGUAGE VERSION MANAGER) - KUBUNTU"
    echo "================================================================="
    echo "Mise Binario:                  $(command -v mise 2>/dev/null || echo 'No instalado')"
    echo "Versión de Mise:               $(if command -v mise &>/dev/null; then mise --version 2>/dev/null; else echo 'n/a'; fi)"
    echo "Módulo Bash (~/.bashrc.d):     $(if [ -f "$USER_HOME/.bashrc.d/mise.sh" ]; then echo 'Configurado'; else echo 'No presente'; fi)"
    echo "Integración KDE Environment:   $(if [ -f "$USER_HOME/.config/environment.d/20-mise.conf" ]; then echo 'Configurado'; else echo 'No presente'; fi)"
    echo "Directorio Shims:              $USER_HOME/.local/share/mise/shims"
    echo "================================================================="
    if command -v mise &>/dev/null; then
        echo ""
        echo "Herramientas activas gestionadas por Mise:"
        run_as_user mise ls 2>/dev/null || echo "  (Sin herramientas instaladas aún)"
    fi
}

install_mise() {
    echo "================================================================="
    echo "INSTALANDO MISE (VERSION MANAGER) - KUBUNTU"
    echo "================================================================="

    if ! command -v mise &> /dev/null; then
        echo "ℹ️ [1/4] Instalando dependencias de APT..."
        $SUDO apt update
        $SUDO apt install -y curl gpg ca-certificates

        echo "ℹ️ [2/4] Añadiendo repositorio APT oficial de Mise..."
        $SUDO mkdir -p -m 755 /etc/apt/keyrings
        if [ ! -f /etc/apt/keyrings/mise-archive-keyring.gpg ]; then
            curl -fsSL https://mise.jdx.dev/gpg-key.pub | $SUDO gpg --dearmor -o /etc/apt/keyrings/mise-archive-keyring.gpg
        fi

        echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$(dpkg --print-architecture)] https://mise.jdx.dev/deb stable main" | $SUDO tee /etc/apt/sources.list.d/mise.list > /dev/null

        echo "ℹ️ [3/4] Instalando paquete mise..."
        $SUDO apt update
        $SUDO apt install -y mise
        echo "✅ Binario mise instalado."
    else
        echo "✅ Mise ya se encuentra instalado en el sistema."
    fi

    echo "ℹ️ [4/4] Configurando integraciones para '$REAL_USER'..."

    # 1. Integración modular con Bash (.bashrc.d)
    run_as_user mkdir -p "$USER_HOME/.bashrc.d"
    cat <<'EOF' > "$USER_HOME/.bashrc.d/mise.sh"
# Mise (Language Version Manager)
if command -v mise &>/dev/null; then
    eval "$(mise activate bash)"
fi
EOF
    chown "$REAL_USER:$REAL_USER" "$USER_HOME/.bashrc.d/mise.sh" 2>/dev/null || true

    # Si .bashrc no carga .bashrc.d, añadir fallback
    if [ ! -d "$USER_HOME/.bashrc.d" ] || ! grep -q "\.bashrc\.d" "$USER_HOME/.bashrc" 2>/dev/null; then
        if ! grep -q "mise activate bash" "$USER_HOME/.bashrc" 2>/dev/null; then
            echo -e '\n# Mise (Language Version Manager)\nif command -v mise &>/dev/null; then\n    eval "$(mise activate bash)"\nfi' >> "$USER_HOME/.bashrc"
        fi
    fi

    # 2. Integración con KDE Plasma 6 (environment.d)
    # Permite que IDEs gráficos lanzados desde el menú de aplicaciones (Antigravity, VS Code, JetBrains) reconozcan los runtimes
    run_as_user mkdir -p "$USER_HOME/.config/environment.d"
    cat <<'EOF' > "$USER_HOME/.config/environment.d/20-mise.conf"
PATH=$HOME/.local/share/mise/shims:$PATH
EOF
    chown "$REAL_USER:$REAL_USER" "$USER_HOME/.config/environment.d/20-mise.conf" 2>/dev/null || true

    echo ""
    echo "================================================================="
    echo "✅ Mise instalado y configurado correctamente para Kubuntu."
    echo "   - Bash: Activo en ~/.bashrc.d/mise.sh"
    echo "   - KDE Plasma: Shims integrados en ~/.config/environment.d/20-mise.conf"
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
        install_mise
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
