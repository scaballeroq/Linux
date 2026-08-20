#!/bin/bash
# fedora-tuning.sh - Optimizaciones de Kernel Sysctl y Distrobox en Fedora 44 + GNOME

set -euo pipefail

echo "🚀 Iniciando optimización avanzada del sistema Fedora 44 + GNOME..."

# 1. Ajustes de Sysctl para Desarrollo (Inotify, Map Count, Swappiness)
echo "ℹ️ Aplicando optimizaciones de kernel sysctl..."
sudo tee /etc/sysctl.d/99-fedora-dev.conf > /dev/null << 'EOF'
# Optimizaciones de desarrollo para Fedora 44 + GNOME
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
fs.file-max = 2097152
vm.max_map_count = 16777216
vm.swappiness = 10
EOF

sudo sysctl --system > /dev/null || true

# 2. Herramientas de Desarrollo (Distrobox)
echo "ℹ️ Instalando Distrobox para contenedores de desarrollo..."
sudo dnf5 install -y distrobox 2>/dev/null || true

echo "✅ Optimizaciones avanzadas de Fedora 44 + GNOME completadas."
