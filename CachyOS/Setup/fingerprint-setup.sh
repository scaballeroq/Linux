#!/bin/bash
# fingerprint-setup.sh - Configuracion de autenticacion por huella dactilar (fprintd) en CachyOS (KDE Plasma 6, SDDM, Sudo & PolKit)

set -euo pipefail

echo "🚀 Configurando desbloqueo y autenticacion admin por huella dactilar en CachyOS..."

# 1. Instalacion de paquetes necesarios
echo "ℹ️ Instalando fprintd e imagemagick via Pacman..."
sudo pacman -S --needed --noconfirm fprintd imagemagick 2>/dev/null || true

# 2. Habilitar servicio fprintd
echo "ℹ️ Habilitando e iniciando servicio fprintd..."
sudo systemctl enable --now fprintd.service || true

# 3. Configuracion de PAM para sudo (autenticacion admin en consola)
echo "ℹ️ Configurando PAM para autenticacion por huella en sudo (/etc/pam.d/sudo)..."
if [ -f /etc/pam.d/sudo ]; then
    if ! grep -q "pam_fprintd.so" /etc/pam.d/sudo; then
        sudo sed -i '1s/^/auth       sufficient   pam_fprintd.so\n/' /etc/pam.d/sudo
        echo "✅ Huella dactilar añadida a /etc/pam.d/sudo"
    else
        echo "✅ pam_fprintd.so ya esta presente en /etc/pam.d/sudo"
    fi
fi

# 4. Configuracion de PAM para PolKit (autenticacion admin grafica)
echo "ℹ️ Configurando PAM para autenticacion grafica de administracion (/etc/pam.d/polkit-1)..."
if [ -f /etc/pam.d/polkit-1 ]; then
    if ! grep -q "pam_fprintd.so" /etc/pam.d/polkit-1; then
        sudo sed -i '1s/^/auth       sufficient   pam_fprintd.so\n/' /etc/pam.d/polkit-1
        echo "✅ Huella dactilar añadida a /etc/pam.d/polkit-1"
    else
        echo "✅ pam_fprintd.so ya esta presente en /etc/pam.d/polkit-1"
    fi
fi

# 5. Configuracion de PAM para desbloqueo local y pantalla de bloqueo de KDE / SDDM
for pam_file in /etc/pam.d/system-local-login /etc/pam.d/kde /etc/pam.d/sddm; do
    if [ -f "$pam_file" ]; then
        if ! grep -q "pam_fprintd.so" "$pam_file"; then
            sudo sed -i '1s/^/auth       sufficient   pam_fprintd.so\n/' "$pam_file"
            echo "✅ Huella dactilar añadida a $pam_file"
        fi
    fi
done

# 6. Comprobar lector de huellas dactilares detectado en USB
echo "ℹ️ Buscando lector de huellas dactilares..."
if lsusb | grep -i -E "fingerprint|fprint|sensor|touch|validity|synaptics|elan" > /dev/null 2>&1; then
    echo "✅ Lector de huellas detectado:"
    lsusb | grep -i -E "fingerprint|fprint|sensor|touch|validity|synaptics|elan" || true
else
    echo "ℹ️ No se identifico explicitamente la palabra clave en lsusb, consultando dispositivo en fprintd..."
fi

# 7. Instrucciones y registro opcional
echo ""
echo "================================================================="
echo "💡 Para registrar/enrolar tu huella dactilar:"
echo "   1) Por consola:        fprintd-enroll"
echo "   2) Desde KDE Plasma:   Preferencias del Sistema -> Usuarios -> Huella Dactilar"
echo "================================================================="
echo ""

read -rp "¿Deseas registrar tu huella dactilar por consola ahora mismo? (s/N): " REGISTER_NOW || true
if [[ "${REGISTER_NOW:-n}" =~ ^[Ss]$ ]]; then
    echo "👆 Coloca o desliza el dedo sobre el sensor varias veces..."
    fprintd-enroll "${SUDO_USER:-$USER}" || echo "⚠️ El registro por consola no finalizo. Puedes probar desde Preferencias del Sistema -> Usuarios en KDE Plasma."
fi

echo "✅ Configuracion de huella dactilar completada para CachyOS + KDE Plasma 6."
