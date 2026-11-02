#!/usr/bin/env bash
# ==============================================================================
# gnome-settings.sh - Configuración y Personalización Avanzada de GNOME Shell
# Debian Workstation (Debian 13 Trixie / GNOME Shell 48+ Wayland / Mutter)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)
# Topología: Triple pantalla 1080p (DP-3 principal, DP-4 lateral, eDP-1 portátil)
# ==============================================================================
# Filosofía:
#   - Personalizable y modular: Tú decides qué instalar desde repositorios y qué configurar.
#   - Modo sin paquetes (--no-install / --config-only): Aplica 100% ajustes GSettings y scripts
#     en espacio de usuario sin invocar APT ni requerir privilegios de superusuario (sudo).
#   - Modo interactivo (--interactive / -i): Asistente guiado paso a paso en terminal.
#   - Soporte multimarca de terminales: Elige tu terminal preferida (Kitty, Ptyxis o GNOME Terminal)
#     para el atajo global Ctrl+Alt+T y el menú contextual de Nautilus.
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y PAQUETES DEL SISTEMA
# ------------------------------------------------------------------------------
# Paquetes disponibles en repositorios oficiales de Debian 13 para soporte GNOME:
SUPPORT_PACKAGES=(
    "gnome-tweaks|Herramienta gráfica de Retoques de GNOME"
    "gnome-browser-connector|Integración con navegadores para extensiones GNOME"
    "gnome-shell-extension-gsconnect|GSConnect (KDE Connect nativo en GNOME Shell)"
    "gnome-shell-extensions|Extensiones base oficiales de GNOME"
    "gnome-themes-extra|Temas clásicos GTK (incluye Adwaita-dark para GTK3)"
    "dconf-cli|Herramienta de terminal para consultas y volcados dconf"
    "wl-clipboard|Utilidades nativas de portapapeles Wayland (wl-copy / wl-paste)"
)

TERMINAL_OPTIONS=("kitty" "ptyxis" "gnome-terminal")

# Colores ANSI
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# 2. DETECCIÓN DE USUARIO, ENTORNO Y PRIVILEGIOS SUDO
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

get_gnome_version() {
    local ver
    ver=$(gnome-shell --version 2>/dev/null | awk '{print $3}' || true)
    if [ -z "$ver" ]; then
        ver=$(run_as_user gnome-shell --version 2>/dev/null | awk '{print $3}' || true)
    fi
    echo "${ver:-48}"
}

get_os_description() {
    if [ -f /etc/os-release ]; then
        grep "^PRETTY_NAME=" /etc/os-release | cut -d= -f2 | tr -d '"'
    else
        echo "Debian GNU/Linux 13 (trixie)"
    fi
}

detect_preferred_terminal() {
    if command -v kitty &>/dev/null; then
        echo "kitty"
    elif command -v ptyxis &>/dev/null; then
        echo "ptyxis"
    elif command -v gnome-terminal &>/dev/null; then
        echo "gnome-terminal"
    else
        echo "kitty"
    fi
}

# ------------------------------------------------------------------------------
# 3. AYUDA Y DIAGNÓSTICO DEL SISTEMA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🎨 Personalizador de GNOME Shell - Debian 13 Workstation (Wayland)
Control modular y personal: Elige qué paquetes instalar y qué ajustes aplicar.

Uso:
  $0 [OPCIÓN] [PARÁMETROS]

Opciones de Ejecución:
  (sin argumentos)        Aplica la configuración recomendada completa (Modo oscuro, Mutter,
                          reloj, Nautilus y atajo de terminal detectada).
  -i, --interactive       Modo interactivo: Asistente en terminal para elegir paso a paso qué
                          instalar, qué terminal preferir y qué opciones activar.
  -s, --status            Muestra diagnóstico detallado de paquetes APT, configuraciones y atajos.
  --no-install, --config  Aplica únicamente configuraciones de usuario (GSettings/dconf/Nautilus)
                          SIN instalar paquetes APT ni requerir privilegios de superusuario (sudo).
  --packages, -p          Instala únicamente los paquetes de soporte del sistema desde repositorios APT.

