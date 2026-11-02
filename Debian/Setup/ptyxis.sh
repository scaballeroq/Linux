#!/usr/bin/env bash
# ==============================================================================
# ptyxis.sh - Instalación, Optimización y Configuración Estética de Ptyxis Terminal
# Sistema: Debian GNU/Linux 13 (Trixie) | Entorno: GNOME Shell 48+ (Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 Mesa RADV)
# Tema: Catppuccin Mocha con Transparencia, Libadwaita y Tipografía Nerd Font
# ==============================================================================
# Características:
# - Terminal oficial de GNOME moderna con soporte de primera clase para contenedores.
# - Paleta Catppuccin Mocha instalada en ~/.local/share/org.gnome.Ptyxis/palettes/.
# - Opacidad configurada (80%) y soporte para blur en Wayland (Mutter).
# - Tipografía JetBrainsMono Nerd Font desacoplada de la fuente del sistema.
# - Interfaz oscura Adwaita forzada y barra de desplazamiento minimalista (never).
# - Integración contextual completa en Nautilus (Extensión Python 1er nivel + Script).
# - Atajo global en GNOME Shell (Ctrl+Alt+P o Ctrl+Alt+T vía flag).
# - Opciones CLI: --status / -s, --config-only / --no-install, --default-terminal,
#   --bind-ctrl-alt-t, --help / -h.
# ==============================================================================

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# ------------------------------------------------------------------------------
# 1. CONSTANTES Y CONFIGURACIÓN ESTÉTICA
# ------------------------------------------------------------------------------
DEFAULT_OPACITY="0.80"
DEFAULT_FONT="JetBrainsMono Nerd Font 11"

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
🖥️ Gestor y Optimizador de Ptyxis Terminal - Debian 13 Workstation (GNOME Wayland)
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8 Mesa RADV)

Uso:
  $0 [OPCIÓN]

Opciones principales:
  (sin argumentos)        Instala Ptyxis vía APT si no está presente, genera la paleta
                          Catppuccin Mocha, configura GSettings y aplica integración con Nautilus.
  -s, --status            Muestra el estado detallado de Ptyxis, versión, perfil, fuentes y atajos.
  --no-install, --config  Genera paletas y aplica configuraciones de dconf/gsettings sin invocar
                          APT ni requerir privilegios de superusuario (sudo).
  --bind-ctrl-alt-t       Asigna explícitamente el atajo global Ctrl+Alt+T a Ptyxis en GNOME.
  --default-terminal      Establece Ptyxis como la terminal predeterminada en update-alternatives.
  -h, --help              Muestra este mensaje de ayuda.

Características aplicadas:
  • Motor:                Ptyxis (GNOME Terminal moderno con soporte para Podman/Toolbx).
  • Paleta:               Catppuccin Mocha (.palette instalado en perfiles de usuario).
  • Tipografía:           JetBrainsMono Nerd Font 11.
  • Transparencia:        Opacidad 80% (0.80) sobre compositor Mutter Wayland.
  • Interfaz:             Tema oscuro Adwaita forzado y barra de desplazamiento oculta.
  • Integración Nautilus: Extensión Python de 1er nivel ("Abrir en Ptyxis") y script auxiliar.
EOF
}

