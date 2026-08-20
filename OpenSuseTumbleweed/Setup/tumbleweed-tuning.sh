#!/bin/bash
# tumbleweed-tuning.sh - Optimizaciones de Kernel Sysctl, Snapper (Btrfs) y Distrobox en OpenSUSE Tumbleweed + GNOME

set -euo pipefail

echo "🚀 Iniciando optimización avanzada del sistema OpenSUSE Tumbleweed + GNOME..."

# 1. Ajustes de Sysctl para Desarrollo (Inotify, Map Count, Swappiness)
echo "ℹ️ Aplicando optimizaciones de kernel sysctl..."
sudo tee /etc/sysctl.d/99-tumbleweed-dev.conf > /dev/null <<'EOF'
# Optimizaciones de desarrollo para OpenSUSE Tumbleweed + GNOME
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
fs.file-max = 2097152
vm.max_map_count = 16777216
vm.swappiness = 10
EOF

sudo sysctl --system > /dev/null || true

# 2. Optimización y Políticas de Retención de Snapper (Btrfs)
if command -v snapper &> /dev/null && [ -f /etc/snapper/configs/root ]; then
    echo "ℹ️ Ajustando límites de retención de instantáneas Snapper (/etc/snapper/configs/root)..."
    sudo sed -i 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' /etc/snapper/configs/root 2>/dev/null || true
    sudo sed -i 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="7"/' /etc/snapper/configs/root 2>/dev/null || true
    sudo sed -i 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="2"/' /etc/snapper/configs/root 2>/dev/null || true
    sudo sed -i 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/' /etc/snapper/configs/root 2>/dev/null || true
    sudo sed -i 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' /etc/snapper/configs/root 2>/dev/null || true
    
    # Asegurar timers de limpieza de Snapper activos
    sudo systemctl enable --now snapper-cleanup.timer 2>/dev/null || true
    sudo systemctl enable --now snapper-timeline.timer 2>/dev/null || true
    echo "✅ Políticas de Snapper optimizadas para prevenir saturación de disco Btrfs."
fi

# 3. Herramientas de Desarrollo (Distrobox)
echo "ℹ️ Instalando Distrobox para contenedores de desarrollo..."
sudo zypper --non-interactive install -y distrobox 2>/dev/null || true

echo "================================================================="
echo "✅ Optimizaciones avanzadas de OpenSUSE Tumbleweed completadas."
echo "================================================================="
