#!/usr/bin/env bash
# ==============================================================================
# kitty.sh - Configuración Estética de Kitty Terminal para NixOS
# Entorno: KDE Plasma 6 (Wayland) + Modo Oscuro Catppuccin Mocha
# ==============================================================================

set -euo pipefail

# Detectar usuario real
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

show_help() {
    cat <<EOF
🐱 Configuración de Kitty Terminal - NixOS (KDE Plasma 6)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Genera configuración estética Catppuccin Mocha, atajo Ctrl+Alt+T y Dolphin servicemenu.
  --status, -s        Verifica el estado de Kitty y su configuración.
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE KITTY TERMINAL - NIXOS"
    echo "================================================================="
    echo -n "• Binario kitty: "
    if command -v kitty &>/dev/null; then
        echo "✅ $(kitty --version 2>/dev/null || echo 'instalado')"
    else
        echo "❌ No encontrado en PATH (está declarado en modules/development.nix)"
    fi

    echo -n "• Archivo kitty.conf: "
    if [ -f "$USER_HOME/.config/kitty/kitty.conf" ]; then
        echo "✅ Presente"
    else
        echo "❌ Ausente"
    fi

    echo -n "• Dolphin servicemenu: "
    if [ -f "$USER_HOME/.local/share/kio/servicemenus/open-in-kitty.desktop" ]; then
        echo "✅ Activo"
    else
        echo "❌ No registrado"
    fi
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "🐱 CONFIGURANDO KITTY TERMINAL (NIXOS + KDE PLASMA 6)"
echo "================================================================="

KITTY_CONF_DIR="$USER_HOME/.config/kitty"
mkdir -p "$KITTY_CONF_DIR"

echo "ℹ️ [1/3] Generando ~/.config/kitty/kitty.conf con tema Catppuccin Mocha..."
cat << 'EOF' > "$KITTY_CONF_DIR/kitty.conf"
# =============================================================================
# KITTY CONFIGURATION - NIXOS (KDE Plasma 6 Wayland)
# =============================================================================

# Tipografía
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
font_size        11.0

# Transparencia y Desenfoque Wayland
background_opacity 0.85
background_blur 32

# Cursor
cursor_shape beam
cursor_beam_thickness 1.5
cursor_blink_interval 0.5

# Ventana y Espaciado
window_padding_width 10
hide_window_decorations no
confirm_os_window_close 0

# Audio Bell
enable_audio_bell no

# Tema Catppuccin Mocha
foreground              #cdd6f4
background              #1e1e2e
selection_foreground    #1e1e2e
selection_background    #f5e0dc

# Colores estándar
# Negro
color0 #45475a
color8 #585b70
# Rojo
color1 #f38ba8
color9 #f38ba8
# Verde
color2  #a6e3a1
color10 #a6e3a1
# Amarillo
color3  #f9e2af
color11 #f9e2af
# Azul
color4  #89b4fa
color12 #89b4fa
# Magenta
color5  #f5c2e7
color13 #f5c2e7
# Cyan
color6  #94e2d5
color14 #94e2d5
# Blanco
color7  #bac2de
color15 #a6adc8

# Atajos de copia y pegado
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
EOF

chown -R "$REAL_USER:" "$KITTY_CONF_DIR" 2>/dev/null || true

# 2. Servicemenu Dolphin
echo "ℹ️ [2/3] Configurando servicemenu en Dolphin..."
mkdir -p "$USER_HOME/.local/share/kio/servicemenus"
cat << 'EOF' > "$USER_HOME/.local/share/kio/servicemenus/open-in-kitty.desktop"
[Desktop Entry]
Type=Service
MimeType=inode/directory;
Actions=openInKitty;
X-KDE-Priority=TopLevel
Icon=kitty

[Desktop Action openInKitty]
Name=Abrir en Kitty
Name[en]=Open in Kitty
Icon=kitty
Exec=kitty --directory "%f"
EOF
chown -R "$REAL_USER:" "$USER_HOME/.local/share/kio/servicemenus" 2>/dev/null || true

# 3. Atajo global Ctrl+Alt+T
echo "ℹ️ [3/3] Registrando atajo de teclado Ctrl+Alt+T en KDE..."
run_as_user kwriteconfig6 --file "$USER_HOME/.config/kglobalshortcutsrc" --group "kitty.desktop" --key "_launch" "Ctrl+Alt+T,Ctrl+Alt+T,Lanzar kitty" 2>/dev/null || true

echo "================================================================="
echo "✅ Kitty Terminal configurada correctamente."
echo "================================================================="
