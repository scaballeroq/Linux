#!/bin/bash
# fingerprint-setup.sh - Activación de autenticación por huella dactilar (fprintd) en Manjaro Linux
# Nota: fprintd ya viene instalado por defecto en Manjaro GNOME.

set -euo pipefail

echo "🚀 Activando servicio de huella dactilar en Manjaro..."

# 1. Habilitar servicio fprintd
echo "ℹ️ Habilitando e iniciando servicio fprintd..."
sudo systemctl enable --now fprintd.service

# 2. Estado del servicio
echo "================================================================="
echo "✅ Servicio fprintd activo. Estado:"
systemctl status fprintd.service | head -n 5
echo "================================================================="

# 3. Instrucciones para registrar la huella
echo ""
echo "💡 Para registrar tu huella dactilar:"
echo "   1) Por consola: fprintd-enroll"
echo "   2) Desde GNOME: Configuración -> Usuarios -> Huella Dactilar"
echo ""

read -rp "¿Deseas ejecutar 'fprintd-enroll' ahora para registrar tu huella? (s/N): " ENROLL_NOW || true
if [[ "${ENROLL_NOW:-n}" =~ ^[Ss]$ ]]; then
    fprintd-enroll
fi

echo "✅ Configuración de huella dactilar completada."
