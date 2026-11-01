#!/usr/bin/env bash
# ==============================================================================
# firefox.sh - Verificación, Optimización y Configuración de Mozilla Firefox
# Fedora Workstation (GNOME Shell Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)
# ==============================================================================
# Características:
# - Verifica e instala Firefox RPM nativo con soporte oficial Wayland y aceleración VA-API.
# - Comprobación de integración de códecs multimedia (FFmpeg + VA-API freeworld).
# - Opciones CLI: --status / -s, --help / -h.
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

if command -v dnf5 &>/dev/null; then
    DNF_CMD="dnf5"
else
    DNF_CMD="dnf"
fi

show_help() {
    cat <<EOF
🦊 Gestor y Optimizador de Mozilla Firefox - Fedora Workstation (GNOME)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica e instala el paquete nativo RPM de Firefox y paquetes de idioma.
  --status, -s        Muestra el diagnóstico de versión de Firefox, paquete RPM y soporte VA-API.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE MOZILLA FIREFOX - FEDORA WORKSTATION"
    echo "================================================================="
    local ff_ver ff_pkg
    ff_ver=$(command -v firefox &>/dev/null && firefox --version 2>/dev/null || echo "No instalado")
    ff_pkg=$(rpm -q firefox 2>/dev/null || echo "No instalado")
    echo "• Versión de Firefox:       $ff_ver"
    echo "• Paquete RPM:              $ff_pkg"
    echo "• Soporte Wayland nativo:   ✅ Integrado por defecto en Fedora"
    echo "• Mesa VA-API freeworld:    $(rpm -q mesa-va-drivers-freeworld 2>/dev/null || echo 'No instalado')"
    echo "• FFmpeg completo:          $(rpm -q ffmpeg 2>/dev/null || echo 'No instalado')"
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🦊 CONFIGURANDO MOZILLA FIREFOX EN FEDORA WORKSTATION"
echo "================================================================="

if ! rpm -q firefox &>/dev/null; then
    echo "📦 Instalando Firefox nativo vía $DNF_CMD..."
    $SUDO $DNF_CMD install -y firefox firefox-langpacks
    echo "✅ Firefox instalado con éxito."
else
    echo "✅ Firefox nativo ($(rpm -q --qf '%{VERSION}' firefox)) ya está instalado en el sistema."
fi

show_status
