# =============================================================================
# ALIASES PARA YT-DLP (yt-dlp_aliases.zsh) - Manjaro Linux (ZSH)
# =============================================================================

# Motor de JS para yt-dlp
JS_RUNTIME=""
if command -v yt-dlp &> /dev/null; then
    YT_VERSION=$(yt-dlp --version | head -n1)
    if [[ "$YT_VERSION" > "2025.11.11" ]]; then
        if command -v deno &> /dev/null; then
            JS_RUNTIME="--js-runtimes deno"
        elif command -v mise &> /dev/null && mise where deno &>/dev/null; then
            JS_RUNTIME="--js-runtimes deno:$(mise where deno)/bin/deno"
        fi
    fi
fi

# Navegador predeterminado para cookies en Manjaro GNOME
YT_BROWSER="firefox"

# 1. DESCARGA DE VÍDEO (1080p Max)
alias ytvideo="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 $JS_RUNTIME --rm-cache-dir"

# 2. DESCARGA DE AUDIO (MP3 Alta Calidad)
alias ytaudio="yt-dlp -f 'ba' -x --audio-format mp3 --audio-quality 0 $JS_RUNTIME --rm-cache-dir"

# 3. LISTAS DE REPRODUCCIÓN
alias ytlista="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 --cookies-from-browser $YT_BROWSER -o '%(playlist_index)s - %(title)s.%(ext)s' --yes-playlist $JS_RUNTIME --rm-cache-dir"
alias ytlista-audio="yt-dlp -f 'ba' -x --audio-format mp3 --audio-quality 0 --cookies-from-browser $YT_BROWSER -o '%(playlist_index)s - %(title)s.%(ext)s' --yes-playlist $JS_RUNTIME --rm-cache-dir"

# 4. SUBTÍTULOS Y AVANZADO (Español)
alias ytdl-subs="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 $JS_RUNTIME --impersonate chrome --write-auto-subs --embed-subs --sub-langs 'es.*' --convert-subs srt --cookies-from-browser $YT_BROWSER --sleep-subtitles 15 --rm-cache-dir"

echo "✅ Aliases de yt-dlp para ZSH cargados ($YT_BROWSER)"
