#!/bin/bash
# firefox.sh - Instalación de Mozilla Firefox oficial (.deb) para Soplos Linux Tyson (Debian Testing)

set -euo pipefail

echo "🚀 Configurando repositorio oficial de Mozilla e instalando Firefox..."

# Crear el directorio para los keyrings si no existe
sudo mkdir -p /etc/apt/keyrings
sudo chmod 755 /etc/apt/keyrings

# Descargar e instalar la clave GPG de Mozilla (solo si no existe)
if [ ! -f /etc/apt/keyrings/packages.mozilla.org.asc ]; then
    echo "ℹ️ Descargando clave GPG de Mozilla..."
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
fi

# Añadir el repositorio
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null

# Configurar la prioridad (Pinning)
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla > /dev/null

# Actualizar la lista de paquetes
sudo apt update

# Eliminar firefox-esr (purge elimina también los archivos de configuración)
sudo apt purge -y firefox-esr firefox-esr-l10n-es-ar firefox-esr-l10n-es-cl firefox-esr-l10n-es-es firefox-esr-l10n-es-mx 2>/dev/null || true

# Instalar firefox oficial
sudo apt install -y firefox firefox-l10n-es-es

echo "✅ Mozilla Firefox instalado correctamente desde el repositorio oficial."
