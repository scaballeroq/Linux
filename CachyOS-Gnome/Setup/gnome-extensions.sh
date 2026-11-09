#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  gnome-extensions.sh - Gestor de Extensiones de GNOME Shell (Wayland)
#  Sistema: CachyOS / Arch Linux (GNOME Shell Wayland / Mutter / Pacman)
#  Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM)
#  Topología: Triple Pantalla Full HD 1080p (DP-3, DP-4, eDP-1)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y FORMATO VISUAL
# ------------------------------------------------------------------------------
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

# ------------------------------------------------------------------------------
# 2. PRIVILEGIOS Y CONTEXTO DE USUARIO WAYLAND / D-BUS
# ------------------------------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
    REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER:-root}")}"
else
    REAL_USER="${USER:-$(whoami)}"
fi
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

run_as_user() {
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$REAL_UID}"
    local dbus_addr="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$runtime_dir/bus}"
    local data_dirs="${USER_HOME}/.local/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            XDG_DATA_DIRS="$data_dirs" \
            "$@"
    else
        env \
            XDG_RUNTIME_DIR="$runtime_dir" \
            DBUS_SESSION_BUS_ADDRESS="$dbus_addr" \
            XDG_DATA_DIRS="$data_dirs" \
            "$@"
    fi
}

# ------------------------------------------------------------------------------
# 3. CATÁLOGO DE PAQUETES OFICIALES (PACMAN) Y EXTENSIONES EGO
# ------------------------------------------------------------------------------
APP_PKGS=(
    extension-manager                       # Gestor gráfico de extensiones
    gnome-browser-connector                 # Conector nativo de navegador con extensions.gnome.org
    jq                                      # Procesador JSON para API EGO
    curl                                    # Descargas HTTP seguras
    unzip                                   # Descompresor de paquetes .zip
    glib2                                   # Compilador de esquemas GSettings
)

# Extensiones disponibles en repositorios oficiales / extra de Arch & CachyOS
EXTENSION_PKGS=(
    gnome-shell-extension-appindicator      # Bandeja de iconos del sistema (AppIndicator/KStatusNotifierItem)
    gnome-shell-extensions                  # Extensiones oficiales GNOME (user-theme, places-menu, etc.)
    gnome-shell-extension-caffeine          # Inhibición de suspensión y bloqueo de pantalla
)

# Extensiones desde extensions.gnome.org (EGO) optimizadas para HP ProBook y triple pantalla FHD
EGO_EXTENSIONS=(
    "https://extensions.gnome.org/extension/8773/multi-monitor-bar/"             # Barra superior en monitores externos (DP-3, DP-4)
    "https://extensions.gnome.org/extension/7065/tiling-shell/"                 # Snap y layouts tiling multimonitor
    "https://extensions.gnome.org/extension/5940/quick-settings-audio-panel/"   # Control rápido de audio PipeWire (auriculares / HP ALC236 / DP)
    "https://extensions.gnome.org/extension/779/clipboard-indicator/"           # Historial del portapapeles en Wayland
    "https://extensions.gnome.org/extension/36/lock-keys/"                      # OSD / Estado de NumLock (HP ProBook 455 G10)
    "https://extensions.gnome.org/extension/4470/media-controls/"               # Controles multimedia MPRIS en barra superior
    "https://extensions.gnome.org/extension/355/status-area-horizontal-spacing/" # Densidad y espaciado de iconos en barra superior
    "https://extensions.gnome.org/extension/3843/just-perfection/"              # Personalización avanzada del Shell y visibilidad UI
    "https://extensions.gnome.org/extension/307/dash-to-dock/"                  # Dock personalizable en Wayland
    "https://extensions.gnome.org/extension/3193/blur-my-shell/"                # Efecto blur optimizado para Mutter y Vega 8
    "https://extensions.gnome.org/extension/1262/bing-wallpaper/"               # Fondo diario de Bing en alta resolución
)

