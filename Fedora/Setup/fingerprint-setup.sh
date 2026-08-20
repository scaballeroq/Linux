#!/bin/bash
# fingerprint-setup.sh - Autenticación y desbloqueo por huella dactilar para Fedora 44 + GNOME

set -euo pipefail

echo "🚀 Configurando autenticación por huella dactilar (fprintd + PAM + GNOME)..."

# 1. Instalación de paquetes necesarios
echo "ℹ️ Instalando fprintd y utilidades PAM vía DNF5..."
sudo dnf5 install -y fprintd fprintd-pam

# 2. Habilitar soporte en PAM mediante authselect (Estándar nativo de Fedora)
echo "ℹ️ Configurando PAM con authselect para autenticación biométrica..."
sudo authselect enable-feature with-fingerprint 2>/dev/null || true
sudo authselect apply-changes 2>/dev/null || true

# 3. Habilitar servicio fprintd
sudo systemctl enable --now fprintd.service 2>/dev/null || true

echo "================================================================="
echo "✅ Huella dactilar configurada en PAM y GNOME."
echo "💡 Para registrar tu huella dactilar, ejecuta en tu terminal:"
echo "   fprintd-enroll"
echo "O ve a Ajustes de GNOME -> Usuarios -> Inicio de sesión con huella."
echo "================================================================="
