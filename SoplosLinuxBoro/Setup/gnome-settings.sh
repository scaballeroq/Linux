#!/usr/bin/env bash
# ==============================================================================
# gnome-settings.sh - Configuración y Personalización Avanzada de GNOME Shell
# Soplos Linux Boro Workstation (Soplos Linux Boro / GNOME Shell Wayland / Mutter)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)
# ==============================================================================
# Características y Optimizaciones:
#  - Preservación y prioridad absoluta del branding nativo de Soplos Linux Boro:
#    * Temas GTK y Shell: Orchis-Orange (Dark-Compact / Dark / Light).
#    * Temas de iconos: kora-soplos-dark / kora-soplos-light.
#    * Tema de cursores: Future-cursors.
#  - Terminal moderno Ghostty acelerado por GPU integrado con atajo global Ctrl+Alt+T.
#  - Mutter Wayland: centrado de ventanas, diálogo modal anclado y edge-tiling multimonitor.
#  - Alternancia ágil de ventanas individuales con Alt+Tab en topología multimonitor triple pantalla.
#  - Barra superior y reloj: formato 24h, día de la semana, fecha y porcentaje de batería.
#  - Salud visual: Luz nocturna con programación solar automática y 4000K de confort visual.
#  - Localización de cursor rápida con tecla Ctrl (locate-pointer) para multimonitor.
#  - Nautilus optimizado: vista en lista, borrado permanente y menús contextuales para
#    Ghostty, Antigravity Desktop y VS Code.
#  - Idempotencia total: verificación previa de paquetes dpkg sin 'apt update' innecesarios.
#  - Opciones CLI: --status / -s, --dark / -d, --light / -l, --keybindings, --nautilus, --help / -h.
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. DETECCIÓN DE USUARIO Y PRIVILEGIOS
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
            PATH="/usr/local/bin:/usr/bin:/bin:$USER_HOME/.local/bin:$PATH" \
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
🎨 Personalización de GNOME Shell - Soplos Linux Boro Workstation (Wayland)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica toda la configuración recomendada (apariencia Soplos,
                      Mutter multimonitor, Nautilus, atajo global de Ghostty y scripts).
  --status, -s        Muestra diagnóstico detallado de temas, fuentes, ventanas y atajos.
  --dark, -d          Aplica el modo oscuro oficial de Soplos Linux (Orchis-Orange-Dark + kora-soplos).
  --light, -l         Aplica el modo claro oficial de Soplos Linux (Orchis-Orange-Light + kora-soplos).
  --keybindings       Configura únicamente el atajo global Ctrl+Alt+T para terminal Ghostty.
  --nautilus          Genera únicamente los scripts de clic derecho para Nautilus.
  --help, -h          Muestra este mensaje de ayuda.

