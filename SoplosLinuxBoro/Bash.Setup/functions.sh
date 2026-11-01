# =============================================================================
# FUNCIONES DE SHELL (functions.sh) - Adaptado para Bash y Zsh en Soplos Linux Boro
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

# Evitar ejecución en subshells y sesiones no interactivas
[[ $- != *i* ]] && return 0 2>/dev/null || true

# =============================================================================
# 1. NAVEGACIÓN Y GESTIÓN DE ARCHIVOS
# =============================================================================

# -----------------------------------------------------------------------------
# mkcd: Crear y entrar
# Uso: mkcd <nombre_directorio>
# -----------------------------------------------------------------------------
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# -----------------------------------------------------------------------------
# up: Subir niveles rápidamente
# Uso: up [numero]
# -----------------------------------------------------------------------------
up() {
    local d=""
    local limit="${1:-1}"
    for ((i=1 ; i <= limit ; i++)); do
        d="$d/.."
    done
    d=$(echo "$d" | sed 's/^\///')
    if [ -z "$d" ]; then
        d=..
    fi
    cd "$d"
}

# -----------------------------------------------------------------------------
# backup: Copia de seguridad rápida
# Uso: backup <archivo>
# -----------------------------------------------------------------------------
backup() {
    cp "$1" "${1}.bak-$(date +%Y%m%d-%H%M%S)"
}

# -----------------------------------------------------------------------------
# extract: Extractor universal
# Uso: extract <archivo>
# -----------------------------------------------------------------------------
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
            *.tar.xz)    tar xf "$1"      ;;
            *.tar.zst)   tar --zstd -xf "$1" ;;
            *)           echo "'$1' no puede ser extraído mediante extract()" ;;
        esac
    else
        echo "'$1' no es un archivo válido"
    fi
}

# -----------------------------------------------------------------------------
# compress: Compresor rápido
# Uso: compress <formato> <nombre_salida> <archivos...>
# Formatos soportados: tar.gz, tar.bz2, tar.xz, zip, 7z
# -----------------------------------------------------------------------------
compress() {
    local format=$1
    local output=$2
    shift 2

    case $format in
        tar.gz)  tar -czf "${output}.tar.gz" "$@" ;;
        tar.bz2) tar -cjf "${output}.tar.bz2" "$@" ;;
        tar.xz)  tar -cJf "${output}.tar.xz" "$@" ;;
        zip)     zip -r "${output}.zip" "$@" ;;
        7z)      7z a "${output}.7z" "$@" ;;
        *)       echo "Formato no soportado. Usa: tar.gz, tar.bz2, tar.xz, zip, 7z" ;;
    esac
}

# =============================================================================
# 2. SISTEMA E INFORMACIÓN
# =============================================================================

# -----------------------------------------------------------------------------
# psgrep: Buscar procesos por nombre
# Uso: psgrep <nombre_proceso>
# -----------------------------------------------------------------------------
psgrep() {
    ps aux | grep -v grep | grep "$1" -i --color=auto
}

# -----------------------------------------------------------------------------
# duh: Ver tamaño de carpetas ordenado (Human Readable)
# Uso: duh [directorio]
# -----------------------------------------------------------------------------
duh() {
    du -h --max-depth=1 "${1:-.}" | sort -h
}

# -----------------------------------------------------------------------------
# hg: Buscar en el historial
# Uso: hg <termino_busqueda>
# -----------------------------------------------------------------------------
hg() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        fc -l 1 | grep -i "$1"
    else
        history | grep -i "$1"
    fi
}

# =============================================================================
# 3. DISCOS E IMÁGENES ISO
# =============================================================================

