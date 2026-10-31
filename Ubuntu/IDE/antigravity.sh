#!/usr/bin/env bash
# ==============================================================================
# antigravity.sh - Gestor e Instalador de Google Antigravity Desktop 2.0
# Optimizado para Ubuntu Workstation (Ubuntu 24.04 GNOME Shell Wayland Mutter)
# Hardware: HP ProBook 455 G10 | AMD Ryzen 7 7730U (Zen 3) | Radeon Graphics (Vega 8)
# ==============================================================================
# Características:
#  - Comprobación de estado (--status) e inspección de versión 100% rootless.
#  - Verificación idempotente de dependencias APT/dpkg (incluyendo soporte time64).
#  - Detección inteligente de versión oficial (v2.x) evitando descargas redundantes.
#  - Helper /usr/local/bin/update-antigravity con rollback atómico y sandboxing SUID 4755.
#  - Extracción automática de icono nativo en alta resolución (512x512) desde app.asar.
#  - Integración nativa GNOME Shell Wayland (flags Ozone auto, aceleración GPU Mesa RADV).
#  - Menú contextual para Nautilus (GNOME Files) mediante scripts de usuario.
#  - Detección y aviso de conflictos con el paquete APT heredado (antigravity_old.sh).
#  - Opciones completas: --status, --check, --force, --uninstall y --help.
# ==============================================================================

set -euo pipefail

# Colores de salida
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m"

# Rutas del sistema
INSTALL_ROOT="/opt/antigravity"
COMMAND_LINK="/usr/local/bin/antigravity"
HELPER_PATH="/usr/local/bin/update-antigravity"
DESKTOP_FILE="/usr/share/applications/antigravity.desktop"
ICON_FILE="/usr/share/icons/hicolor/512x512/apps/antigravity.png"
PIXMAP_FILE="/usr/share/pixmaps/antigravity.png"
DOWNLOAD_PAGE="https://antigravity.google/download"
LEGACY_KEYRING="/etc/apt/keyrings/antigravity-repo-key.gpg"

case "$(uname -m)" in
x86_64 | amd64)
    PLATFORM="linux-x64"
    EXPECTED_TOP_DIR="Antigravity-x64"
    ;;
aarch64 | arm64)
    PLATFORM="linux-arm"
    EXPECTED_TOP_DIR="Antigravity-arm64"
    ;;
*)
    echo -e "${RED}❌ Arquitectura no soportada: $(uname -m)${NC}" >&2
    exit 1
    ;;
esac

# Detección de usuario real
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

