#!/bin/bash
# screensaver-setup.sh - Instalación y configuración de Salvapantallas (Screensaver 3D / Matrix) al bloquear Debian Testing + GNOME

set -euo pipefail

echo "🎨 Configurando Salvapantallas (Screensaver 3D / Matrix) al bloquear el sistema en Debian Testing + GNOME..."

# 1. Instalación de paquetes de XScreenSaver y efectos 3D OpenGL
echo "ℹ️ Instalando XScreenSaver y colecciones de salvapantallas 3D/GL vía APT..."
sudo apt update
sudo apt install -y \
    xscreensaver \
    xscreensaver-gl \
    xscreensaver-data-extra \
    xscreensaver-gl-extra \
    libgl1-mesa-dri \
    libglx-mesa0 2>/dev/null || true

# 2. Configurar autostart de XScreenSaver en el inicio de sesión de GNOME
echo "ℹ️ Configurando inicio automático de XScreenSaver en autostart de GNOME..."
mkdir -p ~/.config/autostart

cat <<EOF > ~/.config/autostart/xscreensaver.desktop
[Desktop Entry]
Type=Application
Name=XScreenSaver
Comment=Demonio de Salvapantallas 3D para bloqueo de pantalla
Exec=xscreensaver -nosplash
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# 3. Crear archivo de configuración prediseñado de XScreenSaver (~/.xscreensaver)
if [ ! -f "$HOME/.xscreensaver" ]; then
    echo "ℹ️ Creando archivo de configuración inicial ~/.xscreensaver..."
    cat <<EOF > "$HOME/.xscreensaver"
# Configuración predeterminada de XScreenSaver para DebianTesting
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

# 4. Iniciar el servicio en segundo plano si estamos en entorno gráfico
if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
    echo "ℹ️ Iniciando demonio xscreensaver en segundo plano..."
    killall xscreensaver 2>/dev/null || true
    xscreensaver -nosplash &
fi

# 5. Atajo de bloqueo personalizado con Super+L en GNOME
if command -v gsettings &>/dev/null; then
    echo "ℹ️ Configurando atajo de teclado Super+L para bloquear lanzando el salvapantallas en GNOME..."
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/screensaver-lock/']" 2>/dev/null || true

    BINDING_PATH="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/screensaver-lock/"
    gsettings set $BINDING_PATH name 'Bloquear con Salvapantallas' 2>/dev/null || true
    gsettings set $BINDING_PATH command 'xscreensaver-command -lock' 2>/dev/null || true
    gsettings set $BINDING_PATH binding '<Super>l' 2>/dev/null || true
fi

echo "================================================================="
echo "✅ Salvapantallas 3D y sistema de bloqueo configurados con éxito."
echo "💡 Puedes personalizar los salvapantallas gráficos ejecutando: xscreensaver-demo"
echo "💡 Puedes bloquear la pantalla instantáneamente con Super + L."
echo "================================================================="
