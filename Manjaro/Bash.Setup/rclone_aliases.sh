# =============================================================================
# ARCHIVO DE ALIASES PARA RCLONE (rclone_aliases.sh) - Manjaro Linux (Bash)
# =============================================================================

RCLONE_LOG_DIR="$HOME/Workspace/rclone_logs"
mkdir -p "$RCLONE_LOG_DIR"

RCLONE_OPTS="--fast-list --transfers 8 --checkers 16 --tpslimit 10 --verbose -P"
RCLONE_REPOS_BASE="${RCLONE_REPOS_BASE:-$HOME/Workspace/Repositorios}"
RCLONE_EXT_BASE="${RCLONE_EXT_BASE:-/run/media/$USER/NVME_EXT}"

alias gdrive-imagenes="rclone sync \"\$HOME/Imágenes\" \"GoogleDrive:Imágenes\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_imagenes.log\""
alias gdrive-documentos="rclone sync \"\$HOME/Documentos/\" \"GoogleDrive:Documentos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_documentos.log\""
alias gdrive-videos="rclone sync \"\$HOME/Vídeos\" \"GoogleDrive:Vídeos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_videos.log\""
alias gdrive-musica="rclone sync \"\$HOME/Música\" \"GoogleDrive:Música\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_musica.log\""
alias gdrive-software="rclone sync \"$RCLONE_EXT_BASE/Software\" \"GoogleDrive:Workspace/Software\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_software.log\""
alias gdrive-kdenlive="rclone sync \"\$HOME/Workspace/Kdenlive/\" \"GoogleDrive:Workspace/Kdenlive\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_kdenlive.log\""
alias gdrive-repos="rclone sync \"$RCLONE_REPOS_BASE\" \"GoogleDrive:Workspace/Repositorios\" $RCLONE_OPTS --include \"*.zip\" --log-file \"$RCLONE_LOG_DIR/rclone_repos.log\""
alias gdrive-repos-manjaro="rclone sync \"$RCLONE_REPOS_BASE/Manjaro\" \"GoogleDrive:Workspace/Repositorios/Manjaro\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_manjaro.log\""
alias gdrive-repos-debian="rclone sync \"$RCLONE_REPOS_BASE/Debian\" \"GoogleDrive:Workspace/Repositorios/Debian\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_debian.log\""
alias gdrive-repos-loladelacamara="rclone sync \"$RCLONE_REPOS_BASE/loladelacamara.es\" \"GoogleDrive:Workspace/Repositorios/loladelacamara.es\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_loladelacamara.log\""

alias gdrive-imagenes-down="rclone sync \"GoogleDrive:Imágenes\" \"\$HOME/Imágenes\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_imagenes_down.log\""
alias gdrive-documentos-down="rclone sync \"GoogleDrive:Documentos\" \"\$HOME/Documentos/\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_documentos_down.log\""
alias gdrive-videos-down="rclone sync \"GoogleDrive:Vídeos\" \"\$HOME/Vídeos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_videos_down.log\""
alias gdrive-musica-down="rclone sync \"GoogleDrive:Música\" \"\$HOME/Música\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_musica.log\""
alias gdrive-kdenlive-down="rclone sync \"GoogleDrive:Workspace/Kdenlive\" \"\$HOME/Workspace/Kdenlive\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_kdenlive_down.log\""

alias lola-onedrive-documentos-down="rclone sync \"OneDrive:Documentos\" \"\$HOME/Workspace/loladelacamara/Documentos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_lola_onedrive_documentos_down.log\""

unset RCLONE_LOG_DIR
unset RCLONE_OPTS
unset RCLONE_REPOS_BASE
unset RCLONE_EXT_BASE

echo "✅ Aliases de rclone para Bash cargados"
