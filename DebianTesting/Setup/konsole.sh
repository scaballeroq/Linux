#!/usr/bin/env bash
#
# konsole.sh - Configuración e Instalación de Konsole para Debian Testing + KDE Plasma 6
# 
# Este script instala y optimiza Konsole, el emulador de terminal nativo de KDE Plasma,
# creando un perfil moderno con tema oscuro, transparencia (85%), efecto blur, tipografía Nerd Font
# y sin barra de scroll.
# 
# También configura el atajo global (Ctrl+Alt+T) en KDE Plasma y la integración con Dolphin.

set -euo pipefail

echo "==========================================================="
echo "🚀 Iniciando configuración estética y funcional de Konsole en Debian + KDE Plasma"
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
cat <<'EOF' > "$HOME/.local/share/konsole/KDEDebianDark.colorscheme"
[General]
Description=KDEDebian Dark Translucent
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

# 4. Crear Perfil KDEDebian.profile
cat <<'EOF' > "$HOME/.local/share/konsole/KDEDebian.profile"
[General]
Name=KDEDebian
Parent=FALLBACK/
Command=/bin/bash

[Appearance]
ColorScheme=KDEDebianDark
Font=JetBrainsMono Nerd Font,11,-1,5,50,0,0,0,0,0

[Scrolling]
ScrollBarPosition=2
HistoryMode=2
HistorySize=10000

[Terminal Features]
BlinkingCursorEnabled=true
EOF

# 5. Establecer KDEDebian como perfil por defecto en konsolerc
python3 - <<'PYEOF'
import configparser
import os

cfg_path = os.path.expanduser("~/.config/konsolerc")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

if not config.has_section("Desktop Entry"):
    config.add_section("Desktop Entry")
config.set("Desktop Entry", "DefaultProfile", "KDEDebian.profile")

if not config.has_section("Favorite Profiles"):
    config.add_section("Favorite Profiles")
config.set("Favorite Profiles", "Favorites", "KDEDebian.profile")

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

# 6. Configurar atajo de teclado global Ctrl+Alt+T en KDE Plasma (kglobalshortcutsrc)
echo "⌨️ [4/5] Configurando atajo de teclado (Ctrl+Alt+T) para Konsole..."
python3 - <<'PYEOF'
import configparser
import os

cfg_path = os.path.expanduser("~/.config/kglobalshortcutsrc")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

if not config.has_section("org.kde.konsole.desktop"):
    config.add_section("org.kde.konsole.desktop")

config.set("org.kde.konsole.desktop", "_k_friendly_name", "Konsole")
config.set("org.kde.konsole.desktop", "_launch", "Ctrl+Alt+T,Ctrl+Alt+T,Konsole")

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

# 7. Integración con Dolphin (Panel Terminal F4 y menú contextual)
echo "📁 [5/5] Integrando terminal en gestor de archivos Dolphin..."
python3 - <<'PYEOF'
import configparser
import os

cfg_path = os.path.expanduser("~/.config/dolphinrc")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

if not config.has_section("General"):
    config.add_section("General")

config.set("General", "ShowFullPathInTitlebar", "true")

if not config.has_section("TerminalPanel"):
    config.add_section("TerminalPanel")

config.set("TerminalPanel", "AutoSyncDirs", "true")

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

echo "==========================================================="
echo "✅ ¡Konsole configurado con éxito!"
echo "✨ Características aplicadas:"
echo "   - Perfil oscuro translúcido con blur (85% opacidad)"
echo "   - Tipografía JetBrainsMono Nerd Font"
echo "   - Sin barra de scroll (diseño minimalista)"
echo "   - Atajo global: Ctrl+Alt+T"
echo "   - Integración nativa con Dolphin (tecla F4)"
echo "==========================================================="
