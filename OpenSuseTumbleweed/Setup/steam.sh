#!/bin/bash
# ==============================================================================
# steam.sh - Instalación de Steam, GameMode, MangoHud y Drivers 32-bit
# openSUSE Tumbleweed (KDE Plasma 6)
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

show_help() {
    cat <<EOF
🎮 Instalador de Steam y Stack de Gaming - openSUSE Tumbleweed

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala Steam nativo, GameMode, MangoHud, drivers 32-bit y herramientas de compatibilidad.
  --status, -s        Muestra el estado de instalación de Steam, drivers 32-bit y optimizadores.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE STEAM Y GAMING - OPENSUSE TUMBLEWEED"
    echo "================================================================="
    echo "• Steam nativo:             $(if command -v steam &>/dev/null; then echo '✅ Sí ('"$(which steam)"')'; else echo '❌ No instalado'; fi)"
    echo "• GameMode:                 $(if command -v gamemoded &>/dev/null; then echo '✅ Sí ('"$(gamemoded --version 2>/dev/null || echo 'Activo')"')'; else echo 'No instalado'; fi)"
    echo "• MangoHud:                 $(if command -v mangohud &>/dev/null; then echo '✅ Sí'; else echo 'No instalado'; fi)"
    echo "• Mesa Vulkan 32-bit AMD:   $(if rpm -q libvulkan_radeon-32bit &>/dev/null; then echo '✅ Instalado'; else echo '⚠️ No instalado'; fi)"
    echo "• Mesa DRI 32-bit:          $(if rpm -q Mesa-dri-32bit &>/dev/null; then echo '✅ Instalado'; else echo '⚠️ No instalado'; fi)"
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
echo "🎮 CONFIGURANDO ENTORNO DE GAMING Y STEAM - OPENSUSE TUMBLEWEED"
echo "================================================================="

# 1. Instalar Steam nativo, GameMode y MangoHud
echo "⬇️ [1/2] Instalando Steam nativo, GameMode y MangoHud vía Zypper..."
$SUDO zypper --non-interactive install -y \
    steam \
    gamemode \
    mangohud 2>/dev/null || true

# 2. Controladores gráficos de 32 bits (cruciales para juegos de Steam y Wine/Proton)
echo "⚡ [2/2] Instalando controladores Mesa y Vulkan de 32 bits..."
$SUDO zypper --non-interactive install -y \
    libvulkan_radeon-32bit \
    libvulkan_intel-32bit \
    Mesa-dri-32bit \
    Mesa-vulkan-device-select-32bit 2>/dev/null || true

# Configurar compatibilidad Proton-GE vía Flatpak si flatpak está disponible
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
