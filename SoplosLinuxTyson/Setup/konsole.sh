#!/usr/bin/env bash
# konsole.sh - Configuración e Instalación de Konsole para Soplos Linux Tyson (Debian Testing + KDE Plasma 6)
# Crea un perfil moderno con tema oscuro, transparencia (85%), efecto blur, tipografía Nerd Font
# y sin barra de scroll, con atajo global (Ctrl+Alt+T) e integración en Dolphin (F4).

set -euo pipefail

echo "==========================================================="
echo "🚀 Iniciando configuración estética y funcional de Konsole en Soplos Linux Tyson"
echo "==========================================================="

# 1. Actualizar e instalar paquetes necesarios
echo "📦 [1/5] Instalando Konsole y plugins de Dolphin..."
sudo apt update
sudo apt install -y \
    konsole \
    dolphin-plugins \
    kio-extras \
    git \
    build-essential

# 2. Crear directorios de configuración de Konsole
echo "⚙️ [2/5] Creando perfil personalizado de Konsole..."
mkdir -p "$HOME/.local/share/konsole"
mkdir -p "$HOME/.config"

# 3. Crear esquema de color con Transparencia y Blur
cat <<'EOF' > "$HOME/.local/share/konsole/SoplosLinuxDark.colorscheme"
[General]
Description=SoplosLinux Dark Translucent
Opacity=0.85
Blur=true
Wallpaper=

[Background]
Color=24,27,33

[BackgroundFaint]
Color=20,22,27

[BackgroundIntense]
Color=36,41,46

[Foreground]
Color=230,237,243

[ForegroundFaint]
Color=139,148,158

[ForegroundIntense]
Color=240,246,252

[Color0]
Color=72,79,88

[Color0Intense]
Color=110,118,129

[Color1]
Color=255,123,114

[Color1Intense]
Color=255,161,158

[Color2]
Color=86,211,100

[Color2Intense]
Color=126,231,135

[Color3]
Color=227,179,65

[Color3Intense]
Color=242,204,96

[Color4]
Color=88,166,255

[Color4Intense]
Color=121,192,255

[Color5]
Color=188,140,255

[Color5Intense]
Color=210,168,255

[Color6]
Color=57,197,207

[Color6Intense]
Color=86,220,229

[Color7]
Color=177,186,196

[Color7Intense]
Color=240,246,252
EOF

# 4. Crear Perfil SoplosLinux.profile
cat <<'EOF' > "$HOME/.local/share/konsole/SoplosLinux.profile"
[General]
Name=SoplosLinux
Parent=FALLBACK/

[Appearance]
ColorScheme=SoplosLinuxDark
Font=JetBrainsMono Nerd Font,11,-1,5,50,0,0,0,0,0

[Scrolling]
ScrollBarPosition=2
HistoryMode=2
HistorySize=10000

[Terminal Features]
BlinkingCursorEnabled=true
EOF

# Compatibilidad
cp -f "$HOME/.local/share/konsole/SoplosLinux.profile" "$HOME/.local/share/konsole/KDEDebian.profile" 2>/dev/null || true
cp -f "$HOME/.local/share/konsole/SoplosLinuxDark.colorscheme" "$HOME/.local/share/konsole/KDEDebianDark.colorscheme" 2>/dev/null || true

# Detectar ejecutable de configuración de KDE (kwriteconfig6 prioritario en KDE Plasma 6)
if command -v kwriteconfig6 &>/dev/null; then
    KWRITECFG="kwriteconfig6"
elif command -v kwriteconfig5 &>/dev/null; then
    KWRITECFG="kwriteconfig5"
else
    KWRITECFG="kwriteconfig"
fi

# 5. Establecer SoplosLinux como perfil por defecto en konsolerc
echo "⚙️ [3/5] Configurando perfil por defecto en konsolerc..."
$KWRITECFG --file konsolerc --group "Desktop Entry" --key "DefaultProfile" "SoplosLinux.profile"
$KWRITECFG --file konsolerc --group "Favorite Profiles" --key "Favorites" "SoplosLinux.profile"

# 6. Configurar atajo de teclado global Ctrl+Alt+T en KDE Plasma (kglobalshortcutsrc)
echo "⌨️ [4/5] Configurando atajo de teclado (Ctrl+Alt+T) para Konsole..."
$KWRITECFG --file kglobalshortcutsrc --group "org.kde.konsole.desktop" --key "_k_friendly_name" "Konsole"
$KWRITECFG --file kglobalshortcutsrc --group "org.kde.konsole.desktop" --key "_launch" "Ctrl+Alt+T,Ctrl+Alt+T,Konsole"

# 7. Integración con Dolphin (Panel Terminal F4 y menú contextual)
echo "📁 [5/5] Integrando terminal en gestor de archivos Dolphin..."
$KWRITECFG --file dolphinrc --group "General" --key "ShowFullPathInTitlebar" "true"
$KWRITECFG --file dolphinrc --group "TerminalPanel" --key "AutoSyncDirs" "true"

echo "==========================================================="
echo "✅ ¡Konsole configurado con éxito en Soplos Linux Tyson!"
echo "✨ Características aplicadas:"
echo "   - Perfil oscuro translúcido con blur (85% opacidad)"
echo "   - Tipografía JetBrainsMono Nerd Font"
echo "   - Sin barra de scroll (diseño minimalista)"
echo "   - Atajo global: Ctrl+Alt+T"
echo "   - Integración nativa con Dolphin (tecla F4)"
echo "==========================================================="
