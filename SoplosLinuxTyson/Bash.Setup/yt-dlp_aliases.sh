#!/bin/bash
# =============================================================================
# ALIASES PARA YT-DLP (yt-dlp_aliases.sh) - Soplos Linux Tyson
# =============================================================================

# Motor de JS para yt-dlp (YouTube EJS / JS challenge solver)
JS_RUNTIME=""
if command -v yt-dlp &> /dev/null; then
    if command -v deno &> /dev/null; then
        JS_RUNTIME="--js-runtimes deno"
    elif command -v node &> /dev/null; then
        JS_RUNTIME="--js-runtimes node"
    elif command -v quickjs &> /dev/null; then
        JS_RUNTIME="--js-runtimes quickjs"
    elif command -v mise &> /dev/null && mise where deno &>/dev/null; then
        JS_RUNTIME="--js-runtimes deno:$(mise where deno)/bin/deno"
    elif command -v mise &> /dev/null && mise where node &>/dev/null; then
        JS_RUNTIME="--js-runtimes node:$(mise where node)/bin/node"
    fi
fi

# Navegador para extracción de cookies
YT_BROWSER="firefox"
if ! command -v firefox &> /dev/null; then
    if command -v google-chrome &> /dev/null; then
        YT_BROWSER="chrome"
    elif command -v chromium &> /dev/null; then
        YT_BROWSER="chromium"
    elif command -v brave-browser &> /dev/null; then
        YT_BROWSER="brave"
    fi
fi

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

# =============================================================================
# MENSAJE DE CARGA (Solo en sesiones interactivas)
# =============================================================================
[[ $- == *i* ]] && [ -t 1 ] && echo "✅ Aliases de yt-dlp cargados (Navegador: $YT_BROWSER${JS_RUNTIME:+, JS: $JS_RUNTIME})" || true