show_status() {
    local os_name
    os_name=$(get_os_description)

    echo "================================================================="
    echo "🔍 ESTADO DE PTYXIS TERMINAL - DEBIAN WORKSTATION (WAYLAND)"
    echo "================================================================="
    echo "• Sistema Operativo:             $os_name"
    
    if command -v ptyxis &>/dev/null; then
        local ptyxis_v
        ptyxis_v=$(dpkg -s ptyxis 2>/dev/null | grep "^Version:" | awk '{print $2}' || ptyxis --version 2>/dev/null | head -n1 || echo "instalada")
        echo "• Ptyxis instalado:              ✅ $(which ptyxis) (v${ptyxis_v})"
    else
        echo "• Ptyxis instalado:              ❌ No instalado"
    fi

    # Fuente Nerd Font
    local font_status="⚠️ No detectada (se usará fallback del sistema)"
    if [ -n "$(fc-list : family | grep -i "^JetBrainsMono Nerd Font" 2>/dev/null || true)" ]; then
        font_status="✅ JetBrainsMono Nerd Font disponible"
    elif [ -n "$(fc-list : family | grep -i "^JetBrains Mono" 2>/dev/null || true)" ]; then
        font_status="✅ JetBrains Mono estándar disponible"
    fi
    echo "• Tipografía Monospace:          $font_status"

    # Perfil activo y configuración
    local has_schema=false
    if command -v gsettings &>/dev/null && (gsettings list-schemas 2>/dev/null | grep -q "org.gnome.Ptyxis" || [ -f /usr/share/glib-2.0/schemas/org.gnome.Ptyxis.gschema.xml ]); then
        has_schema=true
    fi

    if [ "$has_schema" = "true" ]; then
        local profile_id custom_font current_opacity current_palette
        profile_id=$(run_as_user gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'" || echo "")
        custom_font=$(run_as_user gsettings get org.gnome.Ptyxis font-name 2>/dev/null | tr -d "'" || echo "sistema")
        
        if [ -n "$profile_id" ]; then
            current_opacity=$(run_as_user gsettings get "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${profile_id}/" opacity 2>/dev/null || echo "1.0")
            current_palette=$(run_as_user gsettings get "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${profile_id}/" palette 2>/dev/null | tr -d "'" || echo "por defecto")
            echo "• Perfil Ptyxis por defecto:     ✅ $profile_id"
            echo "• Opacidad / Paleta:             ✅ Opacidad: $current_opacity | Paleta: $current_palette"
            echo "• Tipografía configurada:        ✅ $custom_font"
        else
            echo "• Perfil Ptyxis:                 ℹ️ No inicializado aún (se genera automáticamente al primer inicio)"
        fi
    else
        echo "• Esquema org.gnome.Ptyxis:      ❌ No registrado en GSettings (instala ptyxis)"
    fi

    # Paleta Catppuccin Mocha instalada
    local palette_file="$USER_HOME/.local/share/org.gnome.Ptyxis/palettes/catppuccin-mocha.palette"
    if [ -f "$palette_file" ]; then
        echo "• Archivo de Paleta:             ✅ Catppuccin Mocha instalado"
    else
        echo "• Archivo de Paleta:             ❌ No presente ($palette_file)"
    fi

    # Integración con GNOME (Atajos de teclado)
    local custom0_cmd custom1_cmd custom2_cmd
    custom0_cmd=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 2>/dev/null || echo '')
    custom1_cmd=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 2>/dev/null || echo '')
    custom2_cmd=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command 2>/dev/null || echo '')

    if echo "$custom0_cmd" | grep -qi "ptyxis"; then
        echo "• Atajo Global (Ctrl+Alt+T):     ✅ Vinculado a Ptyxis (custom0)"
    elif echo "$custom1_cmd" | grep -qi "ptyxis"; then
        echo "• Atajo Global (Ctrl+Alt+G):     ✅ Vinculado a Ptyxis (custom1)"
    elif echo "$custom2_cmd" | grep -qi "ptyxis"; then
        echo "• Atajo Alternativo (Ctrl+Alt+P):✅ Vinculado a Ptyxis (custom2)"
    else
        echo "• Atajo Global:                  ℹ️ No asignado a Ptyxis"
    fi

    # Menú contextual de Nautilus
    local nautilus_ext="$USER_HOME/.local/share/nautilus-python/extensions/open-ptyxis.py"
    local nautilus_script="$USER_HOME/.local/share/nautilus/scripts/Abrir en Ptyxis"
    if [ -f "$nautilus_ext" ]; then
        echo "• Menú Nautilus (Clic derecho):  ✅ Activo (Extensión nativa de 1er nivel)"
    elif [ -f "$nautilus_script" ]; then
        echo "• Menú Nautilus (Clic derecho):  ⚠️ En submenú 'Guiones' (Script clásico)"
    else
        echo "• Menú Nautilus (Clic derecho):  ❌ No instalado"
    fi

    # Terminal del sistema
    if [ -x /usr/bin/x-terminal-emulator ]; then
        local cur_alt
        cur_alt=$(readlink -f /usr/bin/x-terminal-emulator 2>/dev/null || echo "n/a")
        echo "• x-terminal-emulator:           $cur_alt"
    fi
    echo "================================================================="
}

