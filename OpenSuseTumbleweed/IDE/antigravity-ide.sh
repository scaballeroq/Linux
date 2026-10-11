#!/usr/bin/env bash
# ==============================================================================
# antigravity-ide.sh - Gestor e Instalador de Google Antigravity IDE Engine
# Optimizado para openSUSE Tumbleweed (KDE Plasma 6 Wayland)
# ==============================================================================
# Características:
#  - Comprobación de estado (--status) e inspección de versión 100% rootless.
#  - Verificación idempotente de dependencias RPM sin llamadas innecesarias a Zypper.
#  - Detección inteligente de versión: evita descargar 200MB+ si ya está al día.
#  - Helper /usr/local/bin/update-antigravity-ide modular con rollback atómico.
#  - Integración nativa con KDE Plasma 6 (Dolphin context menu, KBuildSycoca6).
#  - Permisos correctos de SUID para chrome-sandbox (4755).
#  - Opciones de estado (--status), comprobación (--check), forzado (--force) y desinstalación (--uninstall).
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
INSTALL_ROOT="/opt/antigravity-ide"
INSTALL_DIR="Antigravity-IDE"
COMMAND_LINK="/usr/local/bin/antigravity-ide"
HELPER_PATH="/usr/local/bin/update-antigravity-ide"
DESKTOP_FILE="/usr/share/applications/antigravity-ide.desktop"
ICON_FILE="/usr/share/icons/hicolor/512x512/apps/antigravity-ide.png"
PIXMAP_FILE="/usr/share/pixmaps/antigravity-ide.png"
DOWNLOAD_PAGE="https://antigravity.google/download"
KIO_SYS_FILE="/usr/share/kio/servicemenus/open-in-antigravity-ide.desktop"

# Detección de usuario real
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

KIO_USER_DIR="$USER_HOME/.local/share/kio/servicemenus"
KIO_USER_FILE="$KIO_USER_DIR/open-in-antigravity-ide.desktop"

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# Obtener versión instalada
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
    version=$(echo "$html" | grep -oP 'https://edgedl\.me\.gvt1\.com/edgedl/release2/j0qc3/antigravity/stable/\K[0-9.]+(?=-[0-9]+/linux-x64/Antigravity)' | head -n1 || true)
    if [ -n "$version" ]; then
        echo "$version"
    else
        # Fallback a versión estable conocida si falla la red
        echo "2.5.5"
    fi
}

# ------------------------------------------------------------------------------
# Verificación idempotente de dependencias
# ------------------------------------------------------------------------------
check_dependencies() {
    local pkgs=(
        ca-certificates curl tar desktop-file-utils mozilla-nss
        libatk-1_0-0 libatk-bridge-2_0-0 libcups2 libdrm2
        libxkbcommon0 libXcomposite1 libXdamage1 libXrandr2
        libgbm1 libasound2 libsecret-1-0
    )
    local missing=()
    for pkg in "${pkgs[@]}"; do
        if ! rpm -q "$pkg" &>/dev/null; then
            missing+=("$pkg")
        fi
    done
    if ! command -v python3 &>/dev/null; then
        missing+=("python313-base")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "ℹ️  ${YELLOW}Instalando paquetes requeridos con Zypper: ${missing[*]}...${NC}"
        if [ "$EUID" -ne 0 ]; then
            if ! command -v sudo &>/dev/null; then
                echo -e "${RED}❌ Error: 'sudo' no está disponible para instalar paquetes.${NC}" >&2
                exit 1
            fi
            sudo zypper --non-interactive install -y "${missing[@]}"
        else
            zypper --non-interactive install -y "${missing[@]}"
        fi
    fi
}

