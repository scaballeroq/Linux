#!/bin/bash
# =============================================================================
# ALIASES PARA YT-DLP (yt-dlp_aliases.sh) - Debian Testing (KDE Plasma 6)
# =============================================================================

# Evitar ejecución en subshells y sesiones no interactivas
[[ $- != *i* ]] && return 0 2>/dev/null || true

# 1. Navegador predeterminado para cookies de sesión (evita bloqueos y límites)
if command -v google-chrome-stable &>/dev/null || command -v google-chrome &>/dev/null; then
    YT_BROWSER="chrome"
elif command -v firefox &>/dev/null; then
    YT_BROWSER="firefox"
else
    YT_BROWSER="chrome"
fi

# -----------------------------------------------------------------------------
# 2. ALIASES DE TERMINAL (Aprovechan ~/.config/yt-dlp/config)
# -----------------------------------------------------------------------------

# Descarga de vídeo óptimo hasta 1080p Full HD (MP4/MKV)
alias ytvideo="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4"

# Descarga de audio en MP3 de máxima calidad (320k VBR/CBR)
alias ytaudio="yt-dlp -f 'ba' -x --audio-format mp3 --audio-quality 0"

# Descarga de listas de reproducción de vídeo
alias ytlista="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 --cookies-from-browser $YT_BROWSER -o '%(playlist_index)02d - %(title)s.%(ext)s' --yes-playlist"

# Descarga de listas de reproducción en audio MP3
alias ytlista-audio="yt-dlp -f 'ba' -x --audio-format mp3 --audio-quality 0 --cookies-from-browser $YT_BROWSER -o '%(playlist_index)02d - %(title)s.%(ext)s' --yes-playlist"

# Descarga con subtítulos automáticos en español e inglés
alias ytdl-subs="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 --write-auto-subs --embed-subs --sub-langs 'es.*,en.*' --convert-subs srt --cookies-from-browser $YT_BROWSER --sleep-subtitles 5"

# Limpieza manual de caché de yt-dlp
alias ytclean="yt-dlp --rm-cache-dir"

