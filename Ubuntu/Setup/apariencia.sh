#!/usr/bin/env bash
# ==============================================================================
# apariencia.sh - Instalación y Configuración de Temas, Iconos y Cursores
# Ubuntu Workstation (GNOME Shell 51 + Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)
# ==============================================================================
# Características:
#  - Gestión de temas de iconos: Papirus (Papirus, Papirus-Dark) y Yaru suite completa.
#  - Temas de cursor modernos: Bibata (Bibata-Modern-Classic / Ice) y Yaru cursor.
#  - Tema GTK y Shell: Modo oscuro armonizado (prefer-dark + Yaru-dark / Adwaita).
#  - Instalación idempotente: solo invoca APT si los paquetes no están presentes.
#  - Soporte CLI completo: --status / -s, --dark / -d, --light / -l, --papirus,
#                          --yaru, --bibata, --install / -i, --help / -h.
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO Y PRIVILEGIOS SUDO
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script con privilegios de superusuario."
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

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            PATH="/usr/local/bin:/usr/bin:/bin:$PATH" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$REAL_UID/bus}" \
            "$@"
    else
        "$@"
    fi
}

# ------------------------------------------------------------------------------
# 2. AYUDA Y ESTADO DEL SISTEMA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🎨 Gestor de Apariencia, Temas e Iconos - Ubuntu Workstation (GNOME 51 Wayland)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala temas e iconos y asegura el tema oscuro armónico.
  --status, -s        Muestra el estado detallado de temas, iconos, cursores y paquetes.
  --dark, -d          Aplica el modo oscuro completo (prefer-dark + tema oscuro).
  --light, -l         Aplica el modo claro estándar (default + tema claro).
  --papirus           Aplica Papirus como tema de iconos activo (Papirus-Dark en modo oscuro).
  --yaru              Restablece los iconos nativos de Ubuntu (Yaru / Yaru-dark).
  --bibata            Aplica el cursor moderno Bibata-Modern-Classic.
  --install, -i       Instala únicamente los paquetes estéticos sin alterar la configuración actual.
  --help, -h          Muestra este mensaje de ayuda.

