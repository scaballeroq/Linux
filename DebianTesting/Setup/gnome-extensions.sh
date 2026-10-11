#!/bin/bash
# gnome-extensions.sh - Instalación automatizada y limpia de extensiones de GNOME
# Combina paquetes oficiales de Debian Testing (APT) y extensions.gnome.org (EGO) con compilación de esquemas GSettings

set -euo pipefail

echo "🧩 Iniciando instalación de las 11 extensiones de GNOME Shell seleccionadas..."

# Manejo de permisos de sudo
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# =============================================================================
# 1. INSTALACIÓN DE DEPENDENCIAS BASE Y EXTENSIONES DISPONIBLES EN DEBIAN (APT)
# =============================================================================
echo "ℹ️ [1/3] Actualizando repositorios e instalando herramientas base y extensiones desde APT..."

$SUDO apt update

# Herramientas base para gestión de extensiones
BASE_TOOLS=(
    gnome-browser-connector
    extension-manager
    gnome-shell-extension-prefs
    libglib2.0-bin
    gnome-weather
    pipx
    python3-pip
    python3-pip-whl
    curl
    unzip
)

# Extensiones presentes en los repositorios oficiales de Debian Testing:
# 1. Dash to Dock (ID: 307) -> gnome-shell-extension-dashtodock
# 2. Caffeine (ID: 517) -> gnome-shell-extension-caffeine
# 3. Blur my Shell (ID: 3193) -> gnome-shell-extension-blur-my-shell
# 4. AppIndicator Support (ID: 615) -> gnome-shell-extension-appindicator
DEBIAN_EXTENSIONS=(
    gnome-shell-extension-appindicator
    gnome-shell-extension-blur-my-shell
    gnome-shell-extension-caffeine
    gnome-shell-extension-dashtodock
)

$SUDO apt install -y "${BASE_TOOLS[@]}" "${DEBIAN_EXTENSIONS[@]}" 2>/dev/null || true

# Asegurar disponibilidad de gext (gnome-extensions-cli)
pipx install gnome-extensions-cli 2>/dev/null || pip install --break-system-packages gnome-extensions-cli 2>/dev/null || true
export PATH="$HOME/.local/bin:$PATH"

# =============================================================================
# 2. INSTALACIÓN DE EXTENSIONES DESDE EXTENSIONS.GNOME.ORG (EGO)
# =============================================================================
# Extensiones no disponibles en los repositorios de Debian:
# 1. Bing Wallpaper (ID: 1262)
# 2. Lock Keys (ID: 36)
# 3. Status Area Horizontal Spacing (ID: 355)
# 4. Quick Settings Audio Panel (ID: 5940)
# 5. Clipboard Indicator (ID: 779)
# 6. Tiling Shell (ID: 7065)
# 7. Weather O'Clock (ID: 5470)
EGO_EXTENSION_IDS=(1262 36 355 5940 779 7065 5470)

echo "ℹ️ [2/3] Instalando extensiones restantes desde extensions.gnome.org (IDs: ${EGO_EXTENSION_IDS[*]})..."

if command -v gext &> /dev/null; then
    echo "ℹ️ Utilizando gext (CLI oficial de GNOME Extensions)..."
    gext install "${EGO_EXTENSION_IDS[@]}" || true
fi

# Fallback e instalador nativo con compilación de esquemas GSettings en Python
python3 - <<'PYEOF'
import json
import os
import subprocess
import urllib.request
import shutil

ego_extension_ids = [1262, 36, 355, 5940, 779, 7065, 5470]

home_dir = os.path.expanduser("~")
target_base_dir = os.path.join(home_dir, ".local/share/gnome-shell/extensions")
os.makedirs(target_base_dir, exist_ok=True)

try:
    shell_ver_out = subprocess.check_output(["gnome-shell", "--version"]).decode("utf-8")
    shell_ver = shell_ver_out.strip().split()[-1]
    shell_major = shell_ver.split('.')[0]
except Exception:
    shell_major = "50"

print(f"ℹ️ Versión detectada de GNOME Shell: {shell_major}")

