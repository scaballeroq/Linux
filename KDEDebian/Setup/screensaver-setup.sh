#!/bin/bash
# screensaver-setup.sh - Configuración de Bloqueo de Pantalla y Salvapantallas 3D para Debian Testing + KDE Plasma 6

set -euo pipefail

echo "🎨 Configurando Bloqueo de Pantalla y Salvapantallas en Debian Testing + KDE Plasma..."

# 1. Configuración nativa de KScreenLocker en KDE Plasma
echo "ℹ️ Configurando demonio de bloqueo KScreenLocker..."
python3 - <<'PYEOF'
import configparser
import os

cfg_path = os.path.expanduser("~/.config/kscreenlockerrc")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

if not config.has_section("Daemon"):
    config.add_section("Daemon")

config.set("Daemon", "Autolock", "true")
config.set("Daemon", "Timeout", "5") # 5 minutos
config.set("Daemon", "LockOnResume", "true")

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

# 2. Instalación opcional de suite XScreenSaver y efectos 3D OpenGL
echo "ℹ️ Instalando XScreenSaver y colecciones de salvapantallas 3D/GL vía APT..."
sudo apt update
sudo apt install -y \
    xscreensaver \
    xscreensaver-gl \
    xscreensaver-data-extra \
    xscreensaver-gl-extra \
    libgl1-mesa-dri \
    libglx-mesa0 2>/dev/null || true

# 3. Crear archivo de configuración prediseñado de XScreenSaver (~/.xscreensaver)
if [ ! -f "$HOME/.xscreensaver" ]; then
    echo "ℹ️ Creando archivo de configuración inicial ~/.xscreensaver..."
    cat <<EOF > "$HOME/.xscreensaver"
# Configuración predeterminada de XScreenSaver para KDEDebian
timeout:	0:05:00
cycle:	0:05:00
lock:	True
lockTimeout:	0:00:00
passwdTimeout:	0:00:30
visualID:	default
installColormap:	False
verbose:	False
timestamp:	True
fade:	True
unfade:	False
fadeSeconds:	0:00:03
fadeTicks:	20
dpmsEnabled:	True
dpmsQuickOff:	False
dpmsStandby:	0:15:00
dpmsSuspend:	0:15:00
dpmsOff:	0:30:00
grabDesktopImages:	False
mode:	random
selected:	-1
EOF
fi

# 4. Asegurar atajo Meta+L / Super+L para bloqueo en KDE (kglobalshortcutsrc)
echo "ℹ️ Verificando atajo de bloqueo de pantalla (Meta+L)..."
python3 - <<'PYEOF'
import configparser
import os

cfg_path = os.path.expanduser("~/.config/kglobalshortcutsrc")
config = configparser.ConfigParser(interpolation=None, strict=False)
if os.path.exists(cfg_path):
    config.read(cfg_path, encoding='utf-8')

if not config.has_section("kscreenlocker"):
    config.add_section("kscreenlocker")

config.set("kscreenlocker", "Lock Session", "Meta+L\\tScreensaver,Meta+L\\tScreensaver,Lock Session")

with open(cfg_path, 'w', encoding='utf-8') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

echo "================================================================="
echo "✅ Bloqueo de pantalla y salvapantallas configurados con éxito."
echo "💡 Puedes bloquear la pantalla instantáneamente con Meta + L (Super + L)."
echo "================================================================="
