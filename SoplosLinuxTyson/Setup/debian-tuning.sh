#!/bin/bash
# debian-tuning.sh - Optimizaciones de Kernel Sysctl y Distrobox en Debian Testing + KDE Plasma

set -euo pipefail

echo "🚀 Iniciando optimización avanzada del sistema Debian Testing + KDE Plasma..."

# 1. Ajustes de Sysctl para Desarrollo (Inotify, Map Count, Swappiness)
echo "ℹ️ Aplicando optimizaciones de kernel sysctl..."
sudo cat <<'EOF' | sudo tee /etc/sysctl.d/99-debian-dev.conf > /dev/null
# Optimizaciones de desarrollo para Debian Testing + KDE Plasma
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

echo "✅ Optimizaciones avanzadas de Debian completadas."
