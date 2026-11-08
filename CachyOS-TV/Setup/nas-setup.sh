#!/usr/bin/env bash
# ==============================================================================
# nas-setup.sh - Integración de Almacenamiento NAS para Kodi y Reproducción Red
# Sistema: CachyOS (Arch Linux) | Escritorio: GNOME Shell (Wayland)
# Hardware: HP Z230 SFF Workstation (Intel Core i7-4790 / Sony TV)
# ==============================================================================
# Características:
#   - Instala librerías y utilidades SMB/CIFS, NFS y mDNS/Avahi en CachyOS.
#   - Habilita descubrimiento por red Zeroconf/Avahi (avahi-daemon) para que
#     Kodi y Nautilus detecten el NAS doméstico de forma instantánea.
#   - Configura reglas de cortafuegos en Firewalld (Samba, NFS, mDNS).
#   - Crea carpetas de montaje local (/mnt/nas/peliculas y /mnt/nas/series)
#     con soporte para systemd automount (_netdev,nofail,x-systemd.automount).
#   - Configura marcadores en Nautilus para acceso rápido vía interfaz gráfica.
#   - CLI: --status / -s, --install / -i, --mount / -m, --help / -h.
# ==============================================================================

set -euo pipefail

# Colores ANSI
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

# Detección de usuario real
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

show_help() {
    cat <<EOF
${BOLD}📁 Gestor de Conexión de Red a NAS para Kodi y CachyOS TV${NC}

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Instala paquetes de red, activa Avahi, configura Firewalld y crea carpetas NAS.
  -i, --install       Instala utilidades (smbclient, cifs-utils, nfs-utils, avahi) y activa servicios.
  -f, --firewall      Abre los puertos en Firewalld para descubrimiento y clientes Samba / NFS / mDNS.
  -m, --mount         Crea los puntos de montaje en /mnt/nas y plantilla de credenciales en /etc/samba/.
  -s, --status        Muestra el estado de los paquetes, servicios, puertos y puntos de montaje del NAS.
  -h, --help          Muestra este mensaje de ayuda.

Estructura de montaje creada:
  • /mnt/nas/peliculas  -> Películas en alta definición del NAS
  • /mnt/nas/series     -> Series y temporadas organizadas del NAS
EOF
}

install_nas_stack() {
    echo -e "${BLUE}📦 [1/4] Instalando utilidades de red y clientes NAS en CachyOS...${NC}"
    $SUDO pacman -S --needed --noconfirm \
        smbclient \
        cifs-utils \
        nfs-utils \
        gvfs-smb \
        avahi \
        nss-mdns 2>/dev/null || true

    echo -e "${BLUE}📡 [2/4] Habilitando servicio Avahi (mDNS/Bonjour) para descubrimiento de NAS en Kodi...${NC}"
    $SUDO systemctl enable --now avahi-daemon.service 2>/dev/null || true

    # Habilitar resolución mdns en /etc/nsswitch.conf si no está
    if [ -f /etc/nsswitch.conf ]; then
        if ! grep -q "mdns_minimal" /etc/nsswitch.conf; then
            $SUDO sed -i 's/^hosts:.*/hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns/' /etc/nsswitch.conf 2>/dev/null || true
        fi
    fi

    echo -e "${GREEN}✅ Utilidades y servicio de descubrimiento Avahi configurados.${NC}"
}

setup_firewall() {
    echo -e "${BLUE}🛡️ [3/4] Configurando cortafuegos Firewalld para acceso LAN al NAS...${NC}"
    if command -v firewall-cmd &>/dev/null; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "home")

        echo "Aplicando reglas en la zona: $active_zone"
        $SUDO firewall-cmd --zone="$active_zone" --add-service=samba-client --permanent 2>/dev/null || true
        $SUDO firewall-cmd --zone="$active_zone" --add-service=nfs --permanent 2>/dev/null || true
        $SUDO firewall-cmd --zone="$active_zone" --add-service=mdns --permanent 2>/dev/null || true
        $SUDO firewall-cmd --reload 2>/dev/null || true
        echo -e "${GREEN}✅ Puertos de red habilitados en Firewalld (samba-client, nfs, mdns).${NC}"
    else
        echo -e "${YELLOW}⚠️ firewall-cmd no detectado. Omitiendo reglas de cortafuegos.${NC}"
    fi
}

