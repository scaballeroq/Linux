#!/usr/bin/env bash
# ==============================================================================
# post-install-amd.sh - Post-instalación para Fedora Workstation con AMD Ryzen y Radeon Graphics
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Vega 8)
# (Configurado con ZRAM, DNF paralelo, RPM Fusion, Microcódigo AMD, Mesa RADV/VA-API, PipeWire)
# ==============================================================================

set -euo pipefail

if command -v dnf5 &>/dev/null; then
    DNF_CMD="dnf5"
else
    DNF_CMD="dnf"
fi

show_help() {
    cat <<EOF
🚀 Post-Instalación y Optimización - Fedora Workstation (AMD Ryzen / Radeon)

Uso:
  $0 [OPCIÓN]

Opciones:
  (sin argumentos)    Ejecuta el aprovisionamiento completo (DNF paralelo, RPM Fusion, ZRAM, Kernel, Mesa/RADV, PipeWire, utilidades y Flatpak).
  --status, -s        Muestra el diagnóstico del sistema (CPU, ZRAM, RPM Fusion, Mesa y PipeWire).
  --help, -h          Muestra este mensaje de ayuda.
EOF
}

show_status() {
    echo "================================================================="
    echo "🔍 ESTADO DE POST-INSTALACIÓN - FEDORA WORKSTATION (AMD RYZEN)"
    echo "================================================================="
    echo "• Procesador (CPU):         $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs || echo 'n/a')"
    echo "• Kernel Linux:             $(uname -r)"
    echo "• ZRAM activo:              $(swapon --show 2>/dev/null | grep -i zram || echo 'No activo')"
    echo "• RPM Fusion Free:          $(rpm -q rpmfusion-free-release 2>/dev/null || echo 'No instalado')"
    echo "• RPM Fusion Non-Free:      $(rpm -q rpmfusion-nonfree-release 2>/dev/null || echo 'No instalado')"
    echo "• Mesa VA-API Freeworld:    $(rpm -q mesa-va-drivers-freeworld 2>/dev/null || echo 'No instalado')"
    echo "• FFmpeg Completo:          $(rpm -q ffmpeg 2>/dev/null || echo 'No instalado')"
    echo "• Audio PipeWire:           $(systemctl --user is-active pipewire 2>/dev/null || echo 'inactivo')"
    echo "• Flatpak Flathub:          $(flatpak remotes 2>/dev/null | grep -qi flathub && echo '✅ Configurado' || echo 'No configurado')"
    echo "================================================================="
}

case "${1:-}" in
    --status|-s|status)
        show_status
        exit 0
        ;;
    --help|-h|help)
        show_help
        exit 0
        ;;
esac

echo "================================================================="
echo "INICIANDO POST-INSTALACION: FEDORA WORKSTATION - AMD RYZEN"
echo "================================================================="

# 1. Optimizacion DNF (Paralelismo de descargas)
echo "Configurando optimizaciones en DNF..."
for conf in "/etc/dnf/dnf.conf" "/etc/dnf5/dnf5.conf"; do
    if [ -f "$conf" ]; then
        if ! grep -q "^max_parallel_downloads=" "$conf"; then
            echo "max_parallel_downloads=10" | sudo tee -a "$conf" > /dev/null
        fi
        if ! grep -q "^defaultyes=" "$conf"; then
            echo "defaultyes=True" | sudo tee -a "$conf" > /dev/null
        fi
    fi
done

# 2. Habilitar Repositorios RPM Fusion (Free, Non-Free y Tainted)
echo "Habilitando repositorios oficiales RPM Fusion Free, Non-Free y Tainted..."
sudo $DNF_CMD install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm 2>/dev/null || true

sudo $DNF_CMD install -y \
    rpmfusion-free-release-tainted \
    rpmfusion-nonfree-release-tainted \
    rpmfusion-free-appstream-data \
    rpmfusion-nonfree-appstream-data 2>/dev/null || true

# Actualizar metadatos y sistema
echo "Actualizando base del sistema..."
sudo $DNF_CMD upgrade --refresh -y

# 3. Compresion de Memoria ZRAM (Nativa en Fedora con zram-generator)
echo "Configurando ZRAM con algoritmo ZSTD al 50% de RAM..."
sudo $DNF_CMD install -y zram-generator zram-generator-defaults 2>/dev/null || true
sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
swap-priority = 100
EOF
sudo systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true

