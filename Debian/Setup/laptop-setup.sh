#!/bin/bash
# laptop-setup.sh - Optimización para portátiles de desarrollo en Debian Testing + GNOME

set -euo pipefail

echo "🚀 Iniciando optimización para portátil de desarrollo en Debian Testing + GNOME..."

# 1. Herramientas de Hardware y Conectividad
echo "ℹ️ Instalando servicios de energía, bluetooth y gráficos híbridos..."
sudo apt update
sudo apt install -y \
    power-profiles-daemon \
    switcheroo-control \
    bluez \
    bluez-tools \
    brightnessctl

# Habilitar servicios clave de portátil
echo "ℹ️ Habilitando servicios systemd para portátil..."
sudo systemctl enable --now bluetooth.service || true
sudo systemctl enable --now power-profiles-daemon.service || true
sudo systemctl enable --now switcheroo-control.service || true

# 2. Configuración de Brillo de Pantalla al 95% en cada arranque
echo "ℹ️ Configurando servicio systemd para fijar el brillo de pantalla al 95% al arrancar..."
sudo tee /etc/systemd/system/set-screen-brightness.service > /dev/null << 'EOF'
[Unit]
Description=Fijar brillo de pantalla al 95% al iniciar el sistema
After=systemd-backlight@*.service systemd-udevd.service
Wants=systemd-udevd.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'for dev in /sys/class/backlight/*; do if [ -e "$dev/max_brightness" ]; then max=$(cat "$dev/max_brightness"); val=$(( max * 95 / 100 )); echo "$val" > "$dev/brightness" 2>/dev/null || true; fi; done'
RemainAfterExit=yes

[Install]
WantedBy=graphical.target multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now set-screen-brightness.service || true

# 3. Autostart de GNOME para asegurar el 95% de brillo al iniciar sesión
mkdir -p "${HOME}/.config/autostart"
cat << 'EOF' > "${HOME}/.config/autostart/set-screen-brightness.desktop"
[Desktop Entry]
Type=Application
Name=Set Brightness 95%
Exec=/bin/sh -c 'brightnessctl set 95% 2>/dev/null || for dev in /sys/class/backlight/*; do if [ -e "$dev/max_brightness" ]; then max=$(cat "$dev/max_brightness"); val=$(( max * 95 / 100 )); echo "$val" > "$dev/brightness" 2>/dev/null || true; fi; done'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=Ajusta el brillo de la pantalla al 95% al iniciar sesión
EOF

# 4. Configuraciones de GSettings para Portátil (Touchpad, Pantalla y Energía)
if [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]] || command -v gsettings &>/dev/null; then
    echo "ℹ️ Aplicando configuraciones de Touchpad y pantalla para GNOME..."

    # Gestos y Touchpad
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true

    # Escalado Fraccional y Tasa de Refresco Variable (VRR)
    gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'variable-refresh-rate']" 2>/dev/null || true

    # Comportamiento de energía en batería
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1200 2>/dev/null || true
    gsettings set org.gnome.desktop.privacy idle-delay 600 2>/dev/null || true
fi

echo "================================================================="
echo "✅ Configuración de portátil para Debian Testing + GNOME aplicada correctamente."
echo "💡 El brillo de la pantalla se fijará al 95% automáticamente en cada arranque."
echo "💡 Recuerda reiniciar la sesión para que todos los cambios de GNOME entren en vigor."
echo "================================================================="
