#!/usr/bin/env bash
# ==============================================================================
# apariencia.sh - Instalación y Configuración de Temas, Iconos y Cursores
# Fedora Workstation (GNOME Shell + Wayland / Adwaita)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)
# ==============================================================================
# Características:
#  - Instalación de temas de iconos: Papirus y Adwaita nativo de GNOME.
#  - Instalación de cursores modernos: Bibata y Adwaita cursor.
#  - Por defecto: SOLO instala los paquetes disponibles sin alterar la personalización del usuario.
#  - Cambio de temas bajo demanda explícita: --papirus, --adwaita, --bibata, --dark, --light.
#  - Instalación idempotente: solo invoca DNF si los paquetes no están presentes.
#  - Soporte CLI completo: --status / -s, --dark / -d, --light / -l, --papirus,
#                          --adwaita, --bibata, --install / -i, --help / -h.
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

if command -v dnf5 &>/dev/null; then
    DNF_CMD="dnf5"
else
    DNF_CMD="dnf"
fi

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
🎨 Gestor de Apariencia, Temas e Iconos - Fedora Workstation (GNOME Wayland)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala paquetes estéticos (Papirus, Bibata, Adwaita) sin modificar la configuración activa.
  --status, -s        Muestra el estado detallado de temas, iconos, cursores y paquetes.
  --dark, -d          Aplica el modo oscuro en el sistema (prefer-dark + tema GTK oscuro, sin alterar iconos).
  --light, -l         Aplica el modo claro en el sistema (default + tema GTK claro, sin alterar iconos).
  --papirus           Aplica explícitamente Papirus como tema de iconos activo.
  --adwaita           Restablece explícitamente los iconos nativos de GNOME (Adwaita).
  --bibata            Aplica explícitamente el cursor moderno Bibata-Modern-Classic.
  --install, -i       Instala únicamente los paquetes estéticos sin actualizar el sistema ni repositorios.
  --help, -h          Muestra este mensaje de ayuda.