# 4. Kernel Linux, Firmware y Microcodigo para AMD
echo "Instalando Kernel Linux, Firmware oficial y Microcodigo para AMD Ryzen..."
sudo $DNF_CMD install -y \
    kernel \
    kernel-core \
    kernel-modules \
    kernel-devel \
    kernel-headers \
    linux-firmware \
    microcode_ctl 2>/dev/null || true

# 5. Stack Grafico y Aceleracion HW para AMD (Mesa / RADV / VA-API / Vulkan)
echo "Instalando controladores graficos AMD Mesa (RADV/RadeonSI) y aceleracion de hardware..."
sudo $DNF_CMD install -y \
    mesa-dri-drivers \
    mesa-vulkan-drivers \
    mesa-va-drivers-freeworld \
    mesa-vdpau-drivers-freeworld \
    vulkan-tools \
    libva-utils \
    radeontop 2>/dev/null || true

# Vulkan 32-bit (solo para Wine/Proton gaming)
if command -v wine &>/dev/null || command -v proton &>/dev/null; then
    echo "Wine/Proton detectado. Instalando drivers Vulkan 32-bit..."
    sudo $DNF_CMD install -y mesa-vulkan-drivers.i686 2>/dev/null || true
fi

# 6. Codecs Multimedia y FFmpeg completo (RPM Fusion)
echo "Instalando FFmpeg completo y codecs multimedia de alto rendimiento..."
sudo $DNF_CMD config-manager setopt fedora-cisco-openh264.enabled=1 2>/dev/null || true
sudo $DNF_CMD swap -y ffmpeg-free ffmpeg --allowerasing 2>/dev/null || sudo $DNF_CMD install -y ffmpeg 2>/dev/null || true
sudo $DNF_CMD update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin,libheif-freeworld -y 2>/dev/null || true
sudo $DNF_CMD install -y \
    gstreamer1-plugins-base \
    gstreamer1-plugins-good \
    gstreamer1-plugins-bad-free \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-ugly \
    gstreamer1-plugin-openh264 \
    gstreamer1-vaapi \
    gstreamer1-libav \
    lame \
    faac \
    faad2 \
    x264 \
    x265 \
    libde265 \
    libdvdcss \
    libdvdread \
    libdvdnav \
    libheif-ffmpeg \
    lsdvd 2>/dev/null || true

# Resolver conflicto de versión con libheif-freeworld si estuviera presente
if rpm -q libheif-freeworld &>/dev/null; then
    sudo $DNF_CMD swap -y libheif-freeworld libheif-ffmpeg --allowerasing 2>/dev/null || true
fi

# 7. Sistema de Audio de Alta Fidelidad (PipeWire + WirePlumber)
echo "Verificando y habilitando PipeWire y WirePlumber..."
sudo $DNF_CMD install -y \
    pipewire \
    pipewire-pulseaudio \
    pipewire-alsa \
    pipewire-jack-audio-connection-kit \
    wireplumber 2>/dev/null || true

systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

# 8. Software Esencial de Sistema
echo "Instalando utilidades esenciales para Fedora Workstation..."
sudo $DNF_CMD install -y \
    @development-tools \
    cmake \
    curl \
    btop \
    htop \
    inxi \
    fuse-libs \
    exfatprogs \
    hfsplus-tools \
    vlc \
    gimp \
    gparted \
    p7zip \
    p7zip-plugins \
    unrar \
    zip \
    unzip \
    bzip2 \
    xz \
    fastfetch 2>/dev/null || true

# 9. Integracion de Flatpak & Flathub
echo "Configurando Flatpak y Flathub..."
sudo $DNF_CMD install -y flatpak 2>/dev/null || true
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# 10. Limpieza de Paquetes Antiguos
echo "Limpiando cache y paquetes obsoletos..."
sudo $DNF_CMD autoremove -y 2>/dev/null || true
sudo $DNF_CMD clean all 2>/dev/null || true

echo "================================================================="
echo "Fedora Workstation (AMD Ryzen) configurado con éxito."
echo "Se recomienda reiniciar el equipo para arrancar con el nuevo Kernel, drivers AMD y ZRAM."
echo "================================================================="
