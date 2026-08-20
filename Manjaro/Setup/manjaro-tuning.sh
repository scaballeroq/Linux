#!/bin/bash
# manjaro-tuning.sh - Optimizaciones de Kernel Sysctl, Pacman Paralelo, Pamac y Distrobox para Manjaro Linux + GNOME

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

# 2. Optimización de /etc/pacman.conf (Descargas paralelas, Color, VerbosePkgLists)
echo "ℹ️ Optimizando /etc/pacman.conf para descargas paralelas y colores..."
if [ -f /etc/pacman.conf ]; then
    sudo sed -i 's/^#*Color/Color/' /etc/pacman.conf
    sudo sed -i 's/^#*VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
    sudo sed -i 's/^#*ParallelDownloads = .*/ParallelDownloads = 5/' /etc/pacman.conf
    if ! grep -q "^ParallelDownloads" /etc/pacman.conf; then
        sudo sed -i '/\[options\]/a ParallelDownloads = 5' /etc/pacman.conf
    fi
fi

# 3. Optimización de Servidores Espejo
if command -v pacman-mirrors &> /dev/null; then
    echo "ℹ️ Optimizando espejos más rápidos con pacman-mirrors..."
    sudo pacman-mirrors --fasttrack 5 || true
fi

# 4. Herramientas de Desarrollo y Contenedores (Distrobox)
echo "ℹ️ Instalando Distrobox para entornos aislados de desarrollo..."
sudo pacman -S --needed --noconfirm distrobox 2>/dev/null || true

# 5. Ejecutar instalación modular de extensiones de GNOME
echo "ℹ️ Ejecutando instalación de extensiones de GNOME..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/gnome-extensions.sh" ]; then
    "$SCRIPT_DIR/gnome-extensions.sh"
fi

echo "✅ Optimizaciones avanzadas de Manjaro Linux completadas."
