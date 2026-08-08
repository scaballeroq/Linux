#!/bin/bash
# =============================================================================
# ALIASES PARA YT-DLP (yt-dlp_aliases.sh)
# =============================================================================
# Este archivo contiene atajos para descargar vídeos y audio usando yt-dlp.

# Motor de JS para yt-dlp (Deno es recomendado; detectamos si viene de mise o sistema)
if command -v deno &> /dev/null; then
    JS_RUNTIME="--js-runtimes deno"
elif command -v mise &> /dev/null && mise where deno &>/dev/null; then
    JS_RUNTIME="--js-runtimes deno:$(mise where deno)/bin/deno"
else
    JS_RUNTIME=""
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

#echo "✅ Aliases de yt-dlp cargados (ytvideo, ytaudio, ytlista, ytlista-audio)"
echo "✅ Aliases de yt-dlp cargados"
