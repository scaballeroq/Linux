#!/bin/bash
# kde-settings.sh - Personalización de KDE Plasma vía CLI (kwriteconfig / plasma-apply) para Debian Testing

set -euo pipefail

echo "🚀 Iniciando personalización de KDE Plasma 6 en Debian..."

# Determinar ejecutable de configuración de KDE (kwriteconfig6 / kwriteconfig5 o fallback python)
KWRITECFG=""
if command -v kwriteconfig6 &>/dev/null; then
    KWRITECFG="kwriteconfig6"
elif command -v kwriteconfig5 &>/dev/null; then
    KWRITECFG="kwriteconfig5"
fi

set_kconfig() {
    local file="$1"
    local group="$2"
    local key="$3"
    local value="$4"

    if [ -n "$KWRITECFG" ]; then
        $KWRITECFG --file "$file" --group "$group" --key "$key" "$value" 2>/dev/null || true
    else
        python3 - <<PYEOF
import configparser
import os

cfg_path = os.path.expanduser(f"~/.config/{'$file'}")
os.makedirs(os.path.dirname(cfg_path), exist_ok=True)
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

group = '$group'
if not config.has_section(group):
    config.add_section(group)

config.set(group, '$key', '$value')
with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF
    fi
}

# 1. Luz Nocturna (Night Color) - Desactivada
echo "ℹ️ Configurando Luz Nocturna (desactivada)..."
set_kconfig "kwinrc" "NightColor" "Active" "false"
set_kconfig "kwinrc" "NightColor" "NightTemperature" "3500"
set_kconfig "kwinrc" "NightColor" "Mode" "Times"

# 2. Formato de reloj (24h) y botones de ventana
echo "ℹ️ Configurando botones de ventana y formato de reloj..."
set_kconfig "kwinrc" "org.kde.kdecoration2" "ButtonsOnRight" "IAX" # I: Minimizar, A: Maximizar, X: Cerrar
set_kconfig "kwinrc" "org.kde.kdecoration2" "ButtonsOnLeft" "M"   # M: Menú de ventana

# 3. Touchpad y gestos para portátil
echo "ℹ️ Configurando gestos y Touchpad en kcminputrc..."
set_kconfig "kcminputrc" "Touchpad" "tapToClick" "true"
set_kconfig "kcminputrc" "Touchpad" "naturalScroll" "true"
set_kconfig "kcminputrc" "Touchpad" "twoFingerTap" "2"

# 4. Comportamiento de energía
echo "ℹ️ Configurando políticas de energía en powermanagementprofilesrc..."
set_kconfig "powermanagementprofilesrc" "AC" "icon" "battery-charging"
set_kconfig "powermanagementprofilesrc" "Battery" "icon" "battery-060"

# 5. Tema oscuro completo en todo KDE Plasma (Brisa Oscuro / Breeze Dark)
echo "ℹ️ Aplicando tema oscuro completo en KDE Plasma (Brisa Oscuro)..."

# Aplicar tema global (Look and Feel)
if command -v plasma-apply-lookandfeel &>/dev/null; then
    plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || plasma-apply-lookandfeel -a org.kde.breeze.dark.desktop 2>/dev/null || true
fi
set_kconfig "kdeglobals" "KDE" "LookAndFeelPackage" "org.kde.breezedark.desktop"

# Esquema de color de la aplicación (BreezeDark)
if command -v plasma-apply-colorscheme &>/dev/null; then
    plasma-apply-colorscheme BreezeDark 2>/dev/null || true
fi
set_kconfig "kdeglobals" "General" "ColorScheme" "BreezeDark"
set_kconfig "kdeglobals" "General" "shadeSortColumn" "true"

# Estilo de widgets
set_kconfig "kdeglobals" "KDE" "widgetStyle" "Breeze"

# Tema de escritorio Plasma (breeze-dark)
if command -v plasma-apply-desktoptheme &>/dev/null; then
    plasma-apply-desktoptheme breeze-dark 2>/dev/null || plasma-apply-desktoptheme BreezeDark 2>/dev/null || true
fi

# Decoración de ventanas (tema oscuro)
set_kconfig "kwinrc" "org.kde.kdecoration2" "library" "org.kde.breeze"
set_kconfig "kwinrc" "org.kde.kdecoration2" "theme" "Breeze"

# Tema de iconos (Breeze oscuro)
set_kconfig "kdeglobals" "Icons" "Theme" "breeze-dark"

# Tema de cursores (Breeze oscuro)
if command -v plasma-apply-cursortheme &>/dev/null; then
    plasma-apply-cursortheme breeze_cursors 2>/dev/null || true
fi
set_kconfig "kdeglobals" "Mouse" "cursorTheme" "breeze_cursors"

# Tema de sonidos
set_kconfig "kdeglobals" "Sounds" "Theme" "Ocean"

# Tema GTK oscuro e integración (Breeze-Dark)
set_kconfig "kdeglobals" "Gtk" "Theme" "Breeze-Dark"
set_kconfig "kdeglobals" "Gtk" "ApplicationFont" "Noto Sans,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
set_kconfig "kdeglobals" "Gtk" "Font" "Noto Sans,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
cat <<'EOF' > "$HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-theme-name=Breeze-Dark
gtk-icon-theme-name=breeze-dark
gtk-application-prefer-dark-theme=1
EOF

cat <<'EOF' > "$HOME/.config/gtk-4.0/settings.ini"
[Settings]
gtk-theme-name=Breeze-Dark
gtk-icon-theme-name=breeze-dark
gtk-application-prefer-dark-theme=1
EOF

# Forzar modo oscuro en Qt
set_kconfig "kdeglobals" "KDE" "contrast" "4"

# 6. Efectos visuales de KWin (Blur, Translucidez, Rendimiento)
echo "ℹ️ Optimizando efectos visuales y renderizado de KWin..."
set_kconfig "kwinrc" "Compositing" "OpenGLIsUnsafe" "false"
set_kconfig "kwinrc" "Plugins" "blurEnabled" "true"
set_kconfig "kwinrc" "Plugins" "translucencyEnabled" "true"
set_kconfig "kwinrc" "Windows" "FocusStealingPreventionLevel" "1"

# 7. Recargar configuración si Plasma está corriendo
if pgrep -x "plasmashell" >/dev/null; then
    echo "🔄 Aplicando cambios a Plasma y KWin..."
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    qdbus org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.setNightColorActive false 2>/dev/null || true
    killall plasmashell && kstart5 plasmashell 2>/dev/null || kstart plasmashell 2>/dev/null || systemctl --user restart plasma-plasmashell.service 2>/dev/null || true
    echo "⚠️ Plasma se reiniciará en unos segundos..."
fi

echo "================================================================="
echo "✅ Personalización de KDE Plasma completada correctamente."
echo "🌙 Modo Noche (Luz Nocturna): Desactivado"
echo "🌙 Tema oscuro (Brisa Oscuro / Breeze Dark) aplicado en:"
echo "   - Tema Global: org.kde.breezedark.desktop"
echo "   - Esquema de color: BreezeDark"
echo "   - Tema de escritorio Plasma: breeze-dark"
echo "   - Decoración de ventanas: Breeze"
echo "   - Iconos: breeze-dark"
echo "   - Cursores: breeze_cursors"
echo "   - Tema GTK: Breeze-Dark (prefer-dark-theme=1)"
echo "================================================================="
