# =============================================================================
# FUNCIONES DE SHELL (functions.sh) - Adaptado para Zsh y Bash en NixOS
# =============================================================================
# Colección de funciones y utilidades para potenciar la terminal en NixOS.
#
# ÍNDICE:
#   1. Navegación y Gestión de Archivos
#   2. Utilidades NixOS y Paquetes
#   3. Sistema e Información
#   4. Discos y Almacenamiento
#   5. Multimedia (Audio, Video, Imágenes con FFmpeg)
# =============================================================================

# =============================================================================
# 1. NAVEGACIÓN Y GESTIÓN DE ARCHIVOS
# =============================================================================

# mkcd: Crear y entrar en un directorio
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# up: Subir niveles rápidamente (ej: up 3)
up() {
    local d=""
    local limit="${1:-1}"
    for ((i=1 ; i <= limit ; i++)); do
        d="$d/.."
    done
    d=$(echo "$d" | sed 's/^\///')
    [ -z "$d" ] && d=..
    cd "$d"
}

# backup: Copia de seguridad rápida con timestamp
backup() {
    cp -r "$1" "${1}.bak-$(date +%Y%m%d-%H%M%S)"
}

# extract: Descompresor universal inteligente
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
            *.tar.xz)    tar xJf "$1"     ;;
            *.tar.zst)   tar --zstd -xf "$1" ;;
            *)           echo "❌ No se puede extraer '$1' con extract()" ;;
        esac
    else
        echo "❌ '$1' no es un archivo válido"
    fi
}

# duh: Ver tamaño ordenado de carpetas
duh() {
    du -h --max-depth=1 "${1:-.}" 2>/dev/null | sort -hr
}

# =============================================================================
# 2. UTILIDADES NIXOS Y PAQUETES
# =============================================================================

# nix-where: Muestra la ruta física en /nix/store de un binario
nix-where() {
    local bin="${1:-}"
    if [ -z "$bin" ]; then
        echo "Uso: nix-where <comando>"
        return 1
    fi
    local path
    path=$(which "$bin" 2>/dev/null || true)
    if [ -n "$path" ]; then
        readlink -f "$path"
    else
        echo "❌ Binario '$bin' no encontrado en PATH."
        return 1
    fi
}

# nix-shell-pkg: Lanza una subshell efímera con los paquetes especificados
nix-shell-pkg() {
    if [ $# -eq 0 ]; then
        echo "Uso: nix-shell-pkg <paquete1> [paquete2...]"
        return 1
    fi
    nix-shell -p "$@"
}

# nix-run-tool: Ejecuta una herramienta efímera de nixpkgs sin instalarla permanentemente
nix-run-tool() {
    if [ $# -eq 0 ]; then
        echo "Uso: nix-run-tool <paquete> [argumentos...]"
        return 1
    fi
    local pkg="$1"
    shift
    nix run "nixpkgs#$pkg" -- "$@"
}

# nix-diff-generations: Compara las dos últimas generaciones del sistema
nix-diff-generations() {
    if command -v nvd &>/dev/null; then
        nvd diff /nix/var/nix/profiles/system-*-link | tail -n 2
    else
        echo "ℹ️ Instalando temporalmente 'nvd' para comparar generaciones..."
        nix run nixpkgs#nvd -- diff /nix/var/nix/profiles/system
    fi
}

# =============================================================================
# 3. SISTEMA E INFORMACIÓN
# =============================================================================

# sysinfo: Resumen rápido de recursos
sysinfo() {
    echo "=========================================="
    echo "💻 RESUMEN DEL SISTEMA NIXOS"
    echo "=========================================="
    echo "• Host:        $(hostname)"
    echo "• Kernel:      $(uname -r)"
    echo "• Uptime:      $(uptime -p)"
    echo "• Memoria:     $(free -h | awk '/Mem:/ {print $3 "/" $2}')"
    echo "• ZRAM/Swap:   $(free -h | awk '/Swap:/ {print $3 "/" $2}')"
    echo "• Generación:  $(readlink /nix/var/nix/profiles/system | grep -o 'system-[0-9]*-link' || echo 'Desconocida')"
    echo "=========================================="
}

# =============================================================================
# 4. MULTIMEDIA (FFmpeg & ImageMagick)
# =============================================================================

to-mp4() {
    local input="$1"
    local output="${input%.*}.mp4"
    ffmpeg -i "$input" -c:v libx264 -crf 20 -preset medium -c:a aac -b:a 192k "$output"
}

to-mp3() {
    local input="$1"
    local output="${input%.*}.mp3"
    ffmpeg -i "$input" -vn -c:a libmp3lame -q:a 2 "$output"
}

gif-from-video() {
    local input="$1"
    local output="${input%.*}.gif"
    local fps="${2:-15}"
    local scale="${3:-480}"
    ffmpeg -i "$input" -vf "fps=$fps,scale=$scale:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" "$output"
}
