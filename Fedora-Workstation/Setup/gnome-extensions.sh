#!/bin/bash
# ==============================================================================
# gnome-extensions.sh - Gestor de Extensiones de GNOME Shell para Fedora 44
# Instala y activa extensiones desde repositorios oficiales (DNF5) y
# directamente desde extensions.gnome.org (EGO) con compilación de esquemas.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Paquetes de herramientas y conectores (DNF5)
# ------------------------------------------------------------------------------
APP_PKGS=(
    extension-manager                       # Herramienta nativa para explorar, instalar y gestionar extensiones
    gnome-browser-connector                 # Conector nativo de GNOME Shell con Chrome / Firefox y extensions.gnome.org
    jq                                      # Utilidad para procesar respuestas de la API de extensions.gnome.org
    curl                                    # Herramienta para descarga HTTP de extensiones
    unzip                                   # Descompresor para paquetes de extensiones (.zip)
    glib2-devel                             # Compilador de esquemas GSettings (glib-compile-schemas)
)

# ------------------------------------------------------------------------------
# Lista de paquetes oficiales de extensiones en Fedora 44
# ------------------------------------------------------------------------------
EXTENSION_PKGS=(
    gnome-shell-extension-dash-to-dock      # Dock accesible fuera del overview
    gnome-shell-extension-appindicator      # Soporte de bandeja del sistema / bandejas de apps
    gnome-shell-extension-caffeine          # Desactivador rápido de suspensión / salvapantallas
    gnome-shell-extension-blur-my-shell     # Efecto de desenfoque y estética moderna
    gnome-shell-extension-user-theme        # Soporte para temas de usuario en el shell
    gnome-shell-extension-places-menu       # Menú de accesos directos a lugares
)

# ------------------------------------------------------------------------------
# Extensiones directas desde extensions.gnome.org (EGO)
# Acepta URLs completas, IDs numéricos (PK) o UUIDs.
# ------------------------------------------------------------------------------
EGO_EXTENSIONS=(
    "https://extensions.gnome.org/extension/19/user-themes/"
    "https://extensions.gnome.org/extension/615/appindicator-support/"
    "https://extensions.gnome.org/extension/8/places-status-indicator/"
    "https://extensions.gnome.org/extension/779/clipboard-indicator/"
    "https://extensions.gnome.org/extension/36/lock-keys/"
    "https://extensions.gnome.org/extension/7065/tiling-shell/"
    "https://extensions.gnome.org/extension/5940/quick-settings-audio-panel/"
    "https://extensions.gnome.org/extension/8773/multi-monitor-bar/"
    "https://extensions.gnome.org/extension/4470/media-controls/"
    "https://extensions.gnome.org/extension/1319/gsconnect/"
    "https://extensions.gnome.org/extension/3843/just-perfection/"
    "https://extensions.gnome.org/extension/355/status-area-horizontal-spacing/"
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
    "quick-settings-audio-panel@rayzeq.github.io"
    "multi-monitors-bar@frederykabryan"
    "mediacontrols@cliffniff.github.com"
    "gsconnect@andyholmes.github.io"
    "just-perfection-desktop@just-perfection"
    "status-area-horizontal-spacing@mathematical.coffee.gmail.com"
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
        if ! rpm -q "$pkg" &>/dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        echo "📦 [1/4] Instalando herramientas y extensiones oficiales con DNF5 (${missing_pkgs[*]})..."
        $SUDO dnf5 install -y "${missing_pkgs[@]}" 2>/dev/null || true
        echo "  ✅ Paquetes procesados."
    else
        echo "📦 [1/4] Herramientas oficiales (gnome-browser-connector, etc.) y extensiones ya instaladas vía DNF5."
    fi
}