Paquetes gestionados:
  • Iconos:   papirus-icon-theme, yaru-theme-icon, adwaita-icon-theme.
  • Cursores: bibata-cursor-theme, yaru-theme-gtk.
  • GTK/Shell: yaru-theme-gtk, yaru-theme-gnome-shell, yaru-theme-sound.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE APARIENCIA Y TEMAS - UBUNTU WORKSTATION"
    echo "================================================================="
    echo "• Esquema de color:       $(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo 'n/a')"
    echo "• Tema GTK:               $(run_as_user gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo 'n/a')"
    echo "• Tema de Iconos:         $(run_as_user gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo 'n/a')"
    echo "• Tema de Cursor:         $(run_as_user gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo 'n/a')"
    echo "• Tamaño de Cursor:       $(run_as_user gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null || echo '24') px"
    echo "-----------------------------------------------------------------"
    echo "• Paquetes Estéticos Instalados:"
    echo "  - Papirus Icon Theme:   $(if dpkg -s papirus-icon-theme &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "  - Bibata Cursor Theme:  $(if dpkg -s bibata-cursor-theme &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "  - Yaru Theme Suite:     $(if dpkg -s yaru-theme-gtk &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "  - Adwaita Icons:        $(if dpkg -s adwaita-icon-theme &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. INSTALACIÓN DE PAQUETES ESTÉTICOS (IDEMPOTENTE)
# ------------------------------------------------------------------------------
install_packages() {
    echo "📦 Verificando paquetes de temas, iconos y cursores..."
    local to_install=()

    for pkg in papirus-icon-theme bibata-cursor-theme yaru-theme-gtk yaru-theme-icon yaru-theme-gnome-shell yaru-theme-sound adwaita-icon-theme; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        echo "ℹ️ Instalando paquetes faltantes: ${to_install[*]}..."
        $SUDO apt-get update -qq
        $SUDO apt-get install -y "${to_install[@]}" 2>/dev/null || true
        echo "  ✅ Paquetes instalados con éxito."
    else
        echo "  ✅ Todos los paquetes de temas e iconos ya están instalados."
    fi
}

# ------------------------------------------------------------------------------
# 4. APLICACIÓN DE TEMAS, ICONOS Y CURSORES
# ------------------------------------------------------------------------------
apply_dark() {
    echo "🌙 Aplicando modo oscuro armonizado..."
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

    local gtk_target="Yaru-dark"
    if [ -d "/usr/share/themes/Yaru-dark" ]; then
        gtk_target="Yaru-dark"
    elif [ -d "/usr/share/themes/Adwaita-dark" ]; then
        gtk_target="Adwaita-dark"
    fi
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$gtk_target" 2>/dev/null || true

    # Si Papirus está instalado, usar Papirus-Dark; si no, Yaru-dark
    if [ -d "/usr/share/icons/Papirus-Dark" ]; then
        run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
    elif [ -d "/usr/share/icons/Yaru-dark" ]; then
        run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Yaru-dark' 2>/dev/null || true
    fi

    echo "  ✅ Modo oscuro activado (GTK: $gtk_target)."
}

apply_light() {
    echo "☀️ Aplicando modo claro..."
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'default' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'Yaru' 2>/dev/null || true

    if [ -d "/usr/share/icons/Papirus" ]; then
        run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Papirus' 2>/dev/null || true
    else
        run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Yaru' 2>/dev/null || true
    fi

    echo "  ✅ Modo claro activado."
}

apply_icons_papirus() {
    echo "🎨 Aplicando iconos Papirus..."
    local cs
    cs=$(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "'default'")
    if [ "$cs" = "'prefer-dark'" ] && [ -d "/usr/share/icons/Papirus-Dark" ]; then
        run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
        echo "  ✅ Iconos configurados: Papirus-Dark."
    elif [ -d "/usr/share/icons/Papirus" ]; then
        run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Papirus' 2>/dev/null || true
        echo "  ✅ Iconos configurados: Papirus."
    else
        echo "  ⚠️ Papirus no encontrado en el sistema. Ejecuta '$0 --install' primero."
    fi
}

apply_icons_yaru() {
    echo "🎨 Aplicando iconos Yaru..."
    local cs
    cs=$(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "'default'")
    if [ "$cs" = "'prefer-dark'" ] && [ -d "/usr/share/icons/Yaru-dark" ]; then
        run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Yaru-dark' 2>/dev/null || true
        echo "  ✅ Iconos configurados: Yaru-dark."
    else
        run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Yaru' 2>/dev/null || true
        echo "  ✅ Iconos configurados: Yaru."
    fi
}

apply_cursor_bibata() {
    echo "🖱️ Aplicando cursor moderno Bibata..."
    if [ -d "/usr/share/icons/Bibata-Modern-Classic" ]; then
        run_as_user gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic' 2>/dev/null || true
        echo "  ✅ Cursor configurado: Bibata-Modern-Classic."
    elif [ -d "/usr/share/icons/Bibata-Modern-Ice" ]; then
        run_as_user gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' 2>/dev/null || true
        echo "  ✅ Cursor configurado: Bibata-Modern-Ice."
    else
        echo "  ⚠️ Bibata no encontrado en el sistema. Ejecuta '$0 --install' primero."
    fi
}

# ------------------------------------------------------------------------------
# 5. ENTRADA PRINCIPAL
# ------------------------------------------------------------------------------
case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --dark|-d)
        apply_dark
        exit 0
        ;;
    --light|-l)
        apply_light
        exit 0
        ;;
    --papirus)
        apply_icons_papirus
        exit 0
        ;;
    --yaru)
        apply_icons_yaru
        exit 0
        ;;
    --bibata)
        apply_cursor_bibata
        exit 0
        ;;
    --install|-i)
        install_packages
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🎨 CONFIGURANDO APARIENCIA Y TEMAS (UBUNTU WORKSTATION)"
        echo "================================================================="
        install_packages
        apply_dark
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Configuración estética completada con éxito."
        echo "================================================================="
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
