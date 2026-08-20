#!/bin/bash
# gnome-settings.sh - Personalización automatizada del escritorio GNOME para Manjaro Linux

set -euo pipefail

echo "🎨 Aplicando personalización y configuraciones de GNOME para Manjaro..."

if ! command -v gsettings &> /dev/null; then
    echo "⚠️ gsettings no está disponible en este entorno. Omitiendo."
    exit 0
fi

# 1. Luz Nocturna (Night Light) y Temperatura de Color Cálida
echo "ℹ️ Configurando Luz Nocturna (3500K)..."
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature uint32 3500 2>/dev/null || gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3500 2>/dev/null || true

# 2. Interfaz y Reloj
echo "ℹ️ Configurando formato de reloj 24h y porcentaje de batería..."
gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
gsettings set org.gnome.desktop.interface clock-show-weekday true 2>/dev/null || true
gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true

# 3. Ventanas y Botones
echo "ℹ️ Configurando botones de ventana (:minimize,maximize,close)..."
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' 2>/dev/null || true

# 4. Touchpad y Gestos
echo "ℹ️ Configurando Touchpad (Tap to click, natural scroll)..."
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true

# 5. Rendimiento y Wayland (VRR y escalado fraccional)
echo "ℹ️ Habilitando características experimentales de Mutter (VRR, Fractional Scaling)..."
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'variable-refresh-rate']" 2>/dev/null || true

# 6. Tema Oscuro
echo "ℹ️ Configurando tema oscuro global..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

echo "✅ Configuraciones de GNOME aplicadas correctamente en Manjaro."
