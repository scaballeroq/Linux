#!/bin/bash
# ==============================================================================
# gnome-extensions.sh - Gestor de Extensiones de GNOME Shell para CachyOS
# Instala y activa extensiones desde repositorios oficiales (Pacman) y
# directamente desde extensions.gnome.org (EGO) para extensiones externas.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Paquetes de herramientas y conectores (Pacman)
# ------------------------------------------------------------------------------
APP_PKGS=(
    extension-manager                       # Herramienta nativa para explorar, instalar y gestionar extensiones
    gnome-browser-connector                 # Conector nativo de GNOME Shell con Chrome / Firefox y extensions.gnome.org
    jq                                      # Utilidad para procesar respuestas de la API de extensions.gnome.org
    curl                                    # Herramienta para descarga HTTP de extensiones
    unzip                                   # Descompresor para paquetes de extensiones (.zip)
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
# Extensiones directas desde extensions.gnome.org (EGO)
# Acepta URLs completas, IDs numéricos (PK) o UUIDs.
# Útil para extensiones que no existen en los repositorios oficiales de Arch/CachyOS.
# ------------------------------------------------------------------------------
EGO_EXTENSIONS=(
    "https://extensions.gnome.org/extension/19/user-themes/"
    "https://extensions.gnome.org/extension/615/appindicator-support/"
    "https://extensions.gnome.org/extension/8/places-status-indicator/"
    "https://extensions.gnome.org/extension/779/clipboard-indicator/"
    "https://extensions.gnome.org/extension/36/lock-keys/"
    "https://extensions.gnome.org/extension/7065/tiling-shell/"
)

# ------------------------------------------------------------------------------
# UUIDs correspondientes a cada extensión en GNOME Shell para activación y estado
# ------------------------------------------------------------------------------
EXTENSION_UUIDS=(
    "dash-to-dock@micxgx.gmail.com"
    "appindicatorsupport@rgcjonas.gmail.com"
    "caffeine@patapon.info"
    "weatheroclock@CleoMenezesJr.github.io"
    "BingWallpaper@ineffable-gmail.com"
    "blur-my-shell@aunetx"
    "logomenu@aryan_k"
    "user-theme@gnome-shell-extensions.gcampax.github.com"
    "places-menu@gnome-shell-extensions.gcampax.github.com"
    "clipboard-indicator@tudmotu.com"
    "lockkeys@vaina.lt"
    "tilingshell@ferrarodomenico.com"
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

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            XDG_RUNTIME_DIR="/run/user/$REAL_UID" \
            DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$REAL_UID/bus}" \
            "$@"
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
        echo "📦 [1/4] Instalando herramientas y extensiones oficiales con Pacman (${missing_pkgs[*]})..."
        $SUDO pacman -S --needed --noconfirm "${missing_pkgs[@]}"
        echo "  ✅ Paquetes instalados correctamente."
    else
        echo "📦 [1/4] Herramientas oficiales (gnome-browser-connector, etc.) y extensiones ya instaladas vía Pacman."
    fi
}

