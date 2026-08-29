#!/bin/bash
# plymouth-setup.sh - Instalacion, configuracion y activacion de Splash Screen (Plymouth) en CachyOS + KDE Plasma
#
# Uso:
#   ./plymouth-setup.sh              -> Instala y activa el tema recomendado (breeze, bgrt o spinner)
#   ./plymouth-setup.sh <tema>       -> Instala y activa un tema especifico (ej: breeze, spinner, details, bgrt)
#   ./plymouth-setup.sh --list       -> Lista todos los temas disponibles e instalados
#   ./plymouth-setup.sh --preview    -> Previsualiza el splash screen actual en el escritorio
#   ./plymouth-setup.sh --disable    -> Desactiva el splash visual y vuelve a la visualizacion de logs detallados (details)

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no esta disponible."
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
echo "🎨 ADMINISTRADOR DE SPLASH SCREEN (PLYMOUTH) - CACHYOS (KDE PLASMA)"
echo "================================================================="

# 1. Instalacion de Plymouth y temas para KDE Plasma
ensure_plymouth_installed() {
    echo "ℹ️ Verificando e instalando Plymouth y temas para KDE Plasma en CachyOS..."
    $SUDO pacman -S --needed --noconfirm \
        plymouth \
        plymouth-theme-breeze \
        plymouth-theme-spinner 2>/dev/null || true
}

list_themes() {
    ensure_plymouth_installed
    echo "📌 Temas actualmente instalados en /usr/share/plymouth/themes/:"
    ls -1 /usr/share/plymouth/themes/ 2>/dev/null || echo "No se encontraron temas"
    echo ""
    echo "💡 Tema activo actual: $(cat /etc/plymouth/plymouthd.conf 2>/dev/null | grep "Theme=" | cut -d= -f2 || echo 'desconocido')"
}

preview_theme() {
    ensure_plymouth_installed
    echo "👁️ Iniciando previsualizacion de Plymouth durante 8 segundos..."
    $SUDO plymouthd 2>/dev/null || true
    $SUDO plymouth --show-splash
    for ((i=0; i<8; i++)); do
        sleep 1
    done
    $SUDO plymouth --quit
    echo "✅ Previsualizacion finalizada."
}

apply_theme() {
    local target_theme="$1"
    ensure_plymouth_installed

    echo "⚙️ Configurando tema Plymouth: '$target_theme'..."

    # Crear o actualizar configuracion de Plymouth
    $SUDO mkdir -p /etc/plymouth
    cat <<EOF | $SUDO tee /etc/plymouth/plymouthd.conf > /dev/null
[Plymouth Daemon]
Theme=$target_theme
EOF

    echo "🔄 Regenerando initramfs con mkinitcpio..."
    $SUDO mkinitcpio -P 2>/dev/null || echo "⚠️ mkinitcpio no disponible, regenera el initramfs manualmente."

    echo "================================================================="
    echo "✅ Tema Plymouth '$target_theme' activado con exito en CachyOS."
    echo "================================================================="
}

disable_plymouth() {
    ensure_plymouth_installed
    echo "⚙️ Desactivando splash grafico de Plymouth (estableciendo tema 'details')..."
    $SUDO mkdir -p /etc/plymouth
    cat <<EOF | $SUDO tee /etc/plymouth/plymouthd.conf > /dev/null
[Plymouth Daemon]
Theme=details
EOF

    echo "🔄 Regenerando initramfs con mkinitcpio..."
    $SUDO mkinitcpio -P 2>/dev/null || echo "⚠️ mkinitcpio no disponible, regenera el initramfs manualmente."

    echo "================================================================="
    echo "✅ Splash grafico desactivado. El arranque mostrara los mensajes del kernel/systemd."
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