# -----------------------------------------------------------------------------
# iso2sd: Grabar ISO en pendrive/SD de forma segura
# Uso: iso2sd <archivo.iso> <dispositivo>
# -----------------------------------------------------------------------------
iso2sd() {
  if [ $# -ne 2 ]; then
    echo "Uso: iso2sd <archivo_iso> <dispositivo_salida>"
    echo "Ejemplo: iso2sd ~/soplos.iso /dev/sda"
    echo -e "\nDispositivos disponibles:"
    lsblk -d -o NAME | grep -E '^sd[a-z]' | awk '{print "/dev/"$1}'
    return 1
  else
    sudo dd bs=4M status=progress oflag=sync if="$1" of="$2"
    sudo eject "$2"
  fi
}

# -----------------------------------------------------------------------------
# format-drive: Formatear unidad externa como exFAT (GPT)
# Uso: format-drive <dispositivo> <etiqueta>
# -----------------------------------------------------------------------------
format-drive() {
  if [ $# -ne 2 ]; then
    echo "Uso: format-drive <dispositivo> <etiqueta>"
    echo "Ejemplo: format-drive /dev/sdb 'MiPendrive'"
    echo -e "\nDispositivos disponibles:"
    lsblk -d -o NAME,SIZE,MODEL | grep -E '^sd[a-z]'
    return 1
  fi

  echo "⚠️  ADVERTENCIA: Se borrarán TODOS los datos en $1 y se formateará como exFAT ('$2')"
  printf "¿Continuar? (s/N): "
  read -r confirm

  if [[ "$confirm" =~ ^[Ss]$ ]]; then
    echo "🗑️  Limpiando y creando partición GPT..."
    sudo wipefs -a "$1"
    sudo parted -s "$1" mklabel gpt
    sudo parted -s "$1" mkpart primary 2048s 100%

    local part="${1}1"
    [[ "$1" =~ nvme ]] && part="${1}p1"

    echo "⚙️  Formateando partición $part como exFAT..."
    sudo mkfs.exfat -n "$2" "$part"
    echo "✅ Dispositivo formateado con éxito."
  else
    echo "❌ Operación cancelada."
  fi
}

# =============================================================================
# 4. MULTIMEDIA (AUDIO, VIDEO, IMÁGENES)
# =============================================================================

# -----------------------------------------------------------------------------
# webm2mp4: Convertir WebM a MP4
# Uso: webm2mp4 <archivo.webm>
# -----------------------------------------------------------------------------
webm2mp4() {
  if [ $# -ne 1 ]; then echo "Uso: webm2mp4 <archivo.webm>"; return 1; fi
  if ! command -v ffmpeg &> /dev/null; then echo "❌ Faltan dependencias: ffmpeg"; return 1; fi

  ffmpeg -i "$1" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 192k "${1%.*}.mp4"
  echo "✅ Convertido: ${1%.*}.mp4"
}

# -----------------------------------------------------------------------------
# transcode-video-1080p: Transcodificar a 1080p optimizado para streaming
# Uso: transcode-video-1080p <video>
# -----------------------------------------------------------------------------
transcode-video-1080p() {
  if [ $# -lt 1 ]; then echo "Uso: transcode-video-1080p <video_origen>"; return 1; fi
  if ! command -v ffmpeg &> /dev/null; then echo "❌ Faltan dependencias: ffmpeg"; return 1; fi

  local input="$1"
  local output="${input%.*}-1080p.mp4"

  ffmpeg -i "$input" -vf "scale=-2:1080" -c:v libx264 -preset slow -crf 20 \
         -c:a aac -b:a 192k -movflags +faststart "$output"
  echo "✅ Transcodificado: $output"
}

# -----------------------------------------------------------------------------
# img2jpg / img2png: Conversión y optimización de imágenes (ImageMagick)
# -----------------------------------------------------------------------------
img2jpg() {
  if [ $# -lt 1 ]; then echo "Uso: img2jpg <imagen> [calidad: 85]"; return 1; fi
  if ! command -v magick &> /dev/null; then echo "❌ Falta ImageMagick"; return 1; fi

  local img="$1"
  local quality="${2:-85}"
  echo "🖼️  Optimizando JPG ($quality%)..."
  magick "$img" -strip -interlace Plane -gaussian-blur 0.05 -quality "$quality" "${img%.*}-optimized.jpg"
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
[[ $- == *i* ]] && echo "✅ Funciones cargadas"
