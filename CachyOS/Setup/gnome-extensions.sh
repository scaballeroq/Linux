#!/bin/bash
# ==============================================================================
# gnome-extensions.sh - Gestor de Extensiones de GNOME Shell para CachyOS
# Instala y activa las extensiones oficiales desde los repositorios de CachyOS / Arch
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Paquete de la aplicación gráfica de gestión (Extension Manager)
# ------------------------------------------------------------------------------
APP_PKGS=(
    extension-manager                       # Herramienta nativa para explorar, instalar y gestionar extensiones
)

# ------------------------------------------------------------------------------
# Lista de paquetes oficiales de extensiones (Pacman: cachyos, extra, chaotic-aur)
# ------------------------------------------------------------------------------
EXTENSION_PKGS=(
    gnome-shell-extension-dash-to-dock      # Dock accesible fuera del overview
    gnome-shell-extension-appindicator      # Soporte de bandeja del sistema / bandejas de apps
    gnome-shell-extension-caffeine          # Desactivador rápido de suspensión / salvapantallas
    gnome-shell-extension-weather-oclock    # Clima en la barra superior junto al reloj
    gnome-shell-extension-bing-wallpaper    # Fondo de pantalla dinámico de Bing diario
    gnome-shell-extension-blur-my-shell     # Efecto de desenfoque y estética moderna
    gnome-shell-extension-logo-menu         # Menú con logo y acceso rápido del sistema
)

# ------------------------------------------------------------------------------
# UUIDs correspondientes a cada extensión en GNOME Shell
# ------------------------------------------------------------------------------
EXTENSION_UUIDS=(
    "dash-to-dock@micxgx.gmail.com"
    "appindicatorsupport@rgcjonas.gmail.com"
    "caffeine@patapon.info"
    "weatheroclock@CleoMenezesJr.github.io"
    "BingWallpaper@ineffable-gmail.com"
    "blur-my-shell@aunetx"
    "logomenu@aryan_k"
)

# ------------------------------------------------------------------------------
# Detección de privilegios y usuario real
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# ------------------------------------------------------------------------------
# Funciones principales
# ------------------------------------------------------------------------------
install_packages() {
    local all_pkgs=("${APP_PKGS[@]}" "${EXTENSION_PKGS[@]}")
    local missing_pkgs=()

    for pkg in "${all_pkgs[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        echo "📦 [1/3] Instalando herramientas y extensiones faltantes con Pacman (${missing_pkgs[*]})..."
        $SUDO pacman -S --needed --noconfirm "${missing_pkgs[@]}"
        echo "  ✅ Paquetes instalados correctamente."
    else
        echo "📦 [1/3] Extension Manager y las extensiones ya se encuentran instalados."
    fi
}

enable_extensions() {
    echo "🔌 [2/3] Habilitando soporte global de extensiones de usuario..."
    run_as_user gsettings set org.gnome.shell disable-user-extensions false 2>/dev/null || true

    echo "⚡ [3/3] Activando extensiones en GNOME Shell..."
    for uuid in "${EXTENSION_UUIDS[@]}"; do
        if run_as_user gnome-extensions list 2>/dev/null | grep -q "^${uuid}$"; then
            run_as_user gnome-extensions enable "$uuid" 2>/dev/null || true
            echo "  ✅ Habilitada: $uuid"
        else
            echo "  ⚠️ Extensión no encontrada en la sesión actual: $uuid (se activará al reiniciar sesión)"
            # Forzar habilitación en gsettings enabled-extensions
            CURRENT_EXTS=$(run_as_user gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo "[]")
            if [[ "$CURRENT_EXTS" != *"$uuid"* ]]; then
                NEW_EXTS=$(echo "$CURRENT_EXTS" | sed "s/\]$/,'$uuid'\]/" | sed "s/\[,'/\[/'/")
                run_as_user gsettings set org.gnome.shell enabled-extensions "$NEW_EXTS" 2>/dev/null || true
            fi
        fi
    done

    # Integración de Logo Menu con Extension Manager y Kitty
    if run_as_user gnome-extensions list --enabled 2>/dev/null | grep -q "logomenu@aryan_k"; then
        run_as_user gsettings set org.gnome.shell.extensions.logo-menu menu-button-extensions-app 'com.mattjakeman.ExtensionManager.desktop' 2>/dev/null || true
        run_as_user gsettings set org.gnome.shell.extensions.logo-menu menu-button-terminal 'kitty' 2>/dev/null || true
    fi
}

disable_extensions() {
    echo "🛑 Desactivando extensiones de GNOME..."
    for uuid in "${EXTENSION_UUIDS[@]}"; do
        run_as_user gnome-extensions disable "$uuid" 2>/dev/null || true
        echo "  ❌ Deshabilitada: $uuid"
    done
}

show_status() {
    echo "================================================================="
    echo "🧩 ESTADO DE EXTENSIONES GNOME SHELL"
    echo "================================================================="
    USER_EXT_ENABLED=$(run_as_user gsettings get org.gnome.shell disable-user-extensions 2>/dev/null || echo "unknown")
    echo "• Soporte de extensiones de usuario : $([ "$USER_EXT_ENABLED" = "false" ] && echo "HABILITADO" || echo "DESHABILITADO")"
    
    EXT_MGR_VER=$(pacman -Q extension-manager 2>/dev/null | awk '{print $2}' || echo "")
    if [ -n "$EXT_MGR_VER" ]; then
        echo "• Gestor gráfico (Extension Manager): 🟢 INSTALADO (v$EXT_MGR_VER)"
    else
        echo "• Gestor gráfico (Extension Manager): 🔴 NO INSTALADO"
    fi
    echo ""
    for uuid in "${EXTENSION_UUIDS[@]}"; do
        if run_as_user gnome-extensions list --enabled 2>/dev/null | grep -q "^${uuid}$"; then
            STATE="🟢 ACTIVA"
        elif run_as_user gnome-extensions list 2>/dev/null | grep -q "^${uuid}$"; then
            STATE="🟡 INSTALADA (INACTIVA)"
        else
            STATE="🔴 NO INSTALADA"
        fi
        printf "  %-42s : %s\n" "$uuid" "$STATE"
    done
    echo "================================================================="
}

show_help() {
    echo "Uso: $0 [OPCIÓN]"
    echo ""
    echo "Opciones:"
    echo "  (sin opción)  Instala los paquetes vía pacman y activa las 7 extensiones."
    echo "  --enable      Activa todas las extensiones configuradas."
    echo "  --disable     Desactiva todas las extensiones configuradas."
    echo "  --status      Muestra el estado actual de las extensiones."
    echo "  --help        Muestra esta ayuda."
}

# ------------------------------------------------------------------------------
# Dispatcher de opciones
# ------------------------------------------------------------------------------
case "${1:-}" in
    --enable)
        enable_extensions
        echo ""
        show_status
        ;;
    --disable)
        disable_extensions
        echo ""
        show_status
        ;;
    --status)
        show_status
        ;;
    --help|-h)
        show_help
        ;;
    "")
        echo "================================================================="
        echo "🧩 INSTALADOR DE EXTENSIONES GNOME SHELL PARA CACHYOS"
        echo "================================================================="
        install_packages
        echo ""
        enable_extensions
        echo ""
        show_status
        echo "💡 Nota: En Wayland, algunas extensiones pueden requerir reiniciar la"
        echo "         sesión de usuario para refrescar la interfaz completamente."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción desconocida: $1"
        show_help
        exit 1
        ;;
esac