# ------------------------------------------------------------------------------
# Visualización del estado del sistema (--status)
# ------------------------------------------------------------------------------
show_status() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🚀 ${BOLD}Estado de Google Antigravity IDE Engine (openSUSE Tumbleweed)${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    local installed_v
    installed_v=$(get_installed_version)
    local remote_v
    remote_v=$(get_remote_version)

    echo -e "👤 ${BOLD}Usuario objetivo:${NC} $REAL_USER ($USER_HOME)"

    if [ -n "$installed_v" ] && [ -x "$INSTALL_ROOT/$INSTALL_DIR/antigravity-ide" ]; then
        echo -e "📦 ${BOLD}Estado IDE:${NC}       ${GREEN}Instalado${NC}"
        echo -e "🏷️  ${BOLD}Versión actual:${NC}   ${CYAN}v$installed_v${NC}"
    else
        echo -e "📦 ${BOLD}Estado IDE:${NC}       ${RED}No instalado${NC}"
        echo -e "🏷️  ${BOLD}Versión actual:${NC}   ${YELLOW}Ninguna${NC}"
    fi

    echo -e "🌐 ${BOLD}Última remota:${NC}    ${CYAN}v$remote_v${NC}"

    if [ -n "$installed_v" ]; then
        if [ "$installed_v" = "$remote_v" ]; then
            echo -e "✨ ${BOLD}Actualización:${NC}    ${GREEN}Al día con la versión más reciente${NC}"
        else
            echo -e "⚡ ${BOLD}Actualización:${NC}    ${YELLOW}Actualización disponible (v$installed_v -> v$remote_v)${NC}"
        fi
    fi

    echo ""
    echo -e "${BOLD}📁 Rutas y Binarios:${NC}"
    if [ -x "$INSTALL_ROOT/$INSTALL_DIR/antigravity-ide" ]; then
        echo -e "  • Binario nativo:     ${GREEN}$INSTALL_ROOT/$INSTALL_DIR/antigravity-ide${NC}"
    else
        echo -e "  • Binario nativo:     ${RED}No existe${NC}"
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
    echo -e "${BOLD}🖥️  Integración KDE Plasma 6 / Dolphin / Wayland:${NC}"
    if [ -f "$DESKTOP_FILE" ]; then
        echo -e "  • Lanzador de escritorio: ${GREEN}$DESKTOP_FILE${NC}"
    else
        echo -e "  • Lanzador de escritorio: ${RED}No presente${NC}"
    fi

    if [ -f "$ICON_FILE" ]; then
        echo -e "  • Icono de aplicación:   ${GREEN}$ICON_FILE${NC}"
    else
        echo -e "  • Icono de aplicación:   ${YELLOW}No presente${NC}"
    fi

    if [ -f "$KIO_USER_FILE" ] || [ -f "$KIO_SYS_FILE" ]; then
        echo -e "  • Menú contextual Dolphin: ${GREEN}Activo (KIO ServiceMenu)${NC}"
    else
        echo -e "  • Menú contextual Dolphin: ${YELLOW}No instalado${NC}"
    fi

    echo ""
    echo -e "${BOLD}🧩 Dependencias del sistema:${NC}"
    local pkgs=(
        ca-certificates curl tar desktop-file-utils mozilla-nss
        libatk-1_0-0 libatk-bridge-2_0-0 libcups2 libdrm2
        libxkbcommon0 libXcomposite1 libXdamage1 libXrandr2
        libgbm1 libasound2 libsecret-1-0
    )
    local missing_count=0
    for pkg in "${pkgs[@]}"; do
        if ! rpm -q "$pkg" &>/dev/null; then
            ((missing_count++)) || true
        fi
    done
    if ! command -v python3 &>/dev/null; then
        ((missing_count++)) || true
    fi

    if [ "$missing_count" -eq 0 ]; then
        echo -e "  • Dependencias base:   ${GREEN}Todas satisfechas (17 verificadas)${NC}"
    else
        echo -e "  • Dependencias base:   ${YELLOW}$missing_count paquete(s) pendientes de instalar${NC}"
    fi

    echo ""
    echo -e "${BOLD}⚙️  Configuración de Terminal en Antigravity IDE:${NC}"
    local user_settings="$USER_HOME/.config/Antigravity IDE/User/settings.json"
    if [ -f "$user_settings" ]; then
        local term_font
        term_font=$(python3 -c '
import json, sys
try:
    with open(sys.argv[1]) as f:
        print(json.load(f).get("terminal.integrated.fontFamily", "No configurada"))
except Exception:
    print("Error leyendo settings.json")
' "$user_settings" 2>/dev/null || echo "No configurada")
        echo -e "  • Archivo settings.json:  ${GREEN}$user_settings${NC}"
        echo -e "  • Fuente terminal:        ${CYAN}$term_font${NC}"
    else
        echo -e "  • Archivo settings.json:  ${YELLOW}No existe aún ($user_settings)${NC}"
    fi

    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# Generación / Actualización del Helper (/usr/local/bin/update-antigravity-ide)
# ------------------------------------------------------------------------------
generate_helper() {
    local helper_tmp
    helper_tmp=$(mktemp "${TMPDIR:-/tmp}/update-antigravity-ide.XXXXXX")
    
    cat >"$helper_tmp" <<'HELPER_EOF'
#!/usr/bin/env bash
# LinuxCapable-Managed: google-antigravity-ide-helper-v1
set -euo pipefail

download_page="https://antigravity.google/download"
install_root="/opt/antigravity-ide"
command_link="/usr/local/bin/antigravity-ide"
desktop_file="/usr/share/applications/antigravity-ide.desktop"
icon_file="/usr/share/icons/hicolor/512x512/apps/antigravity-ide.png"
pixmap_file="/usr/share/pixmaps/antigravity-ide.png"
archive_top_dir="Antigravity IDE"
install_dir="Antigravity-IDE"
managed_id="linuxcapable-antigravity-ide-v1"
root_marker="$install_root/.linuxcapable-managed"
kio_sys_file="/usr/share/kio/servicemenus/open-in-antigravity-ide.desktop"

case "$(uname -m)" in
x86_64 | amd64) platform="linux-x64" ;;
aarch64 | arm64) platform="linux-arm" ;;
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
    echo "Antigravity IDE instalada: $installed_version"
    exit 0
fi

if [ "$action" = "check" ]; then
    installed_version=$(cat "$install_root/.linuxcapable-version" 2>/dev/null || echo "")
    html=$(curl -fsSL --compressed -A "Mozilla/5.0 (X11; Linux x86_64)" --retry 2 "$download_page" 2>/dev/null || true)
    version=$(echo "$html" | grep -oP 'https://edgedl\.me\.gvt1\.com/edgedl/release2/j0qc3/antigravity/stable/\K[0-9.]+(?=-[0-9]+/linux-x64/Antigravity)' | head -n1 || true)
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
    echo "🗑️ Desinstalando Google Antigravity IDE..."
    rm -rf "$install_root"
    rm -f "$command_link" "$desktop_file" "$icon_file" "$pixmap_file" "$kio_sys_file"
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
        rm -f "$user_home/.local/share/kio/servicemenus/open-in-antigravity-ide.desktop"
    fi
    command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
    command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t -q /usr/share/icons/hicolor 2>/dev/null || true
    echo "✅ Antigravity IDE ha sido desinstalado correctamente."
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
	echo "$command_link existe y no es un symlink. Muévalo antes de continuar." >&2
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

tmpdir=$(mktemp -d /var/tmp/antigravity-ide.XXXXXX)
download_html="$tmpdir/download.html"
archive="$tmpdir/Antigravity-IDE.tar.gz"
archive_list="$tmpdir/archive-list.txt"
desktop_staged="$tmpdir/antigravity-ide-staged.desktop"
desktop_backup="$tmpdir/antigravity-ide.desktop.before"
icon_backup="$tmpdir/antigravity-ide.png.before"

if [ "$desktop_preexisting" = yes ]; then
	cp -a -- "$desktop_file" "$desktop_backup"
fi
if [ "$icon_preexisting" = yes ]; then
	cp -a -- "$icon_file" "$icon_backup"
fi

curl -fsSL --compressed --proto '=https' --proto-redir '=https' -A "Mozilla/5.0 (X11; Linux x86_64)" --retry 3 -o "$download_html" "$download_page"

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
    r"https://edgedl\.me\.gvt1\.com/edgedl/release2/j0qc3/antigravity/stable/"
    r"([0-9]+\.[0-9]+\.[0-9]+)-[0-9]+/"
    + re.escape(platform)
    + r"/Antigravity(?:%20|\s)IDE\.tar\.gz"
)
matches = []
all_urls = [urljoin(page_url, href) for href in parser.hrefs]
all_urls += re.findall(r'https?://[^\s"\'<>]+', html)

