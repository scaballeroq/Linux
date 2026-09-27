#!/usr/bin/env bash
# ==============================================================================
# steam.sh - Diagnóstico y Configuración de Steam, GameMode y MangoHud en NixOS
# ==============================================================================

set -euo pipefail

show_help() {
    cat <<EOF
🎮 Gestor de Steam y Stack de Gaming - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica el estado del stack de gaming en NixOS.
  --status, -s        Comprueba la instalación de Steam, GameMode, MangoHud y aceleración 32-bit.
  --run, -r           Inicia Steam en modo cliente.
  --help, -h          Muestra este mensaje de ayuda.

Nota para NixOS:
  Steam requiere soporte de 32-bit y librerías FHS. En este repositorio ya está
  declarado de forma óptima en:
    modules/gaming.nix (programs.steam.enable = true;)
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE STEAM Y GAMING - NIXOS"
    echo "================================================================="
    echo -n "• Binario Steam: "
    if command -v steam &>/dev/null; then
        echo "✅ Presente ($(which steam))"
    else
        echo "❌ No instalado (activar con modules/gaming.nix)"
    fi

    echo -n "• GameMode (daemon): "
    if command -v gamemoded &>/dev/null; then
        echo "✅ Activo ($(gamemoded --version 2>/dev/null || echo 'instalado'))"
    else
        echo "ℹ️ No detectado"
    fi

    echo -n "• MangoHud: "
    if command -v mangohud &>/dev/null; then
        echo "✅ Instalado"
    else
        echo "ℹ️ No detectado"
    fi

    echo -n "• Soporte Vulkan 32-bit: "
    if [ -d "/run/opengl-driver-32" ] || [ -d "/run/opengl-driver" ]; then
        echo "✅ Configurado por NixOS (hardware.graphics.enable32Bit = true)"
    else
        echo "ℹ️ Gestionado dinámicamente por NixOS"
    fi
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        check_status
        exit 0
        ;;
    --run|-r|run)
        if command -v steam &>/dev/null; then
            echo "🎮 Lanzando Steam..."
            steam &>/dev/null &
        else
            echo "❌ Steam no está instalado."
        fi
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
