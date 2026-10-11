#!/bin/bash
# =============================================================================
# kde-settings.sh - Configuración Base y Ajustes de KDE Plasma 6 (Kubuntu)
# =============================================================================
# Ajustes incluidos:
#   - Tema Global Oscuro: Kubuntu Dark (org.kubuntudark.desktop)
#   - Luz Nocturna (Night Color) desactivada
#   - Botones de Ventana (Minimizar, Maximizar, Cerrar a la derecha)
#   - Desactivación de pitidos molestos del sistema (System Bell)
#   - Atajos globales estándar (Ctrl+Alt+T para Konsole, Meta+E para Dolphin)
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
echo "CONFIGURANDO AJUSTES BASE DE KDE PLASMA 6 - KUBUNTU"
echo "================================================================="

# 1. Configuración de Tema Global Oscuro (Kubuntu Dark)
if command -v lookandfeeltool &> /dev/null; then
    echo "ℹ️ [1/5] Aplicando tema global Kubuntu Dark..."
    run_as_user lookandfeeltool -a org.kubuntudark.desktop 2>/dev/null || \
    run_as_user lookandfeeltool -a org.kde.breezedark.desktop 2>/dev/null || true
fi

# 2. Luz Nocturna (Night Color) Desactivada
echo "ℹ️ [2/5] Desactivando Luz Nocturna (Night Color)..."
set_kconfig "kwinrc" "NightColor" "Active" "false"

# 3. Comportamiento de Ventanas y Botones de KWin
echo "ℹ️ [3/5] Configurando botones de ventana y comportamiento de KWin..."
# Botones a la derecha: Minimizar (I), Maximizar (A), Cerrar (X)
set_kconfig "kwinrc" "org.kde.kdecoration2" "ButtonsOnRight" "IAX"
set_kconfig "kwinrc" "org.kde.kdecoration2" "ButtonsOnLeft" ""

# 4. Sonidos y Comportamiento General
echo "ℹ️ [4/5] Desactivando campana del sistema (System Bell)..."
set_kconfig "kdeglobals" "General" "UseSystemBell" "false"
set_kconfig "kdeglobals" "KDE" "SingleClick" "false"

# 5. Atajos estándar
echo "ℹ️ [5/5] Configurando atajos estándar de KDE..."
if command -v konsole &>/dev/null; then
    set_kconfig "kglobalshortcutsrc" "org.kde.konsole.desktop" "_launch" "Ctrl+Alt+T,Ctrl+Alt+T,Konsole"
fi
if command -v dolphin &>/dev/null; then
    set_kconfig "kglobalshortcutsrc" "org.kde.dolphin.desktop" "_launch" "Meta+E,none,Dolphin"
fi

# 6. Recargar configuraciones de KWin
if command -v qdbus6 &>/dev/null; then
    run_as_user qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
elif command -v qdbus &>/dev/null; then
    run_as_user qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

echo "================================================================="
echo "✅ Ajustes base de KDE Plasma 6 configurados con éxito."
echo "Tema: Kubuntu Dark | Luz Nocturna: Desactivada"
echo "================================================================="
