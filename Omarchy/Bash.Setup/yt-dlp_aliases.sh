# =============================================================================
# ALIASES PARA YT-DLP (yt-dlp_aliases.sh) - Omarchy
# =============================================================================

if command -v deno &> /dev/null; then
    JS_RUNTIME="--js-runtimes deno"
elif command -v mise &> /dev/null && mise where deno &>/dev/null; then
    JS_RUNTIME="--js-runtimes deno:$(mise where deno)/bin/deno"
else
    JS_RUNTIME=""
fi

if command -v google-chrome-stable &> /dev/null || command -v google-chrome &> /dev/null; then
    YT_BROWSER="chrome"
elif command -v brave &> /dev/null; then
    YT_BROWSER="brave"
else
    YT_BROWSER="firefox"
fi

alias ytvideo="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 $JS_RUNTIME --rm-cache-dir"

alias ytaudio="yt-dlp -f 'ba' -x --audio-format mp3 --audio-quality 0 $JS_RUNTIME --rm-cache-dir"

alias ytlista="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 --cookies-from-browser $YT_BROWSER -o '%(playlist_index)s - %(title)s.%(ext)s' --yes-playlist $JS_RUNTIME --rm-cache-dir"

alias ytlista-audio="yt-dlp -f 'ba' -x --audio-format mp3 --audio-quality 0 --cookies-from-browser $YT_BROWSER -o '%(playlist_index)s - %(title)s.%(ext)s' --yes-playlist $JS_RUNTIME --rm-cache-dir"

alias ytdl-subs="yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' --merge-output-format mp4 $JS_RUNTIME --impersonate chrome --write-auto-subs --embed-subs --sub-langs 'es.*' --convert-subs srt --cookies-from-browser $YT_BROWSER --sleep-subtitles 15 --rm-cache-dir"