Personalización Específica:
  --dark, -d              Aplica el modo oscuro completo (prefer-dark + Adwaita-dark).
  --light, -l             Aplica el modo claro estándar.
  --terminal <nombre>     Configura la terminal preferida para Ctrl+Alt+T y Nautilus.
                          Valores soportados: kitty | ptyxis | gnome-terminal (defecto: auto).
  --buttons <disposición> Configura los botones de ventana.
                          Valores: right (:minimize,maximize,close) | left (close,minimize,maximize:).
  --appearance, -a        Aplica fuentes, nitidez antialiasing (RGBA/slight) y modo oscuro.
  --windows, -w           Configura Mutter (centrado, tiling, multimonitor, experimental-features).
  --nautilus, -n          Configura Nautilus (vista en lista, enlaces) y scripts de clic derecho.
  --keybindings, -k       Configura únicamente el atajo global Ctrl+Alt+T.
  -h, --help              Muestra este mensaje de ayuda.

¿Qué se instala desde repositorios y qué NO?
  • DESDE REPOSITORIOS (APT):
      - gnome-tweaks, gnome-browser-connector, gnome-shell-extension-gsconnect,
        gnome-shell-extensions, gnome-themes-extra, dconf-cli, wl-clipboard.
      - Terminal opcional: kitty o ptyxis.
  • NO SE INSTALA DESDE REPOSITORIOS (Configuración pura en usuario / GSettings / dconf):
      - Temas de color (prefer-dark / Adwaita).
      - Botones de ventanas a la derecha y centrado de ventanas de Mutter.
      - Antialiasing RGBA y fuentes para monitores 1080p.
      - Reloj 24h con fecha y porcentaje de batería en barra superior.
      - Luz nocturna a 4000K con horario automático.
      - Atajo global Ctrl+Alt+T en org.gnome.settings-daemon.plugins.media-keys.
      - Scripts contextuales de clic derecho en ~/.local/share/nautilus/scripts/.
EOF
}