install_ego_extensions() {
    if [ ${#EGO_EXTENSIONS[@]} -eq 0 ]; then
        return 0
    fi

    echo "🌐 [2/4] Verificando e instalando extensiones desde extensions.gnome.org (EGO)..."

    local shell_major
    shell_major=$(run_as_user gnome-shell --version 2>/dev/null | awk '{print $3}' | cut -d. -f1 || echo "")
    [ -z "$shell_major" ] && shell_major="46"

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

            if [ -f "$dest_path/metadata.json" ] && [ -n "$shell_major" ]; then
                local current_versions
                current_versions=$(jq -r '."shell-version"[]?' "$dest_path/metadata.json" 2>/dev/null || echo "")
                if ! echo "$current_versions" | grep -qx "$shell_major"; then
                    jq --arg v "$shell_major" '."shell-version" += [$v]' "$dest_path/metadata.json" > "$dest_path/metadata.json.tmp" && \
                    mv "$dest_path/metadata.json.tmp" "$dest_path/metadata.json"
                fi
            fi

            run_as_user gdbus call --session \
                --dest org.gnome.Shell.Extensions \
                --object-path /org/gnome/Shell/Extensions \
                --method org.gnome.Shell.Extensions.InstallRemoteExtension "$uuid" 2>/dev/null || true

            echo "  ✅ '$ext_name' instalada con éxito."
        else
            echo "  ❌ Error descargando: $ext_name ($uuid)"
            rm -f "$temp_zip"
        fi
    done
}

enable_extensions() {
    echo "⚡ [3/4] Activando extensiones configuradas..."

    run_as_user gsettings set org.gnome.shell disable-user-extensions false 2>/dev/null || true

    for uuid in "${EXTENSION_UUIDS[@]}"; do
        if run_as_user gnome-extensions list 2>/dev/null | grep -qx "$uuid"; then
            run_as_user gnome-extensions enable "$uuid" 2>/dev/null || true
            echo "  ✅ Activada: $uuid"
        fi
    done
}

configure_dash_to_dock() {
    echo "⚙️ [4/4] Aplicando configuración óptima para Dash to Dock..."
    local DOCK_SCHEMA="org.gnome.shell.extensions.dash-to-dock"

    if run_as_user gsettings list-schemas | grep -qx "$DOCK_SCHEMA"; then
        run_as_user gsettings set "$DOCK_SCHEMA" dock-position 'BOTTOM' 2>/dev/null || true
        run_as_user gsettings set "$DOCK_SCHEMA" intellihide true 2>/dev/null || true
        run_as_user gsettings set "$DOCK_SCHEMA" intellihide-mode 'FOCUS_APPLICATION_WINDOWS' 2>/dev/null || true
        run_as_user gsettings set "$DOCK_SCHEMA" dash-max-icon-size 48 2>/dev/null || true
        run_as_user gsettings set "$DOCK_SCHEMA" show-trash true 2>/dev/null || true
        run_as_user gsettings set "$DOCK_SCHEMA" click-action 'minimize-or-previews' 2>/dev/null || true
        run_as_user gsettings set "$DOCK_SCHEMA" custom-theme-shrink true 2>/dev/null || true
        run_as_user gsettings set "$DOCK_SCHEMA" extend-height false 2>/dev/null || true
        echo "  ✅ Dash to Dock configurado (posición inferior, intellihide, iconos 48px)."
    else
        echo "  ℹ️ Esquema Dash to Dock aún no disponible para configurar (reinicia la sesión tras instalar)."
    fi
}

show_status() {
    echo "================================================================="
    echo "🧩 ESTADO DE EXTENSIONES DE GNOME SHELL - FEDORA 44"
    echo "================================================================="
    local disabled_global
    disabled_global=$(run_as_user gsettings get org.gnome.shell disable-user-extensions 2>/dev/null || echo "unknown")
    echo "• Extensiones globales deshabilitadas: $disabled_global"
    echo "• Versión de GNOME Shell: $(run_as_user gnome-shell --version 2>/dev/null || echo 'No detectado')"
    echo "-----------------------------------------------------------------"
    echo "Extensiones gestionadas:"
    for uuid in "${EXTENSION_UUIDS[@]}"; do
        local state="No instalada"
        if run_as_user gnome-extensions list 2>/dev/null | grep -qx "$uuid"; then
            local info
            info=$(run_as_user gnome-extensions info "$uuid" 2>/dev/null || echo "")
            if echo "$info" | grep -q "State: ENABLED"; then
                state="Habilitada ✅"
            else
                state="Deshabilitada ⏸️"
            fi
        fi
        printf "  %-45s : %s\n" "$uuid" "$state"
    done
    echo "================================================================="
}

show_help() {
    cat <<EOF
🧩 Gestor de Extensiones de GNOME Shell - Fedora 44 Workstation

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala paquetes oficiales vía DNF5, descarga desde EGO y activa extensiones.
  --status, -s        Muestra el estado detallado de cada extensión gestionada.
  --enable-all        Activa todas las extensiones configuradas.
  --disable-all       Desactiva todas las extensiones de usuario.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --enable-all)
        enable_extensions
        exit 0
        ;;
    --disable-all)
        echo "⏸️ Desactivando extensiones de usuario..."
        run_as_user gsettings set org.gnome.shell disable-user-extensions true
        echo "✅ Extensiones desactivadas."
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🚀 INICIANDO CONFIGURACIÓN DE EXTENSIONES GNOME - FEDORA 44"
        echo "================================================================="
        install_packages
        install_ego_extensions
        enable_extensions
        configure_dash_to_dock
        echo "================================================================="
        echo "✅ Configuración de extensiones completada."
        echo "💡 Si no se cargan de inmediato, reinicia sesión o pulsa Alt+F2 y escribe 'r' (en X11)."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no válida: $1"
        show_help
        exit 1
        ;;
esac
