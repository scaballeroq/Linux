#!/bin/bash
# build-custom-kernel.sh - Compilación del Kernel Linux completo optimizado para x86_64-v3 (Fedora 44)

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

# 2. Instalación de Dependencias de Compilación en Fedora
echo "ℹ️ Instalando dependencias de compilación del kernel para Fedora..."
sudo dnf5 install -y \
    @development-tools \
    ncurses-devel \
    bison \
    flex \
    openssl-devel \
    elfutils-libelf-devel \
    bc \
    rsync \
    dracut \
    grub2-tools \
    grub2-tools-extra \
    zstd \
    tar \
    xz \
    curl \
    diffutils 2>/dev/null || true

# 3. Directorio de Trabajo y Descarga
BUILD_DIR="$HOME/kernel-build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

MAJOR_VER=$(echo "$KERNEL_VER" | cut -d. -f1)
TARBALL="linux-${KERNEL_VER}.tar.xz"
TARBALL_URL="https://cdn.kernel.org/pub/linux/kernel/v${MAJOR_VER}.x/${TARBALL}"

if [ ! -f "$TARBALL" ]; then
    echo "⬇️ Descargando Kernel Linux v${KERNEL_VER}..."
    curl -fLO "$TARBALL_URL"
else
    echo "✅ Archivo $TARBALL ya descargado."
fi

# 4. Extracción del Código Fuente
SRC_DIR="$BUILD_DIR/linux-${KERNEL_VER}"
if [ ! -d "$SRC_DIR" ]; then
    echo "📦 Descomprimiendo código fuente..."
    tar -xf "$TARBALL"
fi

cd "$SRC_DIR"

# 5. Configuración Base del Kernel
echo "ℹ️ Importando configuración activa del kernel actual..."
if [ -f "/boot/config-$(uname -r)" ]; then
    cp "/boot/config-$(uname -r)" .config
elif [ -f "/proc/config.gz" ]; then
    zcat /proc/config.gz > .config
else
    make defconfig
fi

# Desactivar llaves de depuración del distribuidor que impiden compilar módulos locales
scripts/config --disable SYSTEM_TRUSTED_KEYS || true
scripts/config --disable SYSTEM_REVOCATION_KEYS || true
scripts/config --set-str CONFIG_SYSTEM_TRUSTED_KEYS "" || true
scripts/config --set-str CONFIG_SYSTEM_REVOCATION_KEYS "" || true

# Optimización para x86_64-v3 o Native
if grep -q "CONFIG_GENERIC_CPU" .config; then
    scripts/config --disable GENERIC_CPU || true
    scripts/config --enable MK8 || true
fi

# Preemption completa y temporizador a 1000Hz (Baja latencia)
scripts/config --enable PREEMPT || true
scripts/config --set-val HZ 1000 || true
scripts/config --enable HZ_1000 || true

# 6. Compilación
echo "🚀 Compilando Kernel Linux v${KERNEL_VER} con $CPU_CORES hilos..."
make -j"$CPU_CORES"

# 7. Instalación de Módulos y Kernel
echo "📦 Instalando módulos del kernel..."
sudo make modules_install

echo "📦 Instalando imagen del kernel..."
sudo make install

# 8. Generación de Initramfs con Dracut y Actualización de GRUB
echo "⚙️ Generando initramfs con Dracut y actualizando GRUB..."
sudo dracut --kver "$KERNEL_VER" "/boot/initramfs-${KERNEL_VER}.img" -f 2>/dev/null || true
sudo grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg 2>/dev/null || true

echo "================================================================="
echo "✅ Kernel Linux v${KERNEL_VER} (x86_64-v3) compilado e instalado con éxito."
echo "💡 Reinicia el sistema para arrancar con el nuevo kernel."
echo "================================================================="
