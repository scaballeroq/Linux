flatpak install flathub com.valvesoftware.Steam

set -euo pipefail

echo "ℹ️ Verificando instalación de Flatpak..."
if ! command -v flatpak &>/dev/null; then
    echo "❌ Error: Flatpak no está instalado. Ejecuta post-install.sh primero."
    exit 1
fi

echo "ℹ️ Asegurando que Flathub está configurado..."
if ! flatpak remote-list | grep -q flathub; then
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

echo "ℹ️ Instalando Steam..."
flatpak install -y flathub com.valvesoftware.Steam

echo "ℹ️ Instalando Proton-GE (compatibilidad mejorada)..."
flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE

echo "✅ Steam y Proton-GE instalados correctamente."
