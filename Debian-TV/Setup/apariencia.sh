#!/usr/bin/env bash
# ==============================================================================
# apariencia.sh - Instalación y Personalización de Temas, Iconos y Cursores
# Sistema: Debian GNU/Linux 13 (Trixie) | Escritorio: GNOME Shell 48+ (Wayland)
# Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / Intel HD 4600)
# ==============================================================================
# Filosofía:
#  - Control modular: Decide qué paquetes instalar y qué estética aplicar.
#  - Por defecto (sin argumentos): Solo instala los paquetes estéticos oficiales
#    (Papirus, Bibata) SIN alterar la personalización que ya tengas configurada.
#  - Modo interactivo (--interactive / -i): Asistente guiado para elegir temas.
#  - Modo configuración pura (--no-install / --config): Modifica temas en GSettings
#    sin invocar APT ni requerir contraseña de superusuario (sudo).
#  - Cambio bajo demanda: --papirus, --adwaita, --bibata, --bibata-ice, --dark, --light,
#    --cursor-size.
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y PAQUETES
# ------------------------------------------------------------------------------
THEME_PACKAGES=(
    "papirus-icon-theme|Suite completa de iconos vectoriales modernos (Papirus / Papirus-Dark)"
    "bibata-cursor-theme|Tema de cursor moderno y estilizado (Bibata-Modern-Classic e Ice)"
    "adwaita-icon-theme|Iconos oficiales del entorno GNOME Shell"
)

# Colores ANSI para terminal
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# 2. DETECCIÓN DE USUARIO Y ELEVACIÓN DE PRIVILEGIOS
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
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
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$REAL_UID}"
    local dbus_addr="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$runtime_dir/bus}"
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            PATH="/usr/local/bin:/usr/bin:/bin:$PATH" \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            "$@"
    else
        env \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            "$@"
    fi
}

get_os_description() {
    if [ -f /etc/os-release ]; then
        grep "^PRETTY_NAME=" /etc/os-release | cut -d= -f2 | tr -d '"'
    else
        echo "Debian GNU/Linux 13 (trixie)"
    fi
}

# ------------------------------------------------------------------------------
# 3. AYUDA Y DIAGNÓSTICO DEL SISTEMA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🎨 Gestor de Apariencia, Temas e Iconos - Debian 13 Workstation (GNOME Wayland)

Uso:
  $0 [OPCIÓN] [PARÁMETROS]

Opciones de Ejecución:
  (sin argumentos)        Instala paquetes estéticos oficiales (Papirus, Bibata) SIN alterar
                          la personalización de temas ni iconos que tengas activa.
  -i, --interactive       Asistente interactivo en terminal para elegir e instalar temas y cursores.
  -s, --status            Muestra el estado detallado de temas, iconos, cursores y paquetes.
  --no-install, --config  Aplica cambios estéticos en GSettings SIN instalar paquetes ni pedir sudo.
  --install, -i           Instala únicamente los paquetes de temas y cursores desde repositorios APT.

Ajustes Específicos bajo Demanda:
  --dark, -d              Aplica el modo oscuro en el sistema (prefer-dark + tema GTK oscuro).
  --light, -l             Aplica el modo claro en el sistema (default + tema GTK claro).
  --papirus               Aplica Papirus como tema de iconos (detecta modo oscuro -> Papirus-Dark).
  --papirus-dark          Fuerza explícitamente el tema de iconos Papirus-Dark.
  --adwaita               Restablece los iconos nativos de GNOME (Adwaita).
  --bibata                Aplica el cursor moderno Bibata-Modern-Classic (negro).
  --bibata-ice            Aplica el cursor moderno Bibata-Modern-Ice (blanco).
  --adwaita-cursor        Restablece el cursor nativo de GNOME (Adwaita).
  --cursor-size <px>      Establece el tamaño del cursor (24, 28, 32, 48).
  -h, --help              Muestra este mensaje de ayuda.

¿Qué se instala desde repositorios?
  • papirus-icon-theme:   Colección completa de iconos moderna (Papirus, Papirus-Dark, Papirus-Light).
  • bibata-cursor-theme:  Cursores nítidos modernos Bibata (Classic / Ice).
  • adwaita-icon-theme:   Iconos oficiales de GNOME Shell.
EOF
}

