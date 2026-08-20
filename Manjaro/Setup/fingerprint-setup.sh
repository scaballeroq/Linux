#!/bin/bash
# fingerprint-setup.sh - Configuración de autenticación por huella dactilar (fprintd) en Manjaro Linux (GNOME, Sudo & PolKit)

set -euo pipefail

echo "🚀 Configurando desbloqueo y autenticación admin por huella dactilar en Manjaro..."

# 1. Instalación de paquetes necesarios
echo "ℹ️ Instalando fprintd e imagemagick vía Pacman..."
sudo pacman -S --needed --noconfirm fprintd imagemagick

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

# 4. Configuración de PAM para PolKit (autenticación admin gráfica en GNOME)
echo "ℹ️ Configurando PAM para autenticación gráfica de administración (/etc/pam.d/polkit-1)..."
if [ -f /etc/pam.d/polkit-1 ]; then
    if ! grep -q "pam_fprintd.so" /etc/pam.d/polkit-1; then
        sudo sed -i '1s/^/auth       sufficient   pam_fprintd.so\n/' /etc/pam.d/polkit-1
        echo "✅ Huella dactilar añadida a /etc/pam.d/polkit-1"
    else
        echo "✅ pam_fprintd.so ya está presente en /etc/pam.d/polkit-1"
    fi
fi

# 5. Configuración de PAM para desbloqueo local y GDM (/etc/pam.d/system-local-login)
if [ -f /etc/pam.d/system-local-login ]; then
    if ! grep -q "pam_fprintd.so" /etc/pam.d/system-local-login; then
        sudo sed -i '1s/^/auth       sufficient   pam_fprintd.so\n/' /etc/pam.d/system-local-login
        echo "✅ Huella dactilar añadida a /etc/pam.d/system-local-login"
    fi
fi

# 6. Comprobar lector de huellas dactilares detectado en USB
echo "ℹ️ Buscando lector de huellas dactilares..."
if lsusb | grep -i -E "fingerprint|fprint|sensor|touch|validity|synaptics|elan" > /dev/null 2>&1; then
    echo "✅ Lector de huellas detectado:"
    lsusb | grep -i -E "fingerprint|fprint|sensor|touch|validity|synaptics|elan" || true
else
    echo "ℹ️ No se identificó explícitamente la palabra clave en lsusb, consultando dispositivo en fprintd..."
fi

# 7. Instrucciones y registro opcional
echo ""
echo "================================================================="
echo "💡 Para registrar/enrolar tu huella dactilar:"
echo "   1) Por consola: fprintd-enroll"
echo "   2) Desde GNOME: Configuración -> Usuarios -> Huella Dactilar"
echo "================================================================="
echo ""

read -rp "¿Deseas ejecutar 'fprintd-enroll' ahora para registrar tu huella? (s/N): " ENROLL_NOW || true
if [[ "${ENROLL_NOW:-n}" =~ ^[Ss]$ ]]; then
    fprintd-enroll || true
fi

echo "✅ Configuración de huella dactilar completada en Manjaro."
