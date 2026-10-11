#!/bin/bash
# ==============================================================================
# cockpit.sh - Administración Web Ligera (Cockpit) para Arch Linux (Niri + DMS)
# Optimizado para HP EliteBook 855 G7:
#   - Podman Rootless (Quadlets) + QEMU/KVM (cockpit-machines)
#   - Almacenamiento NVMe/SSD (cockpit-storaged) + Explorador de archivos (cockpit-files)
#   - Sensores AMD Ryzen k10temp
#   - Firewalld exclusivo (sin UFW) y arranque bajo demanda (cockpit.socket, 0 MB en reposo)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🚀 Configurando Cockpit (Panel Web On-Demand) para Arch Linux..."
echo "================================================================="

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecución con sudo
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# 1. Instalación de Cockpit y módulos esenciales
echo "ℹ️ [1/4] Instalando Cockpit, módulos de Podman, KVM, almacenamiento y archivos..."
$SUDO pacman -S --needed --noconfirm \
    cockpit \
    cockpit-podman \
    cockpit-machines \
    cockpit-storaged \
    cockpit-files \
    udisks2 \
    lm_sensors

# 2. Sensores térmicos de CPU (AMD Ryzen k10temp)
echo "ℹ️ [2/4] Verificando sensores térmicos (k10temp)..."
if ! lsmod | grep -q "k10temp"; then
    $SUDO modprobe k10temp 2>/dev/null || true
fi
if [ ! -f /etc/modules-load.d/k10temp.conf ]; then
    echo "k10temp" | $SUDO tee /etc/modules-load.d/k10temp.conf >/dev/null
fi

# 3. Habilitar Cockpit Socket On-Demand y socket de Podman Rootless
echo "ℹ️ [3/4] Habilitando cockpit.socket y soporte para Podman rootless..."
$SUDO systemctl enable --now cockpit.socket

# Habilitar linger y socket de Podman para gestión de contenedores del usuario sin root
if [ -n "$REAL_USER" ]; then
    $SUDO loginctl enable-linger "$REAL_USER" 2>/dev/null || true
    run_as_user systemctl --user enable --now podman.socket 2>/dev/null || true
    echo "  ✅ Socket de Podman rootless y linger activos para el usuario $REAL_USER."
fi

# 4. Configuración del Firewall (Firewalld exclusivo)
echo "ℹ️ [4/4] Configurando reglas de Firewalld para el puerto 9090..."
if command -v firewall-cmd &> /dev/null && $SUDO firewall-cmd --state &>/dev/null; then
    DEFAULT_ZONE=$($SUDO firewall-cmd --get-default-zone 2>/dev/null || echo "home")
    $SUDO firewall-cmd --permanent --zone=home --add-service=cockpit 2>/dev/null || \
    $SUDO firewall-cmd --permanent --zone=home --add-port=9090/tcp 2>/dev/null || true

    if [ "$DEFAULT_ZONE" != "home" ]; then
        $SUDO firewall-cmd --permanent --zone="$DEFAULT_ZONE" --add-service=cockpit 2>/dev/null || true
    fi

    $SUDO firewall-cmd --reload 2>/dev/null || true
    echo "  ✅ Regla añadida a Firewalld (servicio cockpit en zona '$DEFAULT_ZONE' y 'home')."
fi

# Obtener IP local para el enlace
LOCAL_IP=$(ip -4 addr show scope global 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1 || \
           ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1 || echo "127.0.0.1")

echo "================================================================="
echo "✅ Panel Web Cockpit configurado e integrado con éxito."
echo "🌐 Acceso local:       https://localhost:9090"
echo "🌐 Acceso en tu red:   https://${LOCAL_IP}:9090"
echo "💡 Inicia sesión con tu usuario habitual del sistema ($REAL_USER)."
echo "💡 Consumo: 0 MB RAM en reposo (se activa solo al acceder a la URL)."
echo "💡 Podman Rootless y Máquinas Virtuales KVM integrados automáticamente."
echo "================================================================="
