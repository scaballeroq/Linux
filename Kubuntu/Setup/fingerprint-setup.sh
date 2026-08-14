#!/bin/bash
# fingerprint-setup.sh - Configuración de autenticación por huella dactilar (fprintd) en Kubuntu (KDE, Sudo & PolKit)

set -euo pipefail

echo "🚀 Configurando desbloqueo y autenticación admin por huella dactilar en Kubuntu..."

# 1. Instalación de paquetes necesarios
echo "ℹ️ Instalando fprintd, libpam-fprintd e imagemagick vía APT..."
sudo apt update
sudo apt install -y fprintd libpam-fprintd imagemagick

# 2. Habilitar servicio fprintd
echo "ℹ️ Habilitando e iniciando servicio fprintd..."
sudo systemctl enable --now fprintd.service || true

# 3. Configuración de PAM para sudo (autenticación admin en consola)
echo "ℹ️ Configurando PAM para autenticación por huella en sudo (/etc/pam.d/sudo)..."
if ! grep -q "pam_fprintd.so" /etc/pam.d/sudo; then
    sudo sed -i '1s/^/auth       sufficient   pam_fprintd.so\n/' /etc/pam.d/sudo
    echo "✅ Huella dactilar añadida a /etc/pam.d/sudo"
else
    echo "✅ pam_fprintd.so ya está presente en /etc/pam.d/sudo"
fi

# 4. Configuración de PAM para PolKit (autenticación admin gráfica en KDE)
echo "ℹ️ Configurando PAM para autenticación gráfica de administración (/etc/pam.d/polkit-1)..."
if [ -f /etc/pam.d/polkit-1 ]; then
    if ! grep -q "pam_fprintd.so" /etc/pam.d/polkit-1; then
        sudo sed -i '1s/^/auth       sufficient   pam_fprintd.so\n/' /etc/pam.d/polkit-1
        echo "✅ Huella dactilar añadida a /etc/pam.d/polkit-1"
    else
        echo "✅ pam_fprintd.so ya está presente en /etc/pam.d/polkit-1"
    fi
fi

# 5. Configuración de PAM para pantalla de bloqueo / SDDM
if [ -f /etc/pam.d/sddm ]; then
    if ! grep -q "pam_fprintd.so" /etc/pam.d/sddm; then
        sudo sed -i '1s/^/auth       sufficient   pam_fprintd.so\n/' /etc/pam.d/sddm || true
    fi
fi

# 6. Configurar pam-auth-update (PAM estándar de Ubuntu/Debian)
if command -v pam-auth-update &> /dev/null; then
    sudo pam-auth-update --enable fprintd 2>/dev/null || true
fi

# 7. Comprobar lector de huellas dactilares detectado en USB
echo "ℹ️ Buscando lector de huellas dactilares..."
if lsusb | grep -i -E "fingerprint|fprint|sensor|touch|validity|synaptics|elan" > /dev/null 2>&1; then
    echo "✅ Lector de huellas detectado:"
    lsusb | grep -i -E "fingerprint|fprint|sensor|touch|validity|synaptics|elan" || true
else
    echo "ℹ️ Consultando estado del lector en fprintd..."
fi

# 8. Instrucciones y registro opcional
echo ""
echo "================================================================="
echo "💡 Para registrar/enrolar tu huella dactilar:"
echo "   1) Por consola: fprintd-enroll"
echo "   2) Desde KDE: Preferencias del Sistema -> Usuarios -> Huella Dactilar"
echo "================================================================="
echo ""

read -rp "¿Deseas registrar tu huella dactilar por consola ahora mismo? (s/N): " REGISTER_NOW || true
if [[ "${REGISTER_NOW:-n}" =~ ^[Ss]$ ]]; then
    echo "👆 Coloca o desliza el dedo sobre el sensor varias veces..."
    fprintd-enroll "${SUDO_USER:-$USER}" || echo "⚠️ El registro por consola no finalizó. Puedes probar desde Preferencias del Sistema en KDE."
fi

echo "✅ Configuración de huella dactilar completada en Kubuntu."