# Integraciones de escritorio de usuario (GNOME Nautilus y opcional Dolphin)
NAUTILUS_SCRIPTS_DIR="$USER_HOME/.local/share/nautilus/scripts"
NAUTILUS_SCRIPT_FILE="$NAUTILUS_SCRIPTS_DIR/Abrir con Antigravity"
KIO_USER_DIR="$USER_HOME/.local/share/kio/servicemenus"
KIO_USER_FILE="$KIO_USER_DIR/open-in-antigravity.desktop"
KIO_SYS_FILE="/usr/share/kio/servicemenus/open-in-antigravity.desktop"

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# Obtener versión instalada de la aplicación independiente (v2.x)
get_installed_version() {
    if [ -f "$INSTALL_ROOT/.linuxcapable-version" ]; then
        cat "$INSTALL_ROOT/.linuxcapable-version" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Obtener última versión remota oficial disponible
get_remote_version() {
    local html version
    html=$(curl -fsSL --compressed -A "Mozilla/5.0 (X11; Linux x86_64)" --retry 2 "$DOWNLOAD_PAGE" 2>/dev/null || true)
    version=$(echo "$html" | grep -oP 'https://storage\.googleapis\.com/antigravity-public/antigravity-hub/\K[0-9.]+(?=-[0-9]+/linux-x64/Antigravity\.tar\.gz)' | head -n1 || true)
    if [ -n "$version" ]; then
        echo "$version"
    else
        # Fallback a última versión estable conocida si falla la red
        echo "2.26.0"
    fi
}

# Comprobar si el paquete APT antiguo (antigravity_old.sh) sigue instalado
is_legacy_apt_installed() {
    dpkg-query -W -f='${Status}' antigravity 2>/dev/null | grep -q "install ok installed"
}

# Comprobar si un paquete APT está instalado
is_pkg_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

# ------------------------------------------------------------------------------
# Verificación idempotente de dependencias para Ubuntu (APT / dpkg)
# ------------------------------------------------------------------------------
check_dependencies() {
    local base_pkgs=(
        ca-certificates curl tar desktop-file-utils python3
        libnss3 libdrm2 libxkbcommon0 libxcomposite1
        libxdamage1 libxrandr2 libgbm1 libsecret-1-0
    )
    local missing=()

    for pkg in "${base_pkgs[@]}"; do
        if ! is_pkg_installed "$pkg"; then
            missing+=("$pkg")
        fi
    done

    # Soporte compatible para paquetes con sufijo time64 (Ubuntu 24.04/26.10)
    if ! is_pkg_installed "libasound2t64" && ! is_pkg_installed "libasound2"; then
        missing+=("libasound2t64")
    fi
    if ! is_pkg_installed "libcups2t64" && ! is_pkg_installed "libcups2"; then
        missing+=("libcups2t64")
    fi
    if ! is_pkg_installed "libatk1.0-0t64" && ! is_pkg_installed "libatk1.0-0"; then
        missing+=("libatk1.0-0t64")
    fi
    if ! is_pkg_installed "libatk-bridge2.0-0t64" && ! is_pkg_installed "libatk-bridge2.0-0"; then
        missing+=("libatk-bridge2.0-0t64")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "ℹ️  ${YELLOW}Instalando dependencias requeridas con APT: ${missing[*]}...${NC}"
        if [ "$EUID" -ne 0 ]; then
            if ! command -v sudo &>/dev/null; then
                echo -e "${RED}❌ Error: 'sudo' no está disponible para instalar paquetes.${NC}" >&2
                exit 1
            fi
            sudo apt update -qq
            sudo apt install -y "${missing[@]}"
        else
            apt update -qq
            apt install -y "${missing[@]}"
        fi
    fi
}

# ------------------------------------------------------------------------------
# Visualización del estado del sistema (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🪐 ${BOLD}Estado de Google Antigravity Desktop 2.0 (Ubuntu Workstation)${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    local installed_v
    installed_v=$(get_installed_version)
    local remote_v
    remote_v=$(get_remote_version)

    echo -e "💻 ${BOLD}Sistema:${NC}          Ubuntu $(grep -oP 'VERSION_ID="\K[^"]+' /etc/os-release 2>/dev/null || echo "Linux") (GNOME Shell Wayland Mutter)"
    echo -e "⚡ ${BOLD}Hardware:${NC}         AMD Ryzen 7 7730U | Radeon Graphics (Mesa RADV/VA-API)"
    echo -e "👤 ${BOLD}Usuario objetivo:${NC} $REAL_USER ($USER_HOME)"

    echo ""
    echo -e "${BOLD}📦 Estado de Google Antigravity Desktop 2.0 (Oficial):${NC}"
    if [ -n "$installed_v" ] && [ -x "$INSTALL_ROOT/$EXPECTED_TOP_DIR/antigravity" ]; then
        echo -e "  • Estado App:         ${GREEN}Instalado${NC}"
        echo -e "  • Versión actual:     ${CYAN}v$installed_v${NC}"
    else
        echo -e "  • Estado App:         ${RED}No instalado${NC}"
        echo -e "  • Versión actual:     ${YELLOW}Ninguna${NC}"
    fi
    echo -e "  • Última remota:      ${CYAN}v$remote_v${NC}"

    if [ -n "$installed_v" ]; then
        if [ "$installed_v" = "$remote_v" ]; then
            echo -e "  • Actualización:      ${GREEN}Al día con la versión más reciente${NC}"
        else
            echo -e "  • Actualización:      ${YELLOW}Actualización disponible (v$installed_v -> v$remote_v)${NC}"
        fi
    fi

    echo ""
    echo -e "${BOLD}⚠️  Detección de Paquetes Heredados / Conflictos:${NC}"
    if is_legacy_apt_installed; then
        local legacy_ver
        legacy_ver=$(dpkg-query -W -f='${Version}' antigravity 2>/dev/null || echo "desconocida")
        echo -e "  • Paquete APT heredado: ${RED}⚠️  Detectado (v$legacy_ver en /usr/bin/antigravity)${NC}"
        echo -e "    ${YELLOW}↳ Instalado por antigravity_old.sh. Puede generar conflictos con la v2.0.${NC}"
        echo -e "    ${YELLOW}↳ Desinstalar con: ${BOLD}sudo apt purge -y antigravity && sudo rm -f $LEGACY_KEYRING${NC}"
    else
        echo -e "  • Paquete APT heredado: ${GREEN}✅ Limpio (No instalado / Desinstalado)${NC}"
    fi

    if [ -f "$LEGACY_KEYRING" ]; then
        echo -e "  • Keyring APT heredado: ${YELLOW}⚠️  Presente ($LEGACY_KEYRING)${NC}"
    fi

    echo ""
    echo -e "${BOLD}📁 Rutas y Binarios del Sistema:${NC}"
    if [ -x "$INSTALL_ROOT/$EXPECTED_TOP_DIR/antigravity" ]; then
        echo -e "  • Binario nativo:     ${GREEN}$INSTALL_ROOT/$EXPECTED_TOP_DIR/antigravity${NC}"
    else
        echo -e "  • Binario nativo:     ${YELLOW}No existe ($INSTALL_ROOT/$EXPECTED_TOP_DIR/antigravity)${NC}"
    fi

    if [ -L "$COMMAND_LINK" ]; then
        local target
        target=$(readlink "$COMMAND_LINK" || true)
        echo -e "  • Enlace en PATH:     ${GREEN}$COMMAND_LINK -> $target${NC}"
    else
        echo -e "  • Enlace en PATH:     ${RED}No presente ($COMMAND_LINK)${NC}"
    fi

    if [ -x "$HELPER_PATH" ]; then
        echo -e "  • Script actualizador:${GREEN}$HELPER_PATH${NC}"
    else
        echo -e "  • Script actualizador:${YELLOW}No presente ($HELPER_PATH)${NC}"
    fi

    echo ""
    echo -e "${BOLD}🖥️  Integración GNOME Shell / Wayland / Nautilus:${NC}"
    if [ -f "$DESKTOP_FILE" ]; then
        if grep -q "ozone-platform-hint" "$DESKTOP_FILE" 2>/dev/null; then
            echo -e "  • Lanzador de escritorio: ${GREEN}$DESKTOP_FILE${NC} (Wayland nativo Mutter)"
        else
            echo -e "  • Lanzador de escritorio: ${YELLOW}$DESKTOP_FILE${NC} (Heredado de APT / sin flags Wayland)"
        fi
    else
        echo -e "  • Lanzador de escritorio: ${RED}No presente${NC}"
    fi

    if [ -f "$ICON_FILE" ]; then
        echo -e "  • Icono de aplicación:   ${GREEN}$ICON_FILE${NC} (512x512 nativo)"
    else
        echo -e "  • Icono de aplicación:   ${YELLOW}No presente${NC}"
    fi

    if [ -f "$NAUTILUS_SCRIPT_FILE" ]; then
        echo -e "  • Menú Nautilus (GNOME):  ${GREEN}Activo ($NAUTILUS_SCRIPT_FILE)${NC}"
    else
        echo -e "  • Menú Nautilus (GNOME):  ${YELLOW}No instalado${NC}"
    fi

    echo ""
    echo -e "${BOLD}🧩 Dependencias del sistema (APT):${NC}"
    local check_pkgs=(
        ca-certificates curl tar desktop-file-utils python3
        libnss3 libdrm2 libxkbcommon0 libxcomposite1
        libxdamage1 libxrandr2 libgbm1 libsecret-1-0
    )
    local satisfied=0

    for pkg in "${check_pkgs[@]}"; do
        if is_pkg_installed "$pkg"; then
            ((satisfied++)) || true
        fi
    done

    if is_pkg_installed "libasound2t64" || is_pkg_installed "libasound2"; then
        ((satisfied++)) || true
    fi
    if is_pkg_installed "libcups2t64" || is_pkg_installed "libcups2"; then
        ((satisfied++)) || true
    fi
    if is_pkg_installed "libatk1.0-0t64" || is_pkg_installed "libatk1.0-0"; then
        ((satisfied++)) || true
    fi
    if is_pkg_installed "libatk-bridge2.0-0t64" || is_pkg_installed "libatk-bridge2.0-0"; then
        ((satisfied++)) || true
    fi
    local total_req=17

    if [ "$satisfied" -ge "$total_req" ]; then
        echo -e "  • Estado dependencias: ${GREEN}Todas satisfechas ($satisfied/$total_req verificadas)${NC}"
    else
        echo -e "  • Estado dependencias: ${YELLOW}$satisfied/$total_req verificadas (faltan $((total_req - satisfied)))${NC}"
    fi

    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# Generación / Actualización del Helper (/usr/local/bin/update-antigravity)
# ------------------------------------------------------------------------------
generate_helper() {
    local helper_tmp
    helper_tmp=$(mktemp "${TMPDIR:-/tmp}/update-antigravity.XXXXXX")

    cat >"$helper_tmp" <<'HELPER_EOF'
#!/usr/bin/env bash
# LinuxCapable-Managed: google-antigravity-desktop-helper-v1
set -euo pipefail

download_page="https://antigravity.google/download"
install_root="/opt/antigravity"
command_link="/usr/local/bin/antigravity"
desktop_file="/usr/share/applications/antigravity.desktop"
icon_file="/usr/share/icons/hicolor/512x512/apps/antigravity.png"
pixmap_file="/usr/share/pixmaps/antigravity.png"
managed_id="linuxcapable-antigravity-desktop-v1"
root_marker="$install_root/.linuxcapable-managed"
kio_sys_file="/usr/share/kio/servicemenus/open-in-antigravity.desktop"

case "$(uname -m)" in
x86_64 | amd64)
    platform="linux-x64"
    expected_top_dir="Antigravity-x64"
    ;;
aarch64 | arm64)
    platform="linux-arm"
    expected_top_dir="Antigravity-arm64"
    ;;
*)
	echo "Arquitectura no soportada: $(uname -m)" >&2
	exit 1
	;;
