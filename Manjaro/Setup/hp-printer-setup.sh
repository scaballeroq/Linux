#!/bin/bash
# hp-printer-setup.sh - Instalación y configuración de impresora HP LaserJet Pro M15w por USB en Manjaro Linux + GNOME

set -euo pipefail

echo "🚀 Iniciando configuración de impresora HP LaserJet Pro M15w (USB) en Manjaro Linux..."

# 1. Identificar usuario principal
TARGET_USER="${SUDO_USER:-$USER}"

# 2. Instalación de paquetes necesarios
echo "ℹ️ Instalando paquetes de impresión vía Pacman..."
sudo pacman -S --needed --noconfirm \
    cups \
    cups-filters \
    libcups \
    hplip \
    python-pyqt5 \
    system-config-printer \
    usbutils \
    wget

# 3. Habilitar e iniciar servicio CUPS
echo "ℹ️ Habilitando e iniciando el servicio CUPS..."
sudo systemctl enable --now cups.service

# 4. Añadir usuario a los grupos de impresión
echo "ℹ️ Añadiendo al usuario '$TARGET_USER' a los grupos lp y sys..."
sudo usermod -aG lp,sys "$TARGET_USER" 2>/dev/null || true

# 5. Comprobación de detección de la impresora por USB
echo "ℹ️ Verificando conexión USB de la impresora HP..."
if lsusb | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17" > /dev/null 2>&1; then
    echo "✅ Impresora HP detectada en el puerto USB:"
    lsusb | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17" || true
else
    echo "⚠️ No se detectó explícitamente la HP LaserJet M15w en lsusb."
    echo "   Por favor, asegúrate de que la impresora esté encendida y conectada mediante cable USB."
fi

# 6. Plugin Propietario de HP
echo ""
echo "================================================================="
echo "💡 IMPORTANTE: La serie HP LaserJet M15w requiere el PLUGIN PROPIETARIO"
echo "   de HP (hplip-plugin) para poder procesar trabajos de impresión."
echo "================================================================="
echo ""

read -rp "¿Deseas instalar el plugin propietario con hp-plugin / pamac? (S/n): " INSTALL_PLUGIN || true
INSTALL_PLUGIN="${INSTALL_PLUGIN:-s}"

if [[ "$INSTALL_PLUGIN" =~ ^[Ss]$ ]]; then
    if command -v pamac &> /dev/null; then
        echo "ℹ️ Intentando instalar hplip-plugin desde AUR con Pamac..."
        pamac build --no-confirm hplip-plugin || sudo hp-plugin -i || true
    else
        sudo hp-plugin -i || true
    fi
fi

# 7. Configuración de la cola de impresión
read -rp "¿Deseas lanzar 'hp-setup' en modo USB interactivo? (S/n): " RUN_HP_SETUP || true
RUN_HP_SETUP="${RUN_HP_SETUP:-s}"

if [[ "$RUN_HP_SETUP" =~ ^[Ss]$ ]]; then
    sudo hp-setup -b usb -i || true
fi

# 8. Resumen
echo ""
echo "================================================================="
echo "✅ Estado de las impresoras en CUPS:"
lpstat -p -d 2>/dev/null || echo "ℹ️ No hay impresoras configuradas aún o CUPS requiere reinicio de sesión."
echo "================================================================="
echo "🌐 Panel Web de CUPS: http://localhost:631"
echo "✅ Configuración de HP LaserJet Pro M15w completada en Manjaro."
