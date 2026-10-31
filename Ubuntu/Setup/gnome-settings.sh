#!/usr/bin/env bash
# ==============================================================================
# gnome-settings.sh - Configuración y Personalización Avanzada de GNOME Shell
# Ubuntu Workstation (Ubuntu 24.04 / GNOME Shell 50 + Wayland / Mutter)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)
# ==============================================================================
# Características y Optimizaciones:
#  - Modo oscuro persistente y armonizado (prefer-dark + Yaru-dark / Adwaita).
#  - Tipografía JetBrainsMono Nerd Font para terminal y desarrollo.
#  - Disposición completa de botones de ventana (minimizar, maximizar, cerrar a la derecha).
#  - Mutter Wayland: centrado de ventanas, diálogo modal anclado y edge-tiling multimonitor.
#  - Barra superior y reloj: formato 24h, día de la semana, fecha y porcentaje de batería.
#  - Salud visual: Luz nocturna activada a 4000K para reducir fatiga ocular.
#  - Localización de cursor rápida con tecla Ctrl (locate-pointer) en triple pantalla.
#  - Nautilus optimizado: vista en lista y habilitación de borrado permanente directo.
#  - Terminal Kitty acelerada por GPU vinculada a atajo global Ctrl+Alt+T sin colisiones.
#  - Menús contextuales nativos en Nautilus (clic derecho) para Kitty, Antigravity y VS Code.
#  - Opciones CLI: --status / -s, --dark / -d, --light / -l, --keybindings, --nautilus, --help / -h.
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

# ------------------------------------------------------------------------------
# 2. AYUDA Y ESTADO DEL SISTEMA
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
🎨 Personalización de GNOME Shell - Ubuntu Workstation (Wayland)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Aplica toda la configuración recomendada (apariencia, Mutter,
                      Nautilus, atajo global de Kitty y scripts contextuales).
  --status, -s        Muestra diagnóstico detallado de temas, fuentes, ventanas y atajos.
  --dark, -d          Aplica el modo oscuro completo (prefer-dark + tema oscuro del sistema).
  --light, -l         Aplica el modo claro estándar.
  --keybindings       Configura únicamente el atajo global Ctrl+Alt+T para Kitty.
  --nautilus          Genera únicamente los scripts de clic derecho para Nautilus.
  --help, -h          Muestra este mensaje de ayuda.

