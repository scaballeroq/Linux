#!/bin/bash
# laptop-setup.sh - Optimización para portátiles de desarrollo en Kubuntu (KDE Plasma)

set -euo pipefail

echo "🚀 Iniciando optimización para portátil de desarrollo en Kubuntu (KDE Plasma)..."

# 1. Herramientas de Hardware, Conectividad y Energía
echo "ℹ️ Instalando servicios de energía, bluetooth y gráficos híbridos..."
sudo apt update
sudo apt install -y \
    power-profiles-daemon \
    switcheroo-control \
    bluez \
    bluez-tools \
    brightnessctl \
    tlp-rdw || true

# Habilitar servicios clave de portátil
echo "ℹ️ Habilitando servicios systemd para portátil..."
sudo systemctl enable --now bluetooth.service || true
sudo systemctl enable --now power-profiles-daemon.service || true
sudo systemctl enable --now switcheroo-control.service || true

# 2. Configuraciones de KDE Plasma para Portátil (Touchpad, Pantalla y Energía)
if [[ "${XDG_CURRENT_DESKTOP:-}" == *"KDE"* ]]; then
    echo "ℹ️ Aplicando configuraciones de Touchpad y energía para KDE Plasma..."

    if command -v kwriteconfig6 &> /dev/null; then
        KCONFIG="kwriteconfig6"
        QDBUS_CMD="qdbus6"
    elif command -v kwriteconfig5 &> /dev/null; then
        KCONFIG="kwriteconfig5"
        QDBUS_CMD="qdbus"
    else
        KCONFIG=""
        QDBUS_CMD=""
    fi

    if [ -n "$KCONFIG" ]; then
        # Touchpad: Tap to click (Tocar para hacer clic) y Natural Scrolling
        $KCONFIG --file touchpadrcl --group "parameters" --key "TapToClick" "true" || true
        $KCONFIG --file touchpadrcl --group "parameters" --key "NaturalScrolling" "true" || true

        # Energía en Batería (Suspender a los 20 minutos / 1200 segundos)
        $KCONFIG --file powerdevilrc --group Battery --group SuspendSession --key suspendType 1 || true
        $KCONFIG --file powerdevilrc --group Battery --group SuspendSession --key idleTime 1200000 || true
        $KCONFIG --file powerdevilrc --group Battery --group Display --key dimOnIdleEnabled true || true

        if command -v "$QDBUS_CMD" &> /dev/null; then
            $QDBUS_CMD org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement.refreshStatus 2>/dev/null || true
        fi
    fi
fi

echo "✅ Configuración de portátil para Kubuntu aplicada correctamente."
echo "💡 Recuerda reiniciar la sesión para que todos los cambios de KDE Plasma entren en vigor."