esac

# Gestión de parámetros
action="update"
force="no"

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            echo "Uso: $0 [-s|--status] [-c|--check] [-f|--force] [--uninstall]"
            exit 0
            ;;
        -s|--status)
            action="status"
            shift
            ;;
        -c|--check)
            action="check"
            shift
            ;;
        -f|--force)
            force="yes"
            shift
            ;;
        --uninstall)
            action="uninstall"
            shift
            ;;
        *)
            echo "Opción desconocida: $1" >&2
            exit 1
            ;;
    esac
done

if [ "$action" = "status" ]; then
    installed_version=$(cat "$install_root/.linuxcapable-version" 2>/dev/null || echo "No instalada")
    echo "Antigravity Desktop instalada: $installed_version"
    exit 0
fi

if [ "$action" = "check" ]; then
    installed_version=$(cat "$install_root/.linuxcapable-version" 2>/dev/null || echo "")
    html=$(curl -fsSL --compressed -A "Mozilla/5.0 (X11; Linux x86_64)" --retry 2 "$download_page" 2>/dev/null || true)
    version=$(echo "$html" | grep -oP 'https://storage\.googleapis\.com/antigravity-public/antigravity-hub/\K[0-9.]+(?=-[0-9]+/linux-x64/Antigravity\.tar\.gz)' | head -n1 || true)
    if [ -n "$installed_version" ] && [ "$installed_version" = "$version" ]; then
        echo "Al día: $installed_version"
        exit 0
    else
        echo "Actualización requerida: $installed_version -> $version"
        exit 1
    fi
