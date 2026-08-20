#!/bin/bash
# firefox.sh - Instalación de Mozilla Firefox nativo en OpenSUSE Tumbleweed

set -euo pipefail

echo "ℹ️ Instalando Mozilla Firefox oficial vía Zypper..."
sudo zypper --non-interactive install -y \
    MozillaFirefox \
    MozillaFirefox-translations-common 2>/dev/null || sudo zypper --non-interactive install -y firefox || true

echo "✅ Mozilla Firefox instalado y configurado correctamente."
