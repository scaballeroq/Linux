#!/bin/bash
# ==============================================================================
# steam.sh - Instalación de Steam, Repositorio RPM Fusion Nonfree y Utilidades Gaming
# Fedora 44 Workstation (GNOME)
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
🎮 Instalador de Steam y Stack de Gaming - Fedora 44 Workstation

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Activa el repositorio RPM Fusion Nonfree (y repo steam), instala Steam nativo,
                      drivers Vulkan 32-bit (i686), GameMode y MangoHud.
  --status, -s        Muestra el estado de instalación de Steam, drivers 32-bit y herramientas.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE STEAM Y GAMING - FEDORA 44"
    echo "================================================================="
    echo "• RPM Fusion Non-Free:      $(rpm -q rpmfusion-nonfree-release 2>/dev/null || echo 'No instalado')"
    echo "• Steam nativo instalado:   $(if command -v steam &>/dev/null; then echo '✅ Sí ('"$(which steam)"')'; else echo '❌ No instalado'; fi)"
    echo "• GameMode instalado:       $(if command -v gamemoded &>/dev/null; then echo '✅ Sí ('"$(gamemoded --version 2>/dev/null || echo 'Activo')"')'; else echo 'No instalado'; fi)"
    echo "• MangoHud instalado:       $(if command -v mangohud &>/dev/null; then echo '✅ Sí'; else echo 'No instalado'; fi)"
    echo "• Mesa Vulkan 32-bit (i686): $(if rpm -q mesa-vulkan-drivers.i686 &>/dev/null; then echo '✅ Instalado'; else echo '⚠️ No instalado (necesario para títulos 32-bit)'; fi)"
    echo "• Mesa DRI 32-bit (i686):    $(if rpm -q mesa-dri-drivers.i686 &>/dev/null; then echo '✅ Instalado'; else echo '⚠️ No instalado'; fi)"
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
echo "🎮 CONFIGURANDO ENTORNO DE GAMING Y STEAM - FEDORA 44"
echo "================================================================="

# 1. Asegurar repositorio RPM Fusion Nonfree y Steam
echo "📦 [1/3] Habilitando repositorios RPM Fusion Non-Free y repositorio Steam..."
$SUDO dnf5 install -y \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm 2>/dev/null || true

# Activar explícitamente el repositorio de steam si existe en la configuración
$SUDO dnf5 config-manager setopt rpmfusion-nonfree-steam.enabled=1 2>/dev/null || true

# 2. Instalar Steam nativo y herramientas de optimización
echo "⬇️ [2/3] Instalando Steam nativo, GameMode y MangoHud..."
$SUDO dnf5 install -y \
    steam \
    gamemode \
    mangohud 2>/dev/null || true

# 3. Controladores gráficos de 32-bit (cruciales para juegos de Steam y compatibilidad Proton/Wine)
echo "⚡ [3/3] Instalando controladores Mesa y Vulkan de 32-bit (i686)..."
$SUDO dnf5 install -y \
    mesa-vulkan-drivers.i686 \
    mesa-dri-drivers.i686 2>/dev/null || true

echo "================================================================="
echo "✅ Steam y entorno de Gaming configurados con éxito."
echo "   - Cliente Steam: $(which steam 2>/dev/null || echo 'steam')"
echo "   - Optimizador GameMode: $(which gamemoderun 2>/dev/null || echo 'gamemoderun')"
echo "   - Overlay MangoHud: $(which mangohud 2>/dev/null || echo 'mangohud')"
echo "   - Drivers 32-bit: mesa-vulkan-drivers.i686 y mesa-dri-drivers.i686"
echo "================================================================="
