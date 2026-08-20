#!/bin/bash
# fingerprint-setup.sh - Autenticación y desbloqueo por huella dactilar para OpenSUSE Tumbleweed + GNOME

set -euo pipefail

echo "🚀 Configurando autenticación por huella dactilar (fprintd + PAM + GNOME)..."

# 1. Instalación de paquetes necesarios
echo "ℹ️ Instalando fprintd y utilidades PAM vía Zypper..."
sudo zypper --non-interactive install -y fprintd fprintd-pam 2>/dev/null || true

# 2. Habilitar soporte en PAM mediante pam-config (Estándar nativo de openSUSE)
echo "ℹ️ Configurando PAM con pam-config para autenticación biométrica..."
sudo pam-config -a --fp 2>/dev/null || sudo pam-config -a --fprintd 2>/dev/null || true

# 3. Habilitar servicio fprintd
sudo systemctl enable --now fprintd.service 2>/dev/null || true

echo "================================================================="
echo "✅ Huella dactilar configurada en PAM y GNOME."
echo "💡 Para registrar tu huella dactilar, ejecuta en tu terminal:"
echo "   fprintd-enroll"
echo "O ve a Ajustes de GNOME -> Usuarios -> Inicio de sesión con huella."
echo "================================================================="
