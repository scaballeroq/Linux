#!/bin/bash
# =============================================================================
# ALIASES PARA YT-DLP (yt-dlp_aliases.sh) - Adaptado para Ubuntu
# =============================================================================

# Motor de JS para yt-dlp (Soportado a partir de la versión 2025.11.12)
JS_RUNTIME=""
if command -v yt-dlp &> /dev/null; then
    YT_VERSION=$(yt-dlp --version | head -n1)
    # Comprobación de versión (Formato YYYY.MM.DD)
    if [[ "$YT_VERSION" > "2025.11.11" ]]; then
        if command -v deno &> /dev/null; then
            JS_RUNTIME="--js-runtimes deno"
        elif command -v mise &> /dev/null && mise where deno &>/dev/null; then
            JS_RUNTIME="--js-runtimes deno:$(mise where deno)/bin/deno"
        fi
    fi
fi

# Navegador predeterminado para cookies (Ubuntu suele usar firefox o chrome)
YT_BROWSER="firefox"

# 1. DESCARGA DE VÍDEO
# Descargar el mejor vídeo (hasta 1080p)
alias ytvideo="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 $JS_RUNTIME --rm-cache-dir"

# 2. DESCARGA DE AUDIO
# Descargar audio en MP3
alias ytaudio="yt-dlp -f 'ba' -x --audio-format mp3 --audio-quality 0 $JS_RUNTIME --rm-cache-dir"

# 3. LISTAS DE REPRODUCCIÓN
# Descargar lista en MP4 (Mantiene cookies para evitar bloqueos)
alias ytlista="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 --cookies-from-browser $YT_BROWSER -o '%(playlist_index)s - %(title)s.%(ext)s' --yes-playlist $JS_RUNTIME --rm-cache-dir"

# Descargar lista en MP3
alias ytlista-audio="yt-dlp -f 'ba' -x --audio-format mp3 --audio-quality 0 --cookies-from-browser $YT_BROWSER -o '%(playlist_index)s - %(title)s.%(ext)s' --yes-playlist $JS_RUNTIME --rm-cache-dir"

# 4. SUBTÍTULOS Y AVANZADO
# Descarga video con subtítulos (Optimizado para español)
alias ytdl-subs="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 $JS_RUNTIME --impersonate chrome --write-auto-subs --embed-subs --sub-langs 'es.*' --convert-subs srt --cookies-from-browser $YT_BROWSER --sleep-subtitles 15 --rm-cache-dir"

echo "✅ Aliases de yt-dlp cargados ($YT_BROWSER, $JS_RUNTIME)"
