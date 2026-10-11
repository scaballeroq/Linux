#!/bin/bash
# =============================================================================
# FUNCIONES BASH (functions.sh) - Adaptado para Manjaro Linux
# =============================================================================

mkcd() {
    mkdir -p "$1" && cd "$1"
}

up() {
    local d=""
    local limit=${1:-1}
    for ((i=1 ; i <= limit ; i++)); do
        d=$d/..
    done
    d=$(echo "$d" | sed 's/^\///')
    if [ -z "$d" ]; then
        d=..
    fi
    cd "$d"
}

backup() {
    if [ $# -ne 1 ] || [ ! -e "$1" ]; then
        echo "Uso: backup <archivo>"
        return 1
    fi
    cp -r "$1" "${1}.bak-$(date +%Y%m%d-%H%M%S)"
    echo "✅ Copia creada: ${1}.bak-$(date +%Y%m%d-%H%M%S)"
}

extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.tar.xz)    tar xJf "$1"     ;;
            *.tar.zst)   tar --zstd -xf "$1" ;;
            *.pkg.tar.zst) tar --zstd -xf "$1" ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1" || 7za x "$1" ;;
            *.xz)        unxz "$1"        ;;
            *.zst)       unzstd "$1"      ;;
            *)           echo "'$1' no se puede extraer con esta función" ;;
        esac
    else
        echo "'$1' no es un archivo válido"
    fi
}