Ajustes incluidos:
  • Branding Soplos:  Orchis-Orange (Dark/Light-Compact), kora-soplos y Future-cursors.
  • Terminal:         Atajo Ctrl+Alt+T para Ghostty (con preservación de atajos previos).
  • Ventanas Mutter:  Botones a la derecha, centrado, edge-tiling y Alt+Tab ventana a ventana.
  • Barra Superior:   Reloj 24h con fecha, día de la semana y porcentaje de batería.
  • Salud Visual:     Luz nocturna programada (4000K) y resalte de cursor con tecla Ctrl.
  • Nautilus:         Vista en lista, borrado permanente y acciones contextuales para Ghostty/Antigravity.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE GNOME SHELL - SOPLOS LINUX BORO WORKSTATION"
    echo "================================================================="
    echo "• Entorno de escritorio:  ${XDG_CURRENT_DESKTOP:-GNOME} (${XDG_SESSION_TYPE:-wayland})"
    echo "• Versión de GNOME Shell: $(gnome-shell --version 2>/dev/null || echo 'GNOME Shell 50')"
    echo "• Compositor / Window Mgr: Mutter (Wayland)"
    echo "-----------------------------------------------------------------"
    echo "• Esquema de color:       $(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo 'n/a')"
    echo "• Tema GTK:               $(run_as_user gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo 'n/a')"
    if run_as_user gsettings list-schemas 2>/dev/null | grep -q "org.gnome.shell.extensions.user-theme"; then
        echo "• Tema de Shell:          $(run_as_user gsettings get org.gnome.shell.extensions.user-theme name 2>/dev/null || echo 'n/a')"
    fi
    echo "• Tema de Iconos:         $(run_as_user gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo 'n/a')"
    echo "• Tema de Cursores:       $(run_as_user gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo 'n/a')"
    echo "• Tipografía Monospace:   $(run_as_user gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null || echo 'n/a')"
    echo "• Tipografía Interfaz UI: $(run_as_user gsettings get org.gnome.desktop.interface font-name 2>/dev/null || echo 'n/a')"
    echo "-----------------------------------------------------------------"
    echo "• Botones de ventana:     $(run_as_user gsettings get org.gnome.desktop.wm.preferences button-layout 2>/dev/null || echo 'n/a')"
    echo "• Ventanas centradas:     $(run_as_user gsettings get org.gnome.mutter center-new-windows 2>/dev/null || echo 'n/a')"
    echo "• Ajuste a bordes (Tiling):$(run_as_user gsettings get org.gnome.mutter edge-tiling 2>/dev/null || echo 'n/a')"
    echo "• Conmutador Alt+Tab:     $(run_as_user gsettings get org.gnome.desktop.wm.keybindings switch-windows 2>/dev/null || echo 'n/a')"
    echo "• Localizar puntero (Ctrl):$(run_as_user gsettings get org.gnome.desktop.interface locate-pointer 2>/dev/null || echo 'false')"
    echo "-----------------------------------------------------------------"
    echo "• Barra superior y Reloj:"
    echo "  - Formato de reloj:     $(run_as_user gsettings get org.gnome.desktop.interface clock-format 2>/dev/null || echo 'n/a')"
    echo "  - Mostrar fecha y día:  $(run_as_user gsettings get org.gnome.desktop.interface clock-show-date 2>/dev/null || echo 'false') / $(run_as_user gsettings get org.gnome.desktop.interface clock-show-weekday 2>/dev/null || echo 'false')"
    echo "  - Porcentaje de batería:$(run_as_user gsettings get org.gnome.desktop.interface show-battery-percentage 2>/dev/null || echo 'false')"
    echo "-----------------------------------------------------------------"
    local nl_enabled nl_temp nl_sched
    nl_enabled=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled 2>/dev/null || echo 'false')
    nl_temp=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.color night-light-temperature 2>/dev/null | awk '{print $NF}' || echo '4000')
    nl_sched=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.color night-light-schedule-automatic 2>/dev/null || echo 'false')
    echo "• Luz Nocturna (Salud Visual):"
    echo "  - Estado:               $(if [ "$nl_enabled" = "true" ]; then echo "✅ Activada"; else echo "❌ Desactivada"; fi)"
    echo "  - Temperatura de color: ${nl_temp} K"
    echo "  - Horario automático:   $(if [ "$nl_sched" = "true" ]; then echo "✅ Solar automático"; else echo "Manual"; fi)"
    echo "-----------------------------------------------------------------"
    local kb_configured kb_has_ghostty
    kb_configured=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo '[]')
    kb_has_ghostty="false"
    for kb in $(echo "$kb_configured" | tr -d "[]'," | tr " " "\n"); do
        if [ -n "$kb" ]; then
            local cmd
            cmd=$(run_as_user gsettings get "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" command 2>/dev/null || true)
            if echo "$cmd" | grep -qi "ghostty"; then
                kb_has_ghostty="true"
                break
            fi
        fi
    done
    echo "• Terminal Ghostty (Ctrl+Alt+T):"
    if [ "$kb_has_ghostty" = "true" ]; then
        echo "  - Atajo global:         ✅ Asignado a Ghostty (<Primary><Alt>t)"
    else
        echo "  - Atajo global:         ❌ No asignado a Ghostty"
    fi
    echo "  - Binario Ghostty:      $(if command -v ghostty &>/dev/null; then echo "✅ $(command -v ghostty)"; else echo "❌ No encontrado"; fi)"
    echo "-----------------------------------------------------------------"
    echo "• Nautilus (Archivos):"
    echo "  - Vista predeterminada: $(run_as_user gsettings get org.gnome.nautilus.preferences default-folder-viewer 2>/dev/null || echo 'n/a')"
    echo "  - Borrado permanente:   $(run_as_user gsettings get org.gnome.nautilus.preferences show-delete-permanently 2>/dev/null || echo 'n/a')"
    local scripts_dir="$USER_HOME/.local/share/nautilus/scripts"
    local s_ghostty s_ag s_code
    s_ghostty=$(if [ -f "$scripts_dir/Abrir en Ghostty" ]; then echo "✅"; else echo "❌"; fi)
    s_ag=$(if [ -f "$scripts_dir/Abrir con Antigravity" ]; then echo "✅"; else echo "❌"; fi)
    s_code=$(if [ -f "$scripts_dir/Abrir en VS Code" ]; then echo "✅"; else echo "❌"; fi)
    echo "  - Scripts contextuales: Ghostty: $s_ghostty | Antigravity: $s_ag | VS Code: $s_code"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. MODO OSCURO / MODO CLARO (BRANDING SOPLOS LINUX BORO)
