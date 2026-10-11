# =============================================================================
# ALIASES PARA YT-DLP (yt-dlp_aliases.sh) - Kubuntu
# =============================================================================
# Atajos para descargar vídeos y audio en alta calidad con yt-dlp.
# =============================================================================

# Motor JS para yt-dlp (Deno es recomendado; detección automática vía mise o sistema)
if command -v deno &> /dev/null; then
    _YT_JS_RUNTIME="--js-runtimes deno"
elif command -v mise &> /dev/null && mise where deno &>/dev/null; then
    _YT_JS_RUNTIME="--js-runtimes deno:$(mise where deno)/bin/deno"
else
    _YT_JS_RUNTIME=""
fi

# Navegador para cookies en Kubuntu (Firefox nativo por defecto)
_YT_BROWSER="firefox"

# Descarga de video en máxima calidad hasta 1080p en formato MP4
alias ytvideo="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 $_YT_JS_RUNTIME --cookies-from-browser $_YT_BROWSER --sleep-subtitles 15 --rm-cache-dir"

# Descarga de audio en formato MP3 con máxima calidad (VBR 0)
alias ytaudio="yt-dlp -x --audio-format mp3 --audio-quality 0 $_YT_JS_RUNTIME --cookies-from-browser $_YT_BROWSER --sleep-subtitles 15 --rm-cache-dir"

# Descarga listas de reproducción completas de video
alias ytlista="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 -o '%(playlist_index)s - %(title)s.%(ext)s' $_YT_JS_RUNTIME --cookies-from-browser $_YT_BROWSER --sleep-subtitles 15 --rm-cache-dir"

# Descarga listas de reproducción completas en formato MP3
alias ytlista-audio="yt-dlp -x --audio-format mp3 --audio-quality 0 -o '%(playlist_index)s - %(title)s.%(ext)s' $_YT_JS_RUNTIME --cookies-from-browser $_YT_BROWSER --sleep-subtitles 15 --rm-cache-dir"

# Descarga video con subtítulos en español
alias ytdl-subs="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 $_YT_JS_RUNTIME --write-auto-subs --embed-subs --sub-langs 'es.*' --convert-subs srt --cookies-from-browser $_YT_BROWSER --sleep-subtitles 15 --rm-cache-dir"

unset _YT_JS_RUNTIME
unset _YT_BROWSER
