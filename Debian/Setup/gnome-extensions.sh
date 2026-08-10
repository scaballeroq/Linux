#!/bin/bash
# gnome-extensions.sh - Instalación automatizada de conectores y extensiones de GNOME para Debian

set -euo pipefail

echo "🧩 Iniciando instalación automatizada de extensiones de GNOME..."

# 1. Instalación de herramientas base (Browser Connector y Extension Manager)
echo "ℹ️ Instalando conector de navegador (gnome-browser-connector) y Extension Manager..."
sudo apt update
sudo apt install -y \
    gnome-browser-connector \
    extension-manager \
    python3 \
    python3-pip 2>/dev/null || true

# 2. Instalación de paquetes de extensiones desde repositorios nativos (si existen)
echo "ℹ️ Instalando paquetes nativos de extensiones de GNOME..."
sudo apt install -y \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-caffeine \
    gnome-shell-extension-dash-to-dock \
    gnome-shell-extension-dash-to-panel 2>/dev/null || true

# 3. Instalación de tus 17 extensiones personalizadas desde extensions.gnome.org (API)
echo "ℹ️ Descargando e instalando extensiones desde extensions.gnome.org..."

python3 - <<'PYEOF'
import json
import os
import subprocess
import urllib.request
import zipfile

# IDs de extensiones del usuario:
extension_ids = [
    1262,  # Bing Wallpaper Changer
    307,   # Dash to Dock
    36,    # Lock Keys
    355,   # Status Area Horizontal Spacing
    517,   # Caffeine
    5940,  # Quick Settings Audio Panel
    779,   # Clipboard Indicator
    3960,  # Transparent Top Bar - Adjustable Transparency
    3193,  # Blur my Shell
    7065,  # Tiling Shell
    615,   # AppIndicator Support
    97,    # Coverflow Alt-Tab
    6682,  # Astra Monitor
    3088,  # Extension List
    5410,  # Grand Theft Focus
    1160,  # Dash to Panel
    2087   # Desktop Icons NG (DING)
]

home_dir = os.path.expanduser("~")
target_base_dir = os.path.join(home_dir, ".local/share/gnome-shell/extensions")
os.makedirs(target_base_dir, exist_ok=True)

try:
    shell_ver_out = subprocess.check_output(["gnome-shell", "--version"]).decode("utf-8")
    shell_ver = shell_ver_out.strip().split()[-1]
    shell_major = shell_ver.split('.')[0]
except Exception:
    shell_major = "43"

print(f"ℹ️ Versión detectada de GNOME Shell: {shell_major}")

for ext_id in extension_ids:
    try:
        url = f"https://extensions.gnome.org/extension-info/?pk={ext_id}&shell_version={shell_major}"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
        
        uuid = data.get('uuid')
        dl_path = data.get('download_url')
        
        if not uuid or not dl_path:
            url_fallback = f"https://extensions.gnome.org/extension-info/?pk={ext_id}"
            req_f = urllib.request.Request(url_fallback, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req_f) as resp_f:
                data = json.loads(resp_f.read().decode('utf-8'))
            uuid = data.get('uuid')
            dl_path = data.get('download_url')
            
        if uuid and dl_path:
            ext_dest = os.path.join(target_base_dir, uuid)
            zip_url = f"https://extensions.gnome.org{dl_path}"
            tmp_zip = f"/tmp/ext_{ext_id}.zip"
            
            print(f"⬇️ Descargando extensión ID {ext_id} ({uuid})...")
            urllib.request.urlretrieve(zip_url, tmp_zip)
            
            os.makedirs(ext_dest, exist_ok=True)
            with zipfile.ZipFile(tmp_zip, 'r') as zip_ref:
                zip_ref.extractall(ext_dest)
            os.remove(tmp_zip)
            
            subprocess.run(["gnome-extensions", "enable", uuid], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print(f"✅ Extensión instalada y habilitada: {uuid}")
        else:
            print(f"⚠️ No se pudo obtener información para la extensión ID {ext_id}")
    except Exception as e:
        print(f"⚠️ Error al procesar extensión ID {ext_id}: {e}")

PYEOF

echo "================================================================="
echo "✅ Instalación de extensiones de GNOME completada."
echo "💡 Se recomienda reiniciar la sesión (cerrar e iniciar sesión) para aplicar todos los cambios visuales."
echo "================================================================="
