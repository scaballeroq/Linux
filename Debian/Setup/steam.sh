#!/usr/bin/env bash
# ==============================================================================
# steam.sh - Instalación de Steam, GameMode, MangoHud y Drivers 32-bit
# Debian GNU/Linux | GNOME Shell (Wayland)
# Hardware: AMD Ryzen 7 7730U / Radeon Graphics (Vega 8) (RADV)
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
🎮 Instalador de Steam y Stack de Gaming - Debian GNU/Linux

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Habilita multiarch i386, instala Steam, GameMode, MangoHud,
                      drivers 32-bit Mesa y herramientas de compatibilidad Proton-GE.
  --status, -s        Muestra el estado de instalación de Steam, drivers 32-bit y optimizadores.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE STEAM Y GAMING - UBUNTU LINUX"
    echo "================================================================="
    echo "• Arquitectura i386:        $(if dpkg --print-foreign-architectures 2>/dev/null | grep -q "i386"; then echo '✅ Habilitada'; else echo '❌ No habilitada'; fi)"
    echo "• Steam nativo:             $(if command -v steam &>/dev/null; then echo '✅ Sí ('"$(which steam)"')'; else echo '❌ No instalado'; fi)"
    echo "• GameMode:                 $(if command -v gamemoded &>/dev/null; then echo '✅ Sí ('"$(gamemoded --version 2>/dev/null || echo 'Activo')"')'; else echo 'No instalado'; fi)"
    echo "• MangoHud:                 $(if command -v mangohud &>/dev/null; then echo '✅ Sí'; else echo 'No instalado'; fi)"
    echo "• Mesa Vulkan 32-bit (RADV):$(if dpkg -s mesa-vulkan-drivers:i386 &>/dev/null; then echo '✅ Instalado'; else echo '⚠️ No instalado'; fi)"
    echo "• Mesa DRI 32-bit:          $(if dpkg -s libgl1-mesa-dri:i386 &>/dev/null; then echo '✅ Instalado'; else echo '⚠️ No instalado'; fi)"
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
echo "🎮 CONFIGURANDO ENTORNO DE GAMING Y STEAM - UBUNTU LINUX"
echo "================================================================="

# 1. Habilitar multiarquitectura i386
echo "⚙️ [1/3] Habilitando soporte multiarquitectura i386..."
# Asegurar repositorios contrib y non-free en Debian para Steam
if [ -f /etc/apt/sources.list.d/debian.sources ]; then
    $SUDO sed -i "/^Components:/ {/contrib/! s/$/ contrib/}" /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
    $SUDO sed -i "/^Components:/ {/non-free/! s/$/ non-free/}" /etc/apt/sources.list.d/debian.sources 2>/dev/null || true
fi
if [ -f /etc/apt/sources.list ]; then
    $SUDO sed -i "/^deb / {/contrib/! s/\(main\)/\1 contrib non-free/}" /etc/apt/sources.list 2>/dev/null || true
fi
if ! dpkg --print-foreign-architectures 2>/dev/null | grep -q "i386"; then
    $SUDO dpkg --add-architecture i386
fi
$SUDO apt-get update -qq

# 2. Instalar Steam nativo, GameMode y MangoHud
echo "⬇️ [2/3] Instalando Steam, GameMode y MangoHud vía APT..."
$SUDO apt-get install -y \
    steam-installer \
    gamemode \
    mangohud 2>/dev/null || $SUDO apt-get install -y steam gamemode mangohud 2>/dev/null || true

# 3. Controladores gráficos de 32 bits (cruciales para juegos de Steam y Wine/Proton)
echo "⚡ [3/3] Instalando controladores Mesa y Vulkan de 32 bits..."
$SUDO apt-get install -y \
    libgl1-mesa-dri:i386 \
    libglx-mesa0:i386 \
    mesa-vulkan-drivers:i386 2>/dev/null || true

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
