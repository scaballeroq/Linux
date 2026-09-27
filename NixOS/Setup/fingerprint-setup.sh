#!/usr/bin/env bash
# ==============================================================================
# fingerprint-setup.sh - Gestión de Huella Dactilar (fprintd) en NixOS
# ==============================================================================

set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"

show_help() {
    cat <<EOF
👆 Gestión de Autenticación por Huella Dactilar - NixOS (fprintd)

Uso:
  $0 [OPCIÓN]

Opciones:
  --status, -s        Verifica el estado del servicio fprintd, sensor y dedos registrados.
  --enroll, -e [dedo] Registra una nueva huella (por defecto: right-index-finger).
  --verify, -v        Prueba la verificación de una huella registrada.
  --delete, -d        Elimina las huellas registradas para el usuario actual.
  --help, -h          Muestra este mensaje de ayuda.

Dedos válidos para --enroll:
  right-thumb, right-index-finger, right-middle-finger, right-ring-finger, right-little-finger
  left-thumb, left-index-finger, left-middle-finger, left-ring-finger, left-little-finger
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE HUELLA DACTILAR (FPRINTD) - NIXOS"
    echo "================================================================="
    echo -n "• Servicio fprintd: "
    if systemctl is-active --quiet fprintd 2>/dev/null; then
        echo "✅ Activo"
    else
        echo "ℹ️ En espera (activación por D-Bus)"
    fi

    echo "• Dispositivos biométricos detectados:"
    lsusb | grep -iE 'fingerprint|synaptics|elan|goodix|broadcom' || echo "  ℹ️ No se listaron dispositivos biométricos USB conocidos (comprobar PCI/I2C)"

    echo "• Huellas registradas para '$TARGET_USER':"
    if command -v fprintd-list &>/dev/null; then
        fprintd-list "$TARGET_USER" 2>/dev/null || echo "  ℹ️ Ninguna huella registrada aún."
    else
        echo "  ❌ fprintd-list no disponible en PATH (asegúrate de que services.fprintd.enable = true en NixOS)."
    fi
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        check_status
        exit 0
        ;;
    --enroll|-e|enroll)
        FINGER="${2:-right-index-finger}"
        echo "👆 Registrando huella: $FINGER para '$TARGET_USER'..."
        echo "Coloca el dedo repetidamente sobre el lector cuando se indique:"
        fprintd-enroll -f "$FINGER" "$TARGET_USER"
        echo "✅ Huella registrada con éxito."
        exit 0
        ;;
    --verify|-v|verify)
        echo "🔍 Verificando huella..."
        fprintd-verify "$TARGET_USER"
        exit 0
        ;;
    --delete|-d|delete)
        echo "🗑️ Eliminando huellas de '$TARGET_USER'..."
        fprintd-delete "$TARGET_USER"
        echo "✅ Huellas eliminadas."
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    *)
        check_status
        echo ""
        echo "💡 Para registrar tu huella dactilar, ejecuta: $0 --enroll"
        ;;
esac
