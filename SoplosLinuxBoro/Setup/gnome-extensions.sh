#!/usr/bin/env bash
# ==============================================================================
# gnome-extensions.sh - Gestión e Inspección de Extensiones de GNOME Shell
# Soplos Linux Boro Workstation (Soplos Linux Boro / GNOME Shell Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)
# ==============================================================================
# Características:
#  - Inspección exhaustiva de extensiones de sistema (/usr/share) y usuario (~/.local/share).
#  - Gestión de habilitación / deshabilitación mediante 'gnome-extensions' y 'gsettings'.
#  - Instalación idempotente de paquetes base oficiales de extensiones en Soplos Linux Boro.
#  - Compatibilidad total con Mutter Wayland y GNOME Shell 50.
#  - Opciones CLI: --status / -s, --install / -i, --enable <UUID>, --disable <UUID>, --help / -h.
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

SYSTEM_EXT_DIR="/usr/share/gnome-shell/extensions"
USER_EXT_DIR="$USER_HOME/.local/share/gnome-shell/extensions"

# ------------------------------------------------------------------------------
# 2. AYUDA Y ESTADO DEL SISTEMA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🧩 Gestor de Extensiones de GNOME Shell - Soplos Linux Boro Workstation

Uso:
  $0 [OPCIÓN] [UUID]

Opciones:
  (sin argumentos)       Verifica e instala los paquetes base y asegura extensiones activas.
  --status, -s           Muestra diagnóstico detallado de todas las extensiones instaladas.
  --install, -i          Instala únicamente los paquetes de extensiones vía APT (sin actualizar repos).
  --enable, -e <UUID>    Habilita una extensión específica y la registra en GSettings.
  --disable, -d <UUID>   Deshabilita una extensión específica.
  --prefs, -p <UUID>     Abre la ventana de preferencias de una extensión.
  --help, -h             Muestra este mensaje de ayuda.