# UUIDs gestionados para verificación, activación y persistencia
EXTENSION_UUIDS=(
    "dash-to-dock@micxgx.gmail.com"
    "appindicatorsupport@rgcjonas.gmail.com"
    "caffeine@patapon.info"
    "blur-my-shell@aunetx"
    "user-theme@gnome-shell-extensions.gcampax.github.com"
    "places-menu@gnome-shell-extensions.gcampax.github.com"
    "just-perfection-desktop@just-perfection"
    "gsconnect@andyholmes.github.io"
    "tiling-assistant@leleat-on-github"
    "tilingshell@ferrarodomenico.com"
    "multi-monitors-bar@frederykabryan"
    "quick-settings-audio-panel@rayzeq.github.io"
    "clipboard-indicator@tudmotu.com"
    "lockkeys@vaina.lt"
    "mediacontrols@cliffniff.github.com"
    "status-area-horizontal-spacing@mathematical.coffee.gmail.com"
    "BingWallpaper@ineffable-gmail.com"
)

# ------------------------------------------------------------------------------
# 4. COMPILACIÓN Y SINCRONIZACIÓN DE ESQUEMAS GSETTINGS DE USUARIO
# ------------------------------------------------------------------------------
sync_user_schemas() {
    local user_schema_dir="$USER_HOME/.local/share/glib-2.0/schemas"
    local user_ext_dir="$USER_HOME/.local/share/gnome-shell/extensions"
    run_as_user mkdir -p "$user_schema_dir"

    # Copiar recursivamente esquemas xml de extensiones de usuario a glib-2.0/schemas
    if [[ -d "$user_ext_dir" ]]; then
        find "$user_ext_dir" -type f -name "*.gschema.xml" -exec cp -f {} "$user_schema_dir/" \; 2>/dev/null || true
    fi

    if compgen -G "$user_schema_dir/*.gschema.xml" > /dev/null; then
        run_as_user glib-compile-schemas "$user_schema_dir" 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN DE PAQUETES OFICIALES (PACMAN)
# ------------------------------------------------------------------------------
install_system_packages() {
    log_info "[1/4] Verificando e instalando herramientas oficiales y extensiones (Pacman)..."
    local all_pkgs=("${APP_PKGS[@]}" "${EXTENSION_PKGS[@]}")
    local missing_pkgs=()

    for pkg in "${all_pkgs[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
        log_info "Instalando paquetes vía pacman: ${missing_pkgs[*]}..."
        if [[ $EUID -eq 0 ]]; then
            pacman -S --needed --noconfirm "${missing_pkgs[@]}" 2>/dev/null || true
        else
            sudo pacman -S --needed --noconfirm "${missing_pkgs[@]}" 2>/dev/null || true
        fi
        log_ok "Paquetes oficiales de extensiones instalados."
    else
        log_ok "Herramientas y extensiones oficiales ya instaladas vía Pacman."
    fi
}

# ------------------------------------------------------------------------------
# 6. INSTALACIÓN DESDE EXTENSIONS.GNOME.ORG (EGO)
# ------------------------------------------------------------------------------
install_ego_extensions() {
    if [[ ${#EGO_EXTENSIONS[@]} -eq 0 ]]; then
        return 0
    fi

    log_info "[2/4] Verificando e instalando extensiones desde extensions.gnome.org (EGO)..."

    local shell_major
    shell_major=$(run_as_user gnome-shell --version 2>/dev/null | awk '{print $3}' | cut -d. -f1 || echo "")
    [[ -z "$shell_major" ]] && shell_major="51"

    local user_ext_dir="$USER_HOME/.local/share/gnome-shell/extensions"
    run_as_user mkdir -p "$user_ext_dir"

    # Desactivar validación estricta de versión en GNOME Shell para máxima compatibilidad
    run_as_user gsettings set org.gnome.shell disable-extension-version-validation true 2>/dev/null || true

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
            log_warn "Formato no reconocido: $item"
            continue
        fi

        log_info "Consultando catálogo EGO: $item (GNOME Shell $shell_major)..."
        local info_json
        info_json=$(curl -s "https://extensions.gnome.org/extension-info/?${api_query}&shell_version=${shell_major}" 2>/dev/null || echo "")

        local dl_url ext_name
        dl_url=$(echo "$info_json" | jq -r '.download_url // empty' 2>/dev/null || echo "")
        ext_name=$(echo "$info_json" | jq -r '.name // empty' 2>/dev/null || echo "$item")
        uuid=$(echo "$info_json" | jq -r '.uuid // empty' 2>/dev/null || echo "$uuid")

        # Si no hubo descarga exacta para la versión mayor, buscar última versión publicada
        if [[ -z "$dl_url" ]]; then
            info_json=$(curl -s "https://extensions.gnome.org/extension-info/?${api_query}" 2>/dev/null || echo "")
            dl_url=$(echo "$info_json" | jq -r '.download_url // empty' 2>/dev/null || echo "")
            [[ -z "$ext_name" ]] && ext_name=$(echo "$info_json" | jq -r '.name // empty' 2>/dev/null || echo "$item")
            [[ -z "$uuid" ]] && uuid=$(echo "$info_json" | jq -r '.uuid // empty' 2>/dev/null || echo "")

            if [[ -z "$dl_url" && -n "$uuid" ]]; then
                local latest_tag
                latest_tag=$(echo "$info_json" | jq -r '[.shell_version_map[]] | sort_by(.version) | last | .pk // empty' 2>/dev/null || echo "")
                if [[ -n "$latest_tag" ]]; then
                    dl_url="/download-extension/${uuid}.shell-extension.zip?version_tag=${latest_tag}"
                fi
            fi
        fi

        if [[ -z "$uuid" ]]; then
            log_warn "No se pudo determinar el UUID para: $item"
            continue
        fi

        local dest_path="$user_ext_dir/$uuid"
        if [[ -d "/usr/share/gnome-shell/extensions/$uuid" ]]; then
            log_ok "'$ext_name' ($uuid) ya provista en el sistema (/usr/share)."
            continue
        elif [[ -d "$dest_path" ]]; then
            log_ok "'$ext_name' ($uuid) ya instalada en espacio de usuario."
            continue
        fi

        if [[ -z "$dl_url" ]]; then
            log_warn "No se encontró enlace de descarga para: $ext_name ($uuid)"
            continue
        fi

        log_info "Descargando e instalando: $ext_name ($uuid)..."
        local temp_zip
        temp_zip=$(mktemp /tmp/gnome_ext_XXXXXX.zip)

        if curl -sL "https://extensions.gnome.org${dl_url}" -o "$temp_zip"; then
            run_as_user mkdir -p "$dest_path"
            run_as_user unzip -q -o "$temp_zip" -d "$dest_path"
            rm -f "$temp_zip"

            # Inyectar versión del Shell actual en metadata.json si no está listada
            if [[ -f "$dest_path/metadata.json" && -n "$shell_major" ]]; then
                local current_versions
                current_versions=$(jq -r '."shell-version"[]?' "$dest_path/metadata.json" 2>/dev/null || echo "")
                if ! echo "$current_versions" | grep -qx "$shell_major"; then
                    jq --arg v "$shell_major" '."shell-version" += [$v]' "$dest_path/metadata.json" > "$dest_path/metadata.json.tmp" && \
                    mv "$dest_path/metadata.json.tmp" "$dest_path/metadata.json"
                fi
            fi

            # Compilar esquemas si están presentes
            if [[ -d "$dest_path/schemas" ]]; then
                run_as_user glib-compile-schemas "$dest_path/schemas" 2>/dev/null || true
            fi

            # Notificar al compositor GNOME Shell por D-Bus
            run_as_user gdbus call --session \
                --dest org.gnome.Shell.Extensions \
                --object-path /org/gnome/Shell/Extensions \
                --method org.gnome.Shell.Extensions.InstallRemoteExtension "$uuid" 2>/dev/null || true

            log_ok "'$ext_name' instalada con éxito."
        else
            log_err "Error descargando: $ext_name ($uuid)"
            rm -f "$temp_zip"
        fi
    done

    sync_user_schemas
}

# ------------------------------------------------------------------------------
# 7. ACTIVACIÓN Y HABILITACIÓN DE EXTENSIONES CON PERSISTENCIA
# ------------------------------------------------------------------------------
enable_extensions() {
    log_info "[3/4] Activando extensiones gestionadas..."

    # Permitir extensiones de usuario globalmente
    run_as_user gsettings set org.gnome.shell disable-user-extensions false 2>/dev/null || true

    local available_exts
    available_exts=$(run_as_user gnome-extensions list 2>/dev/null || true)

    for uuid in "${EXTENSION_UUIDS[@]}"; do
        if echo "$available_exts" | grep -qx "$uuid"; then
            # Habilitar vía CLI de GNOME Shell
            run_as_user gnome-extensions enable "$uuid" 2>/dev/null || true

            # Garantizar persistencia directa en el array 'enabled-extensions' de GSettings
            local current_enabled
            current_enabled=$(run_as_user gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo "@as []")
            if ! echo "$current_enabled" | grep -q "'$uuid'"; then
                if [[ "$current_enabled" == "@as []" || "$current_enabled" == "[]" ]]; then
                    run_as_user gsettings set org.gnome.shell enabled-extensions "['$uuid']" 2>/dev/null || true
                else
                    local new_list="${current_enabled%]*}, '$uuid']"
                    run_as_user gsettings set org.gnome.shell enabled-extensions "$new_list" 2>/dev/null || true
                fi
            fi
            log_ok "Activada y persistida: $uuid"
        fi
    done
}

# ------------------------------------------------------------------------------
# 8. AJUSTES ÓPTIMOS (DASH TO DOCK, TRIPLE PANTALLA, BLUR Y HARDWARE AMD)
# ------------------------------------------------------------------------------
set_gsetting() {
    local schema="$1"
    local key="$2"
    local value="$3"
    if run_as_user gsettings list-schemas 2>/dev/null | grep -qx "$schema"; then
        run_as_user gsettings set "$schema" "$key" "$value" 2>/dev/null || true
    fi
}

configure_extensions() {
    log_info "[4/4] Aplicando configuración óptima para extensiones y hardware..."
    sync_user_schemas

    # 1. Dash to Dock (Alineación inferior flotante, 44px para 1080p, triple pantalla)
    local DOCK_SCHEMA="org.gnome.shell.extensions.dash-to-dock"
    if run_as_user gsettings list-schemas 2>/dev/null | grep -qx "$DOCK_SCHEMA"; then
        set_gsetting "$DOCK_SCHEMA" dock-position "'BOTTOM'"
        set_gsetting "$DOCK_SCHEMA" intellihide "true"
        set_gsetting "$DOCK_SCHEMA" intellihide-mode "'FOCUS_APPLICATION_WINDOWS'"
        set_gsetting "$DOCK_SCHEMA" dash-max-icon-size "44"
        set_gsetting "$DOCK_SCHEMA" show-trash "true"
        set_gsetting "$DOCK_SCHEMA" show-mounts "false"
        set_gsetting "$DOCK_SCHEMA" click-action "'minimize-or-previews'"
        set_gsetting "$DOCK_SCHEMA" scroll-action "'cycle-windows'"
        set_gsetting "$DOCK_SCHEMA" custom-theme-shrink "true"
        set_gsetting "$DOCK_SCHEMA" extend-height "false"
        set_gsetting "$DOCK_SCHEMA" multi-monitor "true"
        set_gsetting "$DOCK_SCHEMA" preferred-monitor "-1"
        set_gsetting "$DOCK_SCHEMA" isolate-monitors "false"
        set_gsetting "$DOCK_SCHEMA" running-indicator-style "'DOTS'"
        log_ok "Dash to Dock configurado (flotante, 44px, intellihide, multimonitor activo en DP-3, DP-4, eDP-1)."
    fi

    # 2. Blur my Shell (Optimizado para APU AMD Ryzen 7 7730U y Radeon Vega 8)
    local BLUR_SCHEMA="org.gnome.shell.extensions.blur-my-shell"
    if run_as_user gsettings list-schemas 2>/dev/null | grep -qx "$BLUR_SCHEMA"; then
        set_gsetting "$BLUR_SCHEMA.panel" blur "true"
        set_gsetting "$BLUR_SCHEMA.overview" blur "true"
        set_gsetting "$BLUR_SCHEMA.dash-to-dock" blur "true"
        set_gsetting "$BLUR_SCHEMA.dash-to-dock" sigma "30"
        set_gsetting "$BLUR_SCHEMA.appfolder" blur "true"
        # Desactivar blur en ventanas activas para garantizar 60 fps constantes en triple monitor
        set_gsetting "$BLUR_SCHEMA.window-list" blur "false"
        log_ok "Blur my Shell configurado y optimizado para Radeon Vega 8."
    fi

    # 3. Caffeine (Estado siempre visible, persistente y silencioso)
    local CAFFEINE_SCHEMA="org.gnome.shell.extensions.caffeine"
    if run_as_user gsettings list-schemas 2>/dev/null | grep -qx "$CAFFEINE_SCHEMA"; then
        set_gsetting "$CAFFEINE_SCHEMA" show-indicator "'always'"
        set_gsetting "$CAFFEINE_SCHEMA" restore-state "true"
        set_gsetting "$CAFFEINE_SCHEMA" show-notifications "false"
        log_ok "Caffeine configurado (indicador visible, sin notificaciones invasivas)."
    fi

    # 4. Clipboard Indicator (Wayland portapapeles)
    local CLIP_SCHEMA="org.gnome.shell.extensions.clipboard-indicator"
    if run_as_user gsettings list-schemas 2>/dev/null | grep -qx "$CLIP_SCHEMA"; then
        set_gsetting "$CLIP_SCHEMA" history-size "50"
        set_gsetting "$CLIP_SCHEMA" preview-size "30"
        set_gsetting "$CLIP_SCHEMA" notify-on-copy "false"
        set_gsetting "$CLIP_SCHEMA" confirm-clear "true"
        log_ok "Clipboard Indicator configurado (historial 50 items, notificaciones silenciadas)."
    fi

    # 5. Lock Keys (Teclado HP ProBook 455 G10)
    local LOCK_SCHEMA="org.gnome.shell.extensions.lockkeys"
    if run_as_user gsettings list-schemas 2>/dev/null | grep -qx "$LOCK_SCHEMA"; then
        set_gsetting "$LOCK_SCHEMA" style "'both'"
        set_gsetting "$LOCK_SCHEMA" notification "true"
        log_ok "Lock Keys configurado para teclado HP ProBook."
    fi

    # 6. Status Area Horizontal Spacing (Densidad visual en 1080p)
    local SPACE_SCHEMA="org.gnome.shell.extensions.status-area-horizontal-spacing"
    if run_as_user gsettings list-schemas 2>/dev/null | grep -qx "$SPACE_SCHEMA"; then
        set_gsetting "$SPACE_SCHEMA" hpadding "4"
        log_ok "Espaciado de la barra superior optimizado a 4px."
    fi

    # 7. Quick Settings Audio Panel (Control de PipeWire / ALC236 y DP)
    local AUDIO_SCHEMA="org.gnome.shell.extensions.quick-settings-audio-panel"
    if run_as_user gsettings list-schemas 2>/dev/null | grep -qx "$AUDIO_SCHEMA"; then
        set_gsetting "$AUDIO_SCHEMA" always-show-input-slider "true"
        log_ok "Quick Settings Audio Panel configurado para PipeWire."
    fi

    # 8. Multi-Monitor Bar (Barra de estado en pantallas externas DP-3 y DP-4)
    local MMB_SCHEMA="org.gnome.shell.extensions.multi-monitors-bar"
    if run_as_user gsettings list-schemas 2>/dev/null | grep -qx "$MMB_SCHEMA"; then
        set_gsetting "$MMB_SCHEMA" show-activities-button "true"
        log_ok "Multi-Monitor Bar configurado para monitores DP-3 y DP-4."
    fi

    # 9. Mutter (Espacios de trabajo en todas las pantallas de la estación de trabajo)
    run_as_user gsettings set org.gnome.mutter workspaces-only-on-primary false 2>/dev/null || true
    log_ok "Mutter configurado: Espacios de trabajo extendidos a pantallas externas."
}

# ------------------------------------------------------------------------------
# 9. DIAGNÓSTICO Y ESTADO (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🧩 ${BOLD}ESTADO DE EXTENSIONES DE GNOME SHELL - CACHYOS WORKSTATION${NC}"
    echo -e "      ${CYAN}HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM)${NC}"
    echo -e "      ${CYAN}Topología: Triple Pantalla Full HD (DP-3, DP-4, eDP-1)${NC}"
    echo -e "${BOLD}======================================================================${NC}"

    local disabled_global gnome_ver version_validation
    disabled_global=$(run_as_user gsettings get org.gnome.shell disable-user-extensions 2>/dev/null || echo "unknown")
    gnome_ver=$(run_as_user gnome-shell --version 2>/dev/null || echo 'No detectado')
    version_validation=$(run_as_user gsettings get org.gnome.shell disable-extension-version-validation 2>/dev/null || echo "false")

    echo -e "  • Versión de GNOME Shell:    ${BOLD}${gnome_ver}${NC}"
    echo -e "  • Extensiones de usuario:    ${GREEN}$( [[ "$disabled_global" == "false" ]] && echo "Habilitadas globalmente" || echo "Deshabilitadas globalmente" )${NC}"
    echo -e "  • Validación de Versión:     ${CYAN}$( [[ "$version_validation" == "true" ]] && echo "Desactivada (Permisiva GNOME 51+)" || echo "Activa" )${NC}"
    echo -e "${BOLD}----------------------------------------------------------------------${NC}"
    echo -e "${BOLD}Catálogo de Extensiones Gestionadas:${NC}"

    local available_list enabled_list
    available_list=$(run_as_user gnome-extensions list 2>/dev/null || true)
    enabled_list=$(run_as_user gnome-extensions list --enabled 2>/dev/null || true)

    local total_count=0 installed_count=0 enabled_count=0

    for uuid in "${EXTENSION_UUIDS[@]}"; do
        total_count=$((total_count + 1))
        local state="${RED}No instalada ❌${NC}"
        local origin="               "

        if echo "$available_list" | grep -qx "$uuid"; then
            installed_count=$((installed_count + 1))
            if [[ -d "/usr/share/gnome-shell/extensions/$uuid" ]]; then
                origin="(Pacman/Sistema)"
            else
                origin="(EGO / Usuario) "
            fi

            if echo "$enabled_list" | grep -qx "$uuid"; then
                enabled_count=$((enabled_count + 1))
                state="${GREEN}Habilitada ✅${NC}"
            else
                local info
                info=$(LC_ALL=C run_as_user gnome-extensions info "$uuid" 2>/dev/null || echo "")
                if echo "$info" | grep -qi "State: ERROR"; then
                    state="${RED}Error ⚠️${NC}"
                else
                    state="${YELLOW}Deshabilitada ⏸️${NC}"
                fi
            fi
        fi
        printf "  %-46s %-16s : %b\n" "$uuid" "$origin" "$state"
    done
    echo -e "${BOLD}----------------------------------------------------------------------${NC}"
    echo -e "  Resumen: ${GREEN}${enabled_count} activas${NC} / ${CYAN}${installed_count} instaladas${NC} / ${BOLD}${total_count} gestionadas${NC}"
    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 10. AYUDA CLI (--help)
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}🧩 Gestor de Extensiones de GNOME Shell - CachyOS Workstation (GNOME Wayland)${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / Triple Pantalla)

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)           Instala paquetes Pacman, extensiones EGO, activa y configura
  -s, --status, status       Muestra el diagnóstico detallado de cada extensión gestionada
  --enable-all               Activa y persiste todas las extensiones instaladas configuradas
  --disable-all              Desactiva globalmente las extensiones de usuario
  --config, --tune           Aplica ajustes recomendados (Dash to Dock, Blur, Audio, Multimonitor)
  --sync-schemas             Compila y enlaza esquemas GSettings en espacio de usuario
  --no-install               Solo activa y configura sin descargar paquetes ni extensiones
  -h, --help, help           Muestra este mensaje de ayuda
EOF
}

# ------------------------------------------------------------------------------
# 11. ENTRADA PRINCIPAL Y CONTROL DE FLUJO
# ------------------------------------------------------------------------------
case "${1:-}" in
    -s|--status|status)
        show_status
        exit 0
        ;;
    --enable-all)
        enable_extensions
        exit 0
        ;;
    --disable-all)
        log_info "Desactivando extensiones de usuario..."
        run_as_user gsettings set org.gnome.shell disable-user-extensions true
        log_ok "Extensiones desactivadas globalmente."
        exit 0
        ;;
    --config|--configure|--tune|--config-dock)
        configure_extensions
        exit 0
        ;;
    --sync-schemas)
        log_info "Sincronizando y compilando esquemas GSettings de usuario..."
        sync_user_schemas
        log_ok "Esquemas sincronizados."
        exit 0
        ;;
    --no-install)
        enable_extensions
        configure_extensions
        show_status
        exit 0
        ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
    "")
        echo -e "${BOLD}======================================================================${NC}"
        echo -e "  🚀 ${BOLD}CONFIGURADOR DE EXTENSIONES GNOME - CACHYOS WORKSTATION${NC}"
        echo -e "      ${CYAN}HP ProBook 455 G10 (AMD Ryzen 7 7730U / Triple Pantalla FHD)${NC}"
        echo -e "${BOLD}======================================================================${NC}"
        install_system_packages
        install_ego_extensions
        enable_extensions
        configure_extensions
        echo -e "${BOLD}======================================================================${NC}"
        log_ok "Configuración de extensiones completada."
        show_status
        ;;
    *)
        log_err "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
