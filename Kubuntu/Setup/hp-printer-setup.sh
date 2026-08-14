#!/bin/bash
# hp-printer-setup.sh - Instalación y configuración de impresora HP LaserJet Pro M15w por USB en Kubuntu

set -euo pipefail

echo "🚀 Iniciando configuración de impresora HP LaserJet Pro M15w (USB) en Kubuntu..."

# 1. Identificar usuario principal
TARGET_USER="${SUDO_USER:-$USER}"

# 2. Instalación de paquetes necesarios (CUPS, HPLIP, herramientas GUI y utilidades USB)
echo "ℹ️ Instalando paquetes de impresión (CUPS, HPLIP, HPLIP-GUI, print-manager)..."
sudo apt update
sudo apt install -y \
    cups \
    cups-client \
    cups-filters \
    hplip \
    hplip-gui \
    printer-driver-hpcups \
    python3-pyqt5 \
    system-config-printer \
    print-manager \
    usbutils \
    wget

# 3. Habilitar e iniciar servicio CUPS
echo "ℹ️ Habilitando e iniciando el servicio CUPS..."
sudo systemctl enable --now cups.service

# 4. Añadir usuario a los grupos de impresión lp y lpadmin
echo "ℹ️ Añadiendo al usuario '$TARGET_USER' a los grupos lp y lpadmin..."
sudo usermod -aG lp,lpadmin "$TARGET_USER"

# 5. Comprobación de detección de la impresora por USB
echo "ℹ️ Verificando conexión USB de la impresora HP..."
if lsusb | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17" > /dev/null 2>&1; then
    echo "✅ Impresora HP detectada en el puerto USB:"
    lsusb | grep -i -E "hp|hewlett" | grep -i -E "laserjet|m14|m15|m17" || true
else
    echo "⚠️ No se detectó explícitamente la HP LaserJet M15w en lsusb."
    echo "   Por favor, asegúrate de que la impresora esté encendida y conectada mediante el cable USB al equipo."
fi

# 6. Instalación del Plugin Propietario de HP (Requerido para HP LaserJet Pro M15w)
echo ""
echo "================================================================="
echo "💡 IMPORTANTE: La serie HP LaserJet M15w requiere el PLUGIN PROPIETARIO"
echo "   de HP (hplip-plugin) para poder procesar trabajos de impresión."
echo "================================================================="
echo ""

read -rp "¿Deseas ejecutar 'hp-plugin' ahora para descargar e instalar el plugin? (S/n): " INSTALL_PLUGIN || true
INSTALL_PLUGIN="${INSTALL_PLUGIN:-s}"

if [[ "$INSTALL_PLUGIN" =~ ^[Ss]$ ]]; then
    echo "ℹ️ Ejecutando instalador del plugin HP (sigue las instrucciones en pantalla)..."
    if command -v hp-plugin &> /dev/null; then
        sudo hp-plugin -i || echo "⚠️ hp-plugin terminó con advertencias o requiere interacción manual."
    fi
else
    echo "ℹ️ Saltando la instalación del plugin. Puedes instalarlo más tarde ejecutando: sudo hp-plugin -i"
fi

# 7. Configuración de la cola de impresión en CUPS
echo ""
echo "ℹ️ Intentando añadir/configurar automáticamente la impresora con hp-setup..."
read -rp "¿Deseas lanzar 'hp-setup' en modo USB interactivo para agregar la cola de impresión? (S/n): " RUN_HP_SETUP || true
RUN_HP_SETUP="${RUN_HP_SETUP:-s}"

if [[ "$RUN_HP_SETUP" =~ ^[Ss]$ ]]; then
    sudo hp-setup -b usb -i || true
fi

# 8. Mostrar resumen y estado de CUPS
echo ""
echo "================================================================="
echo "✅ Estado de las impresoras en CUPS:"
lpstat -p -d 2>/dev/null || echo "ℹ️ No hay impresoras configuradas aún o CUPS requiere reinicio de sesión."
echo "================================================================="
echo ""
echo "💡 Notas finales:"
echo "   1) Si no has añadido el grupo 'lpadmin' a tu sesión actual, ejecuta: newgrp lpadmin (o reinicia sesión)."
echo "   2) Puedes administrar impresoras desde KDE Plasma en 'Preferencias del Sistema -> Impresoras'."
echo "   3) Panel Web de CUPS disponible en: http://localhost:631"
echo "   4) Para probar la impresión, puedes enviar una página de prueba con: hp-testpage"
echo ""
echo "✅ Configuración de HP LaserJet Pro M15w completada."