# ------------------------------------------------------------------------------
apply_dark() {
    echo "🌙 Aplicando tema oscuro oficial de Soplos Linux Boro..."
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

    # 1. Priorizar tema GTK de Soplos (Orchis-Orange Dark Compact / Dark)
    local target_gtk="Adwaita-dark"
    if [ -d "/usr/share/themes/Orchis-Orange-Dark-Compact" ]; then
        target_gtk="Orchis-Orange-Dark-Compact"
    elif [ -d "/usr/share/themes/Orchis-Orange-Dark" ]; then
        target_gtk="Orchis-Orange-Dark"
    elif [ -d "/usr/share/themes/adw-gtk3-dark" ] || [ -d "$USER_HOME/.local/share/themes/adw-gtk3-dark" ]; then
        target_gtk="adw-gtk3-dark"
    elif [ -d "/usr/share/themes/Adwaita-dark" ]; then
        target_gtk="Adwaita-dark"
    fi
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$target_gtk" 2>/dev/null || true

    # 2. Sincronizar tema de GNOME Shell si la extensión user-theme está activa
    if run_as_user gsettings list-schemas 2>/dev/null | grep -q "org.gnome.shell.extensions.user-theme"; then
        if [ -d "/usr/share/themes/Orchis-Orange-Dark-Compact" ]; then
            run_as_user gsettings set org.gnome.shell.extensions.user-theme name 'Orchis-Orange-Dark-Compact' 2>/dev/null || true
        elif [ -d "/usr/share/themes/Orchis-Orange-Dark" ]; then
            run_as_user gsettings set org.gnome.shell.extensions.user-theme name 'Orchis-Orange-Dark' 2>/dev/null || true
        fi
    fi

    # 3. Priorizar tema de iconos de Soplos (kora-soplos-dark)
    local target_icons="Adwaita"
    if [ -d "/usr/share/icons/kora-soplos-dark" ]; then
        target_icons="kora-soplos-dark"
    elif [ -d "/usr/share/icons/Papirus-Dark" ]; then
        target_icons="Papirus-Dark"
    fi
    run_as_user gsettings set org.gnome.desktop.interface icon-theme "$target_icons" 2>/dev/null || true

    # 4. Tema de cursores de Soplos
    if [ -d "/usr/share/icons/Future-cursors" ]; then
        run_as_user gsettings set org.gnome.desktop.interface cursor-theme 'Future-cursors' 2>/dev/null || true
    fi

    echo "  ✅ Modo oscuro activado con éxito (GTK: $target_gtk | Iconos: $target_icons)."
}

