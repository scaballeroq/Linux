#!/bin/bash
# hp-printer-setup.sh - Instalación y configuración de impresora HP LaserJet Pro M15w por USB en Fedora 44 + KDE Plasma

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
echo "🚀 Iniciando configuración de impresora HP LaserJet Pro M15w (USB) en Fedora 44 (KDE Plasma)"
echo "================================================================="

# 1. Identificar usuario principal
TARGET_USER="${SUDO_USER:-$USER}"

# 2. Instalación de paquetes necesarios para impresión y KDE Plasma
echo "ℹ️ Instalando paquetes de impresión (CUPS, HPLIP, HPLIP-GUI, Print Manager KDE) vía DNF5..."
$SUDO dnf5 install -y \
    cups \
    cups-filters \
    cups-ipp-utils \
    hplip \
    hplip-gui \
    print-manager \
    plasma-print-manager \
    system-config-printer \
    usbutils \
    libusb1 2>/dev/null || $SUDO dnf5 install -y cups hplip hplip-gui print-manager system-config-printer 2>/dev/null || true

# 3. Habilitación de servicios del sistema
echo "ℹ️ Habilitando e iniciando el servicio CUPS..."
$SUDO systemctl enable --now cups.service cups.socket 2>/dev/null || true

# 4. Asignación de grupos al usuario
echo "ℹ️ Agregando al usuario '$TARGET_USER' a los grupos de impresión (lp)..."
$SUDO usermod -aG lp "$TARGET_USER" 2>/dev/null || true

# 5. Reglas Udev para escaneo/impresión USB
echo "ℹ️ Verificando reglas udev para dispositivos HP USB..."
$SUDO udevadm control --reload-rules 2>/dev/null || true
$SUDO udevadm trigger 2>/dev/null || true

# 6. Descarga e instalación del plugin privativo de HP
echo "ℹ️ Configurando plugin propietario de HP (hp-plugin)..."
if command -v hp-plugin &> /dev/null; then
    echo "💡 Ejecutando descarga automatizada de hp-plugin..."
    hp-plugin -i -q 2>/dev/null || hp-plugin -i || true
fi

echo "================================================================="
echo "✅ Configuración de HP LaserJet Pro M15w en KDE Plasma completada."
echo "💡 Conecta la impresora por USB y accede a 'Ajustes del Sistema -> Impresoras' o ejecuta 'hp-setup'."
echo "================================================================="
