#!/bin/bash
# =============================================================================
# ALIASES PARA YT-DLP (yt-dlp_aliases.sh) - openSUSE Tumbleweed (KDE Plasma 6)
# =============================================================================

# 1. Detección del motor JavaScript para retos n-token / n-sig de YouTube
JS_RUNTIME=""
if command -v yt-dlp &> /dev/null; then
    YT_VERSION=$(yt-dlp --version 2>/dev/null | awk 'NR==1')
    if [[ "$YT_VERSION" > "2025.11.11" ]]; then
        if command -v deno &> /dev/null; then
            JS_RUNTIME="--js-runtimes deno"
        elif [ -x "$HOME/.local/bin/mise" ] && "$HOME/.local/bin/mise" where deno &>/dev/null; then
            JS_RUNTIME="--js-runtimes deno:$("$HOME/.local/bin/mise" where deno)/bin/deno"
        elif command -v mise &> /dev/null && mise where deno &>/dev/null; then
            JS_RUNTIME="--js-runtimes deno:$(mise where deno)/bin/deno"
        elif command -v node &> /dev/null; then
            JS_RUNTIME="--js-runtimes node"
        fi
    fi
fi

# 2. Navegador predeterminado para cookies de sesión (evita bloqueos y límites)
if command -v google-chrome-stable &>/dev/null || command -v google-chrome &>/dev/null; then
    YT_BROWSER="chrome"
elif command -v firefox &>/dev/null; then
    YT_BROWSER="firefox"
else
    YT_BROWSER="chrome"
fi

# -----------------------------------------------------------------------------
# 3. ALIASES DE TERMINAL
# -----------------------------------------------------------------------------

# Descarga de vídeo óptimo hasta 1080p Full HD (MP4/MKV)
alias ytvideo="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 $JS_RUNTIME --rm-cache-dir"

# Descarga de audio en MP3 de máxima calidad (320k VBR/CBR)
alias ytaudio="yt-dlp -f 'ba' -x --audio-format mp3 --audio-quality 0 $JS_RUNTIME --rm-cache-dir"

# Descarga de listas de reproducción de vídeo
alias ytlista="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 --cookies-from-browser $YT_BROWSER -o '%(playlist_index)s - %(title)s.%(ext)s' --yes-playlist $JS_RUNTIME --rm-cache-dir"

# Descarga de listas de reproducción en audio MP3
alias ytlista-audio="yt-dlp -f 'ba' -x --audio-format mp3 --audio-quality 0 --cookies-from-browser $YT_BROWSER -o '%(playlist_index)s - %(title)s.%(ext)s' --yes-playlist $JS_RUNTIME --rm-cache-dir"

# Descarga con subtítulos automáticos en español e inglés
alias ytdl-subs="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 $JS_RUNTIME --write-auto-subs --embed-subs --sub-langs 'es.*,en.*' --convert-subs srt --cookies-from-browser $YT_BROWSER --sleep-subtitles 5 --rm-cache-dir"

echo "✅ Aliases de yt-dlp cargados ($YT_BROWSER, ${JS_RUNTIME:-nativo})"
