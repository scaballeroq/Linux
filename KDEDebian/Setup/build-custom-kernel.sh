#!/bin/bash
# build-custom-kernel.sh - Compilación del Kernel Linux completo optimizado para x86_64-v3 (Debian / Arch)

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

# 2. Instalación de Dependencias de Compilación
echo "ℹ️ Instalando dependencias de compilación del kernel..."
if command -v apt &> /dev/null; then
    sudo apt update
    sudo apt install -y \
        build-essential \
        debhelper \
        libncurses-dev \
        bison \
        flex \
        libssl-dev \
        libelf-dev \
        bc \
        rsync \
        kmod \
        ccache \
        dwarves \
        git \
        wget \
        cpio
elif command -v pacman &> /dev/null; then
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
fi

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
echo "ℹ️ Obteniendo la configuración del kernel base (compilación del kernel completo)..."
BASE_CONFIG=""
if [ -f "/boot/config-$(uname -r)" ]; then
    BASE_CONFIG="/boot/config-$(uname -r)"
elif [ -f "/proc/config.gz" ]; then
    zcat /proc/config.gz > .config
else
    BASE_CONFIG=$(ls -1t /boot/config-*amd64* /boot/config-* 2>/dev/null | grep -v "\-v3" | head -n1 || true)
    if [ -z "$BASE_CONFIG" ]; then
        BASE_CONFIG=$(ls -1t /boot/config-* 2>/dev/null | head -n1 || true)
    fi
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

# Desactivar firma de módulos y limpiar certificados de Debian para evitar errores con OpenSSL/sign-file
scripts/config --disable CONFIG_MODULE_SIG
scripts/config --disable CONFIG_MODULE_SIG_ALL
scripts/config --set-str CONFIG_SYSTEM_TRUSTED_KEYS ""
scripts/config --set-str CONFIG_SYSTEM_REVOCATION_KEYS ""
scripts/config --set-str CONFIG_MODULE_SIG_KEY ""

# Desactivar símbolos de depuración para acelerar la compilación y evitar paquetes -dbg gigantes con conflictos de instalación
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

# Resolver cualquier nueva opción usando valores por defecto de forma silenciosa
make olddefconfig > /dev/null

# 6. Compilación Paralela
echo "🚀 Iniciando compilación del Kernel Linux v${KERNEL_VER}-v3 (Completo) con $CPU_CORES hilos..."
echo "☕ Compilando todos los módulos y controladores (kernel completo con optimización x86_64-v3)..."

if command -v apt &> /dev/null; then
    # En Debian compilamos paquetes .deb nativos para una instalación y desinstalación limpia
    make -j"$CPU_CORES" KCFLAGS="-march=x86-64-v3 -O3 -pipe" bindeb-pkg DPKG_FLAGS="-d"
    
    echo "================================================================="
    echo "✅ Compilación completada con éxito. Paquetes .deb generados en:"
    echo "   $KERNEL_BUILD_DIR"
    echo "================================================================="
    
    read -rp "¿Deseas instalar el nuevo Kernel v${KERNEL_VER}-v3 personalizado ahora mismo? (s/N): " INSTALL_NOW || true
    if [[ "${INSTALL_NOW:-n}" =~ ^[Ss]$ ]]; then
        IMAGE_DEB=$(ls -1 "$KERNEL_BUILD_DIR"/linux-image-"${KERNEL_VER}-v3"_"${KERNEL_VER}"*.deb 2>/dev/null | grep -v '\-dbg' | head -n1 || true)
        HEADERS_DEB=$(ls -1 "$KERNEL_BUILD_DIR"/linux-headers-"${KERNEL_VER}-v3"_"${KERNEL_VER}"*.deb 2>/dev/null | grep -v '\-dbg' | head -n1 || true)
        
        DEBS_TO_INSTALL=()
        [ -n "$IMAGE_DEB" ] && DEBS_TO_INSTALL+=("$IMAGE_DEB")
        [ -n "$HEADERS_DEB" ] && DEBS_TO_INSTALL+=("$HEADERS_DEB")

        if [ ${#DEBS_TO_INSTALL[@]} -gt 0 ]; then
            echo "📦 Instalando:"
            for deb in "${DEBS_TO_INSTALL[@]}"; do
                echo "   - $(basename "$deb")"
            done
            sudo dpkg -i "${DEBS_TO_INSTALL[@]}"
            sudo update-grub
            echo "🎉 ¡Kernel v${KERNEL_VER}-v3 instalado! Reinicia el equipo para arrancar con tu nuevo kernel x86_64-v3."
        else
            echo "⚠️ No se encontraron los paquetes .deb para v${KERNEL_VER}-v3 en $KERNEL_BUILD_DIR"
        fi
    fi
else
    make -j"$CPU_CORES" KCFLAGS="-march=x86-64-v3 -O3 -pipe"
    sudo make modules_install
    sudo make install
    echo "✅ Kernel v${KERNEL_VER}-v3 instalado. Actualiza tu gestor de arranque (grub-mkconfig o bootctl) y reinicia."
fi

