#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
#  gnome-extensions.sh - Gestor de Extensiones de GNOME Shell (Wayland)
#  Sistema: Fedora 45 Workstation (GNOME Shell 51+ / Mutter / DNF5)
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
    if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
        sudo -u "$REAL_USER" env \
            HOME="$USER_HOME" \
            USER="$REAL_USER" \
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

DNF_BIN="dnf5"
command -v dnf5 &>/dev/null || DNF_BIN="dnf"

# ------------------------------------------------------------------------------
# 3. CATÁLOGO DE PAQUETES OFICIALES (DNF5) Y EXTENSIONES EGO
# ------------------------------------------------------------------------------
APP_PKGS=(
    extension-manager                       # Gestor gráfico de extensiones
    gnome-browser-connector                 # Conector nativo de navegador con extensions.gnome.org
    jq                                      # Procesador JSON para API EGO
    curl                                    # Descargas HTTP seguras
    unzip                                   # Descompresor de paquetes .zip
    glib2-devel                             # Compilador de esquemas GSettings
)

# Extensiones disponibles en repositorios de Fedora 45 (estabilidad nativa DNF5)
EXTENSION_PKGS=(
    gnome-shell-extension-dash-to-dock      # Dock multifuncional en escritorio
    gnome-shell-extension-appindicator      # Bandeja de iconos del sistema (AppIndicator/KStatusNotifierItem)
    gnome-shell-extension-caffeine          # Inhibidor de suspensión y bloqueo de pantalla
    gnome-shell-extension-blur-my-shell     # Efecto desenfoque acelerado por GPU Radeon
    gnome-shell-extension-user-theme        # Soporte para temas de usuario en el shell
    gnome-shell-extension-places-menu       # Menú de accesos directos a carpetas
    gnome-shell-extension-just-perfection   # Ajustes finos de interfaz y animación
    gnome-shell-extension-gsconnect         # Integración móvil (KDE Connect para GNOME)
    gnome-shell-extension-tiling-assistant  # Tiling avanzado para triple monitor
)

# Extensiones directas desde extensions.gnome.org (EGO) optimizadas para el portátil y triple pantalla
EGO_EXTENSIONS=(
    "https://extensions.gnome.org/extension/8773/multi-monitor-bar/"             # Barra superior en monitores externos (DP-3, DP-4)
    "https://extensions.gnome.org/extension/7065/tiling-shell/"                 # Snap y layouts tiling multimonitor
    "https://extensions.gnome.org/extension/5940/quick-settings-audio-panel/"   # Control rápido de audio PipeWire (auriculares / HP ALC236)
    "https://extensions.gnome.org/extension/779/clipboard-indicator/"           # Historial del portapapeles en Wayland
    "https://extensions.gnome.org/extension/36/lock-keys/"                      # OSD / Estado de NumLock (HP ProBook 455 G10)
    "https://extensions.gnome.org/extension/4470/media-controls/"               # Controles multimedia MPRIS en barra superior
    "https://extensions.gnome.org/extension/355/status-area-horizontal-spacing/" # Densidad y espaciado de iconos en barra superior
)

# UUIDs gestionados para verificación y activación
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
    "multi-monitors-bar@frederykabryan"
    "tilingshell@ferrarodomenico.com"
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

    # Copiar esquemas xml de extensiones de usuario a glib-2.0/schemas para visibilidad en gsettings
    if [[ -d "$user_ext_dir" ]]; then
        find "$user_ext_dir" -type f -name "*.gschema.xml" -exec cp -f {} "$user_schema_dir/" \; 2>/dev/null || true
    fi

    if compgen -G "$user_schema_dir/*.gschema.xml" > /dev/null; then
        run_as_user glib-compile-schemas "$user_schema_dir" 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN DE PAQUETES OFICIALES (DNF5)