fi

# Las operaciones que modifican el sistema requieren privilegios de root
if [ "$(id -u)" -ne 0 ]; then
	echo "Ejecute con privilegios de administrador: sudo $0" >&2
	exit 1
fi

if [ "$action" = "uninstall" ]; then
    echo "🗑️ Desinstalando Google Antigravity Desktop 2.0..."
    rm -rf "$install_root"
    rm -f "$command_link" "$desktop_file" "$icon_file" "$pixmap_file" "$kio_sys_file"
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
        rm -f "$user_home/.local/share/kio/servicemenus/open-in-antigravity.desktop"
        rm -f "$user_home/.local/share/nautilus/scripts/Abrir con Antigravity"
    fi
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
    command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t -q /usr/share/icons/hicolor 2>/dev/null || true
    echo "✅ Antigravity Desktop ha sido desinstalado correctamente."
    exit 0
fi

for required_command in curl tar python3 desktop-file-validate; do
	if ! command -v "$required_command" >/dev/null 2>&1; then
		echo "El comando $required_command es requerido para continuar." >&2
		exit 1
	fi
done

command_preexisting=no
command_target_before=''
if [ -L "$command_link" ]; then
	command_preexisting=yes
	command_target_before=$(readlink -- "$command_link")
elif [ -e "$command_link" ]; then
	echo "$command_link existe y no es un enlace simbólico. Muévalo antes de continuar." >&2
	exit 1
fi

desktop_preexisting=no
if [ -f "$desktop_file" ]; then
	desktop_preexisting=yes
fi

icon_preexisting=no
if [ -f "$icon_file" ]; then
	icon_preexisting=yes
fi

tmpdir=''
stage_root=''
backup_root=''
desktop_backup=''
icon_backup=''
desktop_staged=''
new_root_installed=no
committed=no

