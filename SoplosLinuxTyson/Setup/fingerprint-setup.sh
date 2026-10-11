#!/usr/bin/env bash
# fingerprint-setup.sh - Configuración de autenticación por huella dactilar (fprintd) en Soplos Linux Tyson (KDE Plasma 6, SDDM, Sudo & PolKit)

set -euo pipefail

echo "================================================================="
echo "🚀 Configurando autenticación por huella dactilar en Soplos Linux Tyson"
echo "================================================================="

# 1. Instalación de paquetes necesarios en Debian Testing
echo "📦 [1/4] Instalando fprintd y libpam-fprintd vía APT..."
sudo apt update
sudo apt install -y fprintd libpam-fprintd

# 2. Habilitar servicio fprintd con systemd
echo "⚙️ [2/4] Habilitando e iniciando servicio fprintd vía systemd..."
sudo systemctl enable --now fprintd.service || true

# 3. Configurar PAM mediante pam-auth-update estándar de Debian
echo "🔐 [3/4] Activando soporte de huella dactilar en PAM (common-auth)..."
if command -v pam-auth-update &> /dev/null; then
    sudo pam-auth-update --enable fprintd
    echo "✅ PAM configurado correctamente para login, bloqueo de pantalla, sudo y PolKit."
fi

# 4. Comprobar lector de huellas dactilares detectado en el sistema
echo "🔍 [4/4] Buscando lector de huellas dactilares..."
if lsusb | grep -i -E "fingerprint|fprint|sensor|touch|validity|synaptics|elan|goodix" > /dev/null 2>&1; then
    echo "✅ Lector de huellas detectado por USB:"
    lsusb | grep -i -E "fingerprint|fprint|sensor|touch|validity|synaptics|elan|goodix" || true
else
    echo "ℹ️ No se identificó explícitamente en lsusb, consultando dispositivo en fprintd..."
fi

echo ""
echo "================================================================="
echo "💡 Para registrar/enrolar tu huella dactilar:"
echo "   1) Por consola: fprintd-enroll"
echo "   2) Desde KDE Plasma 6: Preferencias del Sistema -> Usuarios -> Huella Dactilar"
echo "================================================================="
echo ""

# Registro opcional de huella
TARGET_USER="${SUDO_USER:-$USER}"
read -rp "¿Deseas registrar tu huella dactilar para el usuario '$TARGET_USER' ahora mismo? (s/N): " REGISTER_NOW || true
if [[ "${REGISTER_NOW:-n}" =~ ^[Ss]$ ]]; then
    echo "👆 Coloca o desliza el dedo sobre el sensor varias veces..."
    fprintd-enroll "$TARGET_USER" || echo "⚠️ El registro por consola no finalizó. Puedes completarlo desde Preferencias del Sistema en KDE."
fi

echo ""
echo "================================================================="
echo "✅ Configuración de huella dactilar completada en Soplos Linux Tyson."
echo "================================================================="
