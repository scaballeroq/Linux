#!/usr/bin/env bash
# ==============================================================================
# fonts.sh - Gestión y Diagnóstico de Fuentes de Desarrollo (Nerd Fonts) en NixOS
# ==============================================================================

set -euo pipefail

show_help() {
    cat <<EOF
🔤 Gestor de Fuentes de Desarrollo - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Actualiza la caché de fuentes del sistema (fc-cache).
  --status, -s        Verifica la presencia de Nerd Fonts (JetBrainsMono, FiraCode, Hack...).
  --list, -l          Lista las fuentes monoespaciadas detectadas en Fontconfig.
  --help, -h          Muestra este mensaje de ayuda.

Nota:
  En NixOS, las fuentes se declaran en modules/desktop-kde.nix (fonts.packages).
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DE FUENTES DE DESARROLLO (NERD FONTS) - NIXOS"
    echo "================================================================="

    for font in "JetBrainsMono" "FiraCode" "CascadiaCode" "Meslo" "Hack"; do
        echo -n "• $font Nerd Font: "
        if fc-list : family | grep -qi "$font"; then
            echo "✅ Instalada"
        else
            echo "ℹ️ No detectada en fc-list (declarada en modules/desktop-kde.nix)"
        fi
    done
    echo "================================================================="
}

list_fonts() {
    echo "📋 Fuentes monoespaciadas registradas en el sistema:"
    fc-list : spacing=mono family | sort -u | head -n 30
}

case "${1:-}" in
    --status|-s|status)
        check_status
        exit 0
        ;;
    --list|-l|list)
        list_fonts
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    *)
        echo "🔄 Actualizando caché de fuentes de Fontconfig..."
        fc-cache -fv
        echo "✅ Caché de fuentes actualizada."
        check_status
        ;;
esac