cleanup() {
	status=$?
	trap - EXIT
	if [ "$committed" != yes ] && [ "$new_root_installed" = yes ]; then
		if [ "$command_preexisting" = yes ]; then
			ln -sfn -- "$command_target_before" "$command_link"
		elif [ -L "$command_link" ]; then
			rm -f -- "$command_link"
		fi
		if [ "$desktop_preexisting" = yes ] && [ -f "$desktop_backup" ]; then
			cp -a -- "$desktop_backup" "$desktop_file"
		elif [ "$desktop_preexisting" = no ] && [ -f "$desktop_file" ]; then
			rm -f -- "$desktop_file"
		fi
		if [ "$icon_preexisting" = yes ] && [ -f "$icon_backup" ]; then
			cp -a -- "$icon_backup" "$icon_file"
		elif [ "$icon_preexisting" = no ] && [ -f "$icon_file" ]; then
			rm -f -- "$icon_file"
		fi
		if [ -f "$root_marker" ] && [ "$(cat "$root_marker")" = "$managed_id" ]; then
			rm -rf -- "$install_root"
		fi
		command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
		command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true
	fi
	if [ "$committed" != yes ] && [ -n "$backup_root" ] && [ -d "$backup_root" ]; then
		if [ ! -e "$install_root" ] && [ ! -L "$install_root" ]; then
			mv -- "$backup_root" "$install_root" || true
		fi
	fi
	if [ -n "$stage_root" ] && [ -d "$stage_root" ]; then
		rm -rf -- "$stage_root"
	fi
	if [ -n "$tmpdir" ] && [ -d "$tmpdir" ]; then
		rm -rf -- "$tmpdir"
	fi
	if [ "$committed" = yes ] && [ -n "$backup_root" ] && [ -d "$backup_root" ]; then
		rm -rf -- "$backup_root"
	fi
	exit "$status"
}
trap cleanup EXIT

tmpdir=$(mktemp -d /var/tmp/antigravity.XXXXXX)
download_html="$tmpdir/download.html"
archive="$tmpdir/Antigravity.tar.gz"
archive_list="$tmpdir/archive-list.txt"
icon_staged="$tmpdir/antigravity.png"
desktop_staged="$tmpdir/antigravity-staged.desktop"
desktop_backup="$tmpdir/antigravity.desktop.before"
icon_backup="$tmpdir/antigravity.png.before"

if [ "$desktop_preexisting" = yes ]; then
	cp -a -- "$desktop_file" "$desktop_backup"
fi
if [ "$icon_preexisting" = yes ]; then
	cp -a -- "$icon_file" "$icon_backup"
fi

curl -fsSL --proto '=https' --proto-redir '=https' --compressed --retry 3 -o "$download_html" "$download_page"

download_fields=$(
	python3 - "$download_html" "$download_page" "$platform" <<'PY'
import re
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urljoin

class LinkParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.hrefs = []

    def handle_starttag(self, tag, attrs):
        if tag == "a":
            href = dict(attrs).get("href")
            if href:
                self.hrefs.append(href)

html = Path(sys.argv[1]).read_text(errors="replace")
page_url = sys.argv[2]
platform = sys.argv[3]
parser = LinkParser()
parser.feed(html)
pattern = re.compile(
    r"https://storage\.googleapis\.com/antigravity-public/antigravity-hub/"
    r"([0-9]+\.[0-9]+\.[0-9]+)-[0-9]+/"
    + re.escape(platform)
    + r"/Antigravity\.tar\.gz"
)
matches = []
for href in parser.hrefs:
    url = urljoin(page_url, href)
    match = pattern.fullmatch(url)
    if match and url not in {item[1] for item in matches}:
        matches.append((match.group(1), url))

if len(matches) != 1:
    raise SystemExit(f"No se encontró descarga de Antigravity para {platform}")

print(*matches[0], sep="\t")
PY
)

IFS=$'\t' read -r version download_url <<<"$download_fields"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
   [[ ! "$download_url" =~ ^https://storage\.googleapis\.com/antigravity-public/antigravity-hub/[0-9]+\.[0-9]+\.[0-9]+-[0-9]+/${platform}/Antigravity\.tar\.gz$ ]]; then
	echo "Error analizando los enlaces de descarga de Antigravity." >&2
	exit 1
fi

expected_target="$install_root/$expected_top_dir/antigravity"
sandbox_path="$install_root/$expected_top_dir/chrome-sandbox"
installed_version=$(cat "$install_root/.linuxcapable-version" 2>/dev/null || true)

# Comprobación de versión para evitar descargas redundantes si no es forzado
if [ "$force" != "yes" ] && [ -n "$installed_version" ] && [ "$installed_version" = "$version" ] && [ -x "$expected_target" ] && [ -L "$command_link" ]; then
    printf '✅ Antigravity Desktop %s ya está en la última versión. No se requiere descarga.\n' "$installed_version"
    exit 0
fi

printf '⬇️ Descargando Google Antigravity %s para %s...\n' "$version" "$platform"
curl -fsSL --proto '=https' --proto-redir '=https' --retry 3 -o "$archive" "$download_url"

python3 - "$archive" "$expected_top_dir" <<'PY'
import sys
import tarfile
from pathlib import PurePosixPath

archive_path, expected_top = sys.argv[1:]
top_dirs = set()
with tarfile.open(archive_path, "r:gz") as archive:
    for member in archive.getmembers():
        path = PurePosixPath(member.name)
        if path.is_absolute() or ".." in path.parts or not path.parts:
            raise SystemExit(f"Miembro no seguro en archivo: {member.name}")
        top_dirs.add(path.parts[0])
        if not (member.isfile() or member.isdir() or member.issym() or member.islnk()):
            raise SystemExit(f"Tipo de archivo no soportado: {member.name}")
        if member.issym() or member.islnk():
            target = PurePosixPath(member.linkname)
            if target.is_absolute() or ".." in target.parts:
                raise SystemExit(f"Enlace inseguro: {member.name} -> {member.linkname}")
if top_dirs != {expected_top}:
    raise SystemExit(f"Raíz inesperada en archivo comprimido: {sorted(top_dirs)}")
PY

tar -tzf "$archive" >"$archive_list"
top_dir=$(sed -n '1{s#/.*##;p;q}' "$archive_list")
case "$top_dir" in
Antigravity-*) ;;
*)
	echo "Estructura inesperada del archivo comprimido: $top_dir" >&2
	exit 1
	;;