Ajustes incluidos:
  • Apariencia:       Modo oscuro prefer-dark, iconos acordes y JetBrainsMono Nerd Font.
  • Ventanas Mutter:  Minimizar/Maximizar/Cerrar a la derecha, centrado y edge-tiling.
  • Barra Superior:   Reloj 24h con fecha, día de la semana y porcentaje de batería.
  • Confort Visual:   Luz nocturna a 4000K y resalte de cursor con tecla Ctrl.
  • Nautilus:         Vista en lista, borrado permanente habilitado y menús contextuales.
  • Terminal:         Atajo Ctrl+Alt+T para Kitty (sin colisión con terminal por defecto).
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE GNOME SHELL - UBUNTU WORKSTATION"
    echo "================================================================="
    echo "• Entorno de escritorio:  ${XDG_CURRENT_DESKTOP:-ubuntu:GNOME} (${XDG_SESSION_TYPE:-wayland})"
    echo "• Versión de GNOME Shell: $(gnome-shell --version 2>/dev/null || echo 'GNOME 50')"
    echo "• Compositor / Window Mgr: Mutter (Wayland)"
    echo "-----------------------------------------------------------------"
    echo "• Esquema de color:       $(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo 'n/a')"
    echo "• Tema GTK:               $(run_as_user gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo 'n/a')"
    echo "• Tema de Iconos:         $(run_as_user gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo 'n/a')"
    echo "• Tipografía Monospace:   $(run_as_user gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null || echo 'n/a')"
    echo "• Tipografía UI:          $(run_as_user gsettings get org.gnome.desktop.interface font-name 2>/dev/null || echo 'n/a')"
    echo "-----------------------------------------------------------------"
    echo "• Botones de ventana:     $(run_as_user gsettings get org.gnome.desktop.wm.preferences button-layout 2>/dev/null || echo 'n/a')"
    echo "• Ventanas centradas:     $(run_as_user gsettings get org.gnome.mutter center-new-windows 2>/dev/null || echo 'n/a')"
    echo "• Ajuste a bordes (Tiling):$(run_as_user gsettings get org.gnome.mutter edge-tiling 2>/dev/null || echo 'n/a')"
    echo "• Localizar puntero (Ctrl):$(run_as_user gsettings get org.gnome.desktop.interface locate-pointer 2>/dev/null || echo 'false')"
    echo "-----------------------------------------------------------------"
    echo "• Barra superior y Reloj:"
    echo "  - Formato de reloj:     $(run_as_user gsettings get org.gnome.desktop.interface clock-format 2>/dev/null || echo 'n/a')"
    echo "  - Mostrar fecha y día:  $(run_as_user gsettings get org.gnome.desktop.interface clock-show-date 2>/dev/null || echo 'false') / $(run_as_user gsettings get org.gnome.desktop.interface clock-show-weekday 2>/dev/null || echo 'false')"
    echo "  - Porcentaje de batería:$(run_as_user gsettings get org.gnome.desktop.interface show-battery-percentage 2>/dev/null || echo 'false')"
    echo "-----------------------------------------------------------------"
    local nl_enabled nl_temp
    nl_enabled=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled 2>/dev/null || echo 'false')
    nl_temp=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.color night-light-temperature 2>/dev/null | awk '{print $NF}' || echo '4000')
    echo "• Luz Nocturna (Salud Visual):"
    echo "  - Estado:               $(if [ "$nl_enabled" = "true" ]; then echo "✅ Activada"; else echo "❌ Desactivada"; fi)"
    echo "  - Temperatura de color: ${nl_temp} K"
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
    echo "  - Vista predeterminada: $(run_as_user gsettings get org.gnome.nautilus.preferences default-folder-viewer 2>/dev/null || echo 'n/a')"
    echo "  - Borrado permanente:   $(run_as_user gsettings get org.gnome.nautilus.preferences show-delete-permanently 2>/dev/null || echo 'n/a')"
    local scripts_dir="$USER_HOME/.local/share/nautilus/scripts"
    local s_kitty s_ag s_code
    s_kitty=$(if [ -f "$scripts_dir/Abrir en Kitty" ]; then echo "✅"; else echo "❌"; fi)
    s_ag=$(if [ -f "$scripts_dir/Abrir en Antigravity IDE" ]; then echo "✅"; else echo "❌"; fi)
    s_code=$(if [ -f "$scripts_dir/Abrir en VS Code" ]; then echo "✅"; else echo "❌"; fi)
    echo "  - Scripts contextuales: Kitty: $s_kitty | Antigravity: $s_ag | VS Code: $s_code"
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 3. MODO OSCURO / MODO CLARO
# ------------------------------------------------------------------------------
apply_dark() {
    echo "🌙 Aplicando tema oscuro persistente y armónico..."
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

    # Seleccionar tema GTK instalado real
    local target_theme="Yaru-dark"
    if [ -d "/usr/share/themes/adw-gtk3-dark" ] || [ -d "$USER_HOME/.local/share/themes/adw-gtk3-dark" ]; then
        target_theme="adw-gtk3-dark"
    elif [ -d "/usr/share/themes/Yaru-dark" ]; then
        target_theme="Yaru-dark"
    elif [ -d "/usr/share/themes/Adwaita-dark" ]; then
        target_theme="Adwaita-dark"
    fi
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme "$target_theme" 2>/dev/null || true

    # Seleccionar tema de iconos oscuro si existe
    if [ -d "/usr/share/icons/Yaru-dark" ]; then
        run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Yaru-dark' 2>/dev/null || true
    fi

    echo "  ✅ Modo oscuro activado con tema '$target_theme'."
}

