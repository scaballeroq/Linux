#!/bin/bash
# kde-settings.sh - Personalización avanzada de KDE Plasma 6 / 5 vía CLI
# Compatible con Kubuntu 24.04 LTS, 24.10 y 26.04 LTS

set -euo pipefail

echo "🚀 Iniciando configuración y personalización de KDE Plasma..."

# Detectar versión de herramientas de KDE (Plasma 6 vs Plasma 5)
if command -v kwriteconfig6 &> /dev/null; then
    KCONFIG="kwriteconfig6"
    QDBUS_CMD="qdbus6"
    echo "ℹ️ Detectado KDE Plasma 6."
elif command -v kwriteconfig5 &> /dev/null; then
    KCONFIG="kwriteconfig5"
    QDBUS_CMD="qdbus"
    echo "ℹ️ Detectado KDE Plasma 5."
else
    echo "⚠️ No se encontraron herramientas kwriteconfig. Es posible que no estés en un entorno KDE Plasma activo."
    exit 0
fi

# 1. Configuración de Tema Global Oscuro (Breeze Dark)
if command -v lookandfeeltool &> /dev/null; then
    echo "ℹ️ [1/6] Configurando tema Breeze Dark..."
    lookandfeeltool -a org.kde.breezedark.desktop 2>/dev/null || true
fi

# 2. Configurar Luz Nocturna (Night Color) a 3500K
echo "ℹ️ [2/6] Configurando Luz Nocturna (Night Color)..."
$KCONFIG --file kwinrc --group NightColor --key Active true
$KCONFIG --file kwinrc --group NightColor --key Mode Constant
$KCONFIG --file kwinrc --group NightColor --key NightTemperature 3500

# 3. Comportamiento de Energía (No suspender en corriente alterna)
echo "ℹ️ [3/6] Configurando perfiles de energía (Powerdevil)..."
$KCONFIG --file powerdevilrc --group AC --group SuspendSession --key suspendType 0
$KCONFIG --file powerdevilrc --group AC --group Display --key dimOnIdleEnabled false

# 4. Atajos de teclado globales (Meta+T para Konsole / Terminal)
echo "ℹ️ [4/6] Configurando atajos de teclado personalizados..."
if command -v konsole &> /dev/null; then
    $KCONFIG --file kglobalshortcutsrc --group org.kde.konsole.desktop --key "_launch" "Meta+T,none,Konsole"
fi

# 5. Comportamiento de Ventanas y KWin
echo "ℹ️ [5/6] Optimizando comportamiento de KWin..."
# Botones de ventana: Minimizar, Maximizar, Cerrar a la derecha
$KCONFIG --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
$KCONFIG --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""

# 6. Recargar configuraciones de KWin y Powerdevil
echo "ℹ️ [6/6] Aplicando cambios en tiempo real..."
if command -v "$QDBUS_CMD" &> /dev/null; then
    $QDBUS_CMD org.kde.KWin /KWin reconfigure 2>/dev/null || true
    $QDBUS_CMD org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement.refreshStatus 2>/dev/null || true
fi

echo "✅ Personalización de KDE Plasma completada con éxito."
echo "💡 Se recomienda reiniciar la sesión para que todos los efectos y atajos surtan efecto completo."