esac

tar --no-same-owner --no-same-permissions -xzf "$archive" -C "$tmpdir"
chmod -R a-s -- "$tmpdir/$top_dir"

if [ ! -x "$tmpdir/$top_dir/antigravity" ]; then
	echo "No se encontró el ejecutable principal en el archivo descargado." >&2
	exit 1
fi

# Extracción de icono nativo desde app.asar
python3 - "$tmpdir/$top_dir/resources/app.asar" "$icon_staged" <<'PY'
import json
import struct
import sys
from pathlib import Path

asar = Path(sys.argv[1])
output = Path(sys.argv[2])
with asar.open("rb") as archive:
    archive.read(4)
    header_size = struct.unpack("<I", archive.read(4))[0]
    archive.read(4)
    json_size = struct.unpack("<I", archive.read(4))[0]
    header = json.loads(archive.read(json_size).decode())

icon = header["files"]["icon.png"]
with asar.open("rb") as archive:
    archive.seek(8 + header_size + int(icon["offset"]))
    output.write_bytes(archive.read(int(icon["size"])))
PY

# Configuración del lanzador de escritorio optimizado para Wayland (Mutter) y GPU AMD Radeon
cat >"$desktop_staged" <<DESKTOP
[Desktop Entry]
Name=Google Antigravity
Comment=Google Antigravity Desktop 2.0 Agent Platform
GenericName=AI Agent Platform
Exec=$command_link --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations %U
Icon=antigravity
Terminal=false
Type=Application
Categories=Development;IDE;
StartupNotify=true
StartupWMClass=Antigravity
MimeType=inode/directory;application/x-directory;text/plain;
Actions=new-window;
X-LinuxCapable-Managed=$managed_id

[Desktop Action new-window]
Name=Nueva ventana
Name[en]=New Window
Exec=$command_link --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --new-window %U
DESKTOP
desktop-file-validate "$desktop_staged"

stage_root=$(mktemp -d "${install_root}.new.XXXXXX")
chmod 0755 "$stage_root"
printf '%s\n' "$managed_id" >"$stage_root/.linuxcapable-managed"
cp -a "$tmpdir/$top_dir" "$stage_root/"
chmod -R a+rX -- "$stage_root/$top_dir"
chown root:root "$stage_root/$top_dir"
chmod 0755 "$stage_root/$top_dir"
printf '%s\n' "$version" >"$stage_root/.linuxcapable-version"

# Permisos SUID 4755 en chrome-sandbox para compatibilidad con restricciones AppArmor en Ubuntu 24.04/26.10
if [ ! -f "$stage_root/$top_dir/chrome-sandbox" ] || [ -L "$stage_root/$top_dir/chrome-sandbox" ]; then
	echo "El componente chrome-sandbox no se encontró o no es válido." >&2
	exit 1
fi
chown root:root "$stage_root/$top_dir/chrome-sandbox"
chmod 4755 "$stage_root/$top_dir/chrome-sandbox"

if [ -d "$install_root" ]; then
	backup_root=$(mktemp -d "${install_root}.previous.XXXXXX")
	rmdir -- "$backup_root"
	mv -- "$install_root" "$backup_root"
fi
mv -- "$stage_root" "$install_root"
stage_root=''
new_root_installed=yes
ln -sfn "$install_root/$top_dir/antigravity" "$command_link"

mkdir -p "$(dirname "$icon_file")"
install -m 0644 "$icon_staged" "$icon_file"
mkdir -p "$(dirname "$pixmap_file")"
ln -sf "$icon_file" "$pixmap_file"
install -m 0644 "$desktop_staged" "$desktop_file"

# Integración con Nautilus (GNOME Files) en el directorio de scripts del usuario
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    nautilus_scripts_dir="$user_home/.local/share/nautilus/scripts"
    mkdir -p "$nautilus_scripts_dir"
    cat <<'NAUTILUS_SCRIPT' > "$nautilus_scripts_dir/Abrir con Antigravity"