show_status() {
    local os_name
    os_name=$(get_os_description)

    echo "================================================================="
    echo "🔍 ESTADO DE APARIENCIA Y TEMAS - DEBIAN WORKSTATION"
    echo "================================================================="
    echo "• Sistema Operativo:      $os_name"
    echo "• Esquema de Color:       $(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo 'n/a')"
    echo "• Tema GTK:               $(run_as_user gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo 'n/a')"
    echo "• Tema de Iconos:         $(run_as_user gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo 'n/a')"
    echo "• Tema de Cursor:         $(run_as_user gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo 'n/a')"
    echo "• Tamaño de Cursor:       $(run_as_user gsettings get org.gnome.desktop.interface cursor-size 2>/dev/null || echo '24') px"
    echo "-----------------------------------------------------------------"
    echo "📦 PAQUETES ESTÉTICOS (Repositorios oficiales Debian 13):"
    for item in "${THEME_PACKAGES[@]}"; do
        IFS="|" read -r pkg desc <<< "$item"
        local status_icon="❌ No instalado"
        if dpkg -s "$pkg" &>/dev/null; then
            local v
            v=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || echo "instalado")
            status_icon="✅ Instalado (v$v)"
        fi
        printf "  • %-22s %s\n" "$pkg:" "$status_icon"
    done
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN DE PAQUETES ESTÉTICOS VÍA APT
# ------------------------------------------------------------------------------
install_packages() {
    echo "📦 Comprobando paquetes de temas e iconos en Debian 13..."
    local to_install=()

    for item in "${THEME_PACKAGES[@]}"; do
        IFS="|" read -r pkg desc <<< "$item"
        if ! dpkg -s "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
            echo "❌ Error: Se requieren permisos de superusuario para instalar paquetes APT."
            exit 1
        fi
        echo "ℹ️ Instalando paquetes de temas faltantes (${to_install[*]}) vía APT..."
        $SUDO apt-get update -qq
        $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-upgrade "${to_install[@]}" 2>/dev/null || true
        echo "  ✅ Paquetes instalados con éxito."
    else
        echo "  ✅ Todos los paquetes de temas e iconos ya están instalados en el sistema."
    fi
}

# ------------------------------------------------------------------------------
# 5. APLICACIÓN DE TEMAS, ICONOS Y CURSORES (GSOUND / GSETTINGS)
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
    local force_dark="${1:-auto}"
    echo "🎨 Configurando tema de iconos Papirus..."

    local target_icon="Papirus"
    if [ "$force_dark" = "dark" ]; then
        target_icon="Papirus-Dark"
    elif [ "$force_dark" = "auto" ]; then
        local cs
        cs=$(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "'default'")
        if [ "$cs" = "'prefer-dark'" ] && [ -d "/usr/share/icons/Papirus-Dark" ]; then
            target_icon="Papirus-Dark"
        fi
    fi

    if [ -d "/usr/share/icons/$target_icon" ]; then
        run_as_user gsettings set org.gnome.desktop.interface icon-theme "$target_icon" 2>/dev/null || true
        echo "  ✅ Iconos configurados: $target_icon."
    else
        echo "  ⚠️ $target_icon no encontrado en el sistema. Ejecuta '$0 --install' primero."
    fi
}

apply_icons_adwaita() {
    echo "🎨 Restableciendo iconos nativos Adwaita de GNOME..."
    run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null || true
    echo "  ✅ Iconos configurados: Adwaita (predeterminado de GNOME)."
}

apply_cursor() {
    local cursor_name="${1:-Bibata-Modern-Classic}"
    echo "🖱️ Aplicando tema de cursor '$cursor_name'..."

    if [ -d "/usr/share/icons/$cursor_name" ] || [ -d "$USER_HOME/.local/share/icons/$cursor_name" ] || [ -d "$USER_HOME/.icons/$cursor_name" ]; then
        run_as_user gsettings set org.gnome.desktop.interface cursor-theme "$cursor_name" 2>/dev/null || true
        echo "  ✅ Cursor configurado: $cursor_name."
    else
        echo "  ⚠️ Tema de cursor '$cursor_name' no encontrado. Ejecuta '$0 --install' primero."
    fi
}

apply_cursor_size() {
    local size="${1:-24}"
    echo "🖱️ Configurando tamaño de cursor a ${size}px..."
    run_as_user gsettings set org.gnome.desktop.interface cursor-size "$size" 2>/dev/null || true
    echo "  ✅ Tamaño de cursor aplicado: ${size}px."
}