compress() {
    if [ $# -lt 1 ] || [ ! -d "$1" ]; then
        echo "Uso: compress <directorio>"
        return 1
    fi
    tar -czf "${1%/}.tar.gz" "${1%/}"
    echo "✅ Archivo comprimido: ${1%/}.tar.gz"
}

alias decompress="tar -xzf"

psgrep() {
    if [ $# -lt 1 ]; then echo "Uso: psgrep <nombre_proceso>"; return 1; fi
    ps aux | grep -v grep | grep -i -e VSZ -e "$1"
}

duh() {
    du -h --max-depth=1 "$@" 2>/dev/null | sort -hr
}

hg() {
    if [ $# -lt 1 ]; then echo "Uso: hg <termino>"; return 1; fi
    history | grep -i "$1"
}

iso2sd() {
    if [ $# -ne 2 ]; then
        echo "Uso: iso2sd <archivo_iso> <dispositivo_salida>"
        echo "Ejemplo: iso2sd ~/Manjaro-Gnome.iso /dev/sda"
        echo -e "\nDispositivos disponibles:"
        lsblk -d -o NAME,SIZE,MODEL | grep -E '^sd[a-z]|^nvme[0-9]n[0-9]' | awk '{print "/dev/"$1 " (" $2 ", " $3 ")"}'
        return 1
    else
        echo "⚠️ ADVERTENCIA: Se sobrescribirá todo el contenido de $2 con $1"
        read -rp "¿Estás completamente seguro? (s/N): " confirm
        if [[ "$confirm" =~ ^[Ss]$ ]]; then
            sudo dd bs=4M status=progress oflag=sync if="$1" of="$2"
            sudo eject "$2" 2>/dev/null || true
            echo "✅ ISO grabada con éxito en $2"
        else
            echo "❌ Operación cancelada."
        fi
    fi
}

format-drive() {
    if [ $# -ne 2 ]; then
        echo "Uso: format-drive <dispositivo> <nombre_etiqueta>"
        echo "Ejemplo: format-drive /dev/sda 'Mi_USB'"
        lsblk -d -o NAME,SIZE,MODEL -n | awk '{print "/dev/"$1 " (" $2 ")"}'
        return 1
    fi

    echo "⚠️ ADVERTENCIA: Se borrarán TODOS los datos en $1 y se formateará como exFAT ('$2')"
    read -rp "¿Continuar? (s/N): " confirm

    if [[ "$confirm" =~ ^[Ss]$ ]]; then
        echo "🗑️ Limpiando y creando tabla de particiones GPT..."
        sudo wipefs -a "$1"
        sudo dd if=/dev/zero of="$1" bs=1M count=50 status=progress
        sudo parted -s "$1" mklabel gpt
        sudo parted -s "$1" mkpart primary 1MiB 100%

        partition="$([[ "$1" == *"nvme"* ]] && echo "${1}p1" || echo "${1}1")"
        sudo partprobe "$1" 2>/dev/null || true
        sudo udevadm settle 2>/dev/null || true

        echo "💾 Formateando como exFAT..."
        sudo mkfs.exfat -n "$2" "$partition"
        echo "✅ Listo: $1 ($2)"
    else
        echo "❌ Cancelado"
    fi
}

webm2mp4() {
    if [ $# -ne 1 ]; then echo "Uso: webm2mp4 <archivo.webm>"; return 1; fi
    if ! command -v ffmpeg &> /dev/null; then echo "❌ Faltan dependencias: ffmpeg"; return 1; fi

    local input="$1"
    local output="${input%.webm}.mp4"
    ffmpeg -i "$input" -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 192k "$output"
    echo "✅ Video convertido: $output"
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

    echo "🎬 Transcodificando con H.265 (HEVC)..."
    ffmpeg -i "$1" -c:v libx265 -preset slow -crf 24 -c:a aac -b:a 192k "${1%.*}-optimized.mp4"
    echo "✅ Terminado: ${1%.*}-optimized.mp4"
}

img2jpg() {
    if [ $# -lt 1 ]; then echo "Uso: img2jpg <imagen>"; return 1; fi
    if ! command -v magick &> /dev/null; then echo "❌ Falta ImageMagick"; return 1; fi

    local img="$1"; shift
    echo "🖼️ Optimizando a JPG (Alta Calidad)..."
    magick "$img" "$@" -quality 95 -strip "${img%.*}-optimized.jpg"
    echo "✅ ${img%.*}-optimized.jpg"
}

img2jpg-small() {
    if [ $# -lt 1 ]; then echo "Uso: img2jpg-small <imagen>"; return 1; fi
    if ! command -v magick &> /dev/null; then echo "❌ Falta ImageMagick"; return 1; fi

    local img="$1"; shift
    echo "🖼️ Optimizando a JPG (Web/Small)..."
    magick "$img" "$@" -resize 1080x\> -quality 92 -strip "${img%.*}-optimized.jpg"
    echo "✅ ${img%.*}-optimized.jpg"
}

img2png() {
    if [ $# -lt 1 ]; then echo "Uso: img2png <imagen>"; return 1; fi
    if ! command -v magick &> /dev/null; then echo "❌ Falta ImageMagick"; return 1; fi

    local img="$1"; shift
    echo "🖼️ Optimizando PNG..."
    magick "$img" "$@" -strip -define png:compression-filter=5 \
        -define png:compression-level=9 \
        -define png:compression-strategy=1 \
        -define png:exclude-chunk=all \
        "${img%.*}-optimized.png"
    echo "✅ ${img%.*}-optimized.png"
}

manjaro-mirrors-fast() {
    echo "🌐 Clasificando los 5 espejos de Manjaro más rápidos..."
    sudo pacman-mirrors --fasttrack 5
    sudo pacman -Syy
    echo "✅ Lista de espejos de Manjaro optimizada y sincronizada."
}

pacman-clean-all() {
    echo "🧹 Limpiando caché de paquetes descargados de Pacman..."
    sudo pacman -Sc --noconfirm
    if command -v pamac &> /dev/null; then
        echo "🧹 Limpiando caché de compilación de Pamac/AUR..."
        pamac clean --build-files --keep 1 --no-confirm 2>/dev/null || true
    fi
    echo "🔍 Buscando paquetes huérfanos..."
    local orphans
    orphans=$(pacman -Qtdq 2>/dev/null || true)
    if [ -n "$orphans" ]; then
        echo "🗑️ Eliminando paquetes huérfanos:"
        echo "$orphans"
        sudo pacman -Rns $orphans --noconfirm
    else
        echo "✅ No se encontraron paquetes huérfanos en el sistema."
    fi
    echo "✅ Sistema Manjaro completamente limpio."
}

aur-search() {
    if [ $# -lt 1 ]; then echo "Uso: aur-search <nombre_paquete>"; return 1; fi
    if command -v pamac &> /dev/null; then
        pamac search -a "$1"
    else
        curl -s "https://aur.archlinux.org/rpc/?v=5&type=search&arg=$1" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data.get('results', []):
    print(f\"📦 \033[1;34m{r['Name']}\033[0m (v{r['Version']}) - {r.get('Description', 'Sin descripción')}\")
"
    fi
}

pamac-build-aur() {
    if [ $# -lt 1 ]; then echo "Uso: pamac-build-aur <nombre_paquete>"; return 1; fi
    if command -v pamac &> /dev/null; then
        pamac build "$1"
    else
        echo "❌ Pamac no está instalado. Instala pamac-cli o usa un helper AUR."
    fi
}

echo "✅ Funciones Bash cargadas: 📂 Navegación, 💻 Sistema, 💾 Disco, 🎬 Multimedia, 🐧 Manjaro"