show_status() {
    local os_name gnome_ver
    os_name=$(get_os_description)
    gnome_ver=$(get_gnome_version)

    echo "================================================================="
    echo "🔍 ESTADO DE PERSONALIZACIÓN GNOME SHELL - DEBIAN WORKSTATION"
    echo "================================================================="
    echo "• Sistema Operativo:      $os_name (Kernel $(uname -r))"
    echo "• Entorno de Escritorio:  ${XDG_CURRENT_DESKTOP:-GNOME} $gnome_ver (${XDG_SESSION_TYPE:-wayland})"
    echo "• Compositor / Ventanas:  Mutter (Wayland nativo)"
    echo "• Hardware:               HP ProBook 455 G10 (AMD Ryzen 7 7730U / Vega 8)"
    echo "-----------------------------------------------------------------"
    echo "📦 PAQUETES APT EN EL SISTEMA (Repositorios oficiales Debian 13):"
    for item in "${SUPPORT_PACKAGES[@]}"; do
        IFS="|" read -r pkg desc <<< "$item"
        local status_icon="❌"
        local pkg_v="no instalado"
        if dpkg -s "$pkg" &>/dev/null; then
            status_icon="✅"
            pkg_v=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || echo "instalado")
        fi
        printf "  %-32s %s (v%s)\n" "$pkg:" "$status_icon" "$pkg_v"
    done
    echo "• Emuladores de Terminal disponibles:"
    echo "  - Kitty:                $(if command -v kitty &>/dev/null; then echo "✅ $(which kitty) (v$(kitty --version 2>/dev/null | awk '{print $2}'))"; else echo "❌ No instalado"; fi)"
    echo "  - Ptyxis:               $(if command -v ptyxis &>/dev/null; then echo "✅ $(which ptyxis) (v$(dpkg-query -W -f='${Version}' ptyxis 2>/dev/null || echo '48'))"; else echo "❌ No instalado"; fi)"
    echo "  - GNOME Terminal:       $(if command -v gnome-terminal &>/dev/null; then echo "✅ $(which gnome-terminal)"; else echo "❌ No instalado"; fi)"
    echo "-----------------------------------------------------------------"
    echo "⚙️ CONFIGURACIÓN DE USUARIO (GSettings / dconf / scripts - Sin APT):"
    echo "• Esquema de Color:       $(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo 'n/a')"
    echo "• Tema GTK:               $(run_as_user gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo 'n/a')"
    echo "• Tema de Iconos:         $(run_as_user gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo 'n/a')"
    echo "• Tipografía Monospace:   $(run_as_user gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null || echo 'n/a')"
    echo "• Tipografía UI:          $(run_as_user gsettings get org.gnome.desktop.interface font-name 2>/dev/null || echo 'n/a')"
    echo "• Suavizado de Fuentes:   Antialiasing: $(run_as_user gsettings get org.gnome.desktop.interface font-antialiasing 2>/dev/null || echo 'n/a') | Hinting: $(run_as_user gsettings get org.gnome.desktop.interface font-hinting 2>/dev/null || echo 'n/a')"
    echo "-----------------------------------------------------------------"
    echo "• Botones de Ventana:     $(run_as_user gsettings get org.gnome.desktop.wm.preferences button-layout 2>/dev/null || echo 'n/a')"
    echo "• Ventanas Centradas:     $(run_as_user gsettings get org.gnome.mutter center-new-windows 2>/dev/null || echo 'n/a')"
    echo "• Ajuste a Bordes (Tiling):$(run_as_user gsettings get org.gnome.mutter edge-tiling 2>/dev/null || echo 'n/a')"
    echo "• Workspaces Multimonitor:$(if [ "$(run_as_user gsettings get org.gnome.mutter workspaces-only-on-primary 2>/dev/null)" = "true" ]; then echo "✅ Persistentes en monitores secundarios"; else echo "Dinámicos en todas las pantallas"; fi)"
    echo "• Localizar Puntero (Ctrl):$(run_as_user gsettings get org.gnome.desktop.interface locate-pointer 2>/dev/null || echo 'false')"
    echo "-----------------------------------------------------------------"
    echo "• Barra Superior y Reloj:"
    echo "  - Formato de Reloj:     $(run_as_user gsettings get org.gnome.desktop.interface clock-format 2>/dev/null || echo 'n/a')"
    echo "  - Mostrar Fecha y Día:  $(run_as_user gsettings get org.gnome.desktop.interface clock-show-date 2>/dev/null || echo 'false') / $(run_as_user gsettings get org.gnome.desktop.interface clock-show-weekday 2>/dev/null || echo 'false')"
    echo "  - Porcentaje de Batería:$(run_as_user gsettings get org.gnome.desktop.interface show-battery-percentage 2>/dev/null || echo 'false')"
    echo "-----------------------------------------------------------------"
    local nl_enabled nl_temp nl_auto
    nl_enabled=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled 2>/dev/null || echo 'false')
    nl_temp=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.color night-light-temperature 2>/dev/null | awk '{print $NF}' || echo '4000')
    nl_auto=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.color night-light-schedule-automatic 2>/dev/null || echo 'false')
    echo "• Luz Nocturna (Salud Visual):"
    echo "  - Estado:               $(if [ "$nl_enabled" = "true" ]; then echo "✅ Activada (auto: $nl_auto)"; else echo "❌ Desactivada"; fi)"
    echo "  - Temperatura de Color: ${nl_temp} K"
    echo "-----------------------------------------------------------------"
    local kb_configured kb_cmd
    kb_configured=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo '[]')
    kb_cmd=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 2>/dev/null || echo '')
    echo "• Atajo Global de Terminal (Ctrl+Alt+T):"
    if echo "$kb_configured" | grep -qi "custom0" && [ -n "$kb_cmd" ]; then
        echo "  - Estado:               ✅ Configurado ($kb_cmd)"
    else
        echo "  - Estado:               ❌ No configurado (usando atajo predeterminado de GNOME)"
    fi
    echo "-----------------------------------------------------------------"
    echo "• Nautilus (Gestor de Archivos):"
    echo "  - Vista Predeterminada: $(run_as_user gsettings get org.gnome.nautilus.preferences default-folder-viewer 2>/dev/null || echo 'n/a')"
    echo "  - Borrado Permanente:   $(run_as_user gsettings get org.gnome.nautilus.preferences show-delete-permanently 2>/dev/null || echo 'n/a')"
    echo "  - Crear Enlace:         $(run_as_user gsettings get org.gnome.nautilus.preferences show-create-link 2>/dev/null || echo 'n/a')"
    local scripts_dir="$USER_HOME/.local/share/nautilus/scripts"
    local s_term s_ag s_code
    s_term=$(if [ -f "$scripts_dir/Abrir en Terminal" ] || [ -f "$scripts_dir/Abrir en Kitty" ] || [ -f "$scripts_dir/Abrir en Ptyxis" ]; then echo "✅"; else echo "❌"; fi)
    s_ag=$(if [ -f "$scripts_dir/Abrir en Antigravity IDE" ]; then echo "✅"; else echo "❌"; fi)
    s_code=$(if [ -f "$scripts_dir/Abrir en VS Code" ]; then echo "✅"; else echo "❌"; fi)
    echo "  - Scripts Contextuales: Terminal: $s_term | Antigravity: $s_ag | VS Code: $s_code"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN DE PAQUETES BASE DESDE APT (OPCIONAL Y MODULAR)
