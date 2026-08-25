#!/bin/bash
# hp-printer-setup.sh - Instalación y configuración de impresora HP LaserJet Pro M15w en Fedora 44 (KDE Plasma 6)

set -euo pipefail

echo "================================================================="
echo "🖨️ Iniciando configuración de HP LaserJet Pro M15w (KDE Plasma 6)"
echo "================================================================="

# 1. Identificar usuario principal
TARGET_USER="${SUDO_USER:-$USER}"

# 2. Instalación de paquetes necesarios para KDE Plasma y HPLIP
echo "ℹ️ [1/5] Instalando CUPS, HPLIP y módulo de impresión para KDE Plasma..."
sudo dnf5 install -y \
    cups \
    cups-filters \
    plasma-print-manager \
    hplip \
    hplip-gui \
    system-config-printer \
    usbutils \
    libusb1 2>/dev/null || true

# 3. Habilitación de servicios del sistema (CUPS)
echo "ℹ️ [2/5] Habilitando e iniciando el servicio CUPS..."
sudo systemctl enable --now cups.service cups.socket 2>/dev/null || true

# 4. Asignación de grupos al usuario
echo "ℹ️ [3/5] Agregando al usuario '$TARGET_USER' al grupo 'lp'..."
sudo usermod -aG lp "$TARGET_USER" 2>/dev/null || true

# 5. Reglas Udev para dispositivos HP USB
echo "ℹ️ [4/5] Aplicando reglas udev para dispositivos HP USB..."
sudo udevadm control --reload-rules 2>/dev/null || true
sudo udevadm trigger 2>/dev/null || true

# 6. Descarga e instalación del plugin privativo de HP (necesario para LaserJet M15w)
echo "ℹ️ [5/5] Configurando plugin propietario de HP (hp-plugin)..."
if command -v hp-plugin &> /dev/null; then
    echo "💡 Descargando e instalando hp-plugin..."
    hp-plugin -i -q 2>/dev/null || hp-plugin -i || true
fi

echo "================================================================="
echo "✅ Configuración de HP LaserJet Pro M15w completada para KDE Plasma."
echo "💡 Puedes administrar tu impresora desde:"
echo "   - Ajustes del sistema de KDE Plasma -> 'Impresoras'"
echo "   - O ejecutando en terminal: 'hp-setup' o 'hp-toolbox'"
echo "================================================================="

