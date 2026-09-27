#!/usr/bin/env bash
# ==============================================================================
# chrome.sh - Instalación, Optimización y Diagnóstico de Google Chrome en NixOS
# ==============================================================================

set -euo pipefail

# Detección de usuario
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

show_help() {
    cat <<EOF
🌐 Gestor de Google Chrome - NixOS

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica e instala o lanza Google Chrome con Wayland nativo.
  --status, -s        Comprueba el estado del navegador y aceleración gráfica.
  --flatpak           Instala Google Chrome vía Flatpak Flathub (alternativa aislada).
  --run, -r           Lanza Google Chrome con aceleración por hardware en Wayland.
  --help, -h          Muestra este mensaje de ayuda.

Nota para NixOS:
  Google Chrome oficial está disponible en nixpkgs como paquete unfree:
    pkgs.google-chrome
  Asegúrate de tener nixpkgs.config.allowUnfree = true en tu configuración de NixOS.
EOF
}

check_status() {
    echo "================================================================="
    echo "🔍 DIAGNÓSTICO DE GOOGLE CHROME - NIXOS"
    echo "================================================================="

    echo -n "• Google Chrome Nativo (Nixpkgs): "
    if command -v google-chrome-stable &>/dev/null; then
        echo "✅ $(google-chrome-stable --version)"
    elif command -v google-chrome &>/dev/null; then
        echo "✅ $(google-chrome --version)"
    else
        echo "❌ No instalado vía Nix (disponible como pkgs.google-chrome)"
    fi

    echo -n "• Google Chrome Flatpak: "
    if flatpak list 2>/dev/null | grep -qi "com.google.Chrome"; then
        echo "✅ Presente vía Flatpak"
    else
        echo "ℹ️ No instalado en Flatpak"
    fi

    echo -n "• Flags Wayland Ozone: "
    if [ -n "${ELECTRON_OZONE_PLATFORM_HINT:-}" ] || [ -n "${NIXOS_OZONE_WL:-}" ]; then
        echo "✅ Activo para Wayland nativo"
    else
        echo "ℹ️ Estándar"
    fi
    echo "================================================================="
}

launch_chrome() {
    local chrome_bin=""
    if command -v google-chrome-stable &>/dev/null; then
        chrome_bin="google-chrome-stable"
    elif command -v google-chrome &>/dev/null; then
        chrome_bin="google-chrome"
    elif flatpak list 2>/dev/null | grep -qi "com.google.Chrome"; then
        echo "🌐 Lanzando Google Chrome vía Flatpak..."
        flatpak run com.google.Chrome --ozone-platform=wayland --enable-features=VaapiVideoDecodeLinuxGL &
        return 0
    else
        echo "⚠️ Google Chrome no está instalado."
        echo "💡 Para instalarlo temporalmente con Nix, ejecuta:"
        echo "   nix run --impure nixpkgs#google-chrome"
        echo "💡 O instálalo con Flatpak ejecutando:"
        echo "   $0 --flatpak"
        return 1
    fi

    echo "🌐 Lanzando $chrome_bin en Wayland..."
    "$chrome_bin" --ozone-platform=wayland --enable-features=VaapiVideoDecodeLinuxGL &>/dev/null &
}

install_flatpak_chrome() {
    echo "⬇️ Instalando Google Chrome vía Flatpak Flathub..."
    flatpak install -y --user --noninteractive flathub com.google.Chrome
    echo "✅ Google Chrome Flatpak instalado."
}

case "${1:-}" in
    --status|-s|status)
        check_status
        exit 0
        ;;
    --flatpak|flatpak)
        install_flatpak_chrome
        exit 0
        ;;
    --run|-r|run)
        launch_chrome
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
