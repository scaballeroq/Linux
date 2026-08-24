#!/bin/bash
# =============================================================================
# FUNCIONES BASH (functions.sh)
# =============================================================================
# Colección de funciones y utilidades para potenciar la terminal.
#
# ÍNDICE:
#   1. Navegación y Gestión de Archivos
#   2. Sistema e Información
#   3. Discos e Imágenes ISO
#   4. Multimedia (Audio, Video, Imágenes)
#   5. Aliases y Utiles
#
# USO:
#   source /ruta/a/functions.sh
# =============================================================================

# =============================================================================
# 1. NAVEGACIÓN Y GESTIÓN DE ARCHIVOS
# =============================================================================

mkcd() {
    mkdir -p "$1" && cd "$1"
}

up() {
    local d=""
    local limit=$1
    for ((i=1 ; i <= limit ; i++)); do
        d=$d/..
    done
    d=$(echo $d | sed 's/^\///')
    if [ -z "$d" ]; then
        d=..
    fi
    cd $d
}

backup() {
    cp "$1"{,.bak-$(date +%Y%m%d-%H%M%S)}
}

extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' no se puede extraer con esta función" ;;
        esac
    else
        echo "'$1' no es un archivo válido"
    fi
}

compress() { 
  tar -czf "${1%/}.tar.gz" "${1%/}"
}

alias decompress="tar -xzf"

# =============================================================================
# 2. SISTEMA E INFORMACIÓN
# =============================================================================

psgrep() {
    ps aux | grep -v grep | grep -i -e VSZ -e "$1"
}

duh() {
    du -h --max-depth=1 "$@" | sort -hr
}

hg() {
    history | grep "$1"
}

# =============================================================================
# 3. DISCOS E IMÁGENES ISO
# =============================================================================

iso2sd() {
  if [ $# -ne 2 ]; then
    echo "Uso: iso2sd <archivo_iso> <dispositivo_salida>"
    echo "Ejemplo: iso2sd ~/ArchLinux.iso /dev/sda"
    echo -e "\nDispositivos disponibles:"
    lsblk -d -o NAME | grep -E '^sd[a-z]' | awk '{print "/dev/"$1}'
    return 1
  else
    sudo dd bs=4M status=progress oflag=sync if="$1" of="$2"
    sudo eject $2
  fi
}

format-drive() {
  if [ $# -ne 2 ]; then
    echo "Uso: format-drive <dispositivo> <nombre>"
    echo "Ejemplo: format-drive /dev/sda 'Mi USB'"
    lsblk -d -o NAME -n | awk '{print "/dev/"$1}'
    return 1
  fi

  echo "⚠️  ADVERTENCIA: Se borrarán TODOS los datos en $1 y se formateará como exFAT ('$2')"
  read -rp "¿Continuar? (s/N): " confirm

  if [[ "$confirm" =~ ^[Ss]$ ]]; then
    echo "🗑️  Limpiando y creando partición GPT..."
    sudo wipefs -a "$1"
    sudo dd if=/dev/zero of="$1" bs=1M count=100 status=progress
    sudo parted -s "$1" mklabel gpt
    sudo parted -s "$1" mkpart primary 1MiB 100%

    partition="$([[ $1 == *"nvme"* ]] && echo "${1}p1" || echo "${1}1")"
    sudo partprobe "$1" || true
    sudo udevadm settle || true

    echo "💾 Formateando..."
    sudo mkfs.exfat -n "$2" "$partition"
    echo "✅ Listo: $1 ($2)"
  else
    echo "❌ Cancelado"
  fi
}

# =============================================================================
# 4. MULTIMEDIA (AUDIO, VIDEO, IMÁGENES)
# =============================================================================

webm2mp4() {
  if [ $# -ne 1 ]; then echo "Uso: webm2mp4 <archivo.webm>"; return 1; fi
  if ! command -v ffmpeg &> /dev/null; then echo "❌ Faltan dependencias: ffmpeg"; return 1; fi

  local input="$1"
  local output="${input%.webm}.mp4"
  ffmpeg -i "$input" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 192k "$output"
}

transcode-video-1080p() {
  if [ $# -ne 1 ]; then echo "Uso: transcode-video-1080p <video>"; return 1; fi
  if ! command -v ffmpeg &> /dev/null; then echo "❌ Falta ffmpeg"; return 1; fi

  echo "🎬 Transcodificando a 1080p..."
  ffmpeg -i "$1" -vf scale=1920:1080 -c:v libx264 -preset fast -crf 23 -c:a copy "${1%.*}-1080p.mp4"
  echo "✅ Terminado: ${1%.*}-1080p.mp4"
}

transcode-video-4K() {
  if [ $# -ne 1 ]; then echo "Uso: transcode-video-4K <video>"; return 1; fi
  if ! command -v ffmpeg &> /dev/null; then echo "❌ Falta ffmpeg"; return 1; fi

  echo "🎬 Transcodificando a 4K (H.265)..."
  ffmpeg -i "$1" -c:v libx265 -preset slow -crf 24 -c:a aac -b:a 192k "${1%.*}-optimized.mp4"
  echo "✅ Terminado: ${1%.*}-optimized.mp4"
}

img2jpg() {
  if [ $# -lt 1 ]; then echo "Uso: img2jpg <imagen>"; return 1; fi
  if ! command -v magick &> /dev/null; then echo "❌ Falta ImageMagick"; return 1; fi

  local img="$1"; shift
  echo "🖼️  Optimizando a JPG (Alta Calidad)..."
  magick "$img" "$@" -quality 95 -strip "${img%.*}-optimized.jpg"
  echo "✅ ${img%.*}-optimized.jpg"
}

img2jpg-small() {
  if [ $# -lt 1 ]; then echo "Uso: img2jpg-small <imagen>"; return 1; fi
  if ! command -v magick &> /dev/null; then echo "❌ Falta ImageMagick"; return 1; fi

  local img="$1"; shift
  echo "🖼️  Optimizando a JPG (Web/Small)..."
  magick "$img" "$@" -resize 1080x\> -quality 95 -strip "${img%.*}-optimized.jpg"
  echo "✅ ${img%.*}-optimized.jpg"
}

img2png() {
  if [ $# -lt 1 ]; then echo "Uso: img2png <imagen>"; return 1; fi
  if ! command -v magick &> /dev/null; then echo "❌ Falta ImageMagick"; return 1; fi

  local img="$1"; shift
  echo "🖼️  Optimizando PNG..."
  magick "$img" "$@" -strip -define png:compression-filter=5 \
    -define png:compression-level=9 \
    -define png:compression-strategy=1 \
    -define png:exclude-chunk=all \
    "${img%.*}-optimized.png"
  echo "✅ ${img%.*}-optimized.png"
}

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Funciones cargadas: 📂 Navegación, 💻 Sistema, 💾 Disco, 🎬 Multimedia"

  # 📂 Navegación: mkcd, up, extract, backup, compress
  # 💻 Sistema: psgrep, duh, hg
  # 💾 Disco: iso2sd, format-drive
  # 🎬 Multimedia: webm2mp4, transcode-video-*, img2*