apply_light() {
    echo "☀️ Aplicando modo claro..."
    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'default' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'Yaru' 2>/dev/null || \
        run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Yaru' 2>/dev/null || true
    echo "  ✅ Modo claro activado."
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN DE PAQUETES BASE DE SOPORTE
# ------------------------------------------------------------------------------
apply_packages() {
    echo "ℹ️ [1/6] Verificando utilidades de soporte y terminal Kitty en GNOME..."
    $SUDO apt update -qq
    $SUDO apt install -y \
        kitty \
        gnome-tweaks \
        gnome-browser-connector \
        gnome-shell-extension-gsconnect \
        gnome-shell-ubuntu-extensions \
        wl-clipboard 2>/dev/null || true
    echo "  ✅ Utilidades base aseguradas."
}

# ------------------------------------------------------------------------------
# 5. APARIENCIA, TIPOGRAFÍA Y ACCESIBILIDAD
# ------------------------------------------------------------------------------
apply_appearance() {
    echo "ℹ️ [2/6] Configurando apariencia, tipografía y salud visual..."
    apply_dark

    # Tipografía monospace para desarrollo y terminal
    if fc-list "JetBrainsMono Nerd Font" &>/dev/null; then
        run_as_user gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11' 2>/dev/null || true
    elif fc-list "JetBrainsMono Nerd Font Mono" &>/dev/null; then
        run_as_user gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font Mono 11' 2>/dev/null || true
    fi

    # Accesibilidad multimonitor: localizar puntero con Ctrl
    run_as_user gsettings set org.gnome.desktop.interface locate-pointer true 2>/dev/null || true

    echo "  ✅ Apariencia y tipografía configuradas."
}

# ------------------------------------------------------------------------------
# 6. GESTIÓN DE VENTANAS Y MUTTER WAYLAND
# ------------------------------------------------------------------------------
apply_windows() {
    echo "ℹ️ [3/6] Optimizando compositor Mutter y ventanas para multimonitor..."
    # Botones completos a la derecha: minimizar, maximizar, cerrar
    run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close' 2>/dev/null || true

    # Centrado automático de nuevas ventanas y cuadros modales anclados
    run_as_user gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter attach-modal-dialogs true 2>/dev/null || true

    # Edge tiling nativo para dividir ventanas al arrastrar a los bordes
    run_as_user gsettings set org.gnome.mutter edge-tiling true 2>/dev/null || true

    # Si Mutter soporta experimental-features en la versión actual, aplicarlas de forma dinámica y segura
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
            features_str=$(IFS=, ; echo "[${features[*]}]")
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

    # Luz nocturna para reducción de fatiga visual en sesiones de programación
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000 2>/dev/null || true

    # No suspender en corriente alterna por inactividad
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true

    echo "  ✅ Barra superior, reloj y luz nocturna configurados."
}

# ------------------------------------------------------------------------------
# 8. GESTOR DE ARCHIVOS NAUTILUS
# ------------------------------------------------------------------------------
apply_nautilus() {
    echo "ℹ️ [5/6] Optimizando gestor de archivos Nautilus..."
    run_as_user gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' 2>/dev/null || true
    # Habilitar opción directa de borrado permanente (Shift+Supr / menú contextual)
    run_as_user gsettings set org.gnome.nautilus.preferences show-delete-permanently true 2>/dev/null || true

    # Creación de scripts contextuales de clic derecho
    local nautilus_scripts_dir="$USER_HOME/.local/share/nautilus/scripts"
    run_as_user mkdir -p "$nautilus_scripts_dir"

    # Script para abrir en Kitty
    cat << 'EOF' | run_as_user tee "$nautilus_scripts_dir/Abrir en Kitty" > /dev/null
#!/bin/sh
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
exec kitty --directory "${target:-${1:-.}}" &
EOF
    run_as_user chmod +x "$nautilus_scripts_dir/Abrir en Kitty"

    # Script para abrir en Antigravity IDE
    cat << 'EOF' | run_as_user tee "$nautilus_scripts_dir/Abrir en Antigravity IDE" > /dev/null
#!/bin/sh
target="${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-$1}"
if [ -z "$target" ] && [ -n "$NAUTILUS_SCRIPT_CURRENT_URI" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || true)
fi
if command -v antigravity-ide &>/dev/null; then
    exec antigravity-ide "${target:-.}" &
elif command -v antigravity &>/dev/null; then
    exec antigravity "${target:-.}" &
fi
EOF
    run_as_user chmod +x "$nautilus_scripts_dir/Abrir en Antigravity IDE"

    # Script para abrir en VS Code
    cat << 'EOF' | run_as_user tee "$nautilus_scripts_dir/Abrir en VS Code" > /dev/null
#!/bin/sh
target="${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-$1}"
if [ -z "$target" ] && [ -n "$NAUTILUS_SCRIPT_CURRENT_URI" ]; then
    target=$(echo "$NAUTILUS_SCRIPT_CURRENT_URI" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))" 2>/dev/null || true)
fi
exec code "${target:-.}" &
EOF
    run_as_user chmod +x "$nautilus_scripts_dir/Abrir en VS Code"

    echo "  ✅ Nautilus configurado con scripts de clic derecho."
}

# ------------------------------------------------------------------------------
# 9. ATAJO GLOBAL CTRL+ALT+T PARA KITTY
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
        echo "🎨 CONFIGURANDO PERSONALIZACIÓN DE GNOME SHELL (UBUNTU WORKSTATION)"
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
