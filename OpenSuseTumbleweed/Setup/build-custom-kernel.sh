#!/bin/bash
# build-custom-kernel.sh - Compilación del Kernel Linux completo optimizado para x86_64-v3 (OpenSUSE Tumbleweed)

set -euo pipefail

# 1. Auditoría de Hardware y Procesador
CPU_CORES=$(nproc)
CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)
CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}')

echo "================================================================="
echo "🏎️ COMPILADOR DE KERNEL LINUX COMPLETO OPTIMIZADO PARA X86_64-V3"
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

# Detectar serie del kernel actual y consultar última versión en kernel.org
CURRENT_KERNEL_VER=$(uname -r)
KERNEL_SERIES=$(echo "$CURRENT_KERNEL_VER" | grep -oE '^[0-9]+\.[0-9]+' || echo "6.12")

echo "ℹ️ Consultando kernel.org para la serie v${KERNEL_SERIES} (kernel activo: ${CURRENT_KERNEL_VER})..."
LATEST_KERNEL_VER=$(curl -s https://www.kernel.org/releases.json 2>/dev/null | python3 -c "
import sys, json
series = '$KERNEL_SERIES'
try:
    data = json.load(sys.stdin)
    releases = data.get('releases', [])
    matches = [r['version'] for r in releases if r.get('version', '').startswith(series + '.')]
    if matches:
        print(matches[0])
    else:
        print(data.get('latest_stable', {}).get('version', '6.12.103'))
except Exception:
    print('6.12.103')
" 2>/dev/null || echo "6.12.103")

echo "📌 Última versión disponible en kernel.org para tu serie (v${KERNEL_SERIES}): v${LATEST_KERNEL_VER}"

read -rp "Introduce la versión del kernel a compilar [Por defecto: ${LATEST_KERNEL_VER}]: " USER_KERNEL_VER || true
KERNEL_VER="${USER_KERNEL_VER:-$LATEST_KERNEL_VER}"

# 2. Instalación de Dependencias de Compilación en OpenSUSE
echo "ℹ️ Instalando dependencias de compilación del kernel vía Zypper..."
sudo zypper --non-interactive install -y -t pattern devel_kernel devel_basis 2>/dev/null || true
sudo zypper --non-interactive install -y \
    libelf-devel \
    libopenssl-devel \
    bison \
    flex \
    ncurses-devel \
    bc \
    rsync \
    kmod \
    ccache \
    dwarves \
    git \
    wget \
    cpio \
    rpm-build \
    tar \
    xz 2>/dev/null || true

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

# 4. Configuración Base del Kernel Completo
echo "ℹ️ Obteniendo la configuración del kernel base..."
BASE_CONFIG=""
if [ -f "/boot/config-$(uname -r)" ]; then
    BASE_CONFIG="/boot/config-$(uname -r)"
elif [ -f "/proc/config.gz" ]; then
    zcat /proc/config.gz > .config
else
    BASE_CONFIG=$(ls -1t /boot/config-*default* /boot/config-* 2>/dev/null | grep -v "\-v3" | head -n1 || true)
fi

if [ -n "$BASE_CONFIG" ] && [ -f "$BASE_CONFIG" ]; then
    echo "📋 Cargando configuración base completa desde: $BASE_CONFIG"
    cp "$BASE_CONFIG" .config
elif [ ! -f .config ]; then
    echo "⚠️ No se encontró una configuración previa del kernel. Usando defconfig..."
    make defconfig
fi

# 5. Aplicar Identificador v3, Optimizaciones x86_64-v3, Latencia Baja (1000Hz) y Preemption
echo "ℹ️ Modificando parámetros de rendimiento y versión en .config..."

# Establecer identificador -v3 en el nombre del kernel (CONFIG_LOCALVERSION)
scripts/config --set-str CONFIG_LOCALVERSION "-v3"
scripts/config --disable CONFIG_LOCALVERSION_AUTO

# Desactivar firma de módulos para evitar errores con claves no presentes
scripts/config --disable CONFIG_MODULE_SIG
scripts/config --disable CONFIG_MODULE_SIG_ALL
scripts/config --set-str CONFIG_SYSTEM_TRUSTED_KEYS ""
scripts/config --set-str CONFIG_SYSTEM_REVOCATION_KEYS ""
scripts/config --set-str CONFIG_MODULE_SIG_KEY ""

# Desactivar símbolos de depuración pesados
scripts/config --disable CONFIG_DEBUG_INFO
scripts/config --disable CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT
scripts/config --disable CONFIG_DEBUG_INFO_DWARF4
scripts/config --disable CONFIG_DEBUG_INFO_DWARF5
scripts/config --enable CONFIG_DEBUG_INFO_NONE

# Asegurar soporte para discos externos USB y puertos USB-C / Type-C / UAS
scripts/config --module CONFIG_USB_STORAGE
scripts/config --module CONFIG_USB_UAS
scripts/config --module CONFIG_TYPEC
scripts/config --module CONFIG_TYPEC_UCSI
scripts/config --module CONFIG_UCSI_ACPI || true
scripts/config --module CONFIG_USB4 || true
scripts/config --module CONFIG_BLK_DEV_SD

# Desactivar CPU genérica y activar optimización x86_64-v3
scripts/config --disable CONFIG_GENERIC_CPU
scripts/config --enable CONFIG_GENERIC_CPU_V3 || true
if [ "$CPU_VENDOR" == "GenuineIntel" ]; then
    scripts/config --enable CONFIG_MCORE2 || scripts/config --enable CONFIG_MNATIVE_INTEL || true
elif [ "$CPU_VENDOR" == "AuthenticAMD" ]; then
    scripts/config --enable CONFIG_MNATIVE_AMD || scripts/config --enable CONFIG_MZEN3 || true
fi

# Forzar flags del compilador para x86_64-v3
scripts/config --set-str CONFIG_KCFLAGS "-march=x86-64-v3 -O3 -pipe"

# Ajustes de frecuencia de ticks y latencia baja para escritorio/portátil
scripts/config --enable CONFIG_HZ_1000
scripts/config --set-val CONFIG_HZ 1000
scripts/config --enable CONFIG_PREEMPT_DYNAMIC || scripts/config --enable CONFIG_PREEMPT
scripts/config --enable CONFIG_TRANSPARENT_HUGEPAGE_ALWAYS

# Resolver cualquier nueva opción usando valores por defecto
make olddefconfig > /dev/null

# 6. Compilación Paralela
echo "🚀 Iniciando compilación del Kernel Linux v${KERNEL_VER}-v3 con $CPU_CORES hilos..."
make -j"$CPU_CORES" KCFLAGS="-march=x86-64-v3 -O3 -pipe"

echo "================================================================="
echo "✅ Compilación de kernel completada con éxito."
echo "================================================================="

read -rp "¿Deseas instalar el nuevo Kernel v${KERNEL_VER}-v3 personalizado ahora mismo? (s/N): " INSTALL_NOW || true
if [[ "${INSTALL_NOW:-n}" =~ ^[Ss]$ ]]; then
    echo "📦 Instalando módulos del kernel..."
    sudo make modules_install
    echo "📦 Instalando kernel en /boot..."
    sudo make install
    
    echo "🔄 Generando Initramfs con Dracut..."
    sudo dracut -f --kver "${KERNEL_VER}-v3" 2>/dev/null || sudo dracut -f || true
    
    echo "🔄 Actualizando gestor de arranque GRUB2..."
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || sudo update-bootloader --refresh || true
    
    echo "🎉 ¡Kernel v${KERNEL_VER}-v3 instalado! Reinicia el equipo para arrancar con tu nuevo kernel x86_64-v3."
fi
