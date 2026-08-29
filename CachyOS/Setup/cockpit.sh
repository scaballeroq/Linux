#!/bin/bash
# ==============================================================================
# cockpit.sh - Administración Web Ligera (Cockpit) para CachyOS + KDE Plasma
# Optimizado para Podman, KVM, Almacenamiento y Sensores Térmicos
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🚀 Configurando Cockpit (Panel Web On-Demand) para CachyOS..."
echo "================================================================="

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no esta disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# 1. Instalación de Cockpit y módulos esenciales
echo "ℹ️ [1/4] Instalando Cockpit, módulos de Podman, KVM, almacenamiento y archivos..."
$SUDO pacman -S --needed --noconfirm \
    cockpit \
    cockpit-podman \
    cockpit-machines \
    cockpit-storaged \
    cockpit-files \
    udisks2 \
    lm_sensors 2>/dev/null || true

# 2. Inicialización de sensores térmicos de CPU (AMD Ryzen)
echo "ℹ️ [2/4] Verificando sensores de hardware..."
$SUDO sensors-detect --auto &>/dev/null || true

# 3. Habilitar Cockpit Socket On-Demand (0 MB RAM en reposo)
echo "ℹ️ [3/4] Habilitando cockpit.socket..."
$SUDO systemctl enable --now cockpit.socket

# 4. Configuración del Firewall (Firewalld y UFW fallback)
echo "ℹ️ [4/4] Configurando reglas de Firewall para el puerto 9090..."
if command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
    $SUDO firewall-cmd --permanent --add-service=cockpit 2>/dev/null || \
    $SUDO firewall-cmd --permanent --add-port=9090/tcp 2>/dev/null || true
    $SUDO firewall-cmd --reload 2>/dev/null || true
    echo "  ✅ Regla añadida a Firewalld (servicio cockpit / 9090)."
fi

if command -v ufw &> /dev/null && $SUDO ufw status 2>/dev/null | grep -q "Status: active"; then
    $SUDO ufw limit 9090/tcp 2>/dev/null || $SUDO ufw allow 9090/tcp || true
    echo "  ✅ Regla añadida a UFW (puerto 9090)."
fi

# Obtener IP local para el enlace
LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || echo "127.0.0.1")

echo "================================================================="
echo "✅ Panel Web Cockpit configurado e integrado con éxito."
echo "🌐 Acceso local:       https://localhost:9090"
echo "🌐 Acceso en tu red:   https://${LOCAL_IP}:9090"
echo "💡 Inicia sesión con tu usuario habitual del sistema."
echo "💡 Consumo: 0 MB RAM en reposo (se activa solo al acceder a la URL)."
echo "================================================================="
