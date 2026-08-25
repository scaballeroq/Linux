#!/bin/bash
# ==============================================================================
# SEGURIDAD Y CONECTIVIDAD LOCAL (seguridad.sh) - Fedora 44 (KDE Plasma / Home Wi-Fi)
# ==============================================================================
# Configura el cortafuegos estándar (Firewalld) para proteger el sistema mientras
# permite la integración de tu móvil (KDE Connect) e impresoras/dispositivos (mDNS)
# en tu red Wi-Fi de casa.
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🛡️ Configurando Firewall para KDE Plasma y red doméstica..."
echo "================================================================="

# 1. Habilitar y activar Firewalld
sudo systemctl enable --now firewalld

# 2. Permitir KDE Connect (comunicación móvil <-> PC) y mDNS (impresoras / red local)
echo "ℹ️ Habilitando reglas para KDE Connect y mDNS..."
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=kdeconnect 2>/dev/null || true
sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=mdns 2>/dev/null || true
sudo firewall-cmd --reload

echo "================================================================="
echo "✅ Configuración de Firewall completada para red doméstica."
echo "💡 KDE Connect y detección de dispositivos locales habilitados."
echo "================================================================="



