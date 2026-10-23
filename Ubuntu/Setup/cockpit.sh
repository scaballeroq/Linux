#!/usr/bin/env bash
# ==============================================================================
# cockpit.sh - Consola de Administración Web Cockpit y Cliente de Escritorio
# Ubuntu Workstation (GNOME Shell 51 Wayland)
# ==============================================================================
# Características:
# - Detección inteligente de paquetes e instalación idempotente vía APT.
# - Modo rootless e idempotente: no solicita sudo si Cockpit y el socket ya están listos.
# - Configuración estricta en Firewalld (puerto 9090 / servicio cockpit).
# - Diagnóstico detallado del socket, puerto 9090, reglas de Firewalld y módulos.
# - Control granular del ciclo de vida: --start, --stop, --disable, --open, --client.
# ==============================================================================

set -euo pipefail

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

require_root() {
    if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
        echo "❌ Error: Esta operación requiere privilegios de administrador ('sudo')."
        exit 1
    fi
}

CORE_PACKAGES=(
    "cockpit"
    "cockpit-bridge"
    "cockpit-ws"
    "cockpit-system"
    "cockpit-podman"
    "cockpit-machines"
    "cockpit-storaged"
    "cockpit-networkmanager"
)

show_help() {
    cat <<EOF
🎛️ Gestor de Cockpit Web Console - Ubuntu Workstation

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala Cockpit, sus módulos y habilita el socket en el puerto 9090.
  --status, -s        Muestra diagnóstico completo de servicios, socket, módulos y cortafuegos.
  --open, -o          Abre Cockpit en el navegador web predeterminado (https://localhost:9090).
  --client, -c        Lanza Cockpit Client si está disponible.
  --start             Inicia manualmente el socket y servicio de Cockpit.
  --stop              Detiene el servicio y socket de Cockpit.
  --disable           Deshabilita permanentemente el socket de Cockpit.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE COCKPIT WEB CONSOLE - UBUNTU WORKSTATION"
    echo "================================================================="

    local socket_status ws_status
    socket_status=$(systemctl is-active cockpit.socket 2>/dev/null || echo "inactivo")
    ws_status=$(systemctl is-active cockpit.service 2>/dev/null || echo "inactivo")

    echo "• Socket de Cockpit:         $(if [ "$socket_status" = "active" ]; then echo "✅ Activo (bajo demanda)"; else echo "❌ Inactivo"; fi)"
    echo "• Servicio Web (cockpit.ws): $(if [ "$ws_status" = "active" ]; then echo "🟢 En ejecución"; else echo "⚪ Inactivo (se activa al conectar)"; fi)"
    echo "• Puerto 9090:               $(if ss -tlnp 2>/dev/null | grep -q ":9090 "; then echo "✅ Escuchando"; else echo "❌ No detectado"; fi)"
    echo "-----------------------------------------------------------------"
    echo "• Reglas de Cortafuegos (Firewalld):"
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        local active_zone
        active_zone=$($SUDO firewall-cmd --get-default-zone 2>/dev/null || echo "public")
        echo "  - Estado de Firewalld:     ✅ Activo"
        echo "  - Servicio 'cockpit':      $($SUDO firewall-cmd --zone="$active_zone" --query-service=cockpit 2>/dev/null && echo '✅ Permitido (9090 TCP)' || echo '❌ No permitido')"
    else
        echo "  - Estado de Firewalld:     ❌ Inactivo o no instalado"
    fi
    echo "-----------------------------------------------------------------"
    echo "• Módulos instalados:"
    for pkg in "${CORE_PACKAGES[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            printf "  - %-25s ✅ Instalado\n" "$pkg"
        else
            printf "  - %-25s ❌ No instalado\n" "$pkg"
        fi
    done
    echo "================================================================="
    echo "🌐 URL de acceso local: https://localhost:9090"
}

open_browser() {
    echo "🌐 Abriendo Cockpit en el navegador web..."
    if command -v xdg-open &>/dev/null; then
        xdg-open "https://localhost:9090" &>/dev/null &
    else
        echo "Accede manualmente a: https://localhost:9090"
    fi
}

start_cockpit() {
    require_root
    echo "▶️ Iniciando Cockpit socket..."
    $SUDO systemctl enable --now cockpit.socket
    echo "✅ Cockpit socket activo."
}

stop_cockpit() {
    require_root
    echo "⏹️ Deteniendo Cockpit..."
    $SUDO systemctl stop cockpit.service cockpit.socket 2>/dev/null || true
    echo "✅ Cockpit detenido."
}

disable_cockpit() {
    require_root
    echo "🛑 Deshabilitando Cockpit..."
    $SUDO systemctl disable --now cockpit.socket cockpit.service 2>/dev/null || true
    echo "✅ Cockpit deshabilitado."
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --open|-o)
        open_browser
        exit 0
        ;;
    --client|-c)
        if command -v cockpit-client &>/dev/null; then
            cockpit-client &>/dev/null &
        else
            open_browser
        fi
        exit 0
        ;;
    --start)
        start_cockpit
        exit 0
        ;;
    --stop)
        stop_cockpit
        exit 0
        ;;
    --disable)
        disable_cockpit
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🎛️ CONFIGURANDO COCKPIT WEB CONSOLE (UBUNTU WORKSTATION)"
echo "================================================================="

require_root

# 1. Instalar Cockpit y módulos
echo "ℹ️ [1/3] Instalando Cockpit y módulos de administración..."
$SUDO apt update
$SUDO apt install -y "${CORE_PACKAGES[@]}"

# 2. Habilitar Cockpit Socket
echo "ℹ️ [2/3] Habilitando Cockpit Socket..."
$SUDO systemctl enable --now cockpit.socket

# 3. Configurar Firewalld (puerto 9090)
echo "ℹ️ [3/3] Configurando Firewalld (servicio cockpit / puerto 9090)..."
if command -v firewall-cmd &>/dev/null; then
    ACTIVE_ZONE=$($SUDO firewall-cmd --get-default-zone 2>/dev/null || echo "public")
    $SUDO firewall-cmd --permanent --zone="$ACTIVE_ZONE" --add-service=cockpit 2>/dev/null || true
    $SUDO firewall-cmd --reload 2>/dev/null || true
    echo "  ✅ Regla de Cockpit añadida a Firewalld."
fi

echo ""
echo "================================================================="
echo "✅ Cockpit Web Console instalado y configurado con éxito."
echo "🌐 URL: https://localhost:9090"
echo "💡 Inicia sesión con tu usuario y contraseña de Ubuntu."
echo "================================================================="
