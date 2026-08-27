#!/bin/bash
# =============================================================================
# FUNCIONES BASH (functions.sh) - Soplos Linux Tyson
# =============================================================================
# Colección de funciones y utilidades para potenciar la terminal.
#
# ÍNDICE:
#   1. Navegación y Gestión de Archivos
#   2. Sistema e Información
#   3. Discos e Imágenes ISO (Con confirmación de seguridad)
#   4. Multimedia (FFmpeg & ImageMagick)
#
# USO:
#   source /ruta/a/functions.sh
# =============================================================================

# =============================================================================
# 1. NAVEGACIÓN Y GESTIÓN DE ARCHIVOS
# =============================================================================

# -----------------------------------------------------------------------------
# mkcd: Crear y entrar
# Uso: mkcd <nombre_directorio>
# -----------------------------------------------------------------------------
# Crea un directorio (incluyendo padres si es necesario) y entra en él inmediatamente.
mkcd() {
    if [ -z "$1" ]; then
        echo "Uso: mkcd <directorio>"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}

# -----------------------------------------------------------------------------
# up: Subir niveles rápidamente
# Uso: up [numero]
# -----------------------------------------------------------------------------
# Sube 'n' niveles en el árbol de directorios (por defecto 1).
# Ejemplo: 'up 3' equivale a 'cd ../../..'
up() {
    local limit=${1:-1}
    local d=""
    for ((i=1 ; i <= limit ; i++)); do
        d="$d/.."
    done
    d=$(echo "$d" | sed 's/^\///')
    [ -z "$d" ] && d=..
    cd "$d"
}

# -----------------------------------------------------------------------------
# backup: Copia de seguridad rápida
# Uso: backup <archivo_o_directorio>
# -----------------------------------------------------------------------------
# Crea una copia del archivo o carpeta con extensión .bak y la fecha/hora actual.
backup() {
    if [ $# -eq 0 ] || [ ! -e "$1" ]; then
        echo "Uso: backup <archivo_o_directorio>"
        return 1
    fi
    local target="${1%/}"
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    cp -a "$target" "${target}.bak-${timestamp}"
    echo "✅ Respaldo creado: ${target}.bak-${timestamp}"
}

# -----------------------------------------------------------------------------
# extract: Extractor universal
# Uso: extract <archivo_comprimido>
# -----------------------------------------------------------------------------
# Detecta automáticamente la extensión y descomprime usando la herramienta adecuada.
extract() {
    if [ -z "$1" ]; then
        echo "Uso: extract <archivo_comprimido>"
        return 1
    fi

    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2|*.tbz2)    tar xjf "$1"     ;;
            *.tar.gz|*.tgz)      tar xzf "$1"     ;;
            *.tar.xz|*.txz)      tar xJf "$1"     ;;
            *.tar.zst|*.tzst)    tar --zstd -xf "$1" 2>/dev/null || zstd -dc "$1" | tar xf - ;;
            *.tar)               tar xf "$1"      ;;
            *.bz2)               bunzip2 "$1"     ;;
            *.rar)               unrar x "$1"     ;;
            *.gz)                gunzip "$1"      ;;
            *.xz)                unxz "$1"        ;;
            *.zst)               zstd -d "$1"     ;;
            *.zip)               unzip "$1"       ;;
            *.Z)                 uncompress "$1"  ;;
            *.7z)                7z x "$1"        ;;
            *)                   tar -xf "$1" 2>/dev/null || echo "❌ No se puede extraer '$1' con extract" ;;
        esac
    else
        echo "❌ '$1' no es un archivo válido."
        return 1
    fi
}

