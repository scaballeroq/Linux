#!/bin/bash
# =============================================================================
# ALIASES PARA YT-DLP (yt-dlp_aliases.sh) - Soplos Linux Boro
# =============================================================================
# Este archivo contiene atajos para descargar vídeos y audio usando yt-dlp.
# Optimizado con JS Runtime (Deno/Node via Mise) y concurrencia multihilo.
# =============================================================================

# Evitar ejecución en subshells y sesiones no interactivas
[[ $- != *i* ]] && return 0 2>/dev/null || true

# Motor de JS para yt-dlp (Deno o Node.js; detectamos si viene de mise o sistema)
if command -v deno &> /dev/null; then
    JS_RUNTIME="--js-runtimes deno"
elif command -v mise &> /dev/null && mise where deno &>/dev/null; then
    JS_RUNTIME="--js-runtimes deno:$(mise where deno)/bin/deno"
elif [ -x "$HOME/.local/share/mise/shims/node" ]; then
    JS_RUNTIME="--js-runtimes node:$HOME/.local/share/mise/shims/node"
elif command -v node &> /dev/null; then
    JS_RUNTIME="--js-runtimes node"
else
    JS_RUNTIME=""
fi

# Navegador predeterminado para cookies en Soplos Linux Boro
YT_BROWSER="firefox"

# Concurrencia de fragmentos para alta velocidad
DL_OPTS="--concurrent-fragments 4"

# 1. DESCARGA DE VÍDEO
# Descargar el mejor vídeo (hasta 1080p Full HD)
alias ytvideo="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 $DL_OPTS $JS_RUNTIME --rm-cache-dir"

# 2. DESCARGA DE AUDIO
# Descargar audio en MP3 de máxima calidad
alias ytaudio="yt-dlp -f 'ba' -x --audio-format mp3 --audio-quality 0 $DL_OPTS $JS_RUNTIME --rm-cache-dir"

# 3. LISTAS DE REPRODUCCIÓN
# Descargar lista en MP4 (Mantiene cookies para evitar bloqueos)
alias ytlista="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 --cookies-from-browser $YT_BROWSER -o '%(playlist_index)s - %(title)s.%(ext)s' --yes-playlist $DL_OPTS $JS_RUNTIME --rm-cache-dir"

# Descargar lista en MP3
alias ytlista-audio="yt-dlp -f 'ba' -x --audio-format mp3 --audio-quality 0 --cookies-from-browser $YT_BROWSER -o '%(playlist_index)s - %(title)s.%(ext)s' --yes-playlist $DL_OPTS $JS_RUNTIME --rm-cache-dir"

# 4. SUBTÍTULOS Y AVANZADO
# Descarga video con subtítulos (Optimizado para español)
alias ytdl-subs="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 $DL_OPTS $JS_RUNTIME --impersonate chrome --write-auto-subs --embed-subs --sub-langs 'es.*' --convert-subs srt --cookies-from-browser $YT_BROWSER --sleep-subtitles 15 --rm-cache-dir"

# -----------------------------------------------------------------------------
# MENSAJE DE CARGA
# -----------------------------------------------------------------------------
[[ $- == *i* ]] && echo "✅ Aliases de yt-dlp cargados (Soplos Linux Boro)"
