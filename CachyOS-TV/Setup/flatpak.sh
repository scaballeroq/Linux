#!/usr/bin/env bash
# ==============================================================================
# flatpak.sh - Instalación, Gestión y Diagnóstico de Software Flatpak
# Sistema: CachyOS (Arch Linux) | Escritorio: GNOME Shell (Wayland)
# Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / Intel HD Graphics 4600)
# Pantalla: Sony TV (Centro Multimedia HTPC: Stremio, VLC, Kodi)
# ==============================================================================

set -euo pipefail

FLATPAK_BIN="/usr/bin/flatpak"
FLATHUB_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"

# Colores ANSI para terminal
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

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
${BOLD}📦 Gestor de Flatpaks Multimedia - CachyOS TV (HP Z230 SFF)${NC}

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Verifica Flatpak, registra Flathub, instala apps multimedia y aplica overrides.
  -i, --install       Instala las aplicaciones multimedia esenciales (Stremio, VLC).
  -o, --overrides     Aplica permisos y aceleración VA-API para Intel Haswell en Flatpaks.
  -u, --update        Actualiza todos los Flatpaks instalados.
  -c, --clean         Elimina runtimes y paquetes Flatpak no utilizados para liberar espacio.
  -s, --status        Muestra diagnóstico del estado de Flatpak, Flathub y aplicaciones.
  -h, --help          Muestra este mensaje de ayuda.
EOF
}

setup_flatpak_base() {
    echo -e "${BLUE}ℹ️ Verificando soporte base de Flatpak en CachyOS...${NC}"
    if ! command -v flatpak &>/dev/null; then
        echo "Instalando paquete flatpak..."
        $SUDO pacman -S --needed --noconfirm flatpak
    fi

    echo -e "${BLUE}ℹ️ Registrando repositorio oficial Flathub...${NC}"
    run_as_user flatpak remote-add --if-not-exists flathub "$FLATHUB_URL" 2>/dev/null || true
    echo -e "${GREEN}✅ Flathub registrado correctamente.${NC}"
}

install_media_apps() {
    setup_flatpak_base
    echo -e "${BLUE}⬇️ Instalando aplicaciones multimedia vía Flatpak...${NC}"
    
    local apps=(
        "com.stremio.Stremio"
        "org.videolan.VLC"
        "com.github.tchx84.Flatseal"
    )

    for app in "${apps[@]}"; do
        if run_as_user flatpak list --app | grep -qi "$app"; then
            echo -e "  - $app: ${GREEN}Ya instalado${NC}"
        else
            echo -e "  - Instalando $app..."
            run_as_user flatpak install -y flathub "$app" 2>/dev/null || true
        fi
    done
    apply_overrides
}

apply_overrides() {
    echo -e "${BLUE}⚙️ Aplicando permisos de hardware y aceleración GPU (Intel Haswell i965)...${NC}"
    
    # Overrides globales de tema
    run_as_user flatpak override --user --filesystem=xdg-config/gtk-3.0:ro 2>/dev/null || true
    run_as_user flatpak override --user --filesystem=xdg-config/gtk-4.0:ro 2>/dev/null || true
    run_as_user flatpak override --user --device=dri 2>/dev/null || true

    # Stremio: Aceleración GPU OpenGL, driver VA-API Haswell i965 y bypass de Vulkan obsoleto
    run_as_user flatpak override --user \
        --device=dri \
        --socket=wayland \
        --socket=pulseaudio \
        --filesystem=xdg-run/pipewire-0 \
        --talk-name=org.freedesktop.Flatpak \
        --env=VK_DRIVER_FILES=/dev/null \
        --env=VK_ICD_FILENAMES=/dev/null \
        --env=GSK_RENDERER=gl \
        --env=LIBVA_DRIVER_NAME=i965 \
        com.stremio.Stremio 2>/dev/null || true

    # VLC: Acceso DRI y PipeWire
    run_as_user flatpak override --user \
        --device=dri \
        --socket=wayland \
        --socket=pulseaudio \
        --filesystem=xdg-run/pipewire-0 \
        org.videolan.VLC 2>/dev/null || true

    # Perfil mpv.conf para Stremio Flatpak
    local stremio_mpv_dir="${USER_HOME}/.var/app/com.stremio.Stremio/config/mpv"
    if [ -d "${USER_HOME}/.var/app/com.stremio.Stremio" ]; then
        run_as_user mkdir -p "$stremio_mpv_dir"
        cat <<'EOF' | run_as_user tee "$stremio_mpv_dir/mpv.conf" > /dev/null
# Configuración optimizada para Stremio en Sony TV (HDMI Estéreo Haswell)
ao=pulse
audio-channels=stereo
audio-samplerate=48000
audio-format=s16
audio-buffer=0.2
audio-normalize-downmix=yes
volume-max=100
hwdec=vaapi
EOF
    fi

    echo -e "${GREEN}✅ Overrides de aceleración gráfica y audio para Flatpaks aplicados.${NC}"
}

