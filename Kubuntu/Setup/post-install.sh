# Detectar versión de Debian
CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2)
if [ -z "$CODENAME" ]; then
    CODENAME=$(lsb_release -sc 2>/dev/null || echo "bookworm")
fi

echo "🚀 Iniciando configuración base de Debian ($CODENAME)..."

# 1. Actualización Base
echo "ℹ️ Actualizando lista de paquetes..."
sudo apt update

echo "ℹ️ Actualizando sistema..."
sudo apt upgrade -y

# 2. Habilitar Repositorios Extra (Contrib, Non-Free y Backports)
echo "ℹ️ Habilitando repositorios contrib, non-free y non-free-firmware..."
sudo apt-add-repository -y contrib non-free non-free-firmware

echo "ℹ️ Configurando repositorio de Backports para $CODENAME..."
BACKPORTS_REPO="deb http://deb.debian.org/debian ${CODENAME}-backports main contrib non-free non-free-firmware"
BACKPORTS_FILE="/etc/apt/sources.list.d/backports.list"

if ! grep -q "${CODENAME}-backports" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
    echo "$BACKPORTS_REPO" | sudo tee "$BACKPORTS_FILE"
fi

sudo apt update

# 3. Software Esencial
echo "ℹ️ Instalando utilidades esenciales..."
sudo apt install -y build-essential linux-headers-$(uname -r) cmake curl btop htop inxi \
    fuse3 libfuse2t64 exfatprogs vlc gimp gparted p7zip unrar zip unzip bzip2 xz-utils \
    flatpak gnome-software-plugin-flatpak ca-certificates gnupg

# 4. Multimedia Codecs
echo "ℹ️ Instalando codecs multimedia (Debian Restricted Extras)..."
# Se usa DEBIAN_FRONTEND=noninteractive para evitar el prompt de la licencia de fuentes de MS si se desea, 
# pero aquí lo dejamos estándar por si el usuario prefiere aceptar manualmente.
sudo apt install -y libavcodec-extra ffmpeg

# 5. Aceleración HW
echo "ℹ️ Instalando drivers de aceleración de hardware (Mesa/VA-API)..."
sudo apt install -y mesa-va-drivers mesa-vdpau-drivers

# 6. Limpieza Inicial
echo "ℹ️ Limpiando paquetes innecesarios..."
sudo apt autoremove -y
sudo apt clean

echo "✅ Sistema base configurado correctamente (Se recomienda reiniciar)"
