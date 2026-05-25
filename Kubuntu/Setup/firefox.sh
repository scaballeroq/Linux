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

# Eliminar firefox-esr (purge elimina también los archivos de configuración)
sudo apt purge -y firefox-esr firefox-esr-l10n-es-ar firefox-esr-l10n-es-cl firefox-esr-l10n-es-es firefox-esr-l10n-es-mx

# Instalar firefox y firefox-nightly
sudo apt install -y firefox firefox-l10n-es-es firefox-nightly firefox-nightly-l10n-es-es
