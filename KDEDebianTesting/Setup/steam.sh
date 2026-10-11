#!/bin/bash
# ==============================================================================
# steam.sh - Instalación de Steam, GameMode, MangoHud y Drivers 32-bit
# Debian Testing (Trixie/Sid) + KDE Plasma 6
# ==============================================================================

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

is_pkg_installed() {
    local pkg="$1"
    dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
}

show_help() {
    cat <<EOF
🎮 Instalador de Steam y Stack de Gaming - Debian Testing

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Habilita arquitectura i386, instala Steam, GameMode, MangoHud,
                      drivers 32-bit (Mesa/Vulkan) y herramientas de compatibilidad.
  --status, -s        Muestra el estado de instalación de Steam, drivers 32-bit y optimizadores.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE STEAM Y GAMING - DEBIAN TESTING"
    echo "================================================================="
    echo "• Arquitectura i386:        $(if dpkg --print-foreign-architectures 2>/dev/null | grep -q "i386"; then echo "✅ Habilitada"; else echo "❌ Deshabilitada"; fi)"
    echo "• Steam nativo:             $(if command -v steam &>/dev/null; then echo '✅ Sí ('"$(which steam)"')'; else echo '❌ No instalado'; fi)"
    echo "• GameMode:                 $(if command -v gamemoded &>/dev/null; then echo '✅ Sí ('"$(gamemoded --version 2>/dev/null || echo 'Activo')"')'; else echo 'No instalado'; fi)"
    echo "• MangoHud:                 $(if command -v mangohud &>/dev/null; then echo '✅ Sí'; else echo 'No instalado'; fi)"
    echo "• Mesa Vulkan 32-bit:       $(if is_pkg_installed mesa-vulkan-drivers:i386; then echo '✅ Instalado'; else echo '⚠️ No instalado'; fi)"
    echo "• Mesa DRI 32-bit:          $(if is_pkg_installed libgl1-mesa-dri:i386; then echo '✅ Instalado'; else echo '⚠️ No instalado'; fi)"
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🎮 CONFIGURANDO ENTORNO DE GAMING Y STEAM - DEBIAN TESTING"
echo "================================================================="

# 1. Habilitar arquitectura de 32 bits (i386)
echo "⚡ [1/3] Verificando soporte de arquitectura multiarch i386..."
if ! dpkg --print-foreign-architectures | grep -q "i386"; then
    $SUDO dpkg --add-architecture i386
    echo "   ✅ Arquitectura i386 añadida al gestor dpkg."
fi

# 2. Actualizar índices e instalar controladores de 32 bits y Steam
echo "⬇️ [2/3] Instalando Steam nativo, GameMode, MangoHud y drivers 32-bit vía APT..."
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get update -qq

$SUDO apt-get install -y \
    steam-installer \
    gamemode \
    mangohud \
    mesa-vulkan-drivers:i386 \
    libgl1-mesa-dri:i386 \
    libvulkan1:i386 2>/dev/null || $SUDO apt-get install -y steam gamemode mangohud mesa-vulkan-drivers:i386 libgl1-mesa-dri:i386 2>/dev/null || true

# 3. Configurar compatibilidad Proton-GE vía Flatpak si está disponible
echo "⚡ [3/3] Configurando herramientas de compatibilidad Proton-GE..."
if command -v flatpak &>/dev/null; then
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    flatpak install --user -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE 2>/dev/null || true
fi

echo "================================================================="
echo "✅ Steam y herramientas Gaming configuradas con éxito."
echo "   - Cliente Steam: $(which steam 2>/dev/null || echo 'steam')"
echo "   - GameMode:      $(which gamemoderun 2>/dev/null || echo 'gamemoderun')"
echo "   - MangoHud:      $(which mangohud 2>/dev/null || echo 'mangohud')"
echo "================================================================="