# ------------------------------------------------------------------------------
apply_packages() {
    local install_kitty="${1:-false}"
    local install_ptyxis="${2:-false}"

    echo "📦 [1/6] Verificando e instalando utilidades de soporte desde repositorios APT..."
    if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
        echo "⚠️ 'sudo' no está disponible. Omitiendo instalación de paquetes APT."
        return 0
    fi

    local pkgs_to_install=()
    for item in "${SUPPORT_PACKAGES[@]}"; do
        IFS="|" read -r pkg desc <<< "$item"
        if ! dpkg -s "$pkg" &>/dev/null; then
            pkgs_to_install+=("$pkg")
        fi
    done

    if [ "$install_kitty" = "true" ] && ! command -v kitty &>/dev/null; then
        pkgs_to_install+=("kitty")
    fi

    if [ "$install_ptyxis" = "true" ] && ! command -v ptyxis &>/dev/null; then
        pkgs_to_install+=("ptyxis")
    fi

    if [ ${#pkgs_to_install[@]} -gt 0 ]; then
        echo "  - Instalando paquetes seleccionados: ${pkgs_to_install[*]}..."
        $SUDO apt-get update -qq
        $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs_to_install[@]}" 2>/dev/null || true
        echo "  ✅ Paquetes instalados con éxito."
    else
        echo "  ✅ Todos los paquetes seleccionados ya están instalados en el sistema."
    fi
}

# ------------------------------------------------------------------------------
# 5. MODO OSCURO / MODO CLARO (GSettings puro)
# ------------------------------------------------------------------------------
apply_dark() {
    echo "🌙 Aplicando tema oscuro persistente y armónico..."
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

    local target_theme="Adwaita-dark"
    if [ -d "/usr/share/themes/adw-gtk3-dark" ] || [ -d "$USER_HOME/.local/share/themes/adw-gtk3-dark" ]; then
        target_theme="adw-gtk3-dark"
    elif [ -d "/usr/share/themes/Adwaita-dark" ]; then
        target_theme="Adwaita-dark"
    fi
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$target_theme" 2>/dev/null || true

    if [ -d "/usr/share/icons/Adwaita-dark" ]; then
        run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Adwaita-dark' 2>/dev/null || true
    fi

    echo "  ✅ Modo oscuro activado (prefer-dark + tema '$target_theme')."
}

apply_light() {
    echo "☀️ Aplicando modo claro estándar..."
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'default' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null || true
    echo "  ✅ Modo claro activado."
}

# ------------------------------------------------------------------------------
# 6. APARIENCIA, TIPOGRAFÍA Y ACCESIBILIDAD MULTIMONITOR (GSettings puro)
# ------------------------------------------------------------------------------
apply_appearance() {
    echo "🎨 [2/6] Configurando apariencia, nitidez tipográfica y accesibilidad..."
    apply_dark

    # Optimización de renderizado de fuentes para pantallas LCD 1080p (subpixel RGBA)
    run_as_user gsettings set org.gnome.desktop.interface font-antialiasing 'rgba' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface font-hinting 'slight' 2>/dev/null || true

    # Detección precisa de tipografía monospace instalada en el sistema
    if [ -n "$(fc-list : family | grep -i "^JetBrainsMono Nerd Font" 2>/dev/null || true)" ]; then
        run_as_user gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 10' 2>/dev/null || true
        echo "  - Fuente Monospace: JetBrainsMono Nerd Font 10"
    elif [ -n "$(fc-list : family | grep -i "^JetBrains Mono" 2>/dev/null || true)" ]; then
        run_as_user gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10' 2>/dev/null || true
        echo "  - Fuente Monospace: JetBrains Mono 10"
    elif [ -n "$(fc-list : family | grep -i "^FiraCode Nerd Font" 2>/dev/null || true)" ]; then
        run_as_user gsettings set org.gnome.desktop.interface monospace-font-name 'FiraCode Nerd Font 10' 2>/dev/null || true
        echo "  - Fuente Monospace: FiraCode Nerd Font 10"
    fi

    # Accesibilidad multimonitor: localizar puntero pulsando la tecla Ctrl
    run_as_user gsettings set org.gnome.desktop.interface locate-pointer true 2>/dev/null || true

    echo "  ✅ Apariencia, tipografía y accesibilidad multimonitor configuradas."
}

# ------------------------------------------------------------------------------
# 7. GESTIÓN DE VENTANAS Y MUTTER WAYLAND (GSettings puro)
# ------------------------------------------------------------------------------
apply_windows() {
    local button_pos="${1:-right}"
    echo "🖼️ [3/6] Optimizando compositor Mutter y ventanas para multimonitor..."

    if [ "$button_pos" = "left" ]; then
        run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:' 2>/dev/null || true
    else
        run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' 2>/dev/null || true
    fi

    # Acciones de la barra de título
    run_as_user gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar 'toggle-maximize' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.wm.preferences action-middle-click-titlebar 'lower' 2>/dev/null || true

    # Centrado automático de nuevas ventanas y cuadros de diálogo anclados a la ventana padre
    run_as_user gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter attach-modal-dialogs true 2>/dev/null || true

    # Edge tiling nativo para dividir ventanas al arrastrar a los bordes
    run_as_user gsettings set org.gnome.mutter edge-tiling true 2>/dev/null || true

    # En estaciones multimonitor, mantener workspaces persistentes en pantallas laterales
    run_as_user gsettings set org.gnome.mutter workspaces-only-on-primary true 2>/dev/null || true

    # Aplicar experimental-features soportadas en la versión activa de Mutter
    if run_as_user gsettings list-keys org.gnome.mutter 2>/dev/null | grep -q "^experimental-features$"; then
        local range features=()
        range=$(run_as_user gsettings range org.gnome.mutter experimental-features 2>/dev/null || true)

        if echo "$range" | grep -q "scale-monitor-framebuffer"; then
            features+=("'scale-monitor-framebuffer'")
        fi
        if echo "$range" | grep -q "variable-refresh-rate"; then
            features+=("'variable-refresh-rate'")
        fi
        if echo "$range" | grep -q "xwayland-native-scaling"; then
            features+=("'xwayland-native-scaling'")
        fi

        if [ ${#features[@]} -gt 0 ]; then
            local features_str
            features_str="[$(printf "%s, " "${features[@]}" | sed 's/, $//')]"
            run_as_user gsettings set org.gnome.mutter experimental-features "$features_str" 2>/dev/null || true
            echo "  - Mutter experimental-features: $features_str"
        fi
    fi

    echo "  ✅ Mutter optimizado para ventanas fluidas y snapping multimonitor."
}

# ------------------------------------------------------------------------------
# 8. BARRA SUPERIOR, RELOJ Y SALUD VISUAL (GSettings puro)
# ------------------------------------------------------------------------------
apply_topbar_power() {
    local enable_night_light="${1:-true}"
    echo "🕒 [4/6] Configurando barra superior, reloj 24h y confort visual..."
    run_as_user gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface clock-show-weekday true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface clock-show-date true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true

    if [ "$enable_night_light" = "true" ]; then
        run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
        run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000 2>/dev/null || true
        run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic true 2>/dev/null || true
        echo "  - Luz nocturna activada a 4000K con horario automático."
    else
        run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false 2>/dev/null || true
    fi

    # Evitar suspensión por inactividad al estar conectado a corriente alterna
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true

    echo "  ✅ Barra superior, reloj y políticas de pantalla configuradas."
}

# ------------------------------------------------------------------------------
# 9. GESTOR DE ARCHIVOS NAUTILUS Y SCRIPTS CONTEXTUALES (GSettings y Scripts de Usuario)
# ------------------------------------------------------------------------------
apply_nautilus() {
    local pref_term="${1:-auto}"
    if [ "$pref_term" = "auto" ]; then
        pref_term=$(detect_preferred_terminal)
    fi

    echo "📁 [5/6] Optimizando gestor de archivos Nautilus (Terminal: $pref_term)..."
    run_as_user gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences show-delete-permanently true 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences show-create-link true 2>/dev/null || true

    local nautilus_scripts_dir="$USER_HOME/.local/share/nautilus/scripts"
    run_as_user mkdir -p "$nautilus_scripts_dir"

    # Script 1: Abrir en Terminal Preferida
    cat << EOF | run_as_user tee "$nautilus_scripts_dir/Abrir en Terminal" > /dev/null
#!/usr/bin/env bash
target=""
if [ -n "\${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}" ]; then
    first=\$(echo "\$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" | head -n1)
    if [ -d "\$first" ]; then
        target="\$first"
    elif [ -f "\$first" ]; then
        target="\$(dirname "\$first")"
    fi
fi
if [ -z "\$target" ] && [ -n "\${NAUTILUS_SCRIPT_CURRENT_URI:-}" ]; then
    target=\$(echo "\$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || true)
fi
dir_to_open="\${target:-.}"

if [ "$pref_term" = "kitty" ] && command -v kitty &>/dev/null; then
    exec kitty --directory "\$dir_to_open" &
elif [ "$pref_term" = "ptyxis" ] && command -v ptyxis &>/dev/null; then
    exec ptyxis --working-directory="\$dir_to_open" &
elif command -v gnome-terminal &>/dev/null; then
    exec gnome-terminal --working-directory="\$dir_to_open" &
elif command -v kitty &>/dev/null; then
    exec kitty --directory "\$dir_to_open" &
fi
EOF
    run_as_user chmod +x "$nautilus_scripts_dir/Abrir en Terminal"

    # Script de compatibilidad directa si kitty está presente
    if command -v kitty &>/dev/null || [ "$pref_term" = "kitty" ]; then
        cat << 'EOF' | run_as_user tee "$nautilus_scripts_dir/Abrir en Kitty" > /dev/null
#!/usr/bin/env bash
target=""
if [ -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}" ]; then
    first=$(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" | head -n1)
    if [ -d "$first" ]; then target="$first"; elif [ -f "$first" ]; then target="$(dirname "$first")"; fi
fi
if [ -z "$target" ] && [ -n "${NAUTILUS_SCRIPT_CURRENT_URI:-}" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || true)
fi
exec kitty --directory "${target:-.}" &
EOF
        run_as_user chmod +x "$nautilus_scripts_dir/Abrir en Kitty"
    fi

    # Script 2: Abrir en Antigravity IDE
    cat << 'EOF' | run_as_user tee "$nautilus_scripts_dir/Abrir en Antigravity IDE" > /dev/null
#!/usr/bin/env bash
target=""
if [ -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" | head -n1)
fi
if [ -z "$target" ] && [ -n "${NAUTILUS_SCRIPT_CURRENT_URI:-}" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || true)
fi
if command -v antigravity-ide &>/dev/null; then
    exec antigravity-ide "${target:-.}" &
elif command -v antigravity &>/dev/null; then
    exec antigravity "${target:-.}" &
fi
EOF
    run_as_user chmod +x "$nautilus_scripts_dir/Abrir en Antigravity IDE"

    # Script 3: Abrir en VS Code
    cat << 'EOF' | run_as_user tee "$nautilus_scripts_dir/Abrir en VS Code" > /dev/null
#!/usr/bin/env bash
target=""
if [ -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" | head -n1)
fi
if [ -z "$target" ] && [ -n "${NAUTILUS_SCRIPT_CURRENT_URI:-}" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || true)
fi
exec code "${target:-.}" &
EOF
    run_as_user chmod +x "$nautilus_scripts_dir/Abrir en VS Code"

    echo "  ✅ Nautilus configurado con scripts de clic derecho."
}

# ------------------------------------------------------------------------------
# 10. ATAJO GLOBAL CTRL+ALT+T PARA LA TERMINAL PREFERIDA (GSettings puro)
# ------------------------------------------------------------------------------
apply_keybindings() {
    local target_term="${1:-auto}"
    if [ "$target_term" = "auto" ]; then
        target_term=$(detect_preferred_terminal)
    fi

    echo "⌨️ [6/6] Configurando atajo global Ctrl+Alt+T para terminal ($target_term)..."
    local kb_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"

    local term_cmd="kitty"
    local term_name="Kitty Terminal"
    case "$target_term" in
        ptyxis)
            term_cmd="ptyxis"
            term_name="Ptyxis Terminal"
            ;;
        gnome-terminal)
            term_cmd="gnome-terminal"
            term_name="GNOME Terminal"
            ;;
        *)
            term_cmd="kitty"
            term_name="Kitty Terminal"
            ;;
    esac

    # 1. Desvincular el atajo predeterminado de terminal para evitar conflicto en GNOME
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "[]" 2>/dev/null || true

    # 2. Registrar custom0 de forma idempotente preservando otros atajos
    local current_kb
    current_kb=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "[]")
    if [[ "$current_kb" == "@as []" || "$current_kb" == "[]" ]]; then
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$kb_path']" 2>/dev/null || true
    elif ! echo "$current_kb" | grep -q "$kb_path"; then
        local new_kb
        new_kb=$(echo "$current_kb" | sed "s/]/, '$kb_path']/")
        run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_kb" 2>/dev/null || true
    fi

    # 3. Definir nombre, comando y combinación de teclas
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path name "$term_name" 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path command "$term_cmd" 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path binding '<Primary><Alt>t' 2>/dev/null || true

    echo "  ✅ Atajo global Ctrl+Alt+T asignado a '$term_cmd' sin colisiones."
}

# ------------------------------------------------------------------------------
# 11. MODO INTERACTIVO PERSONALIZADO
# ------------------------------------------------------------------------------
run_interactive() {
    clear
    echo -e "${CYAN}${BOLD}=================================================================${NC}"
    echo -e "${BOLD}🎨 ASISTENTE INTERACTIVO DE PERSONALIZACIÓN DE GNOME SHELL${NC}"
    echo -e "${CYAN}${BOLD}=================================================================${NC}"
    echo "Personaliza exactamente lo que quieres instalar y configurar en Debian 13."
    echo ""

    # 1. Instalación de paquetes APT
    local do_apt="n"
    read -rp "¿Deseas instalar/actualizar paquetes de soporte vía APT (Tweaks, GSConnect, wl-clipboard)? [s/N]: " do_apt
    local install_kitty_pkg="false"
    local install_ptyxis_pkg="false"
    if [[ "$do_apt" =~ ^[sSyY]$ ]]; then
        echo ""
        read -rp "  ¿Instalar emulador de terminal Kitty vía APT? [S/n]: " ans_k
        if [[ ! "$ans_k" =~ ^[nN]$ ]]; then install_kitty_pkg="true"; fi

        read -rp "  ¿Instalar emulador de terminal Ptyxis vía APT? [s/N]: " ans_p
        if [[ "$ans_p" =~ ^[sSyY]$ ]]; then install_ptyxis_pkg="true"; fi

        apply_packages "$install_kitty_pkg" "$install_ptyxis_pkg"
    else
        echo "  ℹ️ Omitiendo instalación de paquetes APT (modo configuración de usuario)."
    fi

    # 2. Esquema de Color
    echo ""
    echo "Selecciona el esquema de color:"
    echo "  1) Oscuro (prefer-dark + Adwaita-dark) [Recomendado]"
    echo "  2) Claro (default + Adwaita)"
    read -rp "Opción [1]: " ans_color
    if [ "${ans_color:-1}" = "2" ]; then
        apply_light
    else
        apply_dark
    fi

    # 3. Disposición de Botones de Ventana
    echo ""
    echo "Selecciona la posición de botones de ventana (minimizar, maximizar, cerrar):"
    echo "  1) Derecha (:minimize,maximize,close) [Estándar]"
    echo "  2) Izquierda (close,minimize,maximize:)"
    read -rp "Opción [1]: " ans_btn
    local btn_choice="right"
    if [ "${ans_btn:-1}" = "2" ]; then btn_choice="left"; fi
    apply_windows "$btn_choice"

    # 4. Terminal preferida para Atajo Ctrl+Alt+T y Nautilus
    echo ""
    echo "Selecciona tu terminal preferida para atajos y menú de Nautilus:"
    echo "  1) Kitty (acelerada por GPU, Catppuccin)"
    echo "  2) Ptyxis (moderna nativa GNOME 48)"
    echo "  3) GNOME Terminal"
    read -rp "Opción [1]: " ans_term
    local selected_term="kitty"
    case "${ans_term:-1}" in
        2) selected_term="ptyxis" ;;
        3) selected_term="gnome-terminal" ;;
        *) selected_term="kitty" ;;
    esac

    # 5. Confort Visual (Luz Nocturna)
    echo ""
    read -rp "¿Activar Luz Nocturna automática (4000K al anochecer para descanso visual)? [S/n]: " ans_nl
    local nl_bool="true"
    if [[ "$ans_nl" =~ ^[nN]$ ]]; then nl_bool="false"; fi
    apply_topbar_power "$nl_bool"

    # 6. Apariencia tipográfica, Nautilus y Atajos
    apply_appearance
    apply_nautilus "$selected_term"
    apply_keybindings "$selected_term"

    echo ""
    echo -e "${GREEN}${BOLD}✅ ¡Personalización de GNOME Shell finalizada a tu gusto!${NC}"
    echo ""
    show_status
}