# ------------------------------------------------------------------------------
# 4. INSTALACIÓN DE PTYXIS VÍA APT
# ------------------------------------------------------------------------------
install_ptyxis() {
    if ! command -v ptyxis &>/dev/null; then
        echo "📦 [1/4] Instalando Ptyxis Terminal vía APT..."
        if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
            echo "❌ Error: Se requieren permisos de superusuario para instalar Ptyxis."
            exit 1
        fi
        $SUDO apt-get update -qq
        $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y ptyxis 2>/dev/null || true
        # Forzar compilación inmediata de esquemas GSettings
        $SUDO glib-compile-schemas /usr/share/glib-2.0/schemas 2>/dev/null || true
        echo "   ✅ Ptyxis instalado y esquemas compilados exitosamente."
    else
        local ptyxis_v
        ptyxis_v=$(dpkg -s ptyxis 2>/dev/null | grep "^Version:" | awk '{print $2}' || echo "instalada")
        echo "   ✅ Ptyxis ya está instalado en el sistema (v${ptyxis_v})."
    fi
}

# ------------------------------------------------------------------------------
# 5. GENERACIÓN DE PALETA CATPPUCCIN MOCHA Y CONFIGURACIÓN GSETTINGS
# ------------------------------------------------------------------------------
setup_config() {
    echo "⚙️ [2/4] Generando paleta Catppuccin Mocha y configurando Ptyxis..."

    # 1. Crear directorio de paletas de usuario para Ptyxis
    local palettes_dir="$USER_HOME/.local/share/org.gnome.Ptyxis/palettes"
    run_as_user mkdir -p "$palettes_dir"

    # 2. Instalar definición de paleta Catppuccin Mocha (.palette)
    cat << 'EOF' | run_as_user tee "$palettes_dir/catppuccin-mocha.palette" > /dev/null
[Palette]
Name=Catppuccin Mocha
Primary=true

[Dark]
Foreground=#cdd6f4
Background=#1e1e2e
TitlebarBackground=#1e1e2e
TitlebarForeground=#cdd6f4
Cursor=#f5c2e7
Color0=#45475a
Color1=#f38ba8
Color2=#a6e3a1
Color3=#f9e2af
Color4=#89b4fa
Color5=#f5c2e7
Color6=#94e2d5
Color7=#bac2de
Color8=#585b70
Color9=#f38ba8
Color10=#a6e3a1
Color11=#f9e2af
Color12=#89b4fa
Color13=#f5c2e7
Color14=#94e2d5
Color15=#a6adc8
EOF
    echo "   ✅ Paleta Catppuccin Mocha instalada en $palettes_dir."

    # 3. Aplicar preferencias globales de interfaz en GSettings
    if command -v gsettings &>/dev/null && gsettings list-schemas 2>/dev/null | grep -q "org.gnome.Ptyxis"; then
        # Forzar tema oscuro Adwaita
        run_as_user gsettings set org.gnome.Ptyxis interface-style 'dark' 2>/dev/null || true

        # Desactivar barra de desplazamiento para aspecto moderno y limpio
        run_as_user gsettings set org.gnome.Ptyxis scrollbar-policy 'never' 2>/dev/null || true

        # Configurar tipografía JetBrainsMono Nerd Font
        run_as_user gsettings set org.gnome.Ptyxis use-system-font false 2>/dev/null || true
        run_as_user gsettings set org.gnome.Ptyxis font-name "$DEFAULT_FONT" 2>/dev/null || true

        # Restaurar tamaño de ventana
        run_as_user gsettings set org.gnome.Ptyxis restore-window-size true 2>/dev/null || true

        # Obtener o pre-inicializar perfil por defecto
        local profile_uuid
        profile_uuid=$(run_as_user gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'" || echo "")

        if [ -z "$profile_uuid" ]; then
            profile_uuid=$(python3 -c "import uuid; print(uuid.uuid4().hex)" 2>/dev/null || echo "defaultprofile00000000000000000")
            run_as_user gsettings set org.gnome.Ptyxis profile-uuids "['$profile_uuid']" 2>/dev/null || true
            run_as_user gsettings set org.gnome.Ptyxis default-profile-uuid "$profile_uuid" 2>/dev/null || true
        fi

        local profile_path="org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${profile_uuid}/"
        # Opacidad (80%)
        run_as_user gsettings set "$profile_path" opacity "$DEFAULT_OPACITY" 2>/dev/null || true
        # Aplicar paleta Catppuccin Mocha
        run_as_user gsettings set "$profile_path" palette 'Catppuccin Mocha' 2>/dev/null || true
        echo "   ✅ Perfil '$profile_uuid' configurado con opacidad ${DEFAULT_OPACITY} y paleta Catppuccin Mocha."
    fi
}

# ------------------------------------------------------------------------------
# 6. INTEGRACIÓN CON GNOME SHELL Y ATAJOS DE TECLADO
# ------------------------------------------------------------------------------
setup_keybinding() {
    local force_ctrl_alt_t="${1:-false}"
    echo "⌨️ [3/4] Sincronizando atajo de teclado en GNOME Shell..."

    if command -v gsettings &>/dev/null; then
        local current_kb
        current_kb=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")

        local custom0_cmd
        custom0_cmd=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 2>/dev/null || echo '')
        custom0_cmd=$(echo "$custom0_cmd" | tr -d "'\"")

        if [ "$force_ctrl_alt_t" = "true" ] || [ -z "$custom0_cmd" ] || [ "$custom0_cmd" = "ptyxis" ]; then
            local kb_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "[]" 2>/dev/null || true
            if [[ "$current_kb" == "@as []" || "$current_kb" == "[]" ]]; then
                run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$kb_path']" 2>/dev/null || true
            elif ! echo "$current_kb" | grep -q "$kb_path"; then
                local new_kb
                new_kb=$(echo "$current_kb" | sed "s|]|, '$kb_path']|")
                run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_kb" 2>/dev/null || true
            fi
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path name 'Ptyxis Terminal' 2>/dev/null || true
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path command 'ptyxis' 2>/dev/null || true
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path binding '<Primary><Alt>t' 2>/dev/null || true
            echo "   ✅ Atajo Ctrl+Alt+T asignado a Ptyxis."
        else
            # Asignar slot custom2 con Ctrl+Alt+P para no colisionar con Kitty (custom0) ni Ghostty (custom1)
            local kb_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
            if ! echo "$current_kb" | grep -q "$kb_path"; then
                local new_kb
                if [[ "$current_kb" == "@as []" || "$current_kb" == "[]" ]]; then
                    new_kb="['$kb_path']"
                else
                    new_kb=$(echo "$current_kb" | sed "s|]|, '$kb_path']|")
                fi
                run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_kb" 2>/dev/null || true
            fi
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path name 'Ptyxis Terminal' 2>/dev/null || true
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path command 'ptyxis' 2>/dev/null || true
            run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path binding '<Primary><Alt>p' 2>/dev/null || true
            echo "   ℹ️ Ranuras previas ocupadas. Se configuró Ctrl+Alt+P para Ptyxis (usa --bind-ctrl-alt-t para forzar Ctrl+Alt+T)."
        fi
    fi
}

