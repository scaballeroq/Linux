#!/bin/bash
# laptop-setup.sh - Optimización para portátiles de desarrollo en Fedora 44 + GNOME

set -euo pipefail

echo "🚀 Iniciando optimización para portátil de desarrollo en Fedora 44 + GNOME..."

# 1. Herramientas de Hardware y Conectividad
echo "ℹ️ Instalando servicios de energía, bluetooth y gráficos híbridos..."
sudo dnf5 install -y \
    power-profiles-daemon \
    switcheroo-control \
    bluez \
    bluez-tools \
    brightnessctl \
    tuned \
    tuned-ppd 2>/dev/null || sudo dnf5 install -y power-profiles-daemon switcheroo-control bluez brightnessctl

# 2. Habilitación de servicios
echo "ℹ️ Habilitando servicios de energía y bluetooth..."
sudo systemctl enable --now power-profiles-daemon 2>/dev/null || true
sudo systemctl enable --now switcheroo-control 2>/dev/null || true
sudo systemctl enable --now bluetooth 2>/dev/null || true

# 3. Configuración de GSettings para Portátil (Touchpad, VRR, HiDPI)
if command -v gsettings &> /dev/null; then
    echo "ℹ️ Aplicando optimizaciones de Touchpad y pantalla para GNOME..."
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true
    gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 1800 2>/dev/null || true
fi

# 4. Servicio Systemd para fijar brillo al 95%
echo "ℹ️ Creando servicio de persistencia de brillo al 95%..."
sudo tee /etc/systemd/system/persist-screen-brightness.service > /dev/null << 'EOF'
[Unit]
Description=Fijar brillo de pantalla al 95% en el arranque
After=graphical.target systemd-user-sessions.service

[Service]
Type=oneshot
ExecStart=/usr/bin/brightnessctl set 95%
RemainAfterExit=yes

[Install]
WantedBy=graphical.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable persist-screen-brightness.service 2>/dev/null || true

echo "================================================================="
echo "✅ Optimización para portátil de desarrollo en Fedora 44 completada."
echo "================================================================="