# ------------------------------------------------------------------------------
# 12. ENTRADA PRINCIPAL Y PARSEO DE ARGUMENTOS
# ------------------------------------------------------------------------------
TARGET_TERMINAL="auto"
TARGET_BUTTONS="right"
ENABLE_PACKAGES="true"
ENABLE_NIGHTLIGHT="true"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --status|-s|status)
            show_status
            exit 0
            ;;
        --help|-h|help)
            show_help
            exit 0
            ;;
        --interactive|-i)
            run_interactive
            exit 0
            ;;
        --no-install|--config|--config-only)
            ENABLE_PACKAGES="false"
            shift
            ;;
        --packages|-p)
            apply_packages "true" "false"
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
        --terminal)
            if [ -n "${2:-}" ]; then
                TARGET_TERMINAL="$2"
                shift 2
            else
                echo -e "${RED}❌ Error: Debes especificar una terminal (kitty|ptyxis|gnome-terminal).${NC}"
                exit 1
            fi
            ;;
        --buttons)
            if [ -n "${2:-}" ]; then
                TARGET_BUTTONS="$2"
                shift 2
            else
                TARGET_BUTTONS="right"
                shift
            fi
            ;;
        --appearance|-a)
            apply_appearance
            exit 0
            ;;
        --windows|-w)
            apply_windows "$TARGET_BUTTONS"
            exit 0
            ;;
        --nautilus|-n)
            apply_nautilus "$TARGET_TERMINAL"
            exit 0
            ;;
        --keybindings|-k)
            apply_keybindings "$TARGET_TERMINAL"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opción no reconocida: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Flujo predeterminado (sin argumentos o con modificadores combinados)
echo "================================================================="
echo "🎨 CONFIGURANDO PERSONALIZACIÓN DE GNOME SHELL (DEBIAN 13)"
echo "================================================================="
if [ "$ENABLE_PACKAGES" = "true" ]; then
    apply_packages "true" "false"
else
    echo "ℹ️ Modo sin instalación APT activado (--no-install). Aplicando ajustes de usuario."
fi

apply_appearance
apply_windows "$TARGET_BUTTONS"
apply_topbar_power "$ENABLE_NIGHTLIGHT"
apply_nautilus "$TARGET_TERMINAL"
apply_keybindings "$TARGET_TERMINAL"

echo ""
show_status
echo "================================================================="
echo "✅ Configuración de GNOME Shell completada con éxito."
echo "================================================================="