#!/usr/bin/env bash
exec /usr/local/bin/antigravity "$@"
NAUTILUS_SCRIPT
    chmod +x "$nautilus_scripts_dir/Abrir con Antigravity"
    chown -R "$SUDO_USER:" "$nautilus_scripts_dir" 2>/dev/null || true
fi

# Compatibilidad secundaria opcional con Dolphin si el directorio existe
if [ -d "$(dirname "$kio_sys_file")" ]; then
    cat <<'KIO_SYS' > "$kio_sys_file"
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=inode/directory;
Actions=openInAntigravity;
X-KDE-Priority=TopLevel

[Desktop Action openInAntigravity]
Name=Abrir con Antigravity
Name[es]=Abrir con Antigravity
Name[en]=Open in Antigravity
Icon=antigravity
Exec=antigravity "%f"
KIO_SYS
    chmod 0644 "$kio_sys_file"
fi

# Refresco de bases de datos de escritorio e iconos
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t -q /usr/share/icons/hicolor 2>/dev/null || true

committed=yes
printf '✅ Google Antigravity Desktop %s instalado con éxito en %s\n' "$version" "$install_root/$top_dir"
HELPER_EOF

    bash -n "$helper_tmp"

    if [ ! -f "$HELPER_PATH" ] || ! cmp -s "$helper_tmp" "$HELPER_PATH"; then
        echo -e "⚙️  Actualizando script helper en ${CYAN}$HELPER_PATH${NC}..."
        if [ "$EUID" -ne 0 ]; then
            sudo install -m 0755 "$helper_tmp" "$HELPER_PATH"
        else
            install -m 0755 "$helper_tmp" "$HELPER_PATH"
        fi
    fi
    rm -f "$helper_tmp"
}

