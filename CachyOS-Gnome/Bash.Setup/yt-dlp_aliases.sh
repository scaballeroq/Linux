# =============================================================================
# ALIASES Y FUNCIONES PARA YT-DLP (yt-dlp_aliases.sh)
# Sistema: CachyOS Workstation (GNOME Shell Wayland)
# Compatible con Zsh y Bash (HP ProBook 455 G10 / AMD Ryzen 7 7730U)
# ==============================================================================
# Características:
#   - Detección inteligente de motor JS (Deno nativo o vía Mise, Node.js).
#   - Eliminación del anti-patrón --rm-cache-dir en descargas habituales.
#   - Integración nativa con el portapapeles de Wayland (wl-paste) en GNOME: ytclip y ytclip-audio.
#   - Reproducción directa en streaming acelerada por hardware con MPV: ytplay.
#   - Descargas multi-hilo aceleradas con --concurrent-fragments 4.
#   - Detección automática del navegador para cookies (Firefox nativo o Google Chrome).
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. RESOLUCIÓN DEL MOTOR JAVASCRIPT (Requerido por yt-dlp para firmas YouTube)
# ------------------------------------------------------------------------------
JS_RUNTIME=""
if command -v deno &> /dev/null; then
    JS_RUNTIME="--js-runtimes deno"
elif command -v mise &> /dev/null && mise which deno &>/dev/null; then
    JS_RUNTIME="--js-runtimes deno:$(mise which deno 2>/dev/null)"
elif command -v node &> /dev/null; then
    JS_RUNTIME="--js-runtimes node"
elif command -v mise &> /dev/null && mise which node &>/dev/null; then
    JS_RUNTIME="--js-runtimes node:$(mise which node 2>/dev/null)"
fi

# ------------------------------------------------------------------------------
# 2. NAVEGADOR PREDETERMINADO PARA COOKIES EN CACHYOS GNOME
# ------------------------------------------------------------------------------
if [ -z "${YT_BROWSER:-}" ]; then
    if [ -d "$HOME/.mozilla/firefox" ]; then
        YT_BROWSER="firefox"
    elif [ -d "$HOME/.config/google-chrome" ]; then
        YT_BROWSER="chrome"
    else
        YT_BROWSER="firefox"
    fi
fi

# ------------------------------------------------------------------------------
# 3. ALIASES PRINCIPALES DE DESCARGA (Caché habilitada y fragmentos concurrentes)
# ------------------------------------------------------------------------------

# Vídeo hasta 1080p MP4 (calidad óptima estándar)
alias ytvideo="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 --concurrent-fragments 4 $JS_RUNTIME"

# Vídeo máxima calidad disponible (4K / 1440p / 60fps)
alias ytvideo-max="yt-dlp -f 'bestvideo+bestaudio/best' --merge-output-format mp4 --concurrent-fragments 4 $JS_RUNTIME"

# Audio MP3 de alta fidelidad (VBR 0 / 320k)
alias ytaudio="yt-dlp -f 'ba' -x --audio-format mp3 --audio-quality 0 --concurrent-fragments 4 $JS_RUNTIME"

# Audio Opus nativo sin recodificación
alias ytopus="yt-dlp -f 'ba[ext=opus]/ba' -x --concurrent-fragments 4 $JS_RUNTIME"

# Lista de reproducción completa en vídeo 1080p con índice y cookies
alias ytlista="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 --cookies-from-browser $YT_BROWSER -o '%(playlist_index)02d - %(title)s.%(ext)s' --yes-playlist --concurrent-fragments 4 $JS_RUNTIME"

# Lista de reproducción completa en audio MP3
alias ytlista-audio="yt-dlp -f 'ba' -x --audio-format mp3 --audio-quality 0 --cookies-from-browser $YT_BROWSER -o '%(playlist_index)02d - %(title)s.%(ext)s' --yes-playlist --concurrent-fragments 4 $JS_RUNTIME"

# Descarga con subtítulos incrustados (Español / Inglés)
alias ytdl-subs="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 $JS_RUNTIME --write-auto-subs --embed-subs --sub-langs 'es.*,en.*' --convert-subs srt --cookies-from-browser $YT_BROWSER --concurrent-fragments 4"

# ------------------------------------------------------------------------------
# 4. UTILIDADES Y REPRODUCCIÓN EN STREAMING (MPV Wayland + VA-API)
# ------------------------------------------------------------------------------

# Inspeccionar formatos disponibles de un vídeo sin descargarlo
alias yt-info="yt-dlp -F $JS_RUNTIME"

# Limpieza manual de caché cuando expiran tokens o cookies
alias yt-cleancache="yt-dlp --rm-cache-dir"

# Reproducir en streaming directamente en MPV con aceleración por hardware (sin guardar en disco)
alias ytplay="mpv --vo=gpu-next --gpu-api=vulkan --hwdec=vaapi --ytdl-format='bestvideo[height<=1080]+bestaudio/best'"

# ------------------------------------------------------------------------------
# 5. FUNCIONES GNOME WAYLAND (Integración con el portapapeles wl-paste)
# ------------------------------------------------------------------------------

# Descarga vídeo 1080p desde argumento o directamente del portapapeles Wayland
ytclip() {
    local url="${1:-}"
    if [ -z "$url" ] && command -v wl-paste &>/dev/null; then
        url=$(wl-paste 2>/dev/null | tr -d '[:space:]' || true)
    fi
    if [ -z "$url" ]; then
        echo "❌ Uso: ytclip [URL] (o copia un enlace al portapapeles de Wayland)"
        return 1
    fi
    echo "📥 Descargando vídeo desde portapapeles Wayland: $url"
    yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 --concurrent-fragments 4 $JS_RUNTIME "$url"
}

# Descarga audio MP3 desde argumento o directamente del portapapeles Wayland
ytclip-audio() {
    local url="${1:-}"
    if [ -z "$url" ] && command -v wl-paste &>/dev/null; then
        url=$(wl-paste 2>/dev/null | tr -d '[:space:]' || true)
    fi
    if [ -z "$url" ]; then
        echo "❌ Uso: ytclip-audio [URL] (o copia un enlace al portapapeles de Wayland)"
        return 1
    fi
    echo "🎵 Extrayendo audio MP3 desde portapapeles Wayland: $url"
    yt-dlp -f 'ba' -x --audio-format mp3 --audio-quality 0 --concurrent-fragments 4 $JS_RUNTIME "$url"
}

# Feedback discreto en terminales interactivas
if [[ -t 1 ]]; then
    echo "✅ Aliases de yt-dlp para CachyOS GNOME cargados (ytvideo, ytaudio, ytlista, ytplay, ytclip)"
fi