update_flatpaks() {
    echo -e "${BLUE}🔄 Actualizando paquetes Flatpak...${NC}"
    run_as_user flatpak update -y
    echo -e "${GREEN}✅ Paquetes Flatpak actualizados.${NC}"
}

clean_flatpaks() {
    echo -e "${BLUE}🧹 Liberando espacio de disco en SSD (eliminando runtimes sin uso)...${NC}"
    run_as_user flatpak uninstall --unused -y 2>/dev/null || true
    echo -e "${GREEN}✅ Limpieza de Flatpak completada.${NC}"
}

show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}${BOLD}🔍 DIAGNÓSTICO FLATPAK - CACHYOS TV (HP Z230 SFF)${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    if command -v flatpak &>/dev/null; then
        echo -e "• Flatpak:           ${GREEN}✅ Instalado ($(flatpak --version))${NC}"
    else
        echo -e "• Flatpak:           ${RED}❌ No instalado${NC}"
        return
    fi

    if flatpak remotes 2>/dev/null | grep -qi "flathub"; then
        echo -e "• Repositorio Flathub:${GREEN}✅ Activo y registrado${NC}"
    else
        echo -e "• Repositorio Flathub:${RED}❌ No configurado${NC}"
    fi

    echo -e "-----------------------------------------------------------------"
    echo -e "• Aplicaciones Multimedia Flatpak:"
    for app in "com.stremio.Stremio" "org.videolan.VLC" "com.github.tchx84.Flatseal"; do
        if run_as_user flatpak list --app 2>/dev/null | grep -qi "$app"; then
            echo -e "  - $app: ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  - $app: ${YELLOW}⚪ No instalado${NC}"
        fi
    done

    echo -e "-----------------------------------------------------------------"
    echo -e "• Overrides activos para Stremio:"
    if [ -f "$USER_HOME/.local/share/flatpak/overrides/com.stremio.Stremio" ]; then
        echo -e "  ${GREEN}✅ Presentes en ~/.local/share/flatpak/overrides/com.stremio.Stremio${NC}"
    elif [ -f "/var/lib/flatpak/overrides/com.stremio.Stremio" ]; then
        echo -e "  ${GREEN}✅ Presentes en /var/lib/flatpak/overrides/com.stremio.Stremio${NC}"
    else
        echo -e "  ${YELLOW}⚠️ No detectados (ejecuta '$0 --overrides')${NC}"
    fi
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
    -i|--install|install)
        install_media_apps
        ;;
    -o|--overrides|overrides)
        apply_overrides
        ;;
    -u|--update|update)
        update_flatpaks
        ;;
    -c|--clean|clean)
        clean_flatpaks
        ;;
    "")
        setup_flatpak_base
        install_media_apps
        apply_overrides
        echo ""
        show_status
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida: $1${NC}"
        show_help
        exit 1
        ;;
esac