install_ego_extensions() {
    if [ ${#EGO_EXTENSIONS[@]} -eq 0 ]; then
        return 0
    fi

    echo "🌐 [2/4] Verificando e instalando extensiones desde extensions.gnome.org (EGO)..."

    local shell_major
    shell_major=$(run_as_user gnome-shell --version 2>/dev/null | awk '{print $3}' | cut -d. -f1 || echo "")
    [ -z "$shell_major" ] && shell_major="50"

    local user_ext_dir="$USER_HOME/.local/share/gnome-shell/extensions"
    run_as_user mkdir -p "$user_ext_dir"

    for item in "${EGO_EXTENSIONS[@]}"; do
        local pk=""
        local uuid=""
        local api_query=""

        if [[ "$item" =~ extension/([0-9]+) ]]; then
            pk="${BASH_REMATCH[1]}"
            api_query="pk=${pk}"
        elif [[ "$item" =~ ^[0-9]+$ ]]; then
            pk="$item"
            api_query="pk=${pk}"
        elif [[ "$item" =~ @ ]]; then
            uuid="$item"
            api_query="uuid=${uuid}"
        else
            echo "  ⚠️ Formato no reconocido para extensión: $item"
            continue
        fi

        echo "  🔍 Consultando extensión en EGO: $item"
        local info_json
        info_json=$(curl -s "https://extensions.gnome.org/extension-info/?${api_query}&shell_version=${shell_major}" 2>/dev/null || echo "")

        local dl_url
        dl_url=$(echo "$info_json" | jq -r '.download_url // empty' 2>/dev/null || echo "")
        local ext_name
        ext_name=$(echo "$info_json" | jq -r '.name // empty' 2>/dev/null || echo "$item")
        uuid=$(echo "$info_json" | jq -r '.uuid // empty' 2>/dev/null || echo "$uuid")

        # Si no hubo download_url para la versión exacta, consultar información general
        if [ -z "$dl_url" ]; then
            info_json=$(curl -s "https://extensions.gnome.org/extension-info/?${api_query}" 2>/dev/null || echo "")
            dl_url=$(echo "$info_json" | jq -r '.download_url // empty' 2>/dev/null || echo "")
            [ -z "$ext_name" ] && ext_name=$(echo "$info_json" | jq -r '.name // empty' 2>/dev/null || echo "$item")
            [ -z "$uuid" ] && uuid=$(echo "$info_json" | jq -r '.uuid // empty' 2>/dev/null || echo "")

            # Obtener el tag de versión más reciente si está en shell_version_map
            if [ -z "$dl_url" ] && [ -n "$uuid" ]; then
                local latest_tag
                latest_tag=$(echo "$info_json" | jq -r '[.shell_version_map[]] | sort_by(.version) | last | .pk // empty' 2>/dev/null || echo "")
                if [ -n "$latest_tag" ]; then
                    dl_url="/download-extension/${uuid}.shell-extension.zip?version_tag=${latest_tag}"
                fi
            fi
        fi

        if [ -z "$uuid" ]; then
            echo "  ❌ No se pudo determinar el UUID para: $item"
            continue
        fi

        # Agregar dinámicamente a EXTENSION_UUIDS si no existe
        local exists_in_list=false
        for u in "${EXTENSION_UUIDS[@]}"; do
            if [ "$u" = "$uuid" ]; then
                exists_in_list=true
                break
            fi
        done
        if [ "$exists_in_list" = false ]; then
            EXTENSION_UUIDS+=("$uuid")
        fi

        # Comprobar si ya está instalada a nivel de sistema o usuario
        local dest_path="$user_ext_dir/$uuid"
        if [ -d "/usr/share/gnome-shell/extensions/$uuid" ]; then
            echo "  🟢 '$ext_name' ($uuid) ya provista en el sistema (/usr/share/gnome-shell/extensions)."
            continue
        elif [ -d "$dest_path" ]; then
            echo "  🟢 '$ext_name' ($uuid) ya instalada en espacio de usuario ($dest_path)."
            continue
        fi

        if [ -z "$dl_url" ]; then
            echo "  ❌ No se encontró enlace de descarga para: $ext_name ($uuid)"
            continue
        fi

        echo "  ⬇️ Descargando e instalando: $ext_name ($uuid)..."
        local temp_zip
        temp_zip=$(mktemp /tmp/gnome_ext_XXXXXX.zip)

        if curl -sL "https://extensions.gnome.org${dl_url}" -o "$temp_zip"; then
            run_as_user mkdir -p "$dest_path"
            run_as_user unzip -q -o "$temp_zip" -d "$dest_path"
            if [ -d "$dest_path/schemas" ]; then
                run_as_user glib-compile-schemas "$dest_path/schemas" 2>/dev/null || true
            fi
            rm -f "$temp_zip"

            # Notificar a GNOME Shell por D-Bus para registrarla inmediatamente si la sesión está activa
            run_as_user busctl --user call org.gnome.Shell.Extensions /org/gnome/Shell/Extensions org.gnome.Shell.Extensions InstallRemoteExtension s "$uuid" &>/dev/null || true

            echo "  ✅ Instalada exitosamente: $ext_name"
        else
            echo "  ❌ Error descargando extensión desde https://extensions.gnome.org${dl_url}"
            rm -f "$temp_zip"
        fi
    done
}

enable_extensions() {
    echo "🔌 [3/4] Habilitando soporte global de extensiones de usuario..."
    run_as_user gsettings set org.gnome.shell disable-user-extensions false 2>/dev/null || true

    echo "⚡ [4/4] Activando extensiones en GNOME Shell..."
    for uuid in "${EXTENSION_UUIDS[@]}"; do
        # 1. Intentar activación con CLI nativa de gnome-extensions
        if run_as_user gnome-extensions list 2>/dev/null | grep -q "^${uuid}$"; then
            run_as_user gnome-extensions enable "$uuid" 2>/dev/null || true
            echo "  ✅ Habilitada: $uuid"
        else
            echo "  ⚠️ Extensión no cargada en la sesión activa: $uuid (se habilitará vía gsettings para el próximo inicio)"
        fi

        # 2. Notificar vía D-Bus si GNOME Shell está corriendo
        run_as_user busctl --user call org.gnome.Shell.Extensions /org/gnome/Shell/Extensions org.gnome.Shell.Extensions EnableExtension s "$uuid" &>/dev/null || true

        # 3. Asegurar persistencia en GSettings 'enabled-extensions'
        local current_exts
        current_exts=$(run_as_user gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo "[]")
        if [[ "$current_exts" != *"$uuid"* ]]; then
            if [[ "$current_exts" == "[]" || "$current_exts" == "@as []" ]]; then
                run_as_user gsettings set org.gnome.shell enabled-extensions "['$uuid']" 2>/dev/null || true
            else
                local new_exts
                new_exts=$(echo "$current_exts" | sed "s/\]$/,'$uuid'\]/" | sed "s/\[,'/\[/'/")
                run_as_user gsettings set org.gnome.shell enabled-extensions "$new_exts" 2>/dev/null || true
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
        run_as_user busctl --user call org.gnome.Shell.Extensions /org/gnome/Shell/Extensions org.gnome.Shell.Extensions DisableExtension s "$uuid" &>/dev/null || true
        echo "  ❌ Deshabilitada: $uuid"
    done
}

show_status() {
    echo "================================================================="
    echo "🧩 ESTADO DE EXTENSIONES GNOME SHELL"
    echo "================================================================="
    USER_EXT_ENABLED=$(run_as_user gsettings get org.gnome.shell disable-user-extensions 2>/dev/null || echo "unknown")
    echo "• Soporte de extensiones de usuario   : $([ "$USER_EXT_ENABLED" = "false" ] && echo "HABILITADO" || echo "DESHABILITADO")"
    
    EXT_MGR_VER=$(pacman -Q extension-manager 2>/dev/null | awk '{print $2}' || echo "")
    if [ -n "$EXT_MGR_VER" ]; then
        echo "• Gestor gráfico (Extension Manager)  : 🟢 INSTALADO (v$EXT_MGR_VER)"
    else
        echo "• Gestor gráfico (Extension Manager)  : 🔴 NO INSTALADO"
    fi

    GBC_VER=$(pacman -Q gnome-browser-connector 2>/dev/null | awk '{print $2}' || echo "")
    if [ -n "$GBC_VER" ]; then
        echo "• Conector de navegador (Chrome/EGO)  : 🟢 INSTALADO (v$GBC_VER)"
    else
        echo "• Conector de navegador (Chrome/EGO)  : 🔴 NO INSTALADO"
    fi

    echo ""
    for uuid in "${EXTENSION_UUIDS[@]}"; do
        if run_as_user gnome-extensions list --enabled 2>/dev/null | grep -q "^${uuid}$"; then
            STATE="🟢 ACTIVA"
        elif run_as_user gnome-extensions list 2>/dev/null | grep -q "^${uuid}$"; then
            STATE="🟡 INSTALADA (INACTIVA)"
        elif [ -d "/usr/share/gnome-shell/extensions/$uuid" ] || [ -d "$USER_HOME/.local/share/gnome-shell/extensions/$uuid" ]; then
            STATE="🟡 INSTALADA EN DISCO (PENDIENTE REINICIO)"
        else
            STATE="🔴 NO INSTALADA"
        fi
        printf "  %-52s : %s\n" "$uuid" "$STATE"
    done
    echo "================================================================="
}

show_help() {
    echo "Uso: $0 [OPCIÓN]"
    echo ""
    echo "Opciones:"
    echo "  (sin opción)  Instala paquetes vía Pacman, descarga extensiones de EGO y activa todo."
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
        install_ego_extensions
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
