#!/bin/bash
# gnome-settings.sh - Personalización de GNOME vía CLI (gsettings) para Debian

set -euo pipefail

echo "🚀 Iniciando personalización de GNOME..."

if [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]] || command -v gsettings &>/dev/null; then
    # 1. Luz Nocturna (Night Light)
    echo "ℹ️ Configurando Luz Nocturna..."
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature uint32 3500 2>/dev/null || gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3500 2>/dev/null || true

    # 2. Formato de reloj (24h) y batería
    echo "ℹ️ Configurando formato de reloj y visualización de batería..."
    gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true

    # 3. Mostrar botones de minimizar, maximizar y cerrar en las ventanas
    echo "ℹ️ Habilitando botones de minimizar/maximizar..."
    gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' 2>/dev/null || true

    # 4. Touchpad y gestos para portátil
    echo "ℹ️ Configurando gestos y Touchpad..."
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true

    # 5. Comportamiento de energía
    echo "ℹ️ Configurando políticas de energía..."
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true

    # 6. Tema oscuro preferido (GNOME 42+)
    echo "ℹ️ Estableciendo esquema de color preferido (Oscuro)..."
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

    echo "✅ Personalización de GNOME completada correctamente."
else
    echo "⚠️ Advertencia: No se detectó un entorno GNOME activo. GSettings no se aplicaron."
fi
