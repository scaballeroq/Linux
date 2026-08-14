#!/bin/bash
# =============================================================================
# ALIASES PARA YT-DLP (yt-dlp_aliases.sh) - Kubuntu
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

# Navegador predeterminado para cookies (Kubuntu suele usar firefox o chrome)
YT_BROWSER="firefox"

# Descarga de video en máxima calidad hasta 1080p en formato MP4
alias ytvideo="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 $JS_RUNTIME --cookies-from-browser $YT_BROWSER --sleep-subtitles 15 --rm-cache-dir"

# Descarga de audio en formato MP3 con máxima calidad (VBR 0)
alias ytaudio="yt-dlp -x --audio-format mp3 --audio-quality 0 $JS_RUNTIME --cookies-from-browser $YT_BROWSER --sleep-subtitles 15 --rm-cache-dir"

# Descarga listas de reproducción completas de video
alias ytlista="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 -o '%(playlist_index)s - %(title)s.%(ext)s' $JS_RUNTIME --cookies-from-browser $YT_BROWSER --sleep-subtitles 15 --rm-cache-dir"

# Descarga listas de reproducción completas en formato MP3
alias ytlista-audio="yt-dlp -x --audio-format mp3 --audio-quality 0 -o '%(playlist_index)s - %(title)s.%(ext)s' $JS_RUNTIME --cookies-from-browser $YT_BROWSER --sleep-subtitles 15 --rm-cache-dir"

# Descarga video con subtítulos (Optimizado para español)
alias ytdl-subs="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 $JS_RUNTIME --impersonate chrome --write-auto-subs --embed-subs --sub-langs 'es.*' --convert-subs srt --cookies-from-browser $YT_BROWSER --sleep-subtitles 15 --rm-cache-dir"

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Aliases de yt-dlp cargados"
