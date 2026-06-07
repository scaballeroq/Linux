#!/bin/bash
# kde-settings.sh - Personalización de KDE Plasma 6 vía CLI (kwriteconfig6)

set -e

echo "🚀 Aplicando personalización de KDE Plasma 6..."

# 1. Tema Global (Breeze Dark)
# echo "ℹ️ Configurando tema oscuro..."
# /usr/bin/lookandfeeltool -a org.kde.breezedark.desktop

# 2. Configuración de Ventanas (Botones a la izquierda/derecha)
# Ejemplo: Solo botones de cerrar, minimizar y maximizar
# kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
# kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""

# 3. Comportamiento del ratón (Click simple para abrir)
#kwriteconfig6 --file kdeglobals --group KDE --key SingleClick "true"

# 4. Panel / Barra de tareas
# Activar el "Ocultar automáticamente" (Auto-hide)
# Nota: La configuración de paneles es más compleja, esto afecta a la visibilidad general.
#kwriteconfig6 --file plasmashellrc --group Panels --group 1 --key alignment "left"

# 5. Efectos de KWin
# Desactivar animaciones pesadas si se busca máxima velocidad
# kwriteconfig6 --file kwinrc --group Windows --key AnimationDurationFactor 0.5

# 6. Atajos de teclado personalizados
echo "ℹ️ Configurando atajos de teclado..."
# Abrir terminal con Meta+T (Kitty si está instalado, de lo contrario Konsole)
if command -v kitty &> /dev/null; then
    kwriteconfig6 --file kglobalshortcutsrc --group kitty.desktop --key "_launch" "Meta+T,none,Kitty"
    kwriteconfig6 --file kglobalshortcutsrc --group org.kde.konsole.desktop --key "_launch" "none,none,Konsole"
else
    kwriteconfig6 --file kglobalshortcutsrc --group org.kde.konsole.desktop --key "_launch" "Meta+T,none,Konsole"
fi


# 7. Bloqueo de pantalla
# kwriteconfig6 --file kscreentoolrc --group Daemon --key Autolock "false"

# 8. Reiniciar servicios para aplicar cambios
# echo "ℹ️ Aplicando cambios (Reiniciando KWin y Plasma Shell)..."
# En Plasma 6, es mejor reiniciar la sesión, pero intentamos forzar recarga
# dbus-send --session --dest=org.kde.plasmashell --type=method_call /MainApplication org.kde.KApplication.reparseConfiguration
# kwin_x11 --replace &> /dev/null & disown || kwin_wayland --replace &> /dev/null & disown

echo "✅ Personalización de KDE completada."
echo "💡 Algunos cambios podrían requerir cerrar sesión para verse reflejados."