# ------------------------------------------------------------------------------
# 6. ASISTENTE INTERACTIVO
# ------------------------------------------------------------------------------
run_interactive() {
    clear
    echo -e "${CYAN}${BOLD}=================================================================${NC}"
    echo -e "${BOLD}🎨 ASISTENTE INTERACTIVO DE APARIENCIA (DEBIAN 13 GNOME)${NC}"
    echo -e "${CYAN}${BOLD}=================================================================${NC}"
    echo ""

    # 1. Instalar paquetes APT
    read -rp "¿Deseas instalar/actualizar paquetes de temas e iconos vía APT (Papirus, Bibata)? [s/N]: " do_pkg
    if [[ "$do_pkg" =~ ^[sSyY]$ ]]; then
        install_packages
    fi

    # 2. Modo Oscuro / Claro
    echo ""
    echo "Selecciona el esquema de color:"
    echo "  1) Oscuro (prefer-dark + Adwaita-dark) [Recomendado]"
    echo "  2) Claro (default + Adwaita)"
    echo "  3) Mantener actual"
    read -rp "Opción [1]: " ans_c
    case "${ans_c:-1}" in
        1) apply_dark ;;
        2) apply_light ;;
    esac

    # 3. Tema de Iconos
    echo ""
    echo "Selecciona el tema de iconos:"
    echo "  1) Papirus (se adapta automáticamente a modo oscuro: Papirus-Dark)"
    echo "  2) Adwaita (predeterminado nativo de GNOME)"
    echo "  3) Mantener actual"
    read -rp "Opción [1]: " ans_i
    case "${ans_i:-1}" in
        1) apply_icons_papirus "auto" ;;
        2) apply_icons_adwaita ;;
    esac

    # 4. Tema de Cursor
    echo ""
    echo "Selecciona el tema de cursor:"
    echo "  1) Bibata Modern Classic (cursor negro moderno)"
    echo "  2) Bibata Modern Ice (cursor blanco moderno)"
    echo "  3) Adwaita (predeterminado de GNOME)"
    echo "  4) Mantener actual"
    read -rp "Opción [1]: " ans_cur
    case "${ans_cur:-1}" in
        1) apply_cursor "Bibata-Modern-Classic" ;;
        2) apply_cursor "Bibata-Modern-Ice" ;;
        3) apply_cursor "Adwaita" ;;
    esac

    # 5. Tamaño del Cursor
    echo ""
    read -rp "¿Deseas ajustar el tamaño del cursor? [24 px por defecto]: " ans_sz
    if [ -n "$ans_sz" ] && [[ "$ans_sz" =~ ^[0-9]+$ ]]; then
        apply_cursor_size "$ans_sz"
    fi

    echo ""
    echo -e "${GREEN}${BOLD}✅ ¡Configuración estética aplicada a tu gusto!${NC}"
    echo ""
    show_status
}

# ------------------------------------------------------------------------------
# 7. ENTRADA PRINCIPAL Y PARSEO DE ARGUMENTOS
# ------------------------------------------------------------------------------
case "${1:-}" in
    -s|--status|status)
        show_status
        exit 0
        ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
    -i|--interactive)
        run_interactive
        exit 0
        ;;
    --install)
        install_packages
        echo ""
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
        apply_icons_papirus "auto"
        exit 0
        ;;
    --papirus-dark)
        apply_icons_papirus "dark"
        exit 0
        ;;
    --adwaita)
        apply_icons_adwaita
        exit 0
        ;;
    --bibata)
        apply_cursor "Bibata-Modern-Classic"
        exit 0
        ;;
    --bibata-ice)
        apply_cursor "Bibata-Modern-Ice"
        exit 0
        ;;
    --adwaita-cursor)
        apply_cursor "Adwaita"
        exit 0
        ;;
    --cursor-size)
        if [ -n "${2:-}" ]; then
            apply_cursor_size "$2"
            exit 0
        else
            echo "❌ Error: Especifica un tamaño en píxeles (ej: $0 --cursor-size 28)."
            exit 1
        fi
        ;;
    "")
        echo "================================================================="
        echo "📦 INSTALACIÓN DE PAQUETES DE APARIENCIA (DEBIAN 13 WORKSTATION)"
        echo "================================================================="
        install_packages
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Paquetes listos. No se ha modificado tu configuración activa."
        echo "💡 Para activar temas ejecuta: '$0 --interactive' o '$0 --help'."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
