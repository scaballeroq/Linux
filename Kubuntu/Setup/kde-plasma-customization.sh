#!/bin/bash
# =============================================================================
# kde-plasma-customization.sh - Personalización Visual Avanzada KDE Plasma 6
# =============================================================================
# Ajustes incluidos:
#   - Color de Acento Dinámico nativo desde el Fondo de Pantalla (Material You)
#   - Efectos visuales de KWin en Wayland (Blur y Translucidez activos)
#   - Instalación de plasmoids oficiales y monitor de sistema
#   - Recarga en caliente sin reiniciar la sesión
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
echo "CONFIGURANDO PERSONALIZACIÓN VISUAL - KDE PLASMA 6"
echo "================================================================="

# 1. Color de Acento Dinámico Nativo de Plasma 6 (Material You)
echo "ℹ️ [1/3] Habilitando color de acento dinámico según fondo de pantalla..."
set_kconfig "kdeglobals" "General" "accentColorFromWallpaper" "true"

# 2. Efectos visuales de KWin (Blur y Translucidez)
echo "ℹ️ [2/3] Activando efectos de desenfoque (Blur) y translucidez en KWin..."
set_kconfig "kwinrc" "Plugins" "blurEnabled" "true"
set_kconfig "kwinrc" "Plugins" "translucencyEnabled" "true"
set_kconfig "kwinrc" "Plugins" "contrastEnabled" "true"

# 3. Plasmoids y Addons Oficiales
echo "ℹ️ [3/3] Verificando complementos oficiales..."
$SUDO apt update
$SUDO apt install -y kdeplasma-addons plasma-systemmonitor 2>/dev/null || true

# 4. Recargar KWin
echo "Aplicando cambios en KWin..."
if command -v qdbus6 &>/dev/null; then
    run_as_user qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
elif command -v qdbus &>/dev/null; then
    run_as_user qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

echo "================================================================="
echo "✅ Personalización visual de KDE Plasma 6 completada."
echo "  - Color de acento automático desde el wallpaper (Nativo Plasma 6)"
echo "  - Efectos Blur, Contraste y Translucidez activos en KWin"
echo "  - Addons oficiales y monitor de sistema instalados"
echo "================================================================="
