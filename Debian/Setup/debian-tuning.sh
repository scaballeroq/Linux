#!/bin/bash
# debian-tuning.sh - Optimizaciones de Kernel, Distrobox y Extensiones de GNOME para Debian

set -euo pipefail

echo "🚀 Iniciando optimización avanzada de Debian y GNOME..."

# 1. Ajustes de Sysctl para Desarrollo (Inotify, Map Count, Swappiness)
echo "ℹ️ Aplicando optimizaciones de kernel sysctl..."
sudo cat <<'EOF' | sudo tee /etc/sysctl.d/99-debian-dev.conf > /dev/null
# Optimizaciones de desarrollo para Debian + GNOME
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
fs.file-max = 2097152
vm.max_map_count = 16777216
vm.swappiness = 10
EOF

sudo sysctl --system > /dev/null || true

# 2. Herramientas de Desarrollo y Conector de Navegador GNOME
echo "ℹ️ Instalando Distrobox, GNOME Browser Connector y Extension Manager..."
sudo apt update
sudo apt install -y \
    distrobox \
    gnome-browser-connector \
    extension-manager \
    python3 \
    python3-pip 2>/dev/null || true

# 3. Instalación de Extensiones de GNOME desde Repositorios Nativos (si están disponibles)
echo "ℹ️ Instalando paquetes nativos de extensiones de GNOME..."
sudo apt install -y \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-caffeine \
    gnome-shell-extension-dash-to-dock \
    gnome-shell-extension-dash-to-panel 2>/dev/null || true

# 4. Instalación Automática de Extensiones desde extensions.gnome.org (API)
echo "ℹ️ Instalando extensiones personalizadas desde extensions.gnome.org..."

python3 - <<'PYEOF'
import json
import os
import subprocess
import urllib.request
import zipfile

# IDs a instalar
extension_ids = [1262, 307, 36, 355, 517, 5940, 779, 3960, 3193, 7065, 615, 97, 6682, 3088, 5410, 1160, 2087]

home_dir = os.path.expanduser("~")
target_base_dir = os.path.join(home_dir, ".local/share/gnome-shell/extensions")
os.makedirs(target_base_dir, exist_ok=True)

# Obtener versión de gnome-shell
try:
    shell_ver_out = subprocess.check_output(["gnome-shell", "--version"]).decode("utf-8")
    shell_ver = shell_ver_out.strip().split()[-1]
    shell_major = shell_ver.split('.')[0]
except Exception:
    shell_major = "43"

print(f"ℹ️ Versión detectada de GNOME Shell en Debian: {shell_major}")

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

echo "✅ Optimizaciones avanzadas de Debian y extensiones de GNOME aplicadas correctamente."
echo "💡 Se recomienda reiniciar la sesión para activar las nuevas extensiones de GNOME."
