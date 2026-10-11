#!/usr/bin/env bash
# konsole.sh - Configuracion de Konsole para Kubuntu + KDE Plasma 6
# Perfil oscuro translucido con blur (85% opacidad), JetBrainsMono Nerd Font

set -euo pipefail

echo "==========================================================="
echo "Configurando Konsole en Kubuntu + KDE Plasma"
echo "==========================================================="

# 1. Instalar Konsole
echo "Instalando Konsole y plugins de Dolphin..."
sudo apt update
sudo apt install -y konsole dolphin-plugins kio-extras

# 2. Crear directorios
echo "Creando perfil personalizado de Konsole..."
mkdir -p "$HOME/.local/share/konsole"
mkdir -p "$HOME/.config"

# 3. Esquema de colores con transparencia y blur
cat <<'EOF' > "$HOME/.local/share/konsole/KubuntuDark.colorscheme"
[General]
Description=Kubuntu Dark Translucent
Opacity=0.85
Blur=true

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

# 4. Perfil Kubuntu
cat <<'EOF' > "$HOME/.local/share/konsole/Kubuntu.profile"
[General]
Name=Kubuntu
Parent=FALLBACK/
Command=/bin/bash

[Appearance]
ColorScheme=KubuntuDark
Font=JetBrainsMono Nerd Font,11,-1,5,50,0,0,0,0,0

[Scrolling]
ScrollBarPosition=2
HistoryMode=2
HistorySize=10000

[Terminal Features]
BlinkingCursorEnabled=true
EOF

# 5. Establecer como perfil por defecto
python3 - <<'PYEOF'
import configparser, os

cfg_path = os.path.expanduser("~/.config/konsolerc")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

if not config.has_section("Desktop Entry"):
    config.add_section("Desktop Entry")
config.set("Desktop Entry", "DefaultProfile", "Kubuntu.profile")

if not config.has_section("Favorite Profiles"):
    config.add_section("Favorite Profiles")
config.set("Favorite Profiles", "Favorites", "Kubuntu.profile")

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

# 6. Atajo global Ctrl+Alt+T
echo "Configurando atajo Ctrl+Alt+T para Konsole..."
python3 - <<'PYEOF'
import configparser, os

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

# 7. Integracion Dolphin
echo "Integrando terminal en Dolphin..."
python3 - <<'PYEOF'
import configparser, os

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
echo "Konsole configurado con exito!"
echo "- Perfil oscuro translucido 85% con blur"
echo "- JetBrainsMono Nerd Font, size 11"
echo "- Atajo global: Ctrl+Alt+T"
echo "- Integracion Dolphin: F4 para panel terminal"
echo "==========================================================="