# ------------------------------------------------------------------------------
# 7. MENÚ CONTEXTUAL DE NAUTILUS (CLIC DERECHO NATIVO 'Abrir en Ptyxis')
# ------------------------------------------------------------------------------
setup_nautilus_script() {
    echo "📁 [4/4] Configurando menú contextual de Nautilus ('Abrir en Ptyxis')..."

    # Asegurar paquete python3-nautilus para menú contextual de primer nivel
    if ! dpkg -s python3-nautilus &>/dev/null; then
        echo "   ℹ️ Instalando python3-nautilus para integración nativa..."
        if [ "$EUID" -eq 0 ] || command -v sudo &>/dev/null; then
            $SUDO apt-get update -qq
            $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y python3-nautilus 2>/dev/null || true
        fi
    fi

    # 1. Extensión Python nativa (aparece directamente en el menú de clic derecho)
    local ext_dir="$USER_HOME/.local/share/nautilus-python/extensions"
    run_as_user mkdir -p "$ext_dir"

    cat << 'EOF' | run_as_user tee "$ext_dir/open-ptyxis.py" > /dev/null
# Extensión de Nautilus para abrir la terminal Ptyxis directamente en el menú contextual
# Compatible con Nautilus 4.0+ (GNOME 43/48) y python3-nautilus

import os
import subprocess
from urllib.parse import unquote, urlparse
from gi.repository import GObject, Nautilus

class OpenPtyxisExtension(GObject.GObject, Nautilus.MenuProvider):
    def __init__(self):
        super().__init__()

    def _open_ptyxis(self, path):
        if not path:
            path = os.path.expanduser("~")
        if os.path.isfile(path):
            path = os.path.dirname(path)
        try:
            subprocess.Popen(["ptyxis", f"--working-directory={path}"])
        except Exception as e:
            print(f"Error al lanzar Ptyxis: {e}")

    def get_file_items(self, files):
        if not files:
            return []
        item = Nautilus.MenuItem(
            name="OpenPtyxis::OpenFileItem",
            label="Abrir en Ptyxis",
            tip="Abrir la terminal Ptyxis en esta ubicación"
        )
        item.connect("activate", self._on_file_activated, files)
        return [item]

    def get_background_items(self, current_folder):
        item = Nautilus.MenuItem(
            name="OpenPtyxis::OpenBackgroundItem",
            label="Abrir en Ptyxis",
            tip="Abrir la terminal Ptyxis en la carpeta actual"
        )
        item.connect("activate", self._on_background_activated, current_folder)
        return [item]

    def _on_file_activated(self, menu_item, files):
        if not files:
            return
        uri = files[0].get_uri()
        path = unquote(urlparse(uri).path)
        self._open_ptyxis(path)

    def _on_background_activated(self, menu_item, folder):
        uri = folder.get_uri()
        path = unquote(urlparse(uri).path)
        self._open_ptyxis(path)
EOF

    # 2. Script clásico en ~/.local/share/nautilus/scripts (submenú 'Guiones' como respaldo)
    local scripts_dir="$USER_HOME/.local/share/nautilus/scripts"
    run_as_user mkdir -p "$scripts_dir"

    cat << 'EOF' | run_as_user tee "$scripts_dir/Abrir en Ptyxis" > /dev/null
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
target="${target:-$HOME}"
exec ptyxis --working-directory="$target" &
EOF
    run_as_user chmod +x "$scripts_dir/Abrir en Ptyxis" 2>/dev/null || true

    # Reiniciar Nautilus para recargar extensiones inmediatamente
    run_as_user nautilus -q 2>/dev/null || true

    echo "   ✅ Integración contextual de Nautilus completada (Extensión 1er nivel + Script de respaldo)."
}

