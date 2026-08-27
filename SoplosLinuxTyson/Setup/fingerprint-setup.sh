#!/bin/bash
# fingerprint-setup.sh - Configuración de autenticación por huella dactilar (fprintd) en Soplos Linux Tyson (KDE Plasma 6, SDDM, Sudo & PolKit)

set -euo pipefail

echo "🚀 Configurando desbloqueo y autenticación admin por huella dactilar en Soplos Linux Tyson..."

# 1. Instalación de paquetes necesarios
echo "ℹ️ Instalando fprintd, libpam-fprintd e imagemagick vía APT..."
sudo apt update
sudo apt install -y fprintd libpam-fprintd imagemagick

# 2. Habilitar servicio fprintd con systemd
echo "ℹ️ Habilitando e iniciando servicio fprintd vía systemd..."
sudo systemctl enable --now fprintd.service || true

# 3. Configuración de PAM para sudo (autenticación admin en consola)
echo "ℹ️ Configurando PAM para autenticación por huella en sudo (/etc/pam.d/sudo)..."
if ! grep -q "pam_fprintd.so" /etc/pam.d/sudo; then
    sudo sed -i '1s/^/auth       sufficient   pam_fprintd.so\n/' /etc/pam.d/sudo
    echo "✅ Huella dactilar añadida a /etc/pam.d/sudo"
else
    echo "✅ pam_fprintd.so ya está presente en /etc/pam.d/sudo"
fi

# 4. Configuración de PAM para SDDM (Pantalla de login de KDE)
if [ -f /etc/pam.d/sddm ]; then
    echo "ℹ️ Configurando PAM para login con huella en SDDM (/etc/pam.d/sddm)..."
    if ! grep -q "pam_fprintd.so" /etc/pam.d/sddm; then
        sudo sed -i '1s/^/auth       sufficient   pam_fprintd.so\n/' /etc/pam.d/sddm
        echo "✅ Huella dactilar añadida a /etc/pam.d/sddm"
    fi
fi

# 5. Configuración de PAM para KDE Lock Screen (/etc/pam.d/kde)
if [ -f /etc/pam.d/kde ]; then
    echo "ℹ️ Configurando PAM para desbloqueo de KDE (/etc/pam.d/kde)..."
    if ! grep -q "pam_fprintd.so" /etc/pam.d/kde; then
        sudo sed -i '1s/^/auth       sufficient   pam_fprintd.so\n/' /etc/pam.d/kde
        echo "✅ Huella dactilar añadida a /etc/pam.d/kde"
    fi
fi

# 6. Configuración de PAM para PolKit (autenticación admin gráfica en KDE Plasma)
if [ -f /etc/pam.d/polkit-1 ]; then
    echo "ℹ️ Configurando PAM para autenticación gráfica de administración (/etc/pam.d/polkit-1)..."
    if ! grep -q "pam_fprintd.so" /etc/pam.d/polkit-1; then
        sudo sed -i '1s/^/auth       sufficient   pam_fprintd.so\n/' /etc/pam.d/polkit-1
        echo "✅ Huella dactilar añadida a /etc/pam.d/polkit-1"
    fi
fi

# 7. Configurar pam-auth-update (PAM estándar de Debian)
if command -v pam-auth-update &> /dev/null; then
    sudo pam-auth-update --enable fprintd 2>/dev/null || true
fi

# 8. Comprobar lector de huellas dactilares detectado en USB
echo "ℹ️ Buscando lector de huellas dactilares..."
if lsusb | grep -i -E "fingerprint|fprint|sensor|touch|validity|synaptics|elan" > /dev/null 2>&1; then
    echo "✅ Lector de huellas detectado:"
    lsusb | grep -i -E "fingerprint|fprint|sensor|touch|validity|synaptics|elan" || true
else
    echo "ℹ️ No se identificó explícitamente la palabra clave en lsusb, consultando dispositivo en fprintd..."
fi

# 9. Instrucciones y registro opcional
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

echo "✅ Configuración de huella dactilar completada en Soplos Linux Tyson."
