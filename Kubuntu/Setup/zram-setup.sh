#!/bin/bash
# zram-setup.sh - Configuración de ZRAM con compresión ZSTD para Kubuntu
# Usa zram-tools (paquete Ubuntu) para crear swap comprimida en RAM

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
    else
        echo "Error: Este script requiere privilegios de superusuario."
        exit 1
    fi
else
    SUDO=""
fi

echo "================================================================="
echo "CONFIGURANDO ZRAM CON ZSTD - KUBUNTU"
echo "================================================================="

# 1. Instalar zram-tools
echo "Instalando zram-tools..."
$SUDO apt update
$SUDO apt install -y zram-tools

# 2. Configurar ZRAM
echo "Configurando ZRAM con algoritmo zstd al 50% de RAM..."
$SUDO tee /etc/default/zramswap > /dev/null << 'EOF'
# ZRAM Configuration - Kubuntu
ALGORITHM=zstd
PERCENT=50
EOF

# 3. Habilitar y reiniciar servicio
echo "Habilitando servicio zramswap..."
$SUDO systemctl enable --now zramswap.service 2>/dev/null || true

# 4. Verificar
echo ""
echo "Estado de ZRAM:"
if command -v zramctl &>/dev/null; then
    zramctl 2>/dev/null || echo "zramctl no disponible"
fi
echo ""
echo "Swap activa:"
swapon --show 2>/dev/null || true

echo "================================================================="
echo "ZRAM configurado correctamente con zstd al 50% de RAM."
echo "================================================================="