# -----------------------------------------------------------------------------
# compress: Comprimir directorio o archivo en tar.gz
# Uso: compress <directorio_o_archivo>
# -----------------------------------------------------------------------------
compress() {
    if [ $# -eq 0 ] || [ ! -e "$1" ]; then
        echo "Uso: compress <directorio_o_archivo>"
        return 1
    fi
    local target="${1%/}"
    tar -czf "${target}.tar.gz" "$target"
    echo "✅ Comprimido en: ${target}.tar.gz"
}

# -----------------------------------------------------------------------------
# decompress: Descomprimir tar.gz
# Uso: decompress <archivo.tar.gz>
# -----------------------------------------------------------------------------
alias decompress="tar -xzf"

# =============================================================================
# 2. SISTEMA E INFORMACIÓN
# =============================================================================

# -----------------------------------------------------------------------------
# psgrep: Buscar procesos
# Uso: psgrep <nombre_proceso>
# -----------------------------------------------------------------------------
psgrep() {
    if [ -z "$1" ]; then
        echo "Uso: psgrep <termino_de_busqueda>"
        return 1
    fi
    ps aux | grep -v grep | grep -i -E "VSZ|$1"
}

# -----------------------------------------------------------------------------
# duh: Tamaño de disco legible
# Uso: duh [directorio]
# -----------------------------------------------------------------------------
# Muestra el tamaño de los archivos/carpetas en el nivel actual ordenados por peso.
duh() {
    du -h --max-depth=1 "${1:-.}" | sort -hr
}

# -----------------------------------------------------------------------------
# hg: Grep en historial
# Uso: hg <texto_a_buscar>
# -----------------------------------------------------------------------------
hg() {
    history | grep -i "${1:-.}"
}

# =============================================================================
# 3. DISCOS E IMÁGENES ISO (SEGURIDAD REFORZADA)
# =============================================================================

# -----------------------------------------------------------------------------
# iso2sd: Grabar ISO a SD/USB de forma segura
# Uso: iso2sd <archivo_iso> <dispositivo_salida>
# -----------------------------------------------------------------------------
iso2sd() {
    if [ $# -ne 2 ]; then
        echo "Uso: iso2sd <archivo_iso> <dispositivo_salida>"
        echo "Ejemplo: iso2sd ~/SoplosLinux.iso /dev/sda"
        echo -e "\nDispositivos disponibles detectados:"
        lsblk -d -o NAME,SIZE,MODEL,TRAN | grep -E '^sd[a-z]|^nvme[0-9]n[0-9]|^mmcblk[0-9]' | awk '{print "/dev/"$1 " (" $2 ", " $3 ", " $4 ")"}'
        return 1
    fi

    if [ ! -f "$1" ]; then
        echo "❌ Error: El archivo ISO '$1' no existe."
        return 1
    fi

    if [ ! -b "$2" ]; then
        echo "❌ Error: El destino '$2' no es un dispositivo de bloques válido."
        return 1
    fi

    echo "================================================================="
    echo "⚠️  ADVERTENCIA CRÍTICA DE SEGURIDAD"
    echo "================================================================="
    echo "Se va a sobreescribir completamente el dispositivo: $2"
    echo "Origen: $1"
    echo "¡TODOS LOS DATOS Y PARTICIONES EN $2 SERÁN BORRADOS DE FORMA PERMANENTE!"
    echo "================================================================="
    read -rp "¿Estás absolutamente seguro de continuar? (Escribe 'SI' en mayúsculas): " confirm

    if [ "$confirm" = "SI" ]; then
        echo "🚀 Grabando imagen en $2..."
        sudo dd bs=4M status=progress oflag=sync if="$1" of="$2"
        sync
        sudo eject "$2" 2>/dev/null || true
        echo "✅ Grabación completada y dispositivo expulsado."
    else
        echo "❌ Operación cancelada por el usuario."
    fi
}

# -----------------------------------------------------------------------------
# format-drive: Formatear disco (exFAT)
# Uso: format-drive <dispositivo> <nombre_etiqueta>
# -----------------------------------------------------------------------------
format-drive() {
    if [ $# -ne 2 ]; then
        echo "Uso: format-drive <dispositivo> <nombre_etiqueta>"
        echo "Ejemplo: format-drive /dev/sda 'Mi USB'"
        echo -e "\nDispositivos disponibles:"
        lsblk -d -o NAME,SIZE,MODEL -n | awk '{print "/dev/"$1 " (" $2 ", " $3 ")"}'
        return 1
    fi

    if [ ! -b "$1" ]; then
        echo "❌ Error: '$1' no es un dispositivo de bloques válido."
        return 1
    fi

    echo "⚠️  ADVERTENCIA: Se borrarán TODOS los datos en $1 y se formateará como exFAT ('$2')"
    read -rp "¿Continuar? (s/N): " confirm

    if [[ "$confirm" =~ ^[Ss]$ ]]; then
        echo "🗑️  Limpiando firmas y creando tabla GPT..."
        sudo wipefs -a "$1"
        sudo dd if=/dev/zero of="$1" bs=1M count=10 status=progress
        sudo parted -s "$1" mklabel gpt
        sudo parted -s "$1" mkpart primary 1MiB 100%

        # Detección universal de partición (sda -> sda1, nvme0n1 -> nvme0n1p1, mmcblk0 -> mmcblk0p1)
        local partition
        if [[ "$1" =~ [0-9]$ ]]; then
            partition="${1}p1"
        else
            partition="${1}1"
        fi

        sudo partprobe "$1" 2>/dev/null || true
        sudo udevadm settle 2>/dev/null || true

        echo "💾 Formateando sistema de archivos exFAT..."
        sudo mkfs.exfat -n "$2" "$partition"
        echo "✅ Formateo completado: $1 ($2 en $partition)"
    else
        echo "❌ Operación cancelada."
    fi
}

# =============================================================================
# 4. MULTIMEDIA (FFMPEG & IMAGEMAGICK)
# =============================================================================

# -----------------------------------------------------------------------------
# webm2mp4: Convertir WebM a MP4
# Uso: webm2mp4 <archivo.webm>
# -----------------------------------------------------------------------------
# Ideal para convertir grabaciones de pantalla de KDE Spectacle a MP4 universal.
webm2mp4() {
    if [ $# -ne 1 ] || [ ! -f "$1" ]; then
        echo "Uso: webm2mp4 <archivo.webm>"
        return 1
    fi
    if ! command -v ffmpeg &> /dev/null; then
        echo "❌ Falta dependencia: ffmpeg"
        return 1
    fi

    local input="$1"
    local output="${input%.webm}.mp4"
    ffmpeg -i "$input" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 192k "$output"
}

# -----------------------------------------------------------------------------
# transcode-video-1080p: Optimizar a 1080p (H.264)
# Uso: transcode-video-1080p <video>
# -----------------------------------------------------------------------------
transcode-video-1080p() {
    if [ $# -ne 1 ] || [ ! -f "$1" ]; then
        echo "Uso: transcode-video-1080p <video>"
        return 1
    fi
    if ! command -v ffmpeg &> /dev/null; then
        echo "❌ Falta dependencia: ffmpeg"
        return 1
    fi

    echo "🎬 Transcodificando a 1080p (H.264)..."
    ffmpeg -i "$1" -vf "scale='min(1920,iw)':-2" -c:v libx264 -preset fast -crf 23 -c:a copy "${1%.*}-1080p.mp4"
    echo "✅ Terminado: ${1%.*}-1080p.mp4"
}

# -----------------------------------------------------------------------------
# transcode-video-4K: Optimizar con H.265 (HEVC)
# Uso: transcode-video-4K <video>
# -----------------------------------------------------------------------------
transcode-video-4K() {
    if [ $# -ne 1 ] || [ ! -f "$1" ]; then
        echo "Uso: transcode-video-4K <video>"
        return 1
    fi
    if ! command -v ffmpeg &> /dev/null; then
        echo "❌ Falta dependencia: ffmpeg"
        return 1
    fi

    echo "🎬 Transcodificando con H.265 (HEVC)..."
    ffmpeg -i "$1" -c:v libx265 -preset slow -crf 24 -c:a aac -b:a 192k "${1%.*}-optimized.mp4"
    echo "✅ Terminado: ${1%.*}-optimized.mp4"
}

# Helper interno para ImageMagick (magick o convert)
_img_tool() {
    if command -v magick &> /dev/null; then
        echo "magick"
    elif command -v convert &> /dev/null; then
        echo "convert"
    else
        echo ""
    fi
}

# -----------------------------------------------------------------------------
# img2jpg: Optimizar imagen a JPG (Calidad Alta)
# Uso: img2jpg <imagen>
# -----------------------------------------------------------------------------
img2jpg() {
    if [ $# -lt 1 ] || [ ! -f "$1" ]; then
        echo "Uso: img2jpg <imagen>"
        return 1
    fi
    local tool
    tool=$(_img_tool)
    if [ -z "$tool" ]; then
        echo "❌ Falta ImageMagick (magick / convert)"
        return 1
    fi

    local img="$1"; shift
    echo "🖼️  Optimizando a JPG (Alta Calidad)..."
    "$tool" "$img" "$@" -quality 95 -strip "${img%.*}-optimized.jpg"
    echo "✅ Generado: ${img%.*}-optimized.jpg"
}

# -----------------------------------------------------------------------------
# img2jpg-small: Optimizar imagen a JPG (Web/Small)
# Uso: img2jpg-small <imagen>
# -----------------------------------------------------------------------------
img2jpg-small() {
    if [ $# -lt 1 ] || [ ! -f "$1" ]; then
        echo "Uso: img2jpg-small <imagen>"
        return 1
    fi
    local tool
    tool=$(_img_tool)
    if [ -z "$tool" ]; then
        echo "❌ Falta ImageMagick (magick / convert)"
        return 1
    fi

    local img="$1"; shift
    echo "🖼️  Optimizando a JPG (Web/Redimensionado)..."
    "$tool" "$img" "$@" -resize 1080x\> -quality 90 -strip "${img%.*}-optimized.jpg"
    echo "✅ Generado: ${img%.*}-optimized.jpg"
}

# -----------------------------------------------------------------------------
# img2png: Optimizar PNG
# Uso: img2png <imagen>
# -----------------------------------------------------------------------------
img2png() {
    if [ $# -lt 1 ] || [ ! -f "$1" ]; then
        echo "Uso: img2png <imagen>"
        return 1
    fi
    local tool
    tool=$(_img_tool)
    if [ -z "$tool" ]; then
        echo "❌ Falta ImageMagick (magick / convert)"
        return 1
    fi

    local img="$1"; shift
    echo "🖼️  Optimizando PNG..."
    "$tool" "$img" "$@" -strip -define png:compression-filter=5 \
        -define png:compression-level=9 \
        -define png:compression-strategy=1 \
        -define png:exclude-chunk=all \
        "${img%.*}-optimized.png"
    echo "✅ Generado: ${img%.*}-optimized.png"
}

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Funciones cargadas: 📂 Navegación, 💻 Sistema, 💾 Disco (Seguro), 🎬 Multimedia"

