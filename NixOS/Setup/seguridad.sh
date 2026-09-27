#!/usr/bin/env bash
# ==============================================================================
# seguridad.sh - Diagnóstico de Seguridad, Cortafuegos y Reglas PAM en NixOS
# ==============================================================================

set -euo pipefail

show_help() {
    cat <<EOF
🛡️ Diagnóstico de Seguridad y Cortafuegos - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Muestra el diagnóstico general de seguridad.
  --status, -s        Comprueba el estado de puertos, cortafuegos y reglas PAM.
  --help, -h          Muestra este mensaje de ayuda.

Nota:
  En NixOS, las políticas de seguridad se configuran de forma inmutable en:
    modules/security.nix
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DE SEGURIDAD Y CORTAFUEGOS - NIXOS"
    echo "================================================================="

    echo -n "• Servicio de Cortafuegos (firewall.service): "
    if systemctl is-active --quiet firewall 2>/dev/null; then
        echo "✅ Activo"
    else
        echo "⚠️ Inactivo o gestionado por nftables directo"
    fi

    echo ""
    echo "• Puertos locales en escucha:"
    if command -v ss &>/dev/null; then
        ss -tulpn 2>/dev/null | grep -E ':(22|9090|171[4-9]|172[0-9]|5353)\b' || echo "  ℹ️ No se detectaron servicios escuchando en puertos estándar."
    fi

    echo ""
    echo "• Interfaces virtuales de contenedores/VMs:"
    ip link show | grep -E 'virbr|podman|docker' || echo "  ℹ️ Ninguna interfaz virtual activa en este momento."

    echo ""
    echo "• Módulo PAM fprintd en SDDM:"
    if grep -q "pam_fprintd.so" /etc/pam.d/sddm 2>/dev/null; then
        echo "⚠️ fprintd activo en SDDM (puede causar lentitud en login gráfico)"
    else
        echo "✅ SDDM configurado para contraseña inmediata (fprintAuth = false)"
    fi
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        check_status
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
