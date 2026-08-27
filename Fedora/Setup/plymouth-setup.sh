#!/bin/bash
# plymouth-setup.sh - Instalación, configuración y activación de Splash Screen (Plymouth) en Fedora 44 + KDE Plasma
#
# Uso:
#   ./plymouth-setup.sh              -> Instala y activa el tema recomendado (breeze, bgrt o spinner)
#   ./plymouth-setup.sh <tema>       -> Instala y activa un tema específico (ej: breeze, spinner, details, bgrt)
#   ./plymouth-setup.sh --list       -> Lista todos los temas disponibles e instalados
#   ./plymouth-setup.sh --preview    -> Previsualiza el splash screen actual en el escritorio
#   ./plymouth-setup.sh --disable    -> Desactiva el splash visual y vuelve a la visualización de logs detallados (details)

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar modo UEFI
IS_UEFI=false
if [ -d "/sys/firmware/efi" ]; then
    IS_UEFI=true
fi

echo "================================================================="
echo "🎨 ADMINISTRADOR DE SPLASH SCREEN (PLYMOUTH) - FEDORA 44 (KDE PLASMA)"
echo "================================================================="

# 1. Instalación de Plymouth y temas para KDE Plasma
ensure_plymouth_installed() {
    echo "ℹ️ Verificando e instalando Plymouth, módulo KCM y temas para KDE Plasma en Fedora..."
    $SUDO dnf5 install -y \
        plymouth \
        plymouth-plugin-two-step \
        plymouth-theme-spinner \
        plymouth-theme-breeze \
        plymouth-kcm \
        plymouth-system-theme 2>/dev/null || $SUDO dnf5 install -y plymouth plymouth-theme-spinner plymouth-theme-breeze 2>/dev/null || true
}

list_themes() {
    ensure_plymouth_installed
    echo "📌 Temas actualmente instalados en /usr/share/plymouth/themes/:"
    plymouth-set-default-theme --list || ls -1 /usr/share/plymouth/themes/
    echo ""
    echo "💡 Tema activo actual: $(plymouth-set-default-theme || echo 'desconocido')"
}

preview_theme() {
    ensure_plymouth_installed
    echo "👁️ Iniciando previsualización de Plymouth durante 8 segundos..."
    $SUDO plymouthd 2>/dev/null || true
    $SUDO plymouth --show-splash
    for ((i=0; i<8; i++)); do
        sleep 1
    done
    $SUDO plymouth --quit
    echo "✅ Previsualización finalizada."
}

apply_theme() {
    local target_theme="$1"
    ensure_plymouth_installed

    echo "⚙️ Configurando tema Plymouth: '$target_theme'..."
    $SUDO plymouth-set-default-theme -R "$target_theme" 2>/dev/null || {
        $SUDO plymouth-set-default-theme "$target_theme"
        echo "🔄 Regenerando initramfs con Dracut..."
        $SUDO dracut -f
    }

    echo "================================================================="
    echo "✅ Tema Plymouth '$target_theme' activado con éxito en Fedora 44."
    echo "================================================================="
}

disable_plymouth() {
    ensure_plymouth_installed
    echo "⚙️ Desactivando splash gráfico de Plymouth (estableciendo tema 'details')..."
    $SUDO plymouth-set-default-theme -R details 2>/dev/null || {
        $SUDO plymouth-set-default-theme details
        echo "🔄 Regenerando initramfs con Dracut..."
        $SUDO dracut -f
    }
    echo "================================================================="
    echo "✅ Splash gráfico desactivado. El arranque mostrará los mensajes del kernel/systemd."
    echo "================================================================="
}

# Procesar argumentos
if [ $# -eq 0 ]; then
    if [ -d "/usr/share/plymouth/themes/breeze" ]; then
        apply_theme "breeze"
    elif [ "$IS_UEFI" = true ] && [ -d "/usr/share/plymouth/themes/bgrt" ]; then
        apply_theme "bgrt"
    else
        apply_theme "spinner"
    fi
    exit 0
fi

case "$1" in
    --list|-l|list)
        list_themes
        ;;
    --preview|-p|preview)
        preview_theme
        ;;
    --disable|-d|disable)
        disable_plymouth
        ;;
    *)
        apply_theme "$1"
        ;;
esac
