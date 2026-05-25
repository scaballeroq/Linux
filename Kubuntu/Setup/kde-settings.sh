#!/bin/bash
# kde-settings.sh - Configuración de KDE Plasma para Kubuntu

set -e

echo "🚀 Iniciando configuración de KDE Plasma..."

# Detectar herramienta de configuración
if command -v kwriteconfig6 &> /dev/null; then
    KCONFIG="kwriteconfig6"
    QDBUS="qdbus6"
elif command -v kwriteconfig5 &> /dev/null; then
    KCONFIG="kwriteconfig5"
    QDBUS="qdbus"
else
    echo "❌ Error: No se detectaron las herramientas de configuración de KDE (kwriteconfig6/5)."
    exit 1
fi

echo "ℹ️ Usando $KCONFIG y $QDBUS..."

# 1. Configuración de Luz Nocturna (Night Color)
# Se activa a 3500K constantes (ideal para descanso visual)
echo "ℹ️ Configurando Luz Nocturna (Night Color) a 3500K..."
$KCONFIG --file kwinrc --group NightColor --key Active true
$KCONFIG --file kwinrc --group NightColor --key Mode Constant
$KCONFIG --file kwinrc --group NightColor --key NightTemperature 3500

# Recargar configuración de KWin
echo "ℹ️ Recargando configuración de KWin..."
$QDBUS org.kde.KWin /KWin reconfigure 2>/dev/null || true

# 2. Configuración de Energía (Power Management)
# Evitar que el sistema se suspenda automáticamente cuando está conectado a la corriente (AC)
echo "ℹ️ Configurando opciones de energía (No suspender en corriente alterna)..."
$KCONFIG --file powerdevilrc --group AC --group SuspendSession --key suspendType 0

# Recargar el servicio de energía de KDE
echo "ℹ️ Recargando configuración de energía (Powerdevil)..."
$QDBUS org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement.refreshStatus 2>/dev/null || true

echo "✅ Configuración de KDE Plasma aplicada correctamente."
