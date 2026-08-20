#!/bin/bash
# screensaver-setup.sh - Instalación y configuración de Salvapantallas (Screensaver 3D / Matrix) al bloquear Fedora 44 + GNOME

set -euo pipefail

echo "🎨 Configurando Salvapantallas (Screensaver 3D / Matrix) al bloquear el sistema en Fedora 44 + GNOME..."

# 1. Instalación de paquetes de XScreenSaver y efectos 3D OpenGL
echo "ℹ️ Instalando XScreenSaver y colecciones de salvapantallas 3D/GL vía DNF5..."
sudo dnf5 install -y \
    xscreensaver \
    xscreensaver-gl-base \
    xscreensaver-gl-extras \
    xscreensaver-extras 2>/dev/null || sudo dnf5 install -y xscreensaver

# 2. Configuración del archivo ~/.xscreensaver
cat <<'EOF' > "$HOME/.xscreensaver"
timeout:        5
cycle:          5
lock:           False
lockTimeout:    0
passwdTimeout:  30
visualID:       default
installColormap:True
verbose:        False
timestamp:      True
splash:         False
splashDuration: 5
demoMode:       False
mode:           random
selected:       -1
programs:       \
                glmatrix -root                                \n\
                matrix -root                                  \n\
                polytopes -root                               \n\
                pipes -root                                   \n\
                superquadrics -root                           \n\
                cubestorm -root                               \n\
                circuit -root                                 \n
EOF

# 3. Servicio Systemd de usuario para invocar XScreenSaver al bloquear pantalla
mkdir -p "$HOME/.config/systemd/user"
cat <<'EOF' > "$HOME/.config/systemd/user/screensaver-lock.service"
[Unit]
Description=Lanzar Screensaver 3D al bloquear pantalla en GNOME
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/xscreensaver -no-splash
Restart=always

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now screensaver-lock.service 2>/dev/null || true

echo "================================================================="
echo "✅ Salvapantallas configurado con éxito para Fedora 44 GNOME."
echo "================================================================="