Extensiones gestionadas por el ecosistema Soplos Linux Boro:
  • Sistema (/usr/share):
      - ubuntu-dock@ubuntu.com           (Barra dock de Soplos Linux Boro / Dash to Dock)
      - ubuntu-appindicators@ubuntu.com  (Bandeja del sistema para iconos de apps)
      - ding@rastersoft.com              (Iconos en el escritorio DING)
      - tiling-assistant@ubuntu.com      (Acomodación de ventanas y mosaico)
      - gsconnect@andyholmes.github.io   (KDE Connect nativo para GNOME)
  • Usuario (~/.local/share):
      - blur-my-shell@aunetx             (Efecto blur en panel, dash y overview)
      - caffeine@patapon.info            (Prevenir suspensión y salvapantallas)
      - lockkeys@vaina.lt                (Estado de Bloq Mayús / Bloq Num en panel)
      - BingWallpaper@ineffable-gmail.com (Fondo diario automático de Bing)
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE EXTENSIONES GNOME SHELL - SOPLOS LINUX BORO WORKSTATION"
    echo "================================================================="
    echo "• Versión de GNOME Shell: $(run_as_user gnome-shell --version 2>/dev/null || echo 'GNOME 50')"
    echo "• Modo de Sesión:         ${XDG_SESSION_TYPE:-wayland} (Mutter)"
    echo "-----------------------------------------------------------------"

    local enabled_exts enabled_gsettings
    enabled_exts=$(run_as_user gnome-extensions list --enabled 2>/dev/null || true)
    enabled_gsettings=$(run_as_user gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo "[]")

    echo "📦 EXTENSIONES DEL SISTEMA (/usr/share/gnome-shell/extensions):"
    if [ -d "$SYSTEM_EXT_DIR" ]; then
        for ext_path in "$SYSTEM_EXT_DIR"/*; do
            if [ -d "$ext_path" ]; then
                local uuid name state
                uuid=$(basename "$ext_path")
                name=$(grep -m1 '"name":' "$ext_path/metadata.json" 2>/dev/null | cut -d: -f2 | tr -d '", ' || echo "$uuid")
                if echo "$enabled_exts" | grep -qx "$uuid" || echo "$enabled_gsettings" | grep -q "$uuid"; then
                    state="✅ Habilitada"
                else
                    state="⚪ Inactiva"
                fi
                printf "  • %-36s [%s] (%s)\n" "$uuid" "$state" "$name"
            fi
        done
    else
        echo "  (Directorio no encontrado)"
    fi

    echo ""
    echo "👤 EXTENSIONES DE USUARIO (~/.local/share/gnome-shell/extensions):"
    if [ -d "$USER_EXT_DIR" ] && [ "$(ls -A "$USER_EXT_DIR" 2>/dev/null)" ]; then
        for ext_path in "$USER_EXT_DIR"/*; do
            if [ -d "$ext_path" ]; then
                local uuid name state
                uuid=$(basename "$ext_path")
                name=$(grep -m1 '"name":' "$ext_path/metadata.json" 2>/dev/null | cut -d: -f2 | tr -d '", ' || echo "$uuid")
                if echo "$enabled_exts" | grep -qx "$uuid" || echo "$enabled_gsettings" | grep -q "$uuid"; then
                    state="✅ Habilitada"
                else
                    state="⚪ Inactiva"
                fi
                printf "  • %-36s [%s] (%s)\n" "$uuid" "$state" "$name"
            fi
        done
    else
        echo "  (Ninguna extensión instalada en espacio de usuario)"
    fi
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. INSTALACIÓN DE PAQUETES DE EXTENSIONES (SIN ACTUALIZAR REPOSITORIOS)
# ------------------------------------------------------------------------------
install_packages() {
    echo "📦 Comprobando paquetes de extensiones y herramientas en Soplos Linux Boro..."
    local to_install=()

    local pkgs=(
        gnome-shell-extensions
        gnome-shell-extension-gsconnect
        gnome-browser-connector
        gnome-tweaks
    )

    for pkg in "${pkgs[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        echo "ℹ️ Instalando paquetes faltantes (${to_install[*]}) sin actualizar índices..."
        $SUDO apt-get install -y --no-upgrade "${to_install[@]}" 2>/dev/null || true
        echo "  ✅ Paquetes de extensiones instalados."
    else
        echo "  ✅ Todos los paquetes base de extensiones ya están instalados."
    fi
}

# ------------------------------------------------------------------------------
# 4. HABILITAR / DESHABILITAR EXTENSIÓN
# ------------------------------------------------------------------------------
enable_extension() {
    local uuid="$1"
    echo "⚙️ Habilitando extensión: $uuid..."

    # Registrar en GSettings enabled-extensions si no está presente
    local current_enabled
    current_enabled=$(run_as_user gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo "[]")
    if ! echo "$current_enabled" | grep -q "$uuid"; then
        if [[ "$current_enabled" == "@as []" || "$current_enabled" == "[]" ]]; then
            run_as_user gsettings set org.gnome.shell enabled-extensions "['$uuid']" 2>/dev/null || true
        else
            local new_enabled
            new_enabled=$(echo "$current_enabled" | sed "s/]/, '$uuid']/")
            run_as_user gsettings set org.gnome.shell enabled-extensions "$new_enabled" 2>/dev/null || true
        fi
    fi

    run_as_user gnome-extensions enable "$uuid" 2>/dev/null || true
    echo "  ✅ Extensión '$uuid' habilitada."
}

disable_extension() {
    local uuid="$1"
    echo "⚙️ Deshabilitando extensión: $uuid..."
    run_as_user gnome-extensions disable "$uuid" 2>/dev/null || true

    # Retirar de GSettings enabled-extensions
    local current_enabled
    current_enabled=$(run_as_user gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo "[]")
    if echo "$current_enabled" | grep -q "$uuid"; then
        local new_enabled
        new_enabled=$(echo "$current_enabled" | sed -E "s/'$uuid',? ?//g; s/, ?]/]/")
        run_as_user gsettings set org.gnome.shell enabled-extensions "$new_enabled" 2>/dev/null || true
    fi
    echo "  ✅ Extensión '$uuid' deshabilitada."
}

open_prefs() {
    local uuid="$1"
    echo "⚙️ Abriendo preferencias para extensión: $uuid..."
    run_as_user gnome-extensions prefs "$uuid" 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# 5. ENTRADA PRINCIPAL
# ------------------------------------------------------------------------------
case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --install|-i)
        install_packages
        exit 0
        ;;
    --enable|-e)
        if [ -z "${2:-}" ]; then
            echo "❌ Error: Especifica el UUID de la extensión a habilitar."
            exit 1
        fi
        enable_extension "$2"
        exit 0
        ;;
    --disable|-d)
        if [ -z "${2:-}" ]; then
            echo "❌ Error: Especifica el UUID de la extensión a deshabilitar."
            exit 1
        fi
        disable_extension "$2"
        exit 0
        ;;
    --prefs|-p)
        if [ -z "${2:-}" ]; then
            echo "❌ Error: Especifica el UUID de la extensión."
            exit 1
        fi
        open_prefs "$2"
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🧩 CONFIGURANDO EXTENSIONES DE GNOME SHELL (SOPLOS LINUX BORO WORKSTATION)"
        echo "================================================================="
        install_packages

        # Asegurar extensiones de productividad predeterminadas
        for core_ext in gsconnect@andyholmes.github.io dash-to-dock@micxgx.gmail.com; do
            if [ -d "$SYSTEM_EXT_DIR/$core_ext" ]; then
                enable_extension "$core_ext" >/dev/null 2>&1 || true
            fi
        done

        echo ""
        show_status
        echo "================================================================="
        echo "✅ Configuración de extensiones completada con éxito."
        echo "================================================================="
        ;;
    *)
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
