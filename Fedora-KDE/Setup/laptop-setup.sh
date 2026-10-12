#!/bin/bash
# laptop-setup.sh - Optimización para portátil en Fedora 44 (KDE Plasma)

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

echo "================================================================="
echo "💻 Iniciando optimización para portátil en Fedora 44 (KDE Plasma)"
echo "================================================================="

# 1. Herramientas de Hardware, Energía y Conectividad
echo "ℹ️ [1/4] Instalando servicios de energía, bluetooth y gráficos híbridos..."
$SUDO dnf5 install -y \
    tuned \
    tuned-ppd \
    switcheroo-control \
    bluez \
    bluez-tools \
    brightnessctl 2>/dev/null || true

# 2. Habilitación de servicios del sistema
echo "ℹ️ [2/4] Habilitando servicios de energía, bluetooth y GPU híbrida..."
$SUDO systemctl enable --now tuned 2>/dev/null || true
$SUDO systemctl enable --now tuned-ppd 2>/dev/null || true
$SUDO systemctl enable --now switcheroo-control 2>/dev/null || true
$SUDO systemctl enable --now bluetooth 2>/dev/null || true

# 3. Configuración de Touchpad y Energía para KDE Plasma
echo "ℹ️ [3/4] Aplicando optimizaciones de Touchpad y ahorro de batería en KDE Plasma..."
if command -v kwriteconfig6 &> /dev/null; then
    # Touchpad: Tap-to-click y desplazamiento natural
    kwriteconfig6 --file kcminputrc --group Touchpad --key tapToClick true 2>/dev/null || true
    kwriteconfig6 --file kcminputrc --group Touchpad --key naturalScroll true 2>/dev/null || true
    kwriteconfig6 --file touchpadrsrc --group General --key tapToClick true 2>/dev/null || true
    kwriteconfig6 --file touchpadrsrc --group General --key naturalScroll true 2>/dev/null || true

    # Gestión de Energía en Plasma 6 (PowerDevil: suspensión automática con batería a los 30 min)
    kwriteconfig6 --file powerdevilrc --group Battery --group SuspendAndShutdown --key AutoSuspendIdleTimeoutSec 1800 2>/dev/null || true
    kwriteconfig6 --file powerdevilrc --group Battery --group SuspendAndShutdown --key AutoSuspendAction 1 2>/dev/null || true
    echo "✅ Ajustes de KDE Plasma 6 configurados."
elif command -v kwriteconfig5 &> /dev/null; then
    kwriteconfig5 --file kcminputrc --group Touchpad --key tapToClick true 2>/dev/null || true
    kwriteconfig5 --file kcminputrc --group Touchpad --key naturalScroll true 2>/dev/null || true
    echo "✅ Ajustes de KDE Plasma 5 configurados."
fi

# 4. Servicio Systemd para fijar brillo al 95% al arrancar
echo "ℹ️ [4/4] Creando servicio de persistencia de brillo al 95%..."
$SUDO tee /etc/systemd/system/persist-screen-brightness.service > /dev/null << 'EOF'
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

$SUDO systemctl daemon-reload
$SUDO systemctl enable persist-screen-brightness.service 2>/dev/null || true

echo "================================================================="
echo "✅ Optimización para portátil en Fedora 44 (KDE Plasma) completada."
echo "💡 El perfil de energía (Ahorro / Equilibrado / Rendimiento) se gestiona"
echo "   automáticamente desde el widget de batería de KDE Plasma vía tuned-ppd."
echo "================================================================="