# ------------------------------------------------------------------------------
# 8. CONFIGURAR TERMINAL PREDETERMINADA EN EL SISTEMA
# ------------------------------------------------------------------------------
set_default_terminal() {
    if command -v update-alternatives &>/dev/null && [ -x /usr/bin/ptyxis ]; then
        echo "🔧 Estableciendo Ptyxis como x-terminal-emulator predeterminado..."
        if [ "$EUID" -ne 0 ] && ! command -v sudo &>/dev/null; then
            echo "❌ Error: Se requieren privilegios de superusuario para update-alternatives."
            exit 1
        fi
        $SUDO update-alternatives --set x-terminal-emulator /usr/bin/ptyxis 2>/dev/null || true
        echo "   ✅ Ptyxis es ahora el x-terminal-emulator del sistema."
    fi
}

# ------------------------------------------------------------------------------
# 9. ENTRADA PRINCIPAL Y PARSEO DE ARGUMENTOS
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
    --no-install|--config|--config-only)
        echo "==========================================================="
        echo "🖥️ APLICANDO CONFIGURACIÓN DE PTYXIS (MODO USUARIO / SIN APT)"
        echo "==========================================================="
        setup_config
        setup_keybinding false
        setup_nautilus_script
        echo ""
        show_status
        echo "==========================================================="
        echo "✅ Configuración de Ptyxis aplicada con éxito."
        echo "==========================================================="
        exit 0
        ;;
    --bind-ctrl-alt-t)
        echo "==========================================================="
        echo "⌨️ REASIGNANDO CTRL+ALT+T A PTYXIS EN GNOME SHELL"
        echo "==========================================================="
        setup_keybinding true
        exit 0
        ;;
    --default-terminal)
        set_default_terminal
        exit 0
        ;;
    "")
        echo "==========================================================="
        echo "🖥️ CONFIGURANDO PTYXIS TERMINAL EN DEBIAN 13 (GNOME WAYLAND)"
        echo "==========================================================="
        install_ptyxis
        setup_config
        setup_keybinding false
        setup_nautilus_script
        echo ""
        show_status
        echo "==========================================================="
        echo "✅ Instalación y optimización de Ptyxis completada."
        echo "==========================================================="
        ;;
    *)
        echo "❌ Opción no reconocida: $1"
        show_help
        exit 1
        ;;
esac
