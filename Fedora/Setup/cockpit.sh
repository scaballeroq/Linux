#!/bin/bash
# cockpit.sh - Instalación y configuración del panel web Cockpit en Fedora 44

set -euo pipefail

echo "ℹ️ Instalando Cockpit y módulos avanzados (Podman, Virtualización, Almacenamiento) vía DNF5..."

sudo dnf5 install -y \
    cockpit \
    cockpit-podman \
    cockpit-machines \
    cockpit-storaged \
    cockpit-packagekit \
    cockpit-networkmanager \
    cockpit-selinux 2>/dev/null || sudo dnf5 install -y cockpit cockpit-podman cockpit-machines cockpit-storaged

echo "ℹ️ Habilitando socket de Cockpit..."
sudo systemctl enable --now cockpit.socket

echo "ℹ️ Configurando reglas de firewall para Cockpit..."
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=cockpit 2>/dev/null || sudo firewall-cmd --permanent --add-service=cockpit 2>/dev/null || true
sudo firewall-cmd --reload 2>/dev/null || true

echo "================================================================="
echo "✅ Cockpit instalado y en ejecución."
echo "🌐 Accede desde tu navegador en: https://localhost:9090"
echo "================================================================="
