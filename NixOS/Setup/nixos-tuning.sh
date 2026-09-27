#!/usr/bin/env bash
# ==============================================================================
# nixos-tuning.sh - Diagnóstico, Mantenimiento y Rendimiento del Sistema NixOS
# ==============================================================================

set -euo pipefail

show_help() {
    cat <<EOF
❄️ Mantenimiento y Diagnóstico de Rendimiento para NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  --status, -s        Muestra el estado completo del sistema (ZRAM, Store, Sysctl, Generaciones).
  --gc, -g            Ejecuta recolección de basura (Garbage Collector) liberando espacio en /nix/store.
  --optimise, -o      Optimiza el almacenamiento de /nix/store creando enlaces duros para archivos idénticos.
  --generations, -l   Muestra el listado de generaciones actuales del sistema.
  --verify            Verifica la integridad de las rutas en /nix/store.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE RENDIMIENTO Y MANTENIMIENTO - NIXOS"
    echo "================================================================="

    echo "• Compresión de Memoria ZRAM:"
    if command -v zramctl &>/dev/null; then
        zramctl 2>/dev/null || echo "  ℹ️ Dispositivo ZRAM no activo o sin permisos."
    else
        free -h
    fi

    echo ""
    echo "• Ajustes de Kernel (Sysctl):"
    echo "  - vm.swappiness:                $(sysctl -n vm.swappiness 2>/dev/null || echo 'N/A')"
    echo "  - net.ipv4.tcp_congestion_ctrl: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo 'N/A')"
    echo "  - fs.inotify.max_user_watches:  $(sysctl -n fs.inotify.max_user_watches 2>/dev/null || echo 'N/A')"
    echo "  - fs.file-max:                  $(sysctl -n fs.file-max 2>/dev/null || echo 'N/A')"

    echo ""
    echo "• Almacenamiento de /nix/store:"
    df -h /nix/store 2>/dev/null || df -h /

    echo ""
    echo "• Generaciones del Sistema (últimas 5):"
    if [ -d /nix/var/nix/profiles ]; then
        nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | tail -n 5 || echo "  ℹ️ No se pudieron listar generaciones."
    fi

    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --gc|-g|gc)
        echo "🧹 Ejecutando Garbage Collection en /nix/store..."
        sudo nix-collect-garbage -d
        nix-collect-garbage -d
        echo "✅ Limpieza de paquetes huérfanos completada."
        exit 0
        ;;
    --optimise|-o|optimise|optimize)
        echo "🔗 Optimizando /nix/store con enlaces duros..."
        sudo nix-store --optimise
        echo "✅ Optimización completada."
        exit 0
        ;;
    --generations|-l|generations|list)
        echo "📋 Generaciones registradas en el perfil del sistema:"
        sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
        exit 0
        ;;
    --verify|verify)
        echo "🔍 Verificando integridad de /nix/store..."
        sudo nix-store --verify --check-contents
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    *)
        show_status
        ;;
esac
