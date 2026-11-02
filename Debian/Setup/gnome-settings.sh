#!/usr/bin/env bash
# ==============================================================================
# gnome-settings.sh - Configuración y Personalización Avanzada de GNOME Shell
# Debian Workstation (Debian 13 Trixie / GNOME Shell 48+ Wayland / Mutter)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)
# Topología: Triple pantalla 1080p (DP-3 principal, DP-4 lateral, eDP-1 portátil)
# ==============================================================================
# Características y Optimizaciones:
#  - Modo oscuro persistente y armónico (prefer-dark + Adwaita-dark para GTK3/4 y libadwaita).
#  - Renderizado tipográfico nítido en triple monitor 1080p (subpixel antialiasing RGBA + slight hinting).
#  - Detección precisa de fuentes Nerd Fonts (JetBrainsMono Nerd Font) con fallbacks elegantes.
#  - Disposición limpia de botones de ventana (:minimize,maximize,close) a la derecha.
#  - Mutter Wayland: centrado de ventanas, diálogo modal anclado, edge-tiling y workspaces persistentes.
#  - Mutter adaptativo: escalado fraccional, variable-refresh-rate (VRR) y xwayland-native-scaling.
#  - Barra superior y reloj: formato 24h, día de la semana, fecha completa y porcentaje de batería.
#  - Salud visual: Luz nocturna con programación automática y temperatura cálida de 4000K.
#  - Accesibilidad multimonitor: Localización de cursor rápida con tecla Ctrl (locate-pointer).
#  - Nautilus optimizado: vista en lista, creación de enlaces simbólicos y borrado permanente habilitado.
#  - Menús contextuales nativos en Nautilus (clic derecho) para Kitty, Antigravity IDE y VS Code.
#  - Terminal Kitty acelerada por GPU vinculada a atajo global Ctrl+Alt+T sin colisiones.
#  - Opciones CLI: --status / -s, --dark / -d, --light / -l, --appearance / -a,
#                  --windows / -w, --keybindings / -k, --nautilus / -n, --help / -h.
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO, ENTORNO Y PRIVILEGIOS SUDO
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

# ------------------------------------------------------------------------------
# 2. AYUDA Y DIAGNÓSTICO DEL SISTEMA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🎨 Personalización de GNOME Shell - Debian Workstation (Wayland)
Optimizado para HP ProBook 455 G10 (AMD Ryzen 7 7730U / Vega 8 / Triple Monitor)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica toda la configuración (apariencia, ventanas, reloj,
                      Nautilus, luz nocturna y atajo global de Kitty).
  --status, -s        Muestra diagnóstico detallado de temas, fuentes, ventanas y atajos.
  --dark, -d          Aplica el modo oscuro completo (prefer-dark + Adwaita-dark).
  --light, -l         Aplica el modo claro estándar.
  --appearance, -a    Configura temas, nitidez de fuentes (RGBA/slight) y salud visual.
  --windows, -w       Configura Mutter (botones, centrado, tiling y workspaces multimonitor).
  --nautilus, -n      Configura preferencias y genera scripts de clic derecho en Nautilus.
  --keybindings, -k   Configura el atajo global Ctrl+Alt+T para terminal Kitty.
  --help, -h          Muestra este mensaje de ayuda.

Ajustes incluidos en Debian 13 (GNOME 48+ Wayland):
  • Apariencia:       Modo oscuro prefer-dark + Adwaita-dark, tipografía Nerd Font.
  • Nitidez Textos:   Subpixel RGB antialiasing (rgba) + slight hinting para paneles 1080p.
  • Ventanas Mutter:  Minimizar/Maximizar/Cerrar a la derecha, centrado y edge-tiling.
  • Multimonitor:     Workspaces persistentes en pantallas laterales (DP-4/eDP-1).
  • Barra Superior:   Reloj 24h con fecha, día de la semana y porcentaje de batería.
  • Confort Visual:   Luz nocturna automática a 4000K y resalte de cursor con tecla Ctrl.
  • Nautilus:         Vista en lista, creación de enlaces, borrado directo y scripts contextuales.
  • Terminal:         Atajo Ctrl+Alt+T para Kitty (sin colisión con terminal por defecto).
EOF
}