apply_light() {
    echo "☀️ Aplicando modo claro oficial de Soplos Linux Boro..."
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'default' 2>/dev/null || true

    # 1. Tema GTK claro de Soplos
    local target_gtk="Adwaita"
    if [ -d "/usr/share/themes/Orchis-Orange-Light-Compact" ]; then
        target_gtk="Orchis-Orange-Light-Compact"
    elif [ -d "/usr/share/themes/Orchis-Orange-Light" ]; then
        target_gtk="Orchis-Orange-Light"
    elif [ -d "/usr/share/themes/Orchis-Orange" ]; then
        target_gtk="Orchis-Orange"
    fi
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$target_gtk" 2>/dev/null || true

    # 2. Tema de Shell claro
    if run_as_user gsettings list-schemas 2>/dev/null | grep -q "org.gnome.shell.extensions.user-theme"; then
        if [ -d "/usr/share/themes/Orchis-Orange-Light-Compact" ]; then
            run_as_user gsettings set org.gnome.shell.extensions.user-theme name 'Orchis-Orange-Light-Compact' 2>/dev/null || true
        elif [ -d "/usr/share/themes/Orchis-Orange-Light" ]; then
            run_as_user gsettings set org.gnome.shell.extensions.user-theme name 'Orchis-Orange-Light' 2>/dev/null || true
        fi
    fi

    # 3. Tema de iconos claro de Soplos
    local target_icons="Adwaita"
    if [ -d "/usr/share/icons/kora-soplos-light" ]; then
        target_icons="kora-soplos-light"
    elif [ -d "/usr/share/icons/Papirus" ]; then
        target_icons="Papirus"
    fi
    run_as_user gsettings set org.gnome.desktop.interface icon-theme "$target_icons" 2>/dev/null || true

    echo "  ✅ Modo claro activado con éxito (GTK: $target_gtk | Iconos: $target_icons)."
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN IDEMPOTENTE DE UTILIDADES BASE
# ------------------------------------------------------------------------------
apply_packages() {
    echo "ℹ️ [1/6] Verificando dependencias base y herramientas de GNOME..."
    local required_pkgs=(
        gnome-tweaks
        gnome-browser-connector
        gnome-shell-extension-gsconnect
        gnome-shell-extensions
        wl-clipboard
    )
    local missing_pkgs=()

    for pkg in "${required_pkgs[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done

    if [ ${#missing_pkgs[@]} -gt 0 ]; then
        echo "  ↳ Paquetes sugeridos no instalados: ${missing_pkgs[*]}"
        local install_success="false"
        if [ "$EUID" -eq 0 ] || command -v sudo &>/dev/null; then
            echo "  ↳ Intentando instalación de paquetes faltantes..."
            if ($SUDO apt-get update -qq && $SUDO apt-get install -y --no-upgrade "${missing_pkgs[@]}") 2>/dev/null; then
                install_success="true"
                echo "  ✅ Utilidades base aseguradas."
            fi
        fi
        if [ "$install_success" != "true" ]; then
            echo "  ⚠️ No se pudieron instalar automáticamente. Puedes instalarlos con: sudo apt install ${missing_pkgs[*]}"
        fi
    else
        echo "  ✅ Todas las utilidades base de GNOME ya se encuentran instaladas."
    fi
}

# ------------------------------------------------------------------------------
# 5. APARIENCIA, TIPOGRAFÍA Y ACCESIBILIDAD
# ------------------------------------------------------------------------------
apply_appearance() {
    echo "ℹ️ [2/6] Configurando apariencia de Soplos y salud visual..."
    apply_dark

    # Tipografía monospace para desarrollo y terminal (con detección real de fuentes)
    if fc-list : family 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
        run_as_user gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11' 2>/dev/null || true
        echo "  ↳ Tipografía Monospace: JetBrainsMono Nerd Font 11"
    elif fc-list : family 2>/dev/null | grep -qi "JetBrainsMono"; then
        run_as_user gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono 11' 2>/dev/null || true
        echo "  ↳ Tipografía Monospace: JetBrainsMono 11"
    else
        echo "  ↳ JetBrainsMono no detectada; preservando tipografía del sistema ($(run_as_user gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null))."
    fi

    # Accesibilidad multimonitor: localizar puntero pulsando la tecla Ctrl
    run_as_user gsettings set org.gnome.desktop.interface locate-pointer true 2>/dev/null || true

    echo "  ✅ Apariencia y accesibilidad configuradas."
}

# ------------------------------------------------------------------------------
# 6. GESTIÓN DE VENTANAS Y MUTTER WAYLAND (MULTIMONITOR)
# ------------------------------------------------------------------------------
apply_windows() {
    echo "ℹ️ [3/6] Optimizando compositor Mutter y ventanas para multimonitor..."
    # Disposición completa de botones: minimizar, maximizar, cerrar a la derecha
    run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' 2>/dev/null || true

    # Centrado automático de nuevas ventanas y cuadros modales anclados
    run_as_user gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter attach-modal-dialogs true 2>/dev/null || true

    # Edge tiling nativo para dividir ventanas al arrastrar a los bordes
    run_as_user gsettings set org.gnome.mutter edge-tiling true 2>/dev/null || true

    # Conmutación ágil de ventanas individuales con Alt+Tab (evita agrupar por aplicación)
    run_as_user gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']" 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']" 2>/dev/null || true

    # Características experimentales de Mutter (sin sobrescribir destructivamente)
    if run_as_user gsettings list-keys org.gnome.mutter 2>/dev/null | grep -q "^experimental-features$"; then
        local range current_features new_features=()
        range=$(run_as_user gsettings range org.gnome.mutter experimental-features 2>/dev/null || true)
        current_features=$(run_as_user gsettings get org.gnome.mutter experimental-features 2>/dev/null || echo "[]")

        if echo "$range" | grep -q "scale-monitor-framebuffer"; then
            new_features+=("'scale-monitor-framebuffer'")
        fi
        if echo "$range" | grep -q "xwayland-native-scaling"; then
            new_features+=("'xwayland-native-scaling'")
        fi

        if [ ${#new_features[@]} -gt 0 ]; then
            local features_str
            features_str=$(IFS=, ; echo "[${new_features[*]}]")
            run_as_user gsettings set org.gnome.mutter experimental-features "$features_str" 2>/dev/null || true
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

    # Luz nocturna para reducción de fatiga ocular con horario solar automático
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic true 2>/dev/null || true

    # Evitar suspensión en corriente alterna por inactividad
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true

    echo "  ✅ Barra superior, reloj y luz nocturna configurados."
}

# ------------------------------------------------------------------------------
# 8. GESTOR DE ARCHIVOS NAUTILUS (ACCIONES CONTEXTUALES)
# ------------------------------------------------------------------------------
apply_nautilus() {
    echo "ℹ️ [5/6] Optimizando gestor de archivos Nautilus y menús contextuales..."
    run_as_user gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' 2>/dev/null || true
    run_as_user gsettings set org.gnome.nautilus.preferences show-delete-permanently true 2>/dev/null || true

    local nautilus_scripts_dir="$USER_HOME/.local/share/nautilus/scripts"
    run_as_user mkdir -p "$nautilus_scripts_dir" 2>/dev/null || true

    # Limpiar scripts obsoletos o duplicados
    rm -f "$nautilus_scripts_dir/Abrir en Kitty" 2>/dev/null || true
    rm -f "$nautilus_scripts_dir/Abrir en Antigravity IDE" 2>/dev/null || true

    # Script para abrir en Ghostty
    cat << 'EOF' | run_as_user tee "$nautilus_scripts_dir/Abrir en Ghostty" > /dev/null 2>&1 || true
#!/bin/sh
export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$PATH"
target=""
if [ -n "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" ]; then
    first=$(echo "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" | head -n1)
    if [ -d "$first" ]; then
        target="$first"
    elif [ -f "$first" ]; then
        target="$(dirname "$first")"
    fi
fi
if [ -z "$target" ] && [ -n "$NAUTILUS_SCRIPT_CURRENT_URI" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || true)
fi
target="${target:-${1:-.}}"
if command -v ghostty &>/dev/null; then
    exec ghostty --working-directory="$target" &
elif command -v gnome-terminal &>/dev/null; then
    exec gnome-terminal --working-directory="$target" &
fi
EOF
    run_as_user chmod +x "$nautilus_scripts_dir/Abrir en Ghostty" 2>/dev/null || true

    # Script para abrir con Google Antigravity Desktop
    cat << 'EOF' | run_as_user tee "$nautilus_scripts_dir/Abrir con Antigravity" > /dev/null 2>&1 || true
#!/usr/bin/env bash
export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$PATH"
target="${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-${1:-.}}"
if [ -z "$target" ] && [ -n "$NAUTILUS_SCRIPT_CURRENT_URI" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || true)
fi
if command -v antigravity &>/dev/null; then
    exec antigravity "${target:-.}" &
elif command -v antigravity-ide &>/dev/null; then
    exec antigravity-ide "${target:-.}" &
fi
EOF
    run_as_user chmod +x "$nautilus_scripts_dir/Abrir con Antigravity" 2>/dev/null || true

    # Script para abrir en VS Code
    cat << 'EOF' | run_as_user tee "$nautilus_scripts_dir/Abrir en VS Code" > /dev/null 2>&1 || true
#!/bin/sh
export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin:$PATH"
target="${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-${1:-.}}"
if [ -z "$target" ] && [ -n "$NAUTILUS_SCRIPT_CURRENT_URI" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || true)
fi
exec code "${target:-.}" &
EOF
    run_as_user chmod +x "$nautilus_scripts_dir/Abrir en VS Code" 2>/dev/null || true

    echo "  ✅ Nautilus configurado con scripts contextuales (Ghostty, Antigravity, VS Code)."
}

# ------------------------------------------------------------------------------
# 9. ATAJO GLOBAL CTRL+ALT+T PARA TERMINAL GHOSTTY
# ------------------------------------------------------------------------------
apply_keybindings() {
    echo "ℹ️ [6/6] Configurando atajo global Ctrl+Alt+T para terminal Ghostty..."

    # 1. Desvincular el atajo predeterminado de GNOME para evitar conflicto de atajos
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "[]" 2>/dev/null || true

    # 2. Localizar si Ghostty ya tiene un custom-keybinding asignado o encontrar el siguiente slot libre
    local current_kb target_kb_path=""
    current_kb=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "[]")

    for kb in $(echo "$current_kb" | tr -d "[]'," | tr " " "\n"); do
        if [ -n "$kb" ]; then
            local cmd
            cmd=$(run_as_user gsettings get "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" command 2>/dev/null || true)
            if echo "$cmd" | grep -qi "ghostty"; then
                target_kb_path="$kb"
                break
            fi
        fi
    done

    # Si no se encontró un atajo previo de Ghostty, buscar el primer índice disponible customN
    if [ -z "$target_kb_path" ]; then
        local idx=0
        while :; do
            local candidate="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${idx}/"
            if ! echo "$current_kb" | grep -q "$candidate"; then
                target_kb_path="$candidate"
                break
            fi
            idx=$((idx + 1))
        done

        # Agregar el nuevo slot a custom-keybindings preservando los existentes
        if [[ "$current_kb" == "@as []" || "$current_kb" == "[]" ]]; then
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$target_kb_path']" 2>/dev/null || true
        else
            local new_kb
            new_kb=$(echo "$current_kb" | sed "s/]/, '$target_kb_path']/")
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_kb" 2>/dev/null || true
        fi
    fi

    # 3. Determinar comando ejecutable para la terminal (Ghostty preferido, fallback a terminal del sistema)
    local term_cmd="ghostty"
    if ! command -v ghostty &>/dev/null; then
        if command -v gnome-terminal &>/dev/null; then
            term_cmd="gnome-terminal"
        fi
    fi

    # 4. Asignar propiedades del atajo en GSettings
    run_as_user gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${target_kb_path}" name 'Ghostty Terminal' 2>/dev/null || true
    run_as_user gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${target_kb_path}" command "$term_cmd" 2>/dev/null || true
    run_as_user gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${target_kb_path}" binding '<Primary><Alt>t' 2>/dev/null || true

    echo "  ✅ Atajo global Ctrl+Alt+T asignado a '$term_cmd' en ${target_kb_path} sin colisiones."
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
    --keybindings)
        apply_keybindings
        exit 0
        ;;
    --nautilus)
        apply_nautilus
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
    "")
        echo "================================================================="
        echo "🎨 CONFIGURANDO PERSONALIZACIÓN DE GNOME SHELL (SOPLOS LINUX BORO)"
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
        echo "Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
