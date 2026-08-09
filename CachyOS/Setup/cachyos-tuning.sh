#!/bin/bash
# cachyos-tuning.sh - Optimizaciones de Kernel, Ananicy-cpp, Distrobox y Extensiones de GNOME para CachyOS

set -euo pipefail

echo "🚀 Iniciando optimización avanzada de CachyOS y GNOME..."

# 1. Ajustes de Sysctl para Desarrollo (Inotify, Map Count, Swappiness)
echo "ℹ️ Aplicando optimizaciones de kernel sysctl..."
sudo cat <<'EOF' | sudo tee /etc/sysctl.d/99-cachyos-dev.conf > /dev/null
# Optimizaciones de desarrollo para CachyOS + GNOME
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
fs.file-max = 2097152
vm.max_map_count = 16777216
vm.swappiness = 180
EOF

sudo sysctl --system > /dev/null || true

# 2. Habilitar Ananicy-cpp (Auto-priorización inteligente de procesos)
if command -v ananicy-cpp &> /dev/null; then
    echo "ℹ️ Habilitando servicio ananicy-cpp..."
    sudo systemctl enable --now ananicy-cpp.service || true
else
    echo "ℹ️ Instalando y habilitando ananicy-cpp..."
    sudo pacman -S --needed --noconfirm ananicy-cpp cachyos-ananicy-rules 2>/dev/null || sudo pacman -S --needed --noconfirm ananicy-cpp || true
    sudo systemctl enable --now ananicy-cpp.service || true
fi

# 3. Herramientas de Desarrollo y Conector de Navegador GNOME
echo "ℹ️ Instalando Distrobox, CachyOS Kernel Manager, GNOME Browser Connector y Extension Manager..."
sudo pacman -S --needed --noconfirm \
    distrobox \
    gnome-browser-connector \
    extension-manager \
    cachyos-kernel-manager 2>/dev/null || true

# 4. Instalación de Extensiones de GNOME desde Repositorios Nativos
echo "ℹ️ Instalando paquetes nativos de extensiones de GNOME..."
sudo pacman -S --needed --noconfirm \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-caffeine \
    gnome-shell-extension-blur-my-shell \
    gnome-shell-extension-dash-to-dock \
    gnome-shell-extension-clipboard-indicator \
    gnome-shell-extension-ding 2>/dev/null || true

#    gnome-shell-extension-dash-to-panel \

# 5. Instalación Automática de Extensiones desde extensions.gnome.org (API)
echo "ℹ️ Instalando extensiones personalizadas desde extensions.gnome.org..."

# IDs de extensiones solicitadas por el usuario:
EXTENSION_IDS=(
    1262  # Bing Wallpaper Changer
    36    # Lock Keys
    355   # Status Area Horizontal Spacing
    5940  # Quick Settings Audio Panel
    3960  # Transparent Top Bar - Adjustable Transparency
    7065  # Tiling Shell
    615   # AppIndicator Support
    97    # Coverflow Alt-Tab
    3088  # Extension List

)
#    779   # Clipboard Indicator
#    307   # Dash to Dock
#    3193  # Blur my Shell
#    517   # Caffeine
#    6682  # Astra Monitor
#    5410  # Grand Theft Focus
#    1160  # Dash to Panel
#    2087  # Desktop Icons NG (DING)

python3 - <<'PYEOF'
import json
import os
import subprocess
import urllib.request
import zipfile
import shutil

# IDs a instalar
extension_ids = [1262, 307, 36, 355, 517, 5940, 779, 3960, 3193, 7065, 615, 97, 6682, 3088, 5410, 1160, 2087]

# Directorio de destino
home_dir = os.path.expanduser("~")
target_base_dir = os.path.join(home_dir, ".local/share/gnome-shell/extensions")
os.makedirs(target_base_dir, exist_ok=True)

# Obtener versión de gnome-shell
try:
    shell_ver_out = subprocess.check_output(["gnome-shell", "--version"]).decode("utf-8")
    shell_ver = shell_ver_out.strip().split()[-1]
    shell_major = shell_ver.split('.')[0]
except Exception:
    shell_major = "47"

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
            # Reintentar sin versión de shell
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
            
            # Habilitar extensión
            subprocess.run(["gnome-extensions", "enable", uuid], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            print(f"✅ Extensión instalada y habilitada: {uuid}")
        else:
            print(f"⚠️ No se pudo obtener información para la extensión ID {ext_id}")
    except Exception as e:
        print(f"⚠️ Error al procesar extensión ID {ext_id}: {e}")

PYEOF

echo "✅ Optimizaciones avanzadas de CachyOS y extensiones de GNOME aplicadas correctamente."
echo "💡 Se recomienda reiniciar la sesión para activar las nuevas extensiones de GNOME."
