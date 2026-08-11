#!/bin/bash
# debian-tuning.sh - Optimizaciones de Kernel Sysctl, Distrobox y llamada a extensiones GNOME en Debian

set -euo pipefail

echo "🚀 Iniciando optimización avanzada del sistema Debian..."

# 1. Ajustes de Sysctl para Desarrollo (Inotify, Map Count, Swappiness)
echo "ℹ️ Aplicando optimizaciones de kernel sysctl..."
sudo cat <<'EOF' | sudo tee /etc/sysctl.d/99-debian-dev.conf > /dev/null
# Optimizaciones de desarrollo para Debian + GNOME
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
fs.file-max = 2097152
vm.max_map_count = 16777216
vm.swappiness = 10
EOF

sudo sysctl --system > /dev/null || true

# 2. Herramientas de Desarrollo (Distrobox)
echo "ℹ️ Instalando Distrobox para contenedores de desarrollo..."
sudo apt update
sudo apt install -y distrobox 2>/dev/null || true

# 3. Llamada al script de extensiones de GNOME
echo "ℹ️ Ejecutando instalación de extensiones de GNOME..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/gnome-extensions.sh" ]; then
    "$SCRIPT_DIR/gnome-extensions.sh"
fi

echo "✅ Optimizaciones avanzadas de Debian completadas."
