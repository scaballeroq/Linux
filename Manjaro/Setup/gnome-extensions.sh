#!/bin/bash
# gnome-extensions.sh - Instalación automatizada y limpia de extensiones de GNOME para Manjaro Linux
# (Con compilación de esquemas GSettings y registro nativo en DBus)

set -euo pipefail

echo "🧩 Iniciando instalación limpia y robusta de extensiones de GNOME en Manjaro..."

# 1. Instalación de herramientas base
echo "ℹ️ Instalando dependencias base (gnome-browser-connector, extension-manager, glib2)..."
sudo pacman -S --needed --noconfirm \
    gnome-browser-connector \
    extension-manager \
    glib2 \
    python-pip \
    python-pipx 2>/dev/null || true

# Instalar gnome-extensions-cli (gext) si es posible
pipx install gnome-extensions-cli 2>/dev/null || pip install --break-system-packages gnome-extensions-cli 2>/dev/null || true
export PATH="$HOME/.local/bin:$PATH"

# 2. Instalación de paquetes de extensiones desde repositorios oficiales de Manjaro/Arch
echo "ℹ️ Instalando extensiones nativas del repositorio Manjaro..."
sudo pacman -S --needed --noconfirm \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-caffeine \
    gnome-shell-extension-blur-my-shell \
    gnome-shell-extension-dash-to-dock \
    gnome-shell-extension-dash-to-panel \
    gnome-shell-extension-clipboard-indicator \
    gnome-shell-extension-ding 2>/dev/null || true

# 3. Instalación de las 17 extensiones personalizadas con compilación de esquemas GSettings
echo "ℹ️ Instalando y compilando esquemas GSettings desde extensions.gnome.org..."

EXTENSION_IDS=(1262 307 36 355 517 5940 779 3960 3193 7065 615 97 6682 3088 5410 1160 2087)

if command -v gext &> /dev/null; then
    echo "ℹ️ Utilizando gext (herramienta oficial CLI de GNOME) para instalación limpia..."
    gext install "${EXTENSION_IDS[@]}" || true
else
    python3 - <<'PYEOF'
import json
import os
import subprocess
import urllib.request
import shutil

extension_ids = [1262, 307, 36, 355, 517, 5940, 779, 3960, 3193, 7065, 615, 97, 6682, 3088, 5410, 1160, 2087]

home_dir = os.path.expanduser("~")
target_base_dir = os.path.join(home_dir, ".local/share/gnome-shell/extensions")
os.makedirs(target_base_dir, exist_ok=True)

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
            url_fallback = f"https://extensions.gnome.org/extension-info/?pk={ext_id}"
            req_f = urllib.request.Request(url_fallback, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req_f) as resp_f:
                data = json.loads(resp_f.read().decode('utf-8'))
            uuid = data.get('uuid')
            dl_path = data.get('download_url')
            
        if uuid and dl_path:
            zip_url = f"https://extensions.gnome.org{dl_path}"
            tmp_zip = f"/tmp/ext_{ext_id}.zip"
            
            print(f"⬇️ Descargando extensión ID {ext_id} ({uuid})...")
            urllib.request.urlretrieve(zip_url, tmp_zip)
            
            subprocess.run(["gnome-extensions", "install", "--force", tmp_zip], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if os.path.exists(tmp_zip):
                os.remove(tmp_zip)
            
            # Compilar esquemas GSettings
            ext_dir = os.path.join(target_base_dir, uuid)
            schemas_dir = os.path.join(ext_dir, "schemas")
            if os.path.isdir(schemas_dir):
                subprocess.run(["glib-compile-schemas", schemas_dir], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                print(f"  └─ Esquemas GSettings compilados en {schemas_dir}")
            
            subprocess.run(["gnome-extensions", "enable", uuid], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        print(f"⚠️ Error al procesar extensión ID {ext_id}: {e}")
PYEOF
fi

# 4. Habilitar soporte de extensiones en GNOME Shell
if command -v gsettings &> /dev/null; then
    gsettings set org.gnome.shell disable-user-extensions false 2>/dev/null || true
fi

echo "✅ Proceso de instalación de extensiones completado en Manjaro."
echo "💡 Reinicia la sesión o GNOME Shell para que todas las extensiones carguen correctamente."
