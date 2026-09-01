#!/bin/bash
# =============================================================================
# kde-widgets.sh - Widgets, Klipper y Atajos de Productividad para KDE Plasma 6
# =============================================================================
# Ajustes incluidos:
#   - kdeplasma-addons y plasma-systemmonitor
#   - Klipper (Historial de portapapeles de 100 elementos + persistencia)
#   - KWin Tiling (Mosaico rápido de ventanas nativo)
#   - Atajos globales de productividad:
#       * Meta+V: Menú emergente de portapapeles
#       * Meta+W: Vista general (Overview) de ventanas
#       * Meta+G: Rejilla de escritorios virtuales (Grid View)
#       * Alt+Tab: Cambio rápido de aplicaciones
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

set_kconfig() {
    local file="$1"
    local group="$2"
    local key="$3"
    local value="$4"

    if command -v kwriteconfig6 &>/dev/null; then
        run_as_user kwriteconfig6 --file "$file" --group "$group" --key "$key" "$value" 2>/dev/null || true
    elif command -v kwriteconfig5 &>/dev/null; then
        run_as_user kwriteconfig5 --file "$file" --group "$group" --key "$key" "$value" 2>/dev/null || true
    else
        local target="$USER_HOME/.config/$file"
        run_as_user mkdir -p "$(dirname "$target")"
        touch "$target" 2>/dev/null || true
        if grep -q "^\[$group\]" "$target" 2>/dev/null; then
            if grep -A 100 "^\[$group\]" "$target" | grep -q "^$key="; then
                sed -i "/^\[$group\]/,/^\[/ s|^$key=.*|$key=$value|" "$target"
            else
                sed -i "/^\[$group\]/a $key=$value" "$target"
            fi
        else
            printf "\n[%s]\n%s=%s\n" "$group" "$key" "$value" >> "$target"
        fi
    fi
}

echo "================================================================="
echo "CONFIGURANDO WIDGETS, KLIPPER Y ATAJOS - KDE PLASMA 6"
echo "================================================================="

# 1. Instalar complementos oficiales de KDE Plasma
echo "ℹ️ [1/4] Instalando kdeplasma-addons y plasma-systemmonitor..."
$SUDO apt update
$SUDO apt install -y kdeplasma-addons plasma-systemmonitor 2>/dev/null || true

# 2. Configurar Klipper (Historial de Portapapeles)
echo "ℹ️ [2/4] Configurando historial y sincronización de Klipper..."
set_kconfig "klipperrc" "General" "MaxClipItems" "100"
set_kconfig "klipperrc" "General" "IgnoreSelection" "false"
set_kconfig "klipperrc" "General" "SyncClipboards" "true"
set_kconfig "klipperrc" "General" "KeepClipboardContents" "true"

# 3. Configurar KWin Tiling (Mosaico de Ventanas)
echo "ℹ️ [3/4] Configurando mosaico de ventanas KWin Tiling..."
set_kconfig "kwinrc" "Tiling" "padding" "4"
set_kconfig "kwinrc" "Windows" "ElectricBorders" "1"
set_kconfig "kwinrc" "Windows" "ElectricBorderDelay" "150"

# 4. Configurar Atajos Globales de Navegación
echo "ℹ️ [4/4] Configurando atajos globales de Plasma 6..."
set_kconfig "kglobalshortcutsrc" "kwin" "Overview" "Meta+W,none,Alternar vista general"
set_kconfig "kglobalshortcutsrc" "kwin" "Grid View" "Meta+G,none,Alternar vista de cuadrícula"
set_kconfig "kglobalshortcutsrc" "kwin" "Walk Through Windows" "Alt+Tab,none,Recorrer ventanas"
set_kconfig "kglobalshortcutsrc" "plasmashell" "clipboard_history" "Meta+V,none,Mostrar portapapeles"

# 5. Recargar KWin
if command -v qdbus6 &>/dev/null; then
    run_as_user qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
elif command -v qdbus &>/dev/null; then
    run_as_user qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

echo "================================================================="
echo "✅ Widgets, Klipper y Atajos de KDE Plasma configurados."
echo "Atajos activos:"
echo "  - Meta + V : Historial de Portapapeles (Klipper)"
echo "  - Meta + W : Vista General de Ventanas (Overview)"
echo "  - Meta + G : Vista de Cuadrícula de Escritorios (Grid)"
echo "  - Meta + T : Editor de Mosaico (KWin Tiling)"
echo "================================================================="
