#!/usr/bin/env bash
# ==============================================================================
# cockpit.sh - Consola Web Cockpit para NixOS
# ==============================================================================

set -euo pipefail

show_help() {
    cat <<EOF
🎛️ Consola Web Cockpit para NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  --status, -s        Muestra el estado de la consola Cockpit y su socket.
  --open, -o          Abre la interfaz en el navegador web (https://localhost:9090).
  --start             Inicia el servicio/socket de Cockpit.
  --stop              Detiene el servicio de Cockpit.
  --help, -h          Muestra este mensaje de ayuda.

Nota para NixOS:
  Para activar Cockpit declarativamente, asegúrate de tener en tu configuración:
    services.cockpit.enable = true;
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE COCKPIT WEB CONSOLE - NIXOS"
    echo "================================================================="
    echo -n "• Socket Cockpit (puerto 9090): "
    if systemctl is-active --quiet cockpit.socket 2>/dev/null; then
        echo "✅ Activo (Escuchando en https://localhost:9090)"
    else
        echo "❌ Inactivo"
    fi

    echo -n "• Servicio Cockpit: "
    if systemctl is-active --quiet cockpit.service 2>/dev/null; then
        echo "✅ En ejecución"
    else
        echo "ℹ️ En espera (activación por socket bajo demanda)"
    fi
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        check_status
        exit 0
        ;;
    --open|-o|open)
        echo "🌐 Abriendo Cockpit en el navegador web..."
        xdg-open "https://localhost:9090" &>/dev/null &
        exit 0
        ;;
    --start|start)
        echo "🚀 Iniciando socket de Cockpit..."
        sudo systemctl start cockpit.socket
        check_status
        exit 0
        ;;
    --stop|stop)
        echo "🛑 Deteniendo servicio y socket de Cockpit..."
        sudo systemctl stop cockpit.socket cockpit.service 2>/dev/null || true
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