Paquetes gestionados:
  • Iconos:   papirus-icon-theme, adwaita-icon-theme.
  • Cursores: bibata-cursor-theme, adwaita-cursor-theme.
  • GTK/Shell: adw-gtk3-theme / adw-gtk3 (si está disponible) o Adwaita.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE APARIENCIA Y TEMAS - FEDORA WORKSTATION"
    echo "================================================================="
    echo "• Esquema de color:       $(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo 'n/a')"
    echo "• Tema GTK:               $(run_as_user gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo 'n/a')"
    echo "• Tema de Iconos:         $(run_as_user gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo 'n/a')"
    echo "• Tema de Cursor:         $(run_as_user gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo 'n/a')"
    echo "• Tamaño de Cursor:       $(run_as_user gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null || echo '24') px"
    echo "-----------------------------------------------------------------"
    echo "• Paquetes Estéticos Instalados:"
    echo "  - Papirus Icon Theme:   $(if rpm -q papirus-icon-theme &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "  - Bibata Cursor Theme:  $(if rpm -q bibata-cursor-theme &>/dev/null || [ -d "/usr/share/icons/Bibata-Modern-Classic" ] || [ -d "$USER_HOME/.local/share/icons/Bibata-Modern-Classic" ]; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "  - Adwaita Icon Theme:   $(if rpm -q adwaita-icon-theme &>/dev/null; then echo "✅ Instalado"; else echo "❌ No instalado"; fi)"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. INSTALACIÓN IDEMPOTENTE DE PAQUETES
# ------------------------------------------------------------------------------
install_packages() {
    echo "📦 Comprobando paquetes de temas e iconos en Fedora..."
    local to_install=()

    for pkg in papirus-icon-theme adwaita-icon-theme; do
        if ! rpm -q "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        echo "ℹ️ Instalando paquetes faltantes (${to_install[*]}) vía $DNF_CMD..."
        $SUDO $DNF_CMD install -y "${to_install[@]}" 2>/dev/null || true
    else
        echo "  ✅ Paquetes de iconos oficiales ya están satisfechos."
    fi

    # Bibata Cursor check
    if ! rpm -q bibata-cursor-theme &>/dev/null && [ ! -d "/usr/share/icons/Bibata-Modern-Classic" ] && [ ! -d "$USER_HOME/.local/share/icons/Bibata-Modern-Classic" ]; then
        echo "ℹ️ Intentando instalar bibata-cursor-theme..."
        if ! $SUDO $DNF_CMD install -y bibata-cursor-theme 2>/dev/null; then
            echo "  ⬇️ Descargando e instalando Bibata-Modern-Classic desde GitHub..."
            local tmp_dir
            tmp_dir=$(mktemp -d)
            if curl -fsSL "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Classic.tar.xz" -o "$tmp_dir/bibata.tar.xz" 2>/dev/null; then
                $SUDO mkdir -p /usr/share/icons
                $SUDO tar -xf "$tmp_dir/bibata.tar.xz" -C /usr/share/icons/ 2>/dev/null || true
                echo "  ✅ Bibata Cursor instalado en /usr/share/icons/Bibata-Modern-Classic."
            fi
            rm -rf "$tmp_dir"
        fi
    fi

    # adw-gtk3 si está disponible en Fedora
    if ! rpm -q adw-gtk3-theme &>/dev/null && ! rpm -q adw-gtk3 &>/dev/null; then
        $SUDO $DNF_CMD install -y adw-gtk3-theme 2>/dev/null || $SUDO $DNF_CMD install -y adw-gtk3 2>/dev/null || true
    fi

    echo "  ✅ Verificación e instalación de paquetes estéticos finalizada."
}

# ------------------------------------------------------------------------------
# 4. APLICACIÓN DE TEMAS, ICONOS Y CURSORES (SOLO BAJO DEMANDA EXPLÍCITA)
# ------------------------------------------------------------------------------
apply_dark() {
    echo "🌙 Aplicando modo oscuro en GTK y color-scheme..."
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

    local gtk_target="Adwaita-dark"
    if [ -d "/usr/share/themes/adw-gtk3-dark" ]; then
        gtk_target="adw-gtk3-dark"
    elif [ -d "/usr/share/themes/Adwaita-dark" ]; then
        gtk_target="Adwaita-dark"
    fi
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$gtk_target" 2>/dev/null || true

    echo "  ✅ Modo oscuro activado (GTK: $gtk_target). Iconos conservados sin cambios."
}

apply_light() {
    echo "☀️ Aplicando modo claro en GTK y color-scheme..."
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'default' 2>/dev/null || true
    
    local gtk_target="Adwaita"
    if [ -d "/usr/share/themes/adw-gtk3" ]; then
        gtk_target="adw-gtk3"
    fi
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$gtk_target" 2>/dev/null || true

    echo "  ✅ Modo claro activado. Iconos conservados sin cambios."
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

apply_icons_adwaita() {
    echo "🎨 Restableciendo iconos nativos Adwaita de GNOME..."
    run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null || true
    echo "  ✅ Iconos configurados: Adwaita (predeterminado de GNOME)."
}

apply_cursor_bibata() {
    echo "🖱️ Aplicando cursor moderno Bibata..."
    if [ -d "/usr/share/icons/Bibata-Modern-Classic" ] || [ -d "$USER_HOME/.local/share/icons/Bibata-Modern-Classic" ]; then
        run_as_user gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic' 2>/dev/null || true
        echo "  ✅ Cursor configurado: Bibata-Modern-Classic."
    elif [ -d "/usr/share/icons/Bibata-Modern-Ice" ] || [ -d "$USER_HOME/.local/share/icons/Bibata-Modern-Ice" ]; then
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
    --adwaita)
        apply_icons_adwaita
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
        echo "📦 INSTALACIÓN DE PAQUETES DE APARIENCIA (FEDORA WORKSTATION)"
        echo "================================================================="
        install_packages
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Paquetes instalados con éxito sin modificar la configuración activa de temas ni iconos."
        echo "================================================================="
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