setup_mount_points() {
    echo -e "${BLUE}📁 [4/4] Creando directorios locales de montaje para Kodi...${NC}"
    $SUDO mkdir -p /mnt/nas/peliculas /mnt/nas/series
    $SUDO chmod -R 775 /mnt/nas
    $SUDO chown -R "$REAL_USER:$REAL_USER" /mnt/nas 2>/dev/null || true

    # Crear plantilla de credenciales SMB segura
    $SUDO mkdir -p /etc/samba
    if [ ! -f /etc/samba/credentials-nas.sample ]; then
        $SUDO tee /etc/samba/credentials-nas.sample > /dev/null << 'EOF'
# Plantilla de credenciales para montaje SMB/CIFS de tu NAS
# Para activar:
# 1. Copia este archivo a /etc/samba/credentials-nas:
#    sudo cp /etc/samba/credentials-nas.sample /etc/samba/credentials-nas
#    sudo chmod 600 /etc/samba/credentials-nas
# 2. Rellena tu usuario y contraseña del NAS:
username=tu_usuario_nas
password=tu_contraseña_nas
# domain=WORKGROUP (opcional)
EOF
        $SUDO chmod 600 /etc/samba/credentials-nas.sample
    fi

    # Generar snippet de ejemplo para fstab con automount diferido
    if [ ! -f /etc/samba/fstab-nas.example ]; then
        $SUDO tee /etc/samba/fstab-nas.example > /dev/null << 'EOF'
# Líneas de ejemplo para agregar a /etc/fstab (reemplaza 'IP_O_NOMBRE_NAS'):
# //IP_O_NOMBRE_NAS/Peliculas  /mnt/nas/peliculas  cifs  credentials=/etc/samba/credentials-nas,iocharset=utf8,uid=1000,gid=1000,_netdev,nofail,x-systemd.automount,x-systemd.idle-timeout=60  0  0
# //IP_O_NOMBRE_NAS/Series     /mnt/nas/series     cifs  credentials=/etc/samba/credentials-nas,iocharset=utf8,uid=1000,gid=1000,_netdev,nofail,x-systemd.automount,x-systemd.idle-timeout=60  0  0
EOF
    fi

    # Marcadores en Nautilus para acceso rápido en la interfaz gráfica
    local gtk_bookmarks="$USER_HOME/.config/gtk-3.0/bookmarks"
    run_as_user mkdir -p "$USER_HOME/.config/gtk-3.0"
    if [ -f "$gtk_bookmarks" ]; then
        if ! grep -q "file:///mnt/nas" "$gtk_bookmarks"; then
            echo "file:///mnt/nas/peliculas Películas (NAS)" >> "$gtk_bookmarks"
            echo "file:///mnt/nas/series Series (NAS)" >> "$gtk_bookmarks"
        fi
    else
        run_as_user tee "$gtk_bookmarks" > /dev/null << 'EOF'
file:///mnt/nas/peliculas Películas (NAS)
file:///mnt/nas/series Series (NAS)
EOF
    fi

    echo -e "${GREEN}✅ Carpetas /mnt/nas creadas y marcadores agregados a Nautilus.${NC}"
}

show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "${CYAN}${BOLD}🔍 ESTADO DE CONEXIÓN A RED Y NAS (KODI & CACHYOS TV)${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    echo -e "• Paquetes cliente NAS en CachyOS:"
    for pkg in "smbclient" "cifs-utils" "nfs-utils" "gvfs-smb" "avahi"; do
        if pacman -Qq "$pkg" &>/dev/null; then
            echo -e "  - $pkg: ${GREEN}✅ Instalado${NC}"
        else
            echo -e "  - $pkg: ${RED}❌ No instalado${NC}"
        fi
    done

    echo -e "-----------------------------------------------------------------"
    echo -e "• Servicio mDNS (Avahi) para auto-descubrimiento en Kodi:"
    if systemctl is-active avahi-daemon.service &>/dev/null; then
        echo -e "  - avahi-daemon: ${GREEN}✅ Activo y en ejecución${NC}"
    else
        echo -e "  - avahi-daemon: ${RED}❌ Inactivo${NC}"
    fi

    echo -e "-----------------------------------------------------------------"
    echo -e "• Cortafuegos Firewalld:"
    if command -v firewall-cmd &>/dev/null; then
        local active_zone
        active_zone=$(firewall-cmd --get-default-zone 2>/dev/null || echo "home")
        echo -e "  - Zona activa: $active_zone"
        for srv in "samba-client" "nfs" "mdns"; do
            if firewall-cmd --zone="$active_zone" --query-service="$srv" 2>/dev/null; then
                echo -e "  - Servicio $srv: ${GREEN}✅ Abierto${NC}"
            else
                echo -e "  - Servicio $srv: ${YELLOW}⚠️ Cerrado${NC}"
            fi
        done
    else
        echo -e "  - firewalld: ${RED}❌ No detectado${NC}"
    fi

    echo -e "-----------------------------------------------------------------"
    echo -e "• Puntos de montaje locales para películas y series:"
    for d in "/mnt/nas/peliculas" "/mnt/nas/series"; do
        if [ -d "$d" ]; then
            if mountpoint -q "$d" 2>/dev/null; then
                echo -e "  - $d: ${GREEN}✅ Montado y activo ($(df -h "$d" | tail -n1 | awk '{print $2 " total, " $4 " libre"}'))${NC}"
            else
                echo -e "  - $d: ${YELLOW}⚪ Directorio presente (No montado actualmente)${NC}"
            fi
        else
            echo -e "  - $d: ${RED}❌ Directorio no existe${NC}"
        fi
    done

    echo -e "-----------------------------------------------------------------"
    echo -e "• Integración en Kodi:"
    if command -v kodi &>/dev/null; then
        echo -e "  - Kodi nativo: ${GREEN}✅ Listo para escanear recursos SMB / NFS / /mnt/nas${NC}"
    else
        echo -e "  - Kodi nativo: ${YELLOW}⚠️ No instalado aún${NC}"
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
        install_nas_stack
        ;;
    -f|--firewall|firewall)
        setup_firewall
        ;;
    -m|--mount|mount)
        setup_mount_points
        ;;
    "")
        install_nas_stack
        setup_firewall
        setup_mount_points
        echo ""
        show_status
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida: $1${NC}"
        show_help
        exit 1
        ;;
esac
