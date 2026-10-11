#!/usr/bin/env bash
# ==============================================================================
# shell.sh - Diagnóstico y Verificación de Utilidades Modernas de Shell en NixOS
# ==============================================================================

set -euo pipefail

TOOLS=("eza" "bat" "fzf" "zoxide" "rg" "fd" "duf" "dust" "btop" "jq" "fastfetch" "starship")

show_help() {
    cat <<EOF
🐚 Verificador de Utilidades Modernas de Shell - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Ejecuta diagnóstico de herramientas instaladas.
  --status, -s        Verifica la presencia de utilidades Rust y CLI modernas.
  --help, -h          Muestra este mensaje de ayuda.

Nota:
  En NixOS, estas herramientas se instalan declarativamente en modules/development.nix.
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE HERRAMIENTAS MODERNAS DE TERMINAL (NIXOS)"
    echo "================================================================="

    for tool in "${TOOLS[@]}"; do
        printf "• %-12s: " "$tool"
        if command -v "$tool" &>/dev/null; then
            echo "✅ $(which "$tool")"
        else
            echo "❌ No encontrado (declarado en modules/development.nix)"
        fi
    done
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
