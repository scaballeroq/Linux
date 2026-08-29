#!/bin/bash
# =============================================================================
# CONFIGURACIÓN Y ALIASES PARA KDE PLASMA 6 (kde_settings.sh) - CachyOS
# =============================================================================
# Este archivo contiene configuraciones de entorno para KDE Plasma 6, optimizaciones
# para portátil/escritorio (Touchpad, VRR, Wayland) y utilidades CLI para KDE.

# -----------------------------------------------------------------------------
# 1. AJUSTES BASE DE KDE PLASMA 6 (Solo si estamos en sesión KDE)
# -----------------------------------------------------------------------------
if [[ "${XDG_CURRENT_DESKTOP:-}" == *"KDE"* ]]; then
    # Comando de escritura de configuración de KDE
    KWRITE=$(command -v kwriteconfig6 2>/dev/null || command -v kwriteconfig5 2>/dev/null || true)

    if [ -n "$KWRITE" ]; then
        # 1.1. Touchpad: Tap-to-click y desplazamiento natural
        "$KWRITE" --file kcminputrc --group Touchpad --key tapToClick true 2>/dev/null || true
        "$KWRITE" --file kcminputrc --group Touchpad --key naturalScroll true 2>/dev/null || true
        "$KWRITE" --file touchpadrsrc --group General --key tapToClick true 2>/dev/null || true
        "$KWRITE" --file touchpadrsrc --group General --key naturalScroll true 2>/dev/null || true

        # 1.2. Botones de ventana: Minimizar, Maximizar y Cerrar a la derecha
        "$KWRITE" --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX" 2>/dev/null || true

        # 1.3. Reloj en formato 24 horas y fecha ISO
        "$KWRITE" --file kdeglobals --group Locale --key TimeFormat "%H:%M:%S" 2>/dev/null || true
        "$KWRITE" --file kdeglobals --group Locale --key DateFormat "%Y-%m-%d" 2>/dev/null || true
    fi
    unset KWRITE
fi

# -----------------------------------------------------------------------------
# 2. GESTIÓN Y CONTROL DE PLASMA Y KWIN
# -----------------------------------------------------------------------------

# Reiniciar Shell de Plasma (Plasma 6 en Systemd / Wayland)
alias plasma-restart="systemctl --user restart plasma-plasmashell.service 2>/dev/null || (kquitapp6 plasmashell 2>/dev/null; kstart plasmashell &>/dev/null &)"

# Recargar configuración del compositor KWin sin reiniciar sesión
QDBUS_BIN=$(command -v qdbus-qt6 2>/dev/null || command -v qdbus 2>/dev/null || true)
if [ -n "$QDBUS_BIN" ]; then
    alias kwin-reload="$QDBUS_BIN org.kde.KWin /KWin reconfigure"
    alias kwin-support="$QDBUS_BIN org.kde.KWin /KWin supportInformation | less"
else
    alias kwin-reload="echo 'qdbus no disponible en el PATH'"
fi
unset QDBUS_BIN

# -----------------------------------------------------------------------------
# 3. ACCESOS DIRECTOS A MÓDULOS DE CONFIGURACIÓN (KCMSHELL6)
# -----------------------------------------------------------------------------

alias kde-settings="systemsettings &>/dev/null &"
alias kde-pantallas="kcmshell6 kcm_kscreen &>/dev/null &"
alias kde-wifi="kcmshell6 kcm_networkmanagement &>/dev/null &"
alias kde-audio="kcmshell6 kcm_pulseaudio &>/dev/null &"
alias kde-bluetooth="kcmshell6 kcm_bluetooth &>/dev/null &"
alias kde-teclado="kcmshell6 kcm_keyboard &>/dev/null &"
alias kde-atajos="kcmshell6 kcm_keys &>/dev/null &"
alias kde-touchpad="kcmshell6 kcm_touchpad &>/dev/null &"
alias kde-energia="kcmshell6 kcm_powerdevilprofilesconfig &>/dev/null &"
alias kde-luznocturna="kcmshell6 kcm_nightlight &>/dev/null &"
alias kde-apariencia="kcmshell6 kcm_lookandfeel &>/dev/null &"
alias kde-colores="kcmshell6 kcm_colors &>/dev/null &"
alias kde-iconos="kcmshell6 kcm_icons &>/dev/null &"
alias kde-fondo="kcmshell6 kcm_wallpaper &>/dev/null &"
alias kde-bloqueo="kcmshell6 kcm_screenlocker &>/dev/null &"
alias kde-autostart="kcmshell6 kcm_autostart &>/dev/null &"
alias kde-notificaciones="kcmshell6 kcm_notifications &>/dev/null &"
alias kde-info="kinfocenter &>/dev/null &"

# -----------------------------------------------------------------------------
# 4. GESTIÓN DE PLASMOIDS, WIDGETS Y TEMAS CLI
# -----------------------------------------------------------------------------

# Listar Plasmoids / Widgets y scripts de KWin instalados
alias plasmoids-list="kpackagetool6 --type Plasma/Applet --list 2>/dev/null || kpackagetool5 --type Plasma/Applet --list 2>/dev/null"
alias kwin-scripts-list="kpackagetool6 --type KWin/Script --list 2>/dev/null || kpackagetool5 --type KWin/Script --list 2>/dev/null"

# Cambiar entre Tema Oscuro y Claro desde la terminal
kde-theme-dark() {
    if command -v plasma-apply-lookandfeel &>/dev/null; then
        plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || true
    fi
    if command -v plasma-apply-colorscheme &>/dev/null; then
        plasma-apply-colorscheme BreezeDark 2>/dev/null || true
    fi
    echo "🌙 Tema Breeze Dark aplicado en KDE Plasma."
}

kde-theme-light() {
    if command -v plasma-apply-lookandfeel &>/dev/null; then
        plasma-apply-lookandfeel -a org.kde.breeze.desktop 2>/dev/null || true
    fi
    if command -v plasma-apply-colorscheme &>/dev/null; then
        plasma-apply-colorscheme BreezeLight 2>/dev/null || true
    fi
    echo "☀️ Tema Breeze Light aplicado en KDE Plasma."
}

# Fijar fondo de escritorio por CLI
kde-set-wallpaper() {
    if [ -z "${1:-}" ] || [ ! -f "$1" ]; then
        echo "Uso: kde-set-wallpaper /ruta/a/imagen.jpg"
        return 1
    fi
    if command -v plasma-apply-wallpaperimage &>/dev/null; then
        plasma-apply-wallpaperimage "$1"
        echo "🖼️ Fondo de pantalla actualizado: $1"
    else
        echo "❌ plasma-apply-wallpaperimage no disponible."
        return 1
    fi
}

# -----------------------------------------------------------------------------
# 5. INTEGRACIÓN CON SPECTACLE (CAPTURAS Y GRABACIÓN)
# -----------------------------------------------------------------------------

# Captura de región rectangular directa al portapapeles sin abrir ventana
alias captura="spectacle -r -b -c &>/dev/null &"

# Grabación de pantalla con Spectacle
alias grabacion="spectacle -R &>/dev/null &"

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Configuración y utilidades de KDE Plasma 6 cargadas"
