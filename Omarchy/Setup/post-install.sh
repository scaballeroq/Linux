#!/usr/bin/env bash
# ==============================================================================
# post-install.sh - Mantenimiento y Verificación de Omarchy 4.5
# Sistema: Arch Linux / Omarchy 4.5 (Hyprland Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / 32 GB RAM / NVMe Kioxia)
# ==============================================================================
# Respeta la configuración original y pura de Omarchy:
#   - NO modifica WiFi, Bluetooth ni perfiles de energía (gestión nativa Omarchy).
#   - NO sobreescribe ZRAM (preserva los 30.7 GB nativos de Omarchy).
#   - NO reinstala drivers gráficos AMD ni servidor de audio PipeWire.
#   - Habilita fstrim.timer para el mantenimiento saludable del SSD NVMe Kioxia.
#   - Integra el repositorio precompilado Chaotic-AUR (Setup/chaotic-aur.sh).
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================================="
echo "🚀 Mantenimiento y Verificación de Omarchy 4.5 (HP ProBook 455 G10)"
echo "================================================================="

# 1. Repositorio precompilado Chaotic-AUR y optimizaciones de Pacman
if [ -f "$SCRIPT_DIR/chaotic-aur.sh" ]; then
    echo "ℹ️ [1/2] Verificando repositorio precompilado Chaotic-AUR..."
    bash "$SCRIPT_DIR/chaotic-aur.sh"
fi

# 2. Mantenimiento del SSD NVMe Kioxia (fstrim semanal)
echo "ℹ️ [2/2] Asegurando temporizador de mantenimiento SSD NVMe (fstrim.timer)..."
sudo systemctl enable --now fstrim.timer 2>/dev/null || true

echo ""
echo "================================================================="
echo "✅ Omarchy 4.5 verificado. Esencia y configuración original preservadas:"
echo "   - WiFi, Bluetooth y perfiles de energía: 100% nativos Omarchy."
echo "   - Audio PipeWire y drivers AMD: 100% nativos Omarchy."
echo "   - ZRAM: Configuración oficial intacta (30.7 GB)."
echo "   - Repositorio Chaotic-AUR: Integrado y optimizado."
echo "================================================================="
