#!/bin/bash

# Detener la ejecución si ocurre algún error
set -e

# Crear el directorio para los keyrings si no existe
sudo mkdir -p /etc/apt/keyrings
sudo chmod 755 /etc/apt/keyrings

# Descargar e instalar la clave GPG de Mozilla
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null

# Añadir el repositorio
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null

# Configurar la prioridad (Pinning)
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla

# Actualizar la lista de paquetes
sudo apt update

# Eliminar la versión de Firefox en Snap y Debian ESR si existieran
sudo snap remove firefox || true
sudo apt purge -y firefox-esr firefox-esr-l10n-es-ar firefox-esr-l10n-es-cl firefox-esr-l10n-es-es firefox-esr-l10n-es-mx || true
sudo apt purge -y firefox || true

# Instalar firefox y el paquete de idioma en español de forma nativa (.deb)
sudo apt install -y firefox firefox-l10n-es-es
