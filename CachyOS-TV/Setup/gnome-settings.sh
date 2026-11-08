#!/usr/bin/env bash
# ==============================================================================
# gnome-settings.sh - Configuración y Personalización de GNOME para TV (Sony TV)
# Sistema: CachyOS (Arch Linux) | Escritorio: GNOME Shell (Wayland)
# Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / Intel HD Graphics 4600)
# ==============================================================================
# Características:
#   - Modo oscuro global forzado (prefer-dark / adw-gtk3-dark).
#   - Perfil HTPC / Salón: previene apagado de pantalla en reproducción de vídeo,
#     desactiva suspensión por inactividad, bloqueos molestos de pantalla y
#     ajusta la escala visual (1.15) para máxima legibilidad desde el sofá.
#   - Botones completos de ventana (minimizar, maximizar, cerrar).
#   - Atajos multimedia y scripts contextuales en Nautilus (Reproducir en VLC).
#   - CLI: --status / -s, --tv-mode, --dark, --help / -h.
# ==============================================================================

set -euo pipefail

# Colores ANSI
BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

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

show_help() {
    cat <<EOF
${BOLD}🎨 Personalizador de GNOME para Centro Multimedia TV (Sony TV)${NC}
${CYAN}Hardware:${NC} HP Z230 SFF Workstation (Intel Core i7-4790 / Intel HD 4600 / Sony TV 1080p)

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)    Aplica tema oscuro, perfil HTPC para salón y optimizaciones Mutter.
  --tv-mode           Ajusta energía (sin suspensión ni apagado), escala visual y centrado.
  --dark              Fuerza modo oscuro 'prefer-dark' en GTK3 y GTK4.
  -s, --status        Comprueba el estado de la configuración de GNOME.
  -h, --help          Muestra este mensaje de ayuda.
EOF
}

setup_gnome_tv() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}🎨 CONFIGURANDO ENTORNO GNOME PARA CACHYOS TV (SONY TV)${NC}"
    echo -e "${CYAN}   Equipo: HP Z230 SFF Workstation (Intel Haswell / Modo Salón)${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    echo -e "${BLUE}🌙 [1/4] Configurando Tema Oscuro Global...${NC}"
    $SUDO pacman -S --needed --noconfirm gnome-tweaks adw-gtk-theme 2>/dev/null || true

    run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || \
        run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null || true

    echo -e "${BLUE}📺 [2/4] Configurando perfil HTPC / Salón (Energía y Pantalla TV)...${NC}"
    # Desactivar suspensión automática por inactividad
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true
    
    # Desactivar apagado de pantalla por inactividad durante reproducción (idle-delay a 0)
    run_as_user gsettings set org.gnome.desktop.session idle-delay 0 2>/dev/null || true

    # Desactivar bloqueo de pantalla automático por inactividad (evita pedir clave con mando/sofá)
    run_as_user gsettings set org.gnome.desktop.screensaver lock-enabled false 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.lockdown disable-lock-screen false 2>/dev/null || true

    # Comportamiento del botón de encendido del chasis (interactivo para apagar/reiniciar limpiamente)
    run_as_user gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive' 2>/dev/null || true

    # Escala de texto aumentada (1.15) para máxima legibilidad desde el sofá
    run_as_user gsettings set org.gnome.desktop.interface text-scaling-factor 1.15 2>/dev/null || true

    # Luz nocturna suave para sesiones nocturnas en televisor
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4500 2>/dev/null || true

    echo -e "${BLUE}🪟 [3/4] Configurando gestión de ventanas y Mutter...${NC}"
    run_as_user gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close' 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true
    run_as_user gsettings set org.gnome.mutter attach-modal-dialogs true 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
    run_as_user gsettings set org.gnome.desktop.interface clock-show-date true 2>/dev/null || true

    echo -e "${BLUE}📂 [4/4] Configurando Nautilus y atajos multimedia...${NC}"
    run_as_user gsettings set org.gnome.nautilus.preferences default-folder-viewer 'grid-view' 2>/dev/null || true

    # Terminal Kitty con Ctrl+Alt+T
    run_as_user gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty' 2>/dev/null || true
    local kb_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$kb_path']" 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path name 'Kitty Terminal' 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path command 'kitty' 2>/dev/null || true
    run_as_user gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$kb_path binding '<Primary><Alt>t' 2>/dev/null || true

    # Script nativo de Nautilus para abrir en VLC con clic derecho
    local nautilus_scripts="$USER_HOME/.local/share/nautilus/scripts"
    run_as_user mkdir -p "$nautilus_scripts"
    cat << 'EOF' | run_as_user tee "$nautilus_scripts/Reproducir en VLC" > /dev/null
#!/bin/sh
flatpak run org.videolan.VLC "$@" &
EOF
    run_as_user chmod +x "$nautilus_scripts/Reproducir en VLC" 2>/dev/null || true

    echo -e "${GREEN}✅ Configuración de GNOME TV aplicada con éxito.${NC}"
}

show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}${BOLD}🔍 ESTADO DE CONFIGURACIÓN GNOME TV (CACHYOS / SONY TV)${NC}"
    echo -e "${CYAN}   Equipo: HP Z230 SFF Workstation (Sony TV / Intel Haswell)${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    local color_scheme gtk_theme idle_d text_sc lock_en susp_ac
    color_scheme=$(run_as_user gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "n/a")
    gtk_theme=$(run_as_user gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "n/a")
    idle_d=$(run_as_user gsettings get org.gnome.desktop.session idle-delay 2>/dev/null || echo "n/a")
    text_sc=$(run_as_user gsettings get org.gnome.desktop.interface text-scaling-factor 2>/dev/null || echo "n/a")
    lock_en=$(run_as_user gsettings get org.gnome.desktop.screensaver lock-enabled 2>/dev/null || echo "n/a")
    susp_ac=$(run_as_user gsettings get org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 2>/dev/null || echo "n/a")

    echo -e "• Esquema de color:     ${GREEN}$color_scheme${NC}"
    echo -e "• Tema GTK:            ${GREEN}$gtk_theme${NC}"
    echo -e "• Reposo de pantalla:   ${GREEN}$idle_d s (0 = Desactivado durante reproducción)${NC}"
    echo -e "• Bloqueo de pantalla:  ${GREEN}$lock_en${NC}"
    echo -e "• Escala visual texto:  ${GREEN}$text_sc${NC}"
    echo -e "• Suspensión AC:        ${GREEN}$susp_ac${NC}"
    echo -e "• Disposición botones:  ${GREEN}$(run_as_user gsettings get org.gnome.desktop.wm.preferences button-layout 2>/dev/null || echo "n/a")${NC}"
    echo -e "${BOLD}=================================================================${NC}"
}

case "${1:-}" in
    -s|--status|status)
        show_status
        exit 0
        ;;
    -h|--help|help)
        show_help
        exit 0
        ;;
    --tv-mode|tv)
        setup_gnome_tv
        ;;
    --dark|dark)
        run_as_user gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        run_as_user gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
        echo -e "${GREEN}✅ Modo oscuro aplicado.${NC}"
        ;;
    "")
        setup_gnome_tv
        echo ""
        show_status
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida: $1${NC}"
        show_help
        exit 1
        ;;
esac