# ------------------------------------------------------------------------------
install_system_packages() {
    log_info "[1/4] Verificando e instalando extensiones oficiales y utilidades ($DNF_BIN)..."
    local all_pkgs=("${APP_PKGS[@]}" "${EXTENSION_PKGS[@]}")
    local missing_pkgs=()

    for pkg in "${all_pkgs[@]}"; do
        if ! rpm -q "$pkg" &>/dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
        log_info "Instalando paquetes vía $DNF_BIN: ${missing_pkgs[*]}..."
        if [[ $EUID -eq 0 ]]; then
            "$DNF_BIN" install -y "${missing_pkgs[@]}" || true
        else
            sudo "$DNF_BIN" install -y "${missing_pkgs[@]}" || true
        fi
        log_ok "Paquetes oficiales de extensiones instalados."
    else
        log_ok "Herramientas y extensiones oficiales ya instaladas vía RPM / DNF5."
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
# 7. ACTIVACIÓN Y HABILITACIÓN DE EXTENSIONES
# ------------------------------------------------------------------------------
enable_extensions() {
    log_info "[3/4] Activando extensiones gestionadas..."

    # Permitir extensiones de usuario globalmente
    run_as_user gsettings set org.gnome.shell disable-user-extensions false 2>/dev/null || true

    local available_exts
    available_exts=$(run_as_user gnome-extensions list 2>/dev/null || true)

    for uuid in "${EXTENSION_UUIDS[@]}"; do
        if echo "$available_exts" | grep -qx "$uuid"; then
            run_as_user gnome-extensions enable "$uuid" 2>/dev/null || true
            log_ok "Activada: $uuid"
        fi
    done
}

# ------------------------------------------------------------------------------
# 8. AJUSTES ÓPTIMOS DE EXTENSIONES CLAVE (DASH TO DOCK & MULTIMONITOR)
# ------------------------------------------------------------------------------
configure_extensions() {
    log_info "[4/4] Aplicando configuración óptima para Dash to Dock y entorno de trabajo..."
    sync_user_schemas

    local DOCK_SCHEMA="org.gnome.shell.extensions.dash-to-dock"
    local schema_dir="$USER_HOME/.local/share/glib-2.0/schemas"

    if run_as_user gsettings list-schemas | grep -qx "$DOCK_SCHEMA" || [[ -f "$schema_dir/$DOCK_SCHEMA.gschema.xml" ]]; then
        local gset_prefix="run_as_user gsettings"
        if [[ -d "$schema_dir" && -f "$schema_dir/$DOCK_SCHEMA.gschema.xml" ]]; then
            gset_prefix="run_as_user gsettings --schemadir $schema_dir"
        fi

        $gset_prefix set "$DOCK_SCHEMA" dock-position 'BOTTOM' 2>/dev/null || true
        $gset_prefix set "$DOCK_SCHEMA" intellihide true 2>/dev/null || true
        $gset_prefix set "$DOCK_SCHEMA" intellihide-mode 'FOCUS_APPLICATION_WINDOWS' 2>/dev/null || true
        $gset_prefix set "$DOCK_SCHEMA" dash-max-icon-size 44 2>/dev/null || true
        $gset_prefix set "$DOCK_SCHEMA" show-trash true 2>/dev/null || true
        $gset_prefix set "$DOCK_SCHEMA" click-action 'minimize-or-previews' 2>/dev/null || true
        $gset_prefix set "$DOCK_SCHEMA" custom-theme-shrink true 2>/dev/null || true
        $gset_prefix set "$DOCK_SCHEMA" extend-height false 2>/dev/null || true
        $gset_prefix set "$DOCK_SCHEMA" multi-monitor true 2>/dev/null || true
        $gset_prefix set "$DOCK_SCHEMA" isolate-monitors false 2>/dev/null || true
        log_ok "Dash to Dock configurado (posición inferior, 44px, intellihide, multimonitor activo)."
    else
        log_warn "Esquema Dash to Dock aún no disponible para configuración directa."
    fi

    # Configuración de Caffeine si está presente
    local CAFFEINE_SCHEMA="org.gnome.shell.extensions.caffeine"
    if run_as_user gsettings list-schemas | grep -qx "$CAFFEINE_SCHEMA"; then
        run_as_user gsettings set "$CAFFEINE_SCHEMA" show-indicator 'always' 2>/dev/null || true
        run_as_user gsettings set "$CAFFEINE_SCHEMA" restore-state true 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# 9. DIAGNÓSTICO Y ESTADO (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}======================================================================${NC}"
    echo -e "  🧩 ${BOLD}ESTADO DE EXTENSIONES DE GNOME SHELL - FEDORA 45 WORKSTATION${NC}"
    echo -e "      ${CYAN}HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / 32 GB RAM)${NC}"
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

    local available_list
    available_list=$(run_as_user gnome-extensions list 2>/dev/null || true)

    for uuid in "${EXTENSION_UUIDS[@]}"; do
        local state="No instalada ❌"
        local origin=""

        if echo "$available_list" | grep -qx "$uuid"; then
            if [[ -d "/usr/share/gnome-shell/extensions/$uuid" ]]; then
                origin="(RPM / Sistema)"
            else
                origin="(EGO / Usuario)"
            fi

            local info
            info=$(run_as_user gnome-extensions info "$uuid" 2>/dev/null || echo "")
            if echo "$info" | grep -q "State: ENABLED"; then
                state="${GREEN}Habilitada ✅${NC}"
            else
                state="${YELLOW}Deshabilitada ⏸️${NC}"
            fi
        fi
        printf "  %-46s %-16s : %b\n" "$uuid" "$origin" "$state"
    done
    echo -e "${BOLD}======================================================================${NC}"
}

# ------------------------------------------------------------------------------
# 10. AYUDA CLI (--help)
# ------------------------------------------------------------------------------
show_help() {
    cat << EOF
${BOLD}🧩 Gestor de Extensiones de GNOME Shell - Fedora 45 Workstation (GNOME 51+ Wayland)${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 / Triple Pantalla)

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)    Instala paquetes oficiales vía DNF5, descarga desde EGO, activa y configura
  -s, --status        Muestra el diagnóstico detallado de cada extensión gestionada
  --enable-all        Activa todas las extensiones instaladas configuradas
  --disable-all       Desactiva globalmente las extensiones de usuario
  --config-dock       Aplica ajustes recomendados para Dash to Dock y multimonitor
  --no-install        Solo activa y configura sin descargar paquetes ni extensiones
  -h, --help          Muestra este mensaje de ayuda
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
    --config-dock)
        configure_extensions
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
        echo -e "  🚀 ${BOLD}CONFIGURADOR DE EXTENSIONES GNOME - FEDORA 45 WORKSTATION${NC}"
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
