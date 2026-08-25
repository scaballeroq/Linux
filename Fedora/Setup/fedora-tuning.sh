#!/bin/bash
# fedora-tuning.sh - Optimizaciones de Kernel Sysctl y Distrobox en Fedora 44 (KDE Plasma 6)

set -euo pipefail

echo "================================================================="
echo "🚀 Iniciando optimización avanzada del sistema (Fedora 44 / KDE)"
echo "================================================================="

# 1. Ajustes de Sysctl para Desarrollo, Juegos (Steam Proton) y File Watchers
echo "ℹ️ [1/2] Aplicando optimizaciones de kernel sysctl..."
sudo tee /etc/sysctl.d/99-fedora-dev.conf > /dev/null << 'EOF'
# Monitorización de ficheros (IDEs, VS Code, Vite, Webpack, Baloo indexer)
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024

# Límite ampliado de descriptores de ficheros abiertos
fs.file-max = 2097152

# Asignaciones de memoria virtual para Juegos (Steam Proton/Wine) y Contenedores
vm.max_map_count = 2147483642
EOF

sudo sysctl --system > /dev/null || true

# 2. Herramientas de Desarrollo en Contenedores (Distrobox)
echo "ℹ️ [2/2] Instalando Distrobox para contenedores de desarrollo..."
sudo dnf5 install -y distrobox 2>/dev/null || true

echo "================================================================="
echo "✅ Optimizaciones avanzadas para Fedora 44 (KDE Plasma) completadas."
echo "================================================================="

