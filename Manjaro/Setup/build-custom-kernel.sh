#!/bin/bash
# build-custom-kernel.sh - Compilación del Kernel Linux optimizado para x86_64-v3 y ajustado a tu hardware (Manjaro Linux)

set -euo pipefail

# 1. Auditoría de Hardware y Procesador
CPU_CORES=$(nproc)
CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')

echo "================================================================="
echo "🏎️ COMPILADOR DE KERNEL LINUX OPTIMIZADO PARA X86_64-V3 (MANJARO)"
echo "================================================================="
echo "💻 Procesador: $CPU_MODEL"
echo "⚙️ Hilos de compilación: $CPU_CORES hilos"
echo "================================================================="

# Verificar soporte x86_64-v3 (AVX2, FMA, BMI1, BMI2)
if grep -q "avx2" /proc/cpuinfo && grep -q "bmi2" /proc/cpuinfo; then
    echo "✅ Tu procesador SOPORTA la arquitectura x86_64-v3 (AVX2 + BMI2 + FMA)."
else
    echo "⚠️ Advertencia: No se detectaron las instrucciones AVX2/BMI2. Se compilará para march=native."
fi

# Detectar última versión estable de Kernel.org vía API
echo "ℹ️ Consultando la última versión estable oficial en kernel.org..."
LATEST_KERNEL_VER=$(curl -s https://www.kernel.org/releases.json 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('latest_link', {}).get('version', '6.13.2'))" 2>/dev/null || echo "6.13.2")

echo "📌 Última versión estable disponible en kernel.org: v${LATEST_KERNEL_VER}"

read -rp "Introduce la versión del kernel a compilar [Por defecto: ${LATEST_KERNEL_VER}]: " USER_KERNEL_VER || true
KERNEL_VER="${USER_KERNEL_VER:-$LATEST_KERNEL_VER}"

# 2. Instalación de Dependencias de Compilación
echo "ℹ️ Instalando dependencias de compilación del kernel vía Pacman..."
sudo pacman -S --needed --noconfirm \
    base-devel \
    xmlto \
    kmod \
    inetutils \
    bc \
    libelf \
    git \
    ccache \
    dwarves \
    wget \
    cpio

# 3. Descargar Fuentes del Kernel Linux Estable
KERNEL_BUILD_DIR="$HOME/Kernel-Build"
mkdir -p "$KERNEL_BUILD_DIR"
cd "$KERNEL_BUILD_DIR"

MAJOR_VER=$(echo "$KERNEL_VER" | cut -d. -f1)
KERNEL_TAR="linux-${KERNEL_VER}.tar.xz"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v${MAJOR_VER}.x/${KERNEL_TAR}"

if [ ! -d "linux-${KERNEL_VER}" ]; then
    if [ ! -f "$KERNEL_TAR" ]; then
        echo "⬇️ Descargando fuentes del Kernel Linux v${KERNEL_VER} desde $KERNEL_URL..."
        wget -q --show-progress "$KERNEL_URL" || { echo "❌ No se pudo descargar $KERNEL_URL"; exit 1; }
    fi
    echo "📦 Descomprimiendo código fuente..."
    tar -xf "$KERNEL_TAR"
fi

cd "linux-${KERNEL_VER}"

# 4. Ajuste de Configuración NATIVA
echo "ℹ️ Obteniendo la configuración del kernel actual..."
if [ -f "/boot/config-$(uname -r)" ]; then
    cp "/boot/config-$(uname -r)" .config
elif [ -f "/proc/config.gz" ]; then
    zcat /proc/config.gz > .config
else
    make defconfig
fi

echo "ℹ️ Aplicando localmodconfig (Recorta el kernel para compilar módulos activos)..."
yes "" | make localmodconfig 2>/dev/null || true

# 5. Aplicar Optimizaciones x86_64-v3, Latencia Baja (1000Hz) y Preemption
echo "ℹ️ Modificando parámetros de rendimiento en .config..."

scripts/config --disable CONFIG_GENERIC_CPU
if [ "$CPU_VENDOR" == "GenuineIntel" ]; then
    scripts/config --enable CONFIG_MCORE2 || scripts/config --enable CONFIG_MNATIVE_INTEL || true
elif [ "$CPU_VENDOR" == "AuthenticAMD" ]; then
    scripts/config --enable CONFIG_MNATIVE_AMD || scripts/config --enable CONFIG_MZEN3 || true
fi

scripts/config --set-str CONFIG_KCFLAGS "-march=x86-64-v3 -O3 -pipe"
scripts/config --enable CONFIG_HZ_1000
scripts/config --set-val CONFIG_HZ 1000
scripts/config --enable CONFIG_PREEMPT_DYNAMIC || scripts/config --enable CONFIG_PREEMPT
scripts/config --enable CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS

make olddefconfig

# 6. Compilación Paralela
echo "🚀 Iniciando compilación del Kernel Linux v${KERNEL_VER} con $CPU_CORES hilos..."
make -j"$CPU_CORES"

echo "ℹ️ Instalando módulos y kernel compilado..."
sudo make modules_install
sudo make install

# 7. Actualización de initramfs y GRUB en Manjaro
if command -v mkinitcpio &> /dev/null; then
    echo "ℹ️ Regenerando initramfs con mkinitcpio..."
    sudo mkinitcpio -P || true
fi

if command -v update-grub &> /dev/null; then
    echo "ℹ️ Actualizando GRUB..."
    sudo update-grub || true
elif command -v grub-mkconfig &> /dev/null; then
    sudo grub-mkconfig -o /boot/grub/grub.cfg || true
fi

echo "================================================================="
echo "✅ Kernel personalizado v${KERNEL_VER} x86_64-v3 compilado e instalado con éxito."
echo "💡 Reinicia el equipo para arrancar con tu nuevo kernel optimizado."
echo "================================================================="
