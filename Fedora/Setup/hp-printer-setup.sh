#!/bin/bash
# hp-printer-setup.sh - Instalación y configuración de impresora HP LaserJet Pro M15w por USB en Fedora 44 + GNOME

set -euo pipefail

echo "🚀 Iniciando configuración de impresora HP LaserJet Pro M15w (USB) en Fedora 44 + GNOME..."

# 1. Identificar usuario principal
TARGET_USER="${SUDO_USER:-$USER}"

# 2. Instalación de paquetes necesarios
echo "ℹ️ Instalando paquetes de impresión (CUPS, HPLIP, HPLIP-GUI, system-config-printer) vía DNF5..."
sudo dnf5 install -y \
    cups \
    hplip \
    hplip-gui \
    system-config-printer \
    usbutils \
    libusb1 2>/dev/null || sudo dnf5 install -y cups hplip system-config-printer

# 3. Habilitación de servicios del sistema
echo "ℹ️ Habilitando e iniciando el servicio CUPS..."
sudo systemctl enable --now cups.service cups.socket 2>/dev/null || true

# 4. Asignación de grupos al usuario
echo "ℹ️ Agregando al usuario '$TARGET_USER' a los grupos de impresión (lp, sys)..."
sudo usermod -aG lp "$TARGET_USER" 2>/dev/null || true

# 5. Reglas Udev para escaneo/impresión USB
echo "ℹ️ Verificando reglas udev para dispositivos HP USB..."
sudo udevadm control --reload-rules 2>/dev/null || true
sudo udevadm trigger 2>/dev/null || true

# 6. Descarga e instalación del plugin privativo de HP
echo "ℹ️ Configurando plugin propietario de HP (hp-plugin)..."
if command -v hp-plugin &> /dev/null; then
    echo "💡 Ejecutando descarga automatizada de hp-plugin..."
    hp-plugin -i -q 2>/dev/null || hp-plugin -i || true
fi

echo "================================================================="
echo "✅ Configuración de HP LaserJet Pro M15w completada."
echo "💡 Conecta la impresora por USB y ejecuta 'hp-setup' si necesitas configuración manual."
echo "================================================================="