for url in all_urls:
    match = pattern.search(url)
    if match:
        clean_url = match.group(0).replace(" ", "%20")
        if clean_url not in {item[1] for item in matches}:
            matches.append((match.group(1), clean_url))

if not matches:
    raise SystemExit(f"No se encontró descarga del IDE para {platform}")

print(*matches[0], sep="\t")
PY
)

IFS=$'\t' read -r version download_url <<<"$download_fields"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
   [[ ! "$download_url" =~ ^https://edgedl\.me\.gvt1\.com/edgedl/release2/j0qc3/antigravity/stable/[0-9]+\.[0-9]+\.[0-9]+-[0-9]+/${platform}/Antigravity(%20|\ )IDE\.tar\.gz$ ]]; then
	echo "Error analizando los enlaces de descarga de Antigravity IDE." >&2
	exit 1
fi

expected_target="$install_root/$install_dir/antigravity-ide"
installed_version=$(cat "$install_root/.linuxcapable-version" 2>/dev/null || true)

# Comprobación de versión para evitar descargas redundantes si no es forzado
if [ "$force" != "yes" ] && [ -n "$installed_version" ] && [ "$installed_version" = "$version" ] && [ -x "$expected_target" ] && [ -L "$command_link" ]; then
    printf '✅ Antigravity IDE %s ya está en la última versión. No se requiere descarga.\n' "$installed_version"
    exit 0
fi

printf '⬇️ Descargando Antigravity IDE %s para %s...\n' "$version" "$platform"
curl -fsSL --proto '=https' --proto-redir '=https' --retry 3 -o "$archive" "$download_url"

tar -tzf "$archive" >"$archive_list"
top_dir=$(sed -n '1{s#/.*##;p;q}' "$archive_list")

tar --no-same-owner --no-same-permissions -xzf "$archive" -C "$tmpdir"
chmod -R a-s -- "$tmpdir/$top_dir"

cat >"$desktop_staged" <<DESKTOP
[Desktop Entry]
Name=Antigravity IDE
Comment=Google Antigravity IDE Engine
GenericName=Integrated Development Environment
Exec=$command_link %U
Icon=antigravity-ide
Terminal=false
Type=Application
Categories=Development;IDE;
MimeType=x-scheme-handler/antigravity-ide;application/x-antigravity-workspace;
StartupNotify=true
StartupWMClass=antigravity-ide
X-LinuxCapable-Managed=$managed_id
DESKTOP
desktop-file-validate "$desktop_staged"

stage_root=$(mktemp -d "${install_root}.new.XXXXXX")
chmod 0755 "$stage_root"
printf '%s\n' "$managed_id" >"$stage_root/.linuxcapable-managed"
mkdir -p "$stage_root/$install_dir"
cp -a "$tmpdir/$top_dir/." "$stage_root/$install_dir/"
chmod -R a+rX -- "$stage_root/$install_dir"
chown root:root "$stage_root/$install_dir"
chmod 0755 "$stage_root/$install_dir"
printf '%s\n' "$version" >"$stage_root/.linuxcapable-version"

# Permisos SUID para chrome-sandbox
if [ -f "$stage_root/$install_dir/chrome-sandbox" ]; then
	chown root:root "$stage_root/$install_dir/chrome-sandbox"
	chmod 4755 "$stage_root/$install_dir/chrome-sandbox"
fi

# Iconos
icon_source=""
for possible_icon in \
  "$stage_root/$install_dir/resources/app/resources/linux/code.png" \
  "$stage_root/$install_dir/antigravity-ide.png" \
  "$stage_root/$install_dir/resources/app/resources/linux/antigravity.png"; do
	if [ -f "$possible_icon" ]; then
		icon_source="$possible_icon"
		break
	fi
done

mkdir -p "$(dirname "$icon_file")"
if [ -n "$icon_source" ]; then
	install -m 0644 "$icon_source" "$icon_file"
fi
mkdir -p "$(dirname "$pixmap_file")"
if [ -f "$icon_file" ]; then
	ln -sf "$icon_file" "$pixmap_file"
fi
install -m 0644 "$desktop_staged" "$desktop_file"

# Integración con Dolphin en KDE Plasma (Sistema y Usuario)
mkdir -p "$(dirname "$kio_sys_file")"
cat <<'KIO_SYS' > "$kio_sys_file"
[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=inode/directory;
Actions=openInAntigravityIde;
X-KDE-Priority=TopLevel

[Desktop Action openInAntigravityIde]
Name=Abrir con Antigravity IDE
Name[es]=Abrir con Antigravity IDE
Name[en]=Open in Antigravity IDE
Icon=antigravity-ide
Exec=antigravity-ide "%f"
KIO_SYS
chmod 0644 "$kio_sys_file"

if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
	user_home=$(getent passwd "$SUDO_USER" | cut -d: -f6)
	kio_user_dir="$user_home/.local/share/kio/servicemenus"
	mkdir -p "$kio_user_dir"
	cp -f "$kio_sys_file" "$kio_user_dir/open-in-antigravity-ide.desktop"
	chown -R "$SUDO_USER:" "$kio_user_dir" 2>/dev/null || true
fi

# Sustitución atómica del directorio de instalación
if [ -d "$install_root" ]; then
	backup_root=$(mktemp -d "${install_root}.previous.XXXXXX")
	rmdir -- "$backup_root"
	mv -- "$install_root" "$backup_root"
fi
mv -- "$stage_root" "$install_root"
stage_root=''
new_root_installed=yes
ln -sfn "$install_root/$install_dir/antigravity-ide" "$command_link"

# Refresco de bases de datos de escritorio e iconos
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t -q /usr/share/icons/hicolor 2>/dev/null || true

committed=yes
printf '✅ Antigravity IDE %s instalado con éxito en %s\n' "$version" "$install_root/$install_dir"
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
# Configuración de Usuario (Fuentes Nerd Font en Terminal)
# ------------------------------------------------------------------------------
configure_user_settings() {
    local settings_dir="$USER_HOME/.config/Antigravity IDE/User"
    local settings_file="$settings_dir/settings.json"
    local target_font="'JetBrainsMono Nerd Font Mono', 'MesloLGS Nerd Font Mono', 'FiraCode Nerd Font Mono', monospace"

    run_as_user mkdir -p "$settings_dir"
    if [ ! -f "$settings_file" ]; then
        cat <<JSON | run_as_user tee "$settings_file" > /dev/null
{
    "security.workspace.trust.untrustedFiles": "open",
    "git.confirmSync": false,
    "git.autofetch": true,
    "terminal.integrated.fontFamily": "$target_font"
}
JSON
    else
        python3 -c '
import json, sys

path = sys.argv[1]
font = sys.argv[2]
try:
    with open(path, "r") as f:
        data = json.load(f)
except Exception:
    data = {}

if data.get("terminal.integrated.fontFamily") != font:
    data["terminal.integrated.fontFamily"] = font
    with open(path, "w") as f:
        json.dump(data, f, indent=4)
' "$settings_file" "$target_font" 2>/dev/null || true
    fi
}

# ------------------------------------------------------------------------------
# Desinstalación limpia
# ------------------------------------------------------------------------------
uninstall_ide() {
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🗑️  ${YELLOW}Desinstalando Google Antigravity IDE...${NC}"
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
        rm -f "$KIO_USER_FILE" 2>/dev/null || true
    fi

    # Refrescar caché de KDE Plasma
    if command -v kbuildsycoca6 &>/dev/null; then
        run_as_user kbuildsycoca6 --noincremental 2>/dev/null || true
    fi

    echo -e "${GREEN}✅ Antigravity IDE y sus integraciones han sido eliminados.${NC}"
    echo -e "${BOLD}=================================================================${NC}"
}

# ------------------------------------------------------------------------------
# Instalación / Actualización
# ------------------------------------------------------------------------------
install_or_update() {
    local force_flag="${1:-no}"

    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🚀 ${BOLD}Gestor de Instalación de Google Antigravity IDE Engine${NC}"
    echo -e "${BOLD}=================================================================${NC}"

    # 1. Dependencias del sistema
    echo -e "ℹ️  [1/3] Comprobando dependencias del sistema..."
    check_dependencies

    # Asegurar configuración de fuentes del usuario (JetBrains / Meslo / FiraCode Nerd Font Mono)
    configure_user_settings

    # 2. Comprobación de versión
    local installed_v
    installed_v=$(get_installed_version)
    local remote_v
    remote_v=$(get_remote_version)

    echo -e "ℹ️  [2/3] Comprobando versiones (Local: ${CYAN}v${installed_v:-ninguna}${NC} | Remota: ${CYAN}v$remote_v${NC})..."

    if [ "$force_flag" != "yes" ] && [ -n "$installed_v" ] && [ "$installed_v" = "$remote_v" ] && [ -x "$INSTALL_ROOT/$INSTALL_DIR/antigravity-ide" ] && [ -L "$COMMAND_LINK" ]; then
        echo -e "${GREEN}✨ Antigravity IDE v$installed_v ya se encuentra en su versión más reciente y configurado.${NC}"
        echo -e "💡 No se requiere descarga ni cambios con privilegios de administrador."
        echo -e "💡 Usa ${CYAN}--force${NC} para forzar la reinstalación completa."
    else
        # 3. Solo cuando se requiere instalar o actualizar se toca el helper del sistema
        echo -e "ℹ️  [3/3] Sincronizando script helper ($HELPER_PATH) y ejecutando actualización..."
        generate_helper
        if [ "$force_flag" = "yes" ]; then
            sudo "$HELPER_PATH" --force
        else
            sudo "$HELPER_PATH"
        fi
    fi

    # 4. Asegurar integración de Dolphin en KDE Plasma 6
    if [ -f "$KIO_SYS_FILE" ] && [ ! -f "$KIO_USER_FILE" ]; then
        run_as_user mkdir -p "$KIO_USER_DIR"
        run_as_user cp -f "$KIO_SYS_FILE" "$KIO_USER_FILE" 2>/dev/null || true
    fi

    # Refrescar bases de datos de escritorio y caché de KDE Plasma 6
    if command -v kbuildsycoca6 &>/dev/null; then
        run_as_user kbuildsycoca6 --noincremental 2>/dev/null || true
    fi

    echo -e "${BOLD}=================================================================${NC}"
    local launcher
    launcher=$(readlink -f "$COMMAND_LINK" || true)
    if [ -x "$launcher" ]; then
        echo -e "${GREEN}✅ Antigravity IDE Engine verificado y disponible en:${NC} $launcher"
        echo -e "💡 Ejecutable: ${BOLD}antigravity-ide${NC}"
        echo -e "💡 Dolphin: Click derecho en carpetas -> 'Abrir con Antigravity IDE'"
    else
        echo -e "${RED}❌ No se pudo verificar la instalación del binario.${NC}" >&2
        exit 1
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
    echo -e "  ${CYAN}-c, --check${NC}         Comprueba si hay actualizaciones disponibles sin instalar (exit code)"
    echo -e "  ${CYAN}-f, --force${NC}         Fuerza la descarga y reinstalación de la versión más reciente"
    echo -e "  ${CYAN}--uninstall${NC}         Desinstala Antigravity IDE y elimina accesos e integración con Dolphin"
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
            echo "Antigravity IDE está al día (v$installed_v)"
            exit 0
        else
            echo "Actualización disponible: ${installed_v:-ninguna} -> $remote_v"
            exit 1
        fi
        ;;
    uninstall)
        uninstall_ide
        ;;
    install)
        install_or_update "$FORCE"
        ;;
esac