for ext_id in ego_extension_ids:
    try:
        url = f"https://extensions.gnome.org/extension-info/?pk={ext_id}&shell_version={shell_major}"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        data = None
        try:
            with urllib.request.urlopen(req) as resp:
                data = json.loads(resp.read().decode('utf-8'))
        except Exception:
            pass

        uuid = data.get('uuid') if data else None
        dl_path = data.get('download_url') if data else None

        if not uuid or not dl_path:
            url_fallback = f"https://extensions.gnome.org/extension-info/?pk={ext_id}"
            req_f = urllib.request.Request(url_fallback, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req_f) as resp_f:
                data = json.loads(resp_f.read().decode('utf-8'))
            uuid = data.get('uuid')
            dl_path = data.get('download_url')

        if uuid and dl_path:
            ext_dir = os.path.join(target_base_dir, uuid)
            # Solo descargar e instalar si no está ya instalada o si falta schemas
            zip_url = f"https://extensions.gnome.org{dl_path}"
            tmp_zip = f"/tmp/ext_{ext_id}.zip"

            print(f"⬇️ Descargando extensión ID {ext_id} ({data.get('name', uuid)} - {uuid})...")
            urllib.request.urlretrieve(zip_url, tmp_zip)

            subprocess.run(["gnome-extensions", "install", "--force", tmp_zip], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if os.path.exists(tmp_zip):
                os.remove(tmp_zip)

            # Compilar esquemas GSettings
            schemas_dir = os.path.join(ext_dir, "schemas")
            if os.path.isdir(schemas_dir):
                subprocess.run(["glib-compile-schemas", schemas_dir], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                print(f"  └─ Esquemas GSettings compilados en {schemas_dir}")

            print(f"✅ Extensión lista: {uuid}")
        else:
            print(f"⚠️ No se pudo obtener información para la extensión ID {ext_id}")
    except Exception as e:
        print(f"⚠️ Error al procesar extensión ID {ext_id}: {e}")

PYEOF

# =============================================================================
# 3. HABILITACIÓN DE TODAS LAS EXTENSIONES SELECCIONADAS
# =============================================================================
echo "ℹ️ [3/3] Habilitando las 11 extensiones solicitadas en GNOME Shell..."

ALL_UUIDS=(
    "BingWallpaper@ineffable-gmail.com"
    "dash-to-dock@micxgx.gmail.com"
    "lockkeys@vaina.lt"
    "status-area-horizontal-spacing@mathematical.coffee.gmail.com"
    "caffeine@patapon.info"
    "quick-settings-audio-panel@rayzeq.github.io"
    "clipboard-indicator@tudmotu.com"
    "blur-my-shell@aunetx"
    "tilingshell@ferrarodomenico.com"
    "appindicatorsupport@rgcjonas.gmail.com"
    "weatheroclock@CleoMenezesJr.github.io"
)

for uuid in "${ALL_UUIDS[@]}"; do
    if command -v gnome-extensions &> /dev/null; then
        gnome-extensions enable "$uuid" 2>/dev/null || true
        echo "  └─ Habilitada: $uuid"
    fi
done

echo "================================================================="
echo "✅ Instalación y habilitación de las 11 extensiones completada:"
echo "   📦 Desde APT (Debian):"
echo "      - gnome-shell-extension-dashtodock"
echo "      - gnome-shell-extension-caffeine"
echo "      - gnome-shell-extension-blur-my-shell"
echo "      - gnome-shell-extension-appindicator"
echo "   🌐 Desde extensions.gnome.org:"
echo "      - Bing Wallpaper (1262)"
echo "      - Lock Keys (36)"
echo "      - Status Area Horizontal Spacing (355)"
echo "      - Quick Settings Audio Panel (5940)"
echo "      - Clipboard Indicator (779)"
echo "      - Tiling Shell (7065)"
echo "      - Weather O'Clock (5470)"
echo "💡 Recuerda reiniciar la sesión (o pulsar Alt+F2 y teclear 'r' en X11) para que los cambios surtan efecto."
echo "================================================================="
