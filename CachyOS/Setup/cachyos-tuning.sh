#!/bin/bash
# cachyos-tuning.sh - Optimizaciones de Kernel, Ananicy-cpp y Distrobox para CachyOS

set -euo pipefail

echo "🚀 Iniciando optimización avanzada de CachyOS y GNOME..."

# 1. Ajustes de Sysctl para Desarrollo (Inotify, Map Count, Swappiness)
echo "ℹ️ Aplicando optimizaciones de kernel sysctl..."
sudo cat <<'EOF' | sudo tee /etc/sysctl.d/99-cachyos-dev.conf > /dev/null
# Optimizaciones de desarrollo para CachyOS + GNOME
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
fs.file-max = 2097152
vm.max_map_count = 16777216
vm.swappiness = 180
EOF

sudo sysctl --system > /dev/null || true

# 2. Habilitar Ananicy-cpp (Auto-priorización inteligente de procesos)
if command -v ananicy-cpp &> /dev/null; then
    echo "ℹ️ Habilitando servicio ananicy-cpp..."
    sudo systemctl enable --now ananicy-cpp.service || true
else
    echo "ℹ️ Instalando y habilitando ananicy-cpp..."
    sudo pacman -S --needed --noconfirm ananicy-cpp cachyos-ananicy-rules 2>/dev/null || sudo pacman -S --needed --noconfirm ananicy-cpp || true
    sudo systemctl enable --now ananicy-cpp.service || true
fi

# 3. Herramientas de Desarrollo
echo "ℹ️ Instalando Distrobox y CachyOS Kernel Manager..."
sudo pacman -S --needed --noconfirm \
    distrobox \
    cachyos-kernel-manager 2>/dev/null || true

# 4. Llamar al script modular de extensiones de GNOME
echo "ℹ️ Ejecutando instalación de extensiones de GNOME..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/gnome-extensions.sh" ]; then
    "$SCRIPT_DIR/gnome-extensions.sh"
fi

echo "✅ Optimizaciones avanzadas de CachyOS completadas."