show_status() {
    local os_name gnome_ver
    os_name=$(get_os_description)
    gnome_ver=$(get_gnome_version)

    echo "================================================================="
    echo "🔍 ESTADO DE GNOME SHELL - DEBIAN WORKSTATION"
    echo "================================================================="
    echo "• Sistema Operativo:      $os_name (Kernel $(uname -r))"
    echo "• Entorno de Escritorio:  ${XDG_CURRENT_DESKTOP:-GNOME} $gnome_ver (${XDG_SESSION_TYPE:-wayland})"
    echo "• Compositor / Window Mgr:Mutter (Wayland nativo)"
    echo "• Hardware:               HP ProBook 455 G10 (AMD Ryzen 7 7730U / Vega 8)"
    echo "-----------------------------------------------------------------"
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
    local kb_configured
    kb_configured=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo '[]')
    echo "• Atajos de Terminal:"
    if echo "$kb_configured" | grep -qi "custom0"; then
        echo "  - Atajo Kitty (Ctrl+Alt+T): ✅ Configurado (custom0 -> kitty)"
    else
        echo "  - Atajo Kitty (Ctrl+Alt+T): ❌ No configurado"
    fi
    echo "-----------------------------------------------------------------"
    echo "• Nautilus (Archivos):"
    echo "  - Vista Predeterminada: $(run_as_user gsettings get org.gnome.nautilus.preferences default-folder-viewer 2>/dev/null || echo 'n/a')"
    echo "  - Borrado Permanente:   $(run_as_user gsettings get org.gnome.nautilus.preferences show-delete-permanently 2>/dev/null || echo 'n/a')"
    echo "  - Crear Enlace Simbólico:$(run_as_user gsettings get org.gnome.nautilus.preferences show-create-link 2>/dev/null || echo 'n/a')"
    local scripts_dir="$USER_HOME/.local/share/nautilus/scripts"
    local s_kitty s_ag s_code
    s_kitty=$(if [ -f "$scripts_dir/Abrir en Kitty" ]; then echo "✅"; else echo "❌"; fi)
    s_ag=$(if [ -f "$scripts_dir/Abrir en Antigravity IDE" ]; then echo "✅"; else echo "❌"; fi)
    s_code=$(if [ -f "$scripts_dir/Abrir en VS Code" ]; then echo "✅"; else echo "❌"; fi)
    echo "  - Scripts Contextuales: Kitty: $s_kitty | Antigravity: $s_ag | VS Code: $s_code"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. MODO OSCURO / MODO CLARO
