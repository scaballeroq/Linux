#!/bin/bash
# =============================================================================
# ARCHIVO DE FUNCIONES AVANZADAS (functions.sh) - Kubuntu
# =============================================================================
# Colección de funciones de shell organizadas por categorías:
# 1. Navegación y Directorios (mkcd, up)
# 2. Gestión de Archivos y Archivos Comprimidos (extract, backup, compress)
# 3. Monitorización e Inspección de Procesos (psgrep, duh, hg)
# 4. Administración de Discos y Medios (iso2sd, format-drive)
# 5. Multimedia y Conversión (webm2mp4, transcode-video-*, img2*)

# -----------------------------------------------------------------------------
# 1. NAVEGACIÓN Y DIRECTORIOS
# -----------------------------------------------------------------------------

# mkcd: Crea un directorio y entra en él inmediatamente
# Uso: mkcd <nombre_directorio>
mkcd() {
  if [ -z "$1" ]; then echo "Uso: mkcd <directorio>"; return 1; fi
  mkdir -p "$1" && cd "$1"
}

# up: Sube N niveles en el árbol de directorios (por defecto 1)
# Uso: up [numero_de_niveles] (Ej: up 3)
up() {
  local d=""
  local limit=${1:-1}
  for ((i=1; i<=limit; i++)); do
    d="../$d"
  done
  cd "$d" || return
}

# -----------------------------------------------------------------------------
# 2. GESTIÓN DE ARCHIVOS Y COMPRESIÓN
# -----------------------------------------------------------------------------

# extract: Extractor universal multiformato
# Uso: extract <archivo>
extract() {
  if [ -z "$1" ]; then echo "Uso: extract <archivo>"; return 1; fi
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
      *)           echo "❌ No se puede extraer '$1' con extract()" ;;
    esac
  else
    echo "❌ '$1' no es un archivo válido"
  fi
}

# backup: Crea una copia de seguridad rápida con fecha y hora
# Uso: backup <archivo_o_directorio>
backup() {
  if [ -z "$1" ]; then echo "Uso: backup <archivo_o_directorio>"; return 1; fi
  local target="${1%/}"
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  cp -r "$target" "${target}.bak_${timestamp}"
  echo "✅ Copia creada: ${target}.bak_${timestamp}"
}

# compress: Comprime rápidamente carpetas o archivos
# Uso: compress <formato> <nombre_salida> <archivos...>
# Formatos soportados: zip, tar, tar.gz, tar.bz2, tar.xz, 7z
compress() {
  if [ $# -lt 3 ]; then
    echo "Uso: compress <formato: zip|tar.gz|tar.bz2|tar.xz|7z> <nombre_salida> <origen...>"
    return 1
  fi
  local format="$1"
  local output="$2"
  shift 2

  case "$format" in
    zip)     zip -r "${output}.zip" "$@" ;;
    tar.gz)  tar -czf "${output}.tar.gz" "$@" ;;
    tar.bz2) tar -cjf "${output}.tar.bz2" "$@" ;;
    tar.xz)  tar -cJf "${output}.tar.xz" "$@" ;;
    7z)      7z a "${output}.7z" "$@" ;;
    *)       echo "❌ Formato '$format' no soportado." ;;
  esac
}

# -----------------------------------------------------------------------------
# 3. MONITORIZACIÓN E INSPECCIÓN DE PROCESOS
# -----------------------------------------------------------------------------

# psgrep: Busca procesos por nombre excluyendo el propio grep
# Uso: psgrep <termino_busqueda>
psgrep() {
  if [ -z "$1" ]; then echo "Uso: psgrep <termino>"; return 1; fi
  ps aux | grep -v grep | grep -i --color=auto "$1"
}

# duh: Muestra los directorios más pesados del directorio actual
# Uso: duh [numero_de_elementos] (Por defecto: 10)
duh() {
  local count="${1:-10}"
  du -h --max-depth=1 2>/dev/null | sort -hr | head -n "$count"
}

# hg: Busca en el historial de comandos usando fzf o grep
# Uso: hg [termino_a_buscar]
hg() {
  if command -v fzf &> /dev/null && [ -z "$1" ]; then
    history | fzf --tac --reverse
  else
    history | grep -i --color=auto "${1:-}"
  fi
}

# -----------------------------------------------------------------------------
# 4. ADMINISTRACIÓN DE DISCOS Y MEDIOS
# -----------------------------------------------------------------------------

