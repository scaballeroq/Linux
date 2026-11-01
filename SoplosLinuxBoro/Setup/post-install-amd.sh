#!/bin/bash
# ==============================================================================
# post-install-amd.sh - Post-instalación para Soplos Linux Boro con AMD Ryzen y AMD Graphics
# Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics (Vega 8))
# Sistema: Soplos Linux Boro | Entorno: GNOME Shell (Wayland)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "INICIANDO POST-INSTALACIÓN: SOPLOS LINUX BORO (GNOME SHELL) - AMD RYZEN"
echo "================================================================="

CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 || true)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "trixie")
fi

echo "Soplos Linux Boro detectado: $CODENAME"

# 1. Utilidades y Herramientas Faltantes
echo "ℹ️ Instalando utilidades complementarias del sistema..."
sudo apt install -y \
    linux-headers-amd64 \
    cmake \
    inxi \
    zip \
    wl-clipboard

# Limpieza de paquetes residuales
echo "ℹ️ Limpiando dependencias huérfanas y caché..."
sudo apt autoremove -y
sudo apt clean

# 2. Verificación del estado de AMD GPU
echo "ℹ️ Verificando controlador gráfico AMD GPU..."
if lsmod | grep -q "^amdgpu"; then
    echo "✅ Módulo de kernel amdgpu cargado correctamente."
else
    echo "⚠️ Módulo amdgpu no detectado en memoria."
fi

echo "================================================================="
echo "✅ Post-instalación AMD completada con éxito en Soplos Linux Boro ($CODENAME)."
echo "================================================================="
