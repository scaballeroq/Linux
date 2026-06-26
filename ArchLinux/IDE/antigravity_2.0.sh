#!/bin/bash
# antigravity_2.0.sh - Instalación de Google Antigravity 2.0 (Binario)

set -e

SCRIPT_PATH=""
if [ -n "${BASH_SOURCE[0]}" ]; then
    SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || readlink -f "${BASH_SOURCE[0]}")"
fi

echo "ℹ️ Instalando dependencias necesarias..."
sudo pacman -S --noconfirm curl tar desktop-file-utils python

INSTALL_ROOT="/opt/antigravity"
COMMAND_LINK="/usr/local/bin/antigravity"
DESKTOP_FILE="/usr/share/applications/antigravity.desktop"
ICON_FILE="/usr/share/icons/hicolor/512x512/apps/antigravity.png"
DOWNLOAD_PAGE="https://antigravity.google/download"

case "$(uname -m)" in
    x86_64 | amd64)  PLATFORM="linux-x64"; TOP_DIR_NAME="Antigravity-x64" ;;
    aarch64 | arm64) PLATFORM="linux-arm"; TOP_DIR_NAME="Antigravity-arm64" ;;
    *) echo "❌ Arquitectura no soportada: $(uname -m)"; exit 1 ;;
esac

echo "ℹ️ Buscando la última versión de Antigravity 2.0..."

TMPDIR=$(mktemp -d /tmp/antigravity.XXXXXX)
trap 'rm -rf "$TMPDIR"' EXIT

DOWNLOAD_HTML="$TMPDIR/download.html"
curl -fsSL --compressed -o "$DOWNLOAD_HTML" "$DOWNLOAD_PAGE"

MAIN_JS_URL=$(python3 - "$DOWNLOAD_HTML" "$DOWNLOAD_PAGE" <<'PY'
import re, sys
from pathlib import Path
from urllib.parse import urljoin
html = Path(sys.argv[1]).read_text()
page_url = sys.argv[2]
matches = re.findall(r'(?:src|href)="([^"]*main-[^"]+\.js)"', html)
if not matches: sys.exit(1)
print(urljoin(page_url, matches[-1]))
PY
)

if [ -z "$MAIN_JS_URL" ]; then
    echo "❌ No se pudo encontrar el bundle de descarga."
    exit 1
fi

DOWNLOAD_JS="$TMPDIR/download.js"
curl -fsSL --compressed -o "$DOWNLOAD_JS" "$MAIN_JS_URL"

DOWNLOAD_FIELDS=$(python3 - "$DOWNLOAD_JS" "$PLATFORM" <<'PY'
import re, sys
from pathlib import Path
bundle = Path(sys.argv[1]).read_text(errors="replace")
platform = sys.argv[2]
start = bundle.find('id:"antigravity-2"')
end = bundle.find('},{name:"command",id:"antigravity-cli"', start)
if start == -1 or end == -1: sys.exit(1)
section = bundle[start:end]
match = re.search(r'href:"([^"]+/' + re.escape(platform) + r'/Antigravity\.tar\.gz)"', section)
if not match: sys.exit(1)
url = match.group(1)
version_match = re.search(r'/antigravity-hub/([^/]+)/', url)
version = version_match.group(1).split("-", 1)[0] if version_match else "unknown"
print(version, url)
PY
)

read -r VERSION DOWNLOAD_URL <<< "$DOWNLOAD_FIELDS"

if [ -f "$INSTALL_ROOT/.version" ] && [ "$(cat "$INSTALL_ROOT/.version")" = "$VERSION" ]; then
    echo "✅ Antigravity $VERSION ya está actualizado."
    if [ -n "$SCRIPT_PATH" ] && [ -f "$SCRIPT_PATH" ] && [ "$SCRIPT_PATH" != "/usr/local/bin/update-antigravity" ]; then
        echo "ℹ️ Asegurando registro del script de actualización global..."
        sudo cp "$SCRIPT_PATH" /usr/local/bin/update-antigravity
        sudo chmod +x /usr/local/bin/update-antigravity
    fi
    exit 0