# iso2sd: Graba una imagen ISO en una memoria USB / tarjeta SD de forma segura
# Uso: iso2sd <archivo.iso> <dispositivo> (Ej: iso2sd kubuntu.iso /dev/sdb)
iso2sd() {
  if [ $# -ne 2 ]; then
    echo "Uso: iso2sd <archivo_iso> <dispositivo_salida>"
    echo "Ejemplo: iso2sd ~/Kubuntu.iso /dev/sda"
    echo -e "\nDispositivos disponibles:"
    lsblk -d -o NAME | grep -E '^sd[a-z]' | awk '{print "/dev/"$1}'
    return 1
  fi

  local iso="$1"
  local dev="$2"

  if [ ! -f "$iso" ]; then
    echo "❌ Error: El archivo ISO '$iso' no existe."
    return 1
  fi

  if [ ! -b "$dev" ]; then
    echo "❌ Error: '$dev' no es un dispositivo de bloques válido."
    return 1
  fi

  echo "⚠️ ¡ATENCIÓN! Se van a borrar todos los datos en $dev."
  echo "Dispositivo seleccionado:"
  lsblk "$dev"
  read -p "¿Estás completamente seguro de continuar? (escribe 'si' en mayúsculas/minúsculas): " -r confirm
  if [[ "$confirm" =~ ^[sS][iI]$ ]]; then
    echo "ℹ️ Desmontando particiones del dispositivo..."
    sudo umount "${dev}"* 2>/dev/null || true
    echo "ℹ️ Escribiendo ISO con dd (esto puede tardar unos minutos)..."
    sudo dd if="$iso" of="$dev" bs=4M status=progress oflag=sync
    echo "ℹ️ Sincronizando buffers de disco..."
    sync
    echo "✅ Grabación completada correctamente."
  else
    echo "❌ Operación cancelada por el usuario."
  fi
}

# format-drive: Formatea un disco en FAT32, NTFS, EXT4 o EXFAT de forma guiada
# Uso: format-drive <dispositivo> <sistema_archivos: fat32|ntfs|ext4|exfat> <etiqueta>
format-drive() {
  if [ $# -lt 3 ]; then
    echo "Uso: format-drive <dispositivo> <fat32|ntfs|ext4|exfat> <etiqueta>"
    echo "Ejemplo: format-drive /dev/sdb1 ext4 MiDisco"
    return 1
  fi

  local dev="$1"
  local fstype="$2"
  local label="$3"

  if [ ! -b "$dev" ]; then echo "❌ Error: '$dev' no es un dispositivo válido."; return 1; fi

  echo "⚠️ Se formateará $dev como $fstype con etiqueta '$label'."
  read -p "¿Continuar? (s/N): " -r confirm
  if [[ "$confirm" =~ ^[sS]$ ]]; then
    sudo umount "$dev" 2>/dev/null || true
    case "$fstype" in
      fat32) sudo mkfs.vfat -F 32 -n "$label" "$dev" ;;
      ntfs)  sudo mkfs.ntfs -f -L "$label" "$dev" ;;
      ext4)  sudo mkfs.ext4 -L "$label" "$dev" ;;
      exfat) sudo mkfs.exfat -n "$label" "$dev" ;;
      *)     echo "❌ Sistema de archivos no soportado."; return 1 ;;
    esac
    echo "✅ Formateo completado."
  fi
}

# -----------------------------------------------------------------------------
# 5. MULTIMEDIA Y CONVERSIÓN
# -----------------------------------------------------------------------------

# webm2mp4: Convertir WebM a MP4
# Uso: webm2mp4 <archivo.webm>
webm2mp4() {
  if [ $# -ne 1 ]; then echo "Uso: webm2mp4 <archivo.webm>"; return 1; fi
  if ! command -v ffmpeg &> /dev/null; then echo "❌ Faltan dependencias: ffmpeg"; return 1; fi
  local input="$1"
  local output="${input%.*}.mp4"
  ffmpeg -i "$input" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 192k "$output"
  echo "✅ Convertido a: $output"
}

# transcode-video-1080p: Recodificar video a H.264 1080p con buen ratio de compresión
# Uso: transcode-video-1080p <entrada> <salida>
transcode-video-1080p() {
  if [ $# -ne 2 ]; then echo "Uso: transcode-video-1080p <entrada> <salida.mp4>"; return 1; fi
  ffmpeg -i "$1" -vf "scale=-2:1080" -c:v libx264 -crf 20 -preset medium -c:a aac -b:a 192k "$2"
}

# transcode-video-720p: Recodificar video a H.264 720p optimizado para tamaño
# Uso: transcode-video-720p <entrada> <salida>
transcode-video-720p() {
  if [ $# -ne 2 ]; then echo "Uso: transcode-video-720p <entrada> <salida.mp4>"; return 1; fi
  ffmpeg -i "$1" -vf "scale=-2:720" -c:v libx264 -crf 23 -preset fast -c:a aac -b:a 128k "$2"
}

# img2jpg / img2png: Conversión y optimización de imágenes (ImageMagick)
img2jpg() {
  if [ $# -ne 1 ]; then echo "Uso: img2jpg <imagen_origen>"; return 1; fi
  magick "$1" -quality 85 "${1%.*}.jpg"
}

img2png() {
  if [ $# -ne 1 ]; then echo "Uso: img2png <imagen_origen>"; return 1; fi
  magick "$1" "${1%.*}.png"
}

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Funciones cargadas"
