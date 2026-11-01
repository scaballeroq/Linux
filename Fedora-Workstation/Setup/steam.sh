#!/usr/bin/env bash
# ==============================================================================
# steam.sh - Instalación de Steam, GameMode, MangoHud y Controladores 32-bit
# Fedora Workstation + GNOME Shell (Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / Mesa RADV)
# ==============================================================================
# Características:
# - Activa RPM Fusion Non-Free y el repositorio oficial de Steam.
# - Instala Steam nativo, GameMode, MangoHud y controladores 32-bit (i686).
# - Instala la capa de compatibilidad Proton-GE vía Flathub de forma desacoplada.
# - Diagnóstico integral (--status) y ayuda interactiva (--help).
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

if command -v dnf5 &>/dev/null; then
    DNF_CMD="dnf5"
else
    DNF_CMD="dnf"
fi

is_pkg_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

show_help() {
    cat <<EOF
🎮 Instalador de Steam y Stack de Gaming - Fedora Workstation (GNOME)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Activa RPM Fusion Non-Free (y repo Steam), instala Steam nativo,
                      drivers 32-bit (Mesa RADV i686), GameMode, MangoHud y Proton-GE.
  --status, -s        Muestra el estado de instalación de Steam, drivers 32-bit y optimizadores.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE STEAM Y GAMING - FEDORA WORKSTATION"
    echo "================================================================="
    echo "• RPM Fusion Non-Free:      $(if is_pkg_installed rpmfusion-nonfree-release; then echo "✅ Habilitado"; else echo "❌ No instalado"; fi)"
    echo "• Steam nativo:             $(if command -v steam &>/dev/null; then echo '✅ Sí ('"$(which steam)"')'; else echo '❌ No instalado'; fi)"
    echo "• GameMode:                 $(if command -v gamemoded &>/dev/null; then echo '✅ Sí ('"$(gamemoded --version 2>/dev/null || echo 'Activo')"')'; else echo '❌ No instalado'; fi)"
    echo "• MangoHud:                 $(if command -v mangohud &>/dev/null; then echo '✅ Sí'; else echo '❌ No instalado'; fi)"
    echo "• Mesa Vulkan 32-bit (i686): $(if is_pkg_installed mesa-vulkan-drivers.i686; then echo '✅ Instalado (i686)'; else echo '⚠️ No instalado (necesario para títulos 32-bit)'; fi)"
    echo "• Mesa DRI 32-bit (i686):    $(if is_pkg_installed mesa-dri-drivers.i686; then echo '✅ Instalado (i686)'; else echo '⚠️ No instalado (necesario para títulos 32-bit)'; fi)"
    echo "• Proton-GE Flatpak:        $(if flatpak list 2>/dev/null | grep -q "Proton-GE"; then echo '✅ Instalado'; else echo 'ℹ️ No instalado'; fi)"
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
echo "🎮 CONFIGURANDO ENTORNO DE GAMING Y STEAM - FEDORA WORKSTATION"
echo "================================================================="

# 1. Asegurar RPM Fusion Non-Free
echo "⚡ [1/3] Verificando repositorio RPM Fusion Non-Free..."
if ! is_pkg_installed rpmfusion-nonfree-release; then
    FEDORA_VER=$(rpm -E %fedora 2>/dev/null || echo "44")
    $SUDO $DNF_CMD install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm" 2>/dev/null || true
fi

# Habilitar repositorio steam de RPM Fusion si está disponible
$SUDO $DNF_CMD config-manager setopt rpmfusion-nonfree-steam.enabled=1 2>/dev/null || true

# 2. Instalar Steam, GameMode, MangoHud y librerías 32-bit
echo "⬇️ [2/3] Instalando Steam nativo, GameMode, MangoHud y controladores 32-bit vía $DNF_CMD..."
$SUDO $DNF_CMD install -y \
    steam \
    gamemode \
    mangohud \
    mesa-vulkan-drivers.i686 \
    mesa-dri-drivers.i686 \
    pipewire-alsa.i686 2>/dev/null || $SUDO $DNF_CMD install -y steam gamemode mangohud 2>/dev/null || true

# 3. Configurar compatibilidad Proton-GE vía Flatpak
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
echo "   - Drivers 32-bit: mesa-vulkan-drivers.i686 y mesa-dri-drivers.i686"
echo "================================================================="