fi

echo "ℹ️ Descargando Antigravity $VERSION ($PLATFORM)..."
ARCHIVE="$TMPDIR/Antigravity.tar.gz"
curl -fsSL -o "$ARCHIVE" "$DOWNLOAD_URL"

echo "ℹ️ Extrayendo archivos..."
tar -xzf "$ARCHIVE" -C "$TMPDIR"

ICON_STAGED="$TMPDIR/antigravity.png"
python3 - "$TMPDIR/$TOP_DIR_NAME/resources/app.asar" "$ICON_STAGED" <<'PY'
import json, struct, sys
from pathlib import Path
asar = Path(sys.argv[1])
output = Path(sys.argv[2])
with asar.open("rb") as f:
    f.read(4)
    h_size = struct.unpack("<I", f.read(4))[0]
    f.read(4)
    j_size = struct.unpack("<I", f.read(4))[0]
    header = json.loads(f.read(j_size).decode())
icon = header["files"]["icon.png"]
with asar.open("rb") as f:
    f.seek(8 + h_size + int(icon["offset"]))
    output.write_bytes(f.read(int(icon["size"])))
PY

sudo rm -rf "${INSTALL_ROOT}.new"
sudo mkdir -p "${INSTALL_ROOT}.new"
sudo cp -a "$TMPDIR/$TOP_DIR_NAME/." "${INSTALL_ROOT}.new/"
echo "$VERSION" | sudo tee "${INSTALL_ROOT}.new/.version" > /dev/null

if [ -d "$INSTALL_ROOT" ]; then
    sudo rm -rf "${INSTALL_ROOT}.old"
    sudo mv "$INSTALL_ROOT" "${INSTALL_ROOT}.old"
fi
sudo mv "${INSTALL_ROOT}.new" "$INSTALL_ROOT"

sudo ln -sfn "$INSTALL_ROOT/antigravity" "$COMMAND_LINK"

sudo mkdir -p "$(dirname "$ICON_FILE")"
sudo install -m 0644 "$ICON_STAGED" "$ICON_FILE"

if [ -n "$SCRIPT_PATH" ] && [ -f "$SCRIPT_PATH" ] && [ "$SCRIPT_PATH" != "/usr/local/bin/update-antigravity" ]; then
    echo "ℹ️ Registrando script de actualización global..."
    sudo cp "$SCRIPT_PATH" /usr/local/bin/update-antigravity
    sudo chmod +x /usr/local/bin/update-antigravity
fi

echo "ℹ️ Creando acceso directo de escritorio..."
sudo tee "$DESKTOP_FILE" > /dev/null <<EOF
[Desktop Entry]
Name=Antigravity
Comment=Google Antigravity 2.0 agent platform
Exec=$COMMAND_LINK %U
Icon=antigravity
Terminal=false
Type=Application
Categories=Development;IDE;
StartupNotify=true
StartupWMClass=Antigravity
EOF

if command -v update-desktop-database &>/dev/null; then
    sudo update-desktop-database /usr/share/applications &>/dev/null || true
fi

if command -v gtk-update-icon-cache &>/dev/null; then
    sudo gtk-update-icon-cache -q /usr/share/icons/hicolor &>/dev/null || true
fi

echo "🔍 Verificando instalación..."
readlink -f "$COMMAND_LINK"
test -x "$(readlink -f "$COMMAND_LINK")" && echo "✅ El lanzador es ejecutable."

echo "ℹ️  Propiedades del archivo .desktop:"
grep -E '^(Name|Exec|Icon|Categories|StartupWMClass)=' "$DESKTOP_FILE"

test -f "$ICON_FILE" && echo "✅ Icono verificado en el sistema."

echo "✅ Google Antigravity $VERSION instalado correctamente."
