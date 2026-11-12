#!/bin/bash
# cockpit.sh - Instalación y configuración de Cockpit Web Admin para Omarchy (Arch Linux)

set -euo pipefail

echo "🌐 Instalando y configurando Cockpit Web Admin para Omarchy..."

# 1. Instalar Cockpit y extensiones oficiales compatibles con Arch Linux
echo "ℹ️ Instalando Cockpit y extensiones..."
sudo pacman -S --needed --noconfirm \
    cockpit \
    cockpit-machines \
    cockpit-storaged \
    cockpit-files \
    udisks2

# 2. Habilitar el socket de Cockpit (se activa bajo demanda, 0 consumo de RAM en reposo)
echo "ℹ️ Habilitando socket de Cockpit en systemd..."
sudo systemctl enable --now cockpit.socket

# 3. Configurar Firewall (Firewalld exclusivo) para permitir acceso a la interfaz web (puerto 9090)
if command -v firewall-cmd >/dev/null 2>&1; then
    echo "ℹ️ Configurando regla en Firewalld para Cockpit (servicio cockpit / puerto 9090/tcp)..."
    sudo firewall-cmd --permanent --add-service=cockpit 2>/dev/null || sudo firewall-cmd --permanent --add-port=9090/tcp
    sudo firewall-cmd --reload
fi

echo ""
echo "✅ Cockpit instalado y configurado correctamente con Firewalld."
echo "🔗 Accede desde tu navegador en: https://localhost:9090"