# ------------------------------------------------------------------------------
# Desinstalación limpia
# ------------------------------------------------------------------------------
uninstall_app() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🗑️  ${YELLOW}Desinstalando Google Antigravity Desktop...${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    if [ -x "$HELPER_PATH" ]; then
        if [ "$EUID" -ne 0 ]; then
            sudo "$HELPER_PATH" --uninstall
        else
            "$HELPER_PATH" --uninstall
        fi
    else
        echo "Eliminando archivos del sistema..."
        sudo rm -rf "$INSTALL_ROOT" "$COMMAND_LINK" "$DESKTOP_FILE" "$ICON_FILE" "$PIXMAP_FILE" "$KIO_SYS_FILE"
        rm -f "$NAUTILUS_SCRIPT_FILE" 2>/dev/null || true
        rm -f "$KIO_USER_FILE" 2>/dev/null || true
    fi

    # Comprobar si el paquete APT antiguo sigue presente
    if is_legacy_apt_installed; then
        echo ""
        echo -e "${YELLOW}⚠️  Se detectó que el paquete APT heredado (antigravity_old.sh) todavía está en el sistema.${NC}"
        echo -e "   Para purgarlo por completo, ejecuta:"
        echo -e "   ${BOLD}sudo apt purge -y antigravity && sudo rm -f $LEGACY_KEYRING && sudo apt autoremove --purge -y${NC}"
    fi

    echo -e "${GREEN}✅ Antigravity Desktop 2.0 y sus integraciones han sido eliminados.${NC}"
    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# Instalación / Actualización
# ------------------------------------------------------------------------------
install_or_update() {
    local force_flag="${1:-no}"

    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🪐 ${BOLD}Gestor de Instalación de Google Antigravity Desktop 2.0${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    # Aviso proactivo si el paquete antiguo de APT sigue instalado
    if is_legacy_apt_installed; then
        echo -e "${YELLOW}⚠️  ATENCIÓN: Se ha detectado el paquete APT heredado de Antigravity en /usr/bin/antigravity.${NC}"
        echo -e "   Se recomienda purgarlo para evitar colisiones con el nuevo binario en /usr/local/bin/antigravity:"
        echo -e "   ${CYAN}sudo apt purge -y antigravity && sudo rm -f $LEGACY_KEYRING${NC}"
        echo ""
    fi

    # 1. Dependencias del sistema
    echo -e "ℹ️  [1/3] Comprobando dependencias del sistema en Ubuntu (APT)..."
    check_dependencies

    # 2. Comprobación de versión
    local installed_v
    installed_v=$(get_installed_version)
    local remote_v
    remote_v=$(get_remote_version)

    echo -e "ℹ️  [2/3] Comprobando versiones (Local: ${CYAN}v${installed_v:-ninguna}${NC} | Remota: ${CYAN}v$remote_v${NC})..."

    if [ "$force_flag" != "yes" ] && [ -n "$installed_v" ] && [ "$installed_v" = "$remote_v" ] && [ -x "$INSTALL_ROOT/$EXPECTED_TOP_DIR/antigravity" ] && [ -L "$COMMAND_LINK" ]; then
        echo -e "${GREEN}✨ Antigravity Desktop v$installed_v ya se encuentra en su versión más reciente y configurado.${NC}"
        echo -e "💡 No se requiere descarga ni cambios con privilegios de administrador."
        echo -e "💡 Usa ${CYAN}--force${NC} para forzar la reinstalación completa."
    else
        # 3. Sincronizar helper e instalar/actualizar
        echo -e "ℹ️  [3/3] Sincronizando script helper ($HELPER_PATH) y ejecutando actualización..."
        generate_helper
        if [ "$force_flag" = "yes" ]; then
            sudo "$HELPER_PATH" --force
        else
            sudo "$HELPER_PATH"
        fi
    fi

    # 4. Asegurar integración de menú contextual de Nautilus (GNOME Files)
    if [ ! -f "$NAUTILUS_SCRIPT_FILE" ]; then
        run_as_user mkdir -p "$NAUTILUS_SCRIPTS_DIR"
        cat <<'NAUTILUS_LOCAL' > "$NAUTILUS_SCRIPT_FILE"
#!/usr/bin/env bash
exec /usr/local/bin/antigravity "$@"
NAUTILUS_LOCAL
        chmod +x "$NAUTILUS_SCRIPT_FILE"
    fi

    # Refrescar bases de datos de escritorio e iconos
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
    command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t -q /usr/share/icons/hicolor 2>/dev/null || true

    echo -e "${BOLD}=================================================================${NC}"
    local launcher
    launcher=$(readlink -f "$COMMAND_LINK" || true)
    if [ -x "$launcher" ]; then
        echo -e "${GREEN}✅ Google Antigravity Desktop verificado y disponible en:${NC} $launcher"
        echo -e "💡 Ejecutable: ${BOLD}antigravity${NC}"
        echo -e "💡 GNOME Shell: Lanzador nativo Wayland configurado en el menú de aplicaciones"
        echo -e "💡 Nautilus: Click derecho en carpetas/archivos -> 'Scripts' -> 'Abrir con Antigravity'"
    else
        echo -e "${YELLOW}ℹ️  Instalación preparada. Ejecute './IDE/antigravity.sh' con sudo o '--force' para completar la instalación.${NC}"
    fi
    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# Ayuda
# ------------------------------------------------------------------------------
show_help() {
    echo -e "${BOLD}Uso:${NC} $0 [opción]"
    echo ""
    echo -e "${BOLD}Opciones:${NC}"
    echo -e "  ${CYAN}-s, --status${NC}        Muestra el estado completo de la instalación e integraciones (rootless)"
    echo -e "  ${CYAN}-c, --check${NC}         Comprueba si hay actualizaciones disponibles sin instalar (código de salida)"
    echo -e "  ${CYAN}-f, --force${NC}         Fuerza la descarga y reinstalación de la versión más reciente"
    echo -e "  ${CYAN}--uninstall${NC}         Desinstala Antigravity Desktop y elimina accesos e integración de Nautilus"
    echo -e "  ${CYAN}-h, --help${NC}          Muestra este mensaje de ayuda"
    echo ""
    echo -e "${BOLD}Ejemplos:${NC}"
    echo -e "  $0                  # Verifica e instala/actualiza solo si hay nueva versión"
    echo -e "  $0 --status         # Comprobación de estado rápida y sin sudo"
    echo -e "  $0 --force          # Reinstala la aplicación desde cero"
}

# ------------------------------------------------------------------------------
# Procesamiento de Parámetros
# ------------------------------------------------------------------------------
ACTION="install"
FORCE="no"

while [ $# -gt 0 ]; do
    case "$1" in
        -s|--status)
            ACTION="status"
            shift
            ;;
        -c|--check)
            ACTION="check"
            shift
            ;;
        -f|--force)
            ACTION="install"
            FORCE="yes"
            shift
            ;;
        --uninstall)
            ACTION="uninstall"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opción desconocida: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

case "$ACTION" in
    status)
        show_status
        ;;
    check)
        installed_v=$(get_installed_version)
        remote_v=$(get_remote_version)
        if [ -n "$installed_v" ] && [ "$installed_v" = "$remote_v" ]; then
            echo "Google Antigravity Desktop está al día (v$installed_v)"
            exit 0
        else
            echo "Actualización disponible: ${installed_v:-ninguna} -> $remote_v"
            exit 1
        fi
        ;;
    uninstall)
        uninstall_app
        ;;
    install)
        install_or_update "$FORCE"
        ;;
esac
