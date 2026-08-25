#!/bin/bash
# laptop-setup.sh - Optimización para portátiles en Fedora 44 (KDE Plasma 6)
#
# Configura:
# 1. Servicios de energía modernos (TuneD / tuned-ppd / power-profiles-daemon)
# 2. Conectividad Bluetooth y control de gráficos híbridos (switcheroo-control)
# 3. Utilidades de brillo (brightnessctl)
# 4. Configuración del Touchpad para KDE Plasma (Tap-to-click)

set -euo pipefail

echo "================================================================="
echo "💻 Iniciando optimización para portátil en Fedora 44 (KDE Plasma)"
echo "================================================================="

# 1. Herramientas de Hardware, Energía y Conectividad
echo "ℹ️ [1/3] Instalando servicios de energía, bluetooth y gráficos híbridos..."
sudo dnf5 install -y \
    tuned \
    tuned-ppd \
    switcheroo-control \
    bluez \
    bluez-tools \
    brightnessctl 2>/dev/null || true

# 2. Habilitación de servicios
echo "ℹ️ [2/3] Habilitando servicios de energía, bluetooth y GPU híbrida..."
sudo systemctl enable --now tuned 2>/dev/null || true
sudo systemctl enable --now tuned-ppd 2>/dev/null || true
sudo systemctl enable --now switcheroo-control 2>/dev/null || true
sudo systemctl enable --now bluetooth 2>/dev/null || true

# 3. Configuración de Touchpad para KDE Plasma 6 (y fallback GNOME)
echo "ℹ️ [3/3] Configurando opciones de Touchpad en KDE Plasma..."

# A) KDE Plasma 6 (kcminputrc)
if command -v kwriteconfig6 &>/dev/null; then
    # Habilitar pulsar para hacer clic (Tap-to-click) en Touchpad
    kwriteconfig6 --file kcminputrc --group "Libinput" --group "Touchpad" --key "tapToClick" "true" 2>/dev/null || true
    kwriteconfig6 --file kcminputrc --group "Libinput" --key "tapToClick" "true" 2>/dev/null || true
fi

# B) Fallback para aplicaciones GNOME / GTK si están instaladas
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true
    gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true
fi

echo "================================================================="
echo "✅ Optimización para portátil en Fedora 44 completada."
echo "💡 El perfil de energía (Ahorro / Equilibrado / Rendimiento) se gestiona"
echo "   automáticamente desde el widget de batería de KDE Plasma."
echo "================================================================="

