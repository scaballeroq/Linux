#!/bin/bash
# manjaro-tuning.sh - Optimizaciones de Kernel Sysctl y Distrobox para Manjaro Linux + GNOME

set -euo pipefail

echo "🚀 Iniciando optimización avanzada de Manjaro Linux y GNOME..."

# 1. Ajustes de Sysctl para Desarrollo (Inotify, Map Count, Swappiness)
echo "ℹ️ Aplicando optimizaciones de kernel sysctl..."
sudo tee /etc/sysctl.d/99-manjaro-dev.conf > /dev/null <<'EOF'
# Optimizaciones de desarrollo para Manjaro Linux + GNOME
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
fs.file-max = 2097152
vm.max_map_count = 16777216
vm.swappiness = 10
EOF

sudo sysctl --system > /dev/null || true

# 2. Herramientas de Desarrollo y Contenedores (Distrobox)
echo "️ Instalando Distrobox para entornos aislados de desarrollo..."
sudo pacman -S --needed --noconfirm distrobox 2>/dev/null || true

echo "✅ Optimizaciones avanzadas de Manjaro Linux completadas."