# ------------------------------------------------------------------------------
apply_dark() {
    echo "🌙 Aplicando tema oscuro persistente y armónico..."
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

    # Seleccionar tema GTK instalado real para retrocompatibilidad GTK3/4
    local target_theme="Adwaita-dark"
    if [ -d "/usr/share/themes/adw-gtk3-dark" ] || [ -d "$USER_HOME/.local/share/themes/adw-gtk3-dark" ]; then
        target_theme="adw-gtk3-dark"
    elif [ -d "/usr/share/themes/Adwaita-dark" ]; then
        target_theme="Adwaita-dark"
    fi
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$target_theme" 2>/dev/null || true

    # Tema de iconos acorde
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
# 4. INSTALACIÓN DE PAQUETES BASE DE SOPORTE
# ------------------------------------------------------------------------------
apply_packages() {
    echo "ℹ️ [1/6] Verificando utilidades de soporte y terminal Kitty en GNOME..."
    $SUDO apt-get update -qq
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        kitty \
        gnome-tweaks \
        gnome-browser-connector \
        gnome-shell-extension-gsconnect \
        gnome-shell-extensions \
        gnome-themes-extra \
        dconf-cli \
        wl-clipboard 2>/dev/null || true
    echo "  ✅ Utilidades base aseguradas."
}

# ------------------------------------------------------------------------------
# 5. APARIENCIA, TIPOGRAFÍA Y ACCESIBILIDAD MULTIMONITOR
# ------------------------------------------------------------------------------
apply_appearance() {
    echo "ℹ️ [2/6] Configurando apariencia, nitidez tipográfica y accesibilidad..."
    apply_dark

    # Optimización de renderizado de fuentes para monitores LCD 1080p (subpixel RGBA)
    run_as_user gsettings set org.gnome.desktop.interface font-antialiasing 'rgba' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface font-hinting 'slight' 2>/dev/null || true

    # Detección precisa de tipografía monospace (Nerd Fonts o mono del sistema)
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
# 6. GESTIÓN DE VENTANAS Y COMPOSITOR MUTTER WAYLAND
# ------------------------------------------------------------------------------
apply_windows() {
    echo "ℹ️ [3/6] Optimizando compositor Mutter y ventanas para multimonitor..."
    # Disposición estándar moderna de botones a la derecha: minimizar, maximizar, cerrar
    run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' 2>/dev/null || true

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
# 7. BARRA SUPERIOR, RELOJ Y SALUD VISUAL
# ------------------------------------------------------------------------------
apply_topbar_power() {
    echo "ℹ️ [4/6] Configurando barra superior, reloj 24h y salud visual..."
    run_as_user gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface clock-show-weekday true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface clock-show-date true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true

    # Luz nocturna para reducción de fatiga visual en sesiones de desarrollo prolongadas
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic true 2>/dev/null || true

    # Evitar suspensión por inactividad al estar conectado a corriente alterna
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true

    echo "  ✅ Barra superior, reloj y luz nocturna configurados."
}

# ------------------------------------------------------------------------------
# 8. GESTOR DE ARCHIVOS NAUTILUS (ARCHIVOS)
# ------------------------------------------------------------------------------
apply_nautilus() {
    echo "ℹ️ [5/6] Optimizando gestor de archivos Nautilus..."
    run_as_user gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' 2>/dev/null || true
    # Habilitar opción directa de borrado permanente (Shift+Supr y menú contextual)
    run_as_user gsettings set org.gnome.nautilus.preferences show-delete-permanently true 2>/dev/null || true
    # Habilitar "Crear enlace simbólico" en el menú contextual
    run_as_user gsettings set org.gnome.nautilus.preferences show-create-link true 2>/dev/null || true

    # Creación de scripts contextuales de clic derecho en Nautilus
    local nautilus_scripts_dir="$USER_HOME/.local/share/nautilus/scripts"
    run_as_user mkdir -p "$nautilus_scripts_dir"

    # Script 1: Abrir en Kitty
    cat << 'EOF' | run_as_user tee "$nautilus_scripts_dir/Abrir en Kitty" > /dev/null
#!/usr/bin/env bash
target=""
if [ -n "${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}" ]; then
    first=$(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" | head -n1)
    if [ -d "$first" ]; then
        target="$first"
    elif [ -f "$first" ]; then
        target="$(dirname "$first")"
    fi
fi
if [ -z "$target" ] && [ -n "${NAUTILUS_SCRIPT_CURRENT_URI:-}" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || true)
fi
exec kitty --directory "${target:-.}" &
EOF
    run_as_user chmod +x "$nautilus_scripts_dir/Abrir en Kitty"

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

    echo "  ✅ Nautilus configurado con vista en lista, creación de enlaces y scripts de clic derecho."
}

# ------------------------------------------------------------------------------
# 9. ATAJO GLOBAL CTRL+ALT+T PARA TERMINAL KITTY
# ------------------------------------------------------------------------------
apply_keybindings() {
    echo "ℹ️ [6/6] Configurando atajo global Ctrl+Alt+T para terminal Kitty..."
    local kb_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"

    # 1. Desvincular el atajo predeterminado de terminal para evitar conflicto de atajos en GNOME
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "[]" 2>/dev/null || true

    # 2. Registrar custom0 de forma no destructiva preservando atajos previos
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
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path name 'Kitty Terminal' 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path command 'kitty' 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path binding '<Primary><Alt>t' 2>/dev/null || true

    echo "  ✅ Atajo global Ctrl+Alt+T asignado a Kitty sin colisiones."
}

# ------------------------------------------------------------------------------
# 10. ENTRADA PRINCIPAL
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
    --appearance|-a)
        apply_appearance
        exit 0
        ;;
    --windows|-w)
        apply_windows
        exit 0
        ;;
    --nautilus|-n)
        apply_nautilus
        exit 0
        ;;
    --keybindings|-k)
        apply_keybindings
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🎨 CONFIGURANDO PERSONALIZACIÓN DE GNOME SHELL (DEBIAN WORKSTATION)"
        echo "================================================================="
        apply_packages
        apply_appearance
        apply_windows
        apply_topbar_power
        apply_nautilus
        apply_keybindings
        echo ""
        show_status
        echo "================================================================="
        echo "✅ Configuración de GNOME Shell completada con éxito."
        echo "================================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
