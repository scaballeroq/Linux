# Detectar versión de Kubuntu/Ubuntu
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "resolute")
fi

echo "🚀 Iniciando configuración base de Kubuntu/Ubuntu ($CODENAME)..."

# 1. Actualización Base
echo "ℹ️ Actualizando lista de paquetes..."
sudo apt update

echo "ℹ️ Actualizando sistema..."
sudo apt upgrade -y

# 2. Habilitar Repositorios Extra (Universe, Multiverse y Restricted)
echo "ℹ️ Habilitando repositorios universe, multiverse y restricted..."
sudo add-apt-repository -y universe
sudo add-apt-repository -y multiverse
sudo add-apt-repository -y restricted

sudo apt update

# 3. Software Esencial
echo "ℹ️ Instalando utilidades esenciales..."
# Pre-aceptar la licencia de ttf-mscorefonts-installer para instalación desatendida
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections

sudo apt install -y build-essential linux-headers-$(uname -r) cmake curl btop htop inxi \
    fuse3 libfuse2t64 exfatprogs vlc gimp gparted p7zip unrar zip unzip bzip2 xz-utils \
    flatpak plasma-discover-backend-flatpak ca-certificates gnupg

# 4. Multimedia Codecs
echo "ℹ️ Instalando codecs multimedia (Kubuntu Restricted Extras)..."
# Se configura la instalación no interactiva de apt para evitar prompts
sudo DEBIAN_FRONTEND=noninteractive apt install -y kubuntu-restricted-extras libavcodec-extra ffmpeg

# 5. Aceleración HW
echo "ℹ️ Instalando drivers de aceleración de hardware (Mesa/VA-API)..."
sudo apt install -y mesa-va-drivers mesa-vdpau-drivers

# 6. Limpieza Inicial
echo "ℹ️ Limpiando paquetes innecesarios..."
sudo apt autoremove -y
sudo apt clean

echo "✅ Sistema base configurado correctamente (Se recomienda reiniciar)"
