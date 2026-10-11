#!/usr/bin/env bash
# ==============================================================================
# hp-printer-setup.sh - Diagnóstico y Gestión de Impresoras HP en NixOS
# ==============================================================================

set -euo pipefail

show_help() {
    cat <<EOF
🖨️ Gestor de Impresión HP (LaserJet / DeskJet) - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica el estado de CUPS, HPLIP y dispositivos USB.
  --status, -s        Comprueba el estado del servicio CUPS y colas activas.
  --lpstat, -l        Muestra las impresoras registradas en CUPS.
  --help, -h          Muestra este mensaje de ayuda.

Nota para NixOS:
  CUPS y el plugin de HPLIP (pkgs.hplipWithPlugin) están declarados en:
    modules/hardware.nix
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DE IMPRESIÓN HP - NIXOS"
    echo "================================================================="
    echo -n "• Servicio CUPS (cups.service): "
    if systemctl is-active --quiet cups.service 2>/dev/null; then
        echo "✅ Activo (running)"
    else
        echo "❌ Inactivo (verificar services.printing.enable en modules/hardware.nix)"
    fi

    echo -n "• Binario hp-setup / HPLIP: "
    if command -v hp-setup &>/dev/null; then
        echo "✅ Presente ($(which hp-setup))"
    else
        echo "ℹ️ No disponible en PATH directo"
    fi

    echo ""
    echo "• Impresoras USB detectadas (lsusb):"
    lsusb | grep -iE 'hewlett-packard|hp' || echo "  ℹ️ No se detectaron dispositivos USB de HP conectados."

    echo ""
    echo "• Impresoras configuradas en CUPS:"
    if command -v lpstat &>/dev/null; then
        lpstat -p -d 2>/dev/null || echo "  ℹ️ No hay impresoras registradas todavía."
    else
        echo "  ℹ️ lpstat no disponible en PATH."
    fi
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        check_status
        exit 0
        ;;
    --lpstat|-l)
        lpstat -p -d 2>/dev/null || echo "No hay impresoras registradas."
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    *)
        check_status
        ;;
esac
