# =============================================================================
# ARCHIVO DE ALIASES PARA RCLONE (rclone_aliases.sh)
# =============================================================================

RCLONE_LOG_DIR="$HOME/Workspace/rclone_logs"
mkdir -p "$RCLONE_LOG_DIR"

RCLONE_OPTS="--fast-list --transfers 8 --checkers 16 --tpslimit 10 --verbose -P"

# -----------------------------------------------------------------------------
# 3. GOOGLE DRIVE (UPLOAD) - SUBIR A LA NUBE
# -----------------------------------------------------------------------------

alias gdrive-imagenes="rclone sync \"\$HOME/Imágenes\" \"GoogleDrive:Imágenes\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_imagenes.log\""
alias gdrive-documentos="rclone sync \"\$HOME/Documentos/\" \"GoogleDrive:Documentos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_linuxhowto.log\""
alias gdrive-videos="rclone sync \"\$HOME/Vídeos\" \"GoogleDrive:Vídeos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_videos.log\""
alias gdrive-musica="rclone sync \"\$HOME/Música\" \"GoogleDrive:Música\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_musica.log\""
alias gdrive-software="rclone sync \"/run/media/caballero/NVME_EXT/Software\" \"GoogleDrive:Workspace/Software\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_software.log\""
alias gdrive-kdenlive="rclone sync \"\$HOME/Workspace/Kdenlive/\" \"GoogleDrive:Workspace/Kdenlive\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_kdenlive.log\""
alias gdrive-repos="rclone sync \"\$HOME/Workspace/Repositorios\" \"GoogleDrive:Workspace/Repositorios\" $RCLONE_OPTS --include \"*.zip\" --log-file \"$RCLONE_LOG_DIR/rclone_repos.log\""
alias gdrive-repos-debian="rclone sync \"\$HOME/Workspace/Repositorios/Debian\" \"GoogleDrive:Workspace/Repositorios/Debian\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_debian.log\""
alias gdrive-repos-arch="rclone sync \"\$HOME/Workspace/Repositorios/ArchLinux\" \"GoogleDrive:Workspace/Repositorios/ArchLinux\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_arch.log\""
alias gdrive-repos-loladelacamara="rclone sync \"\$HOME/Workspace/Repositorios/loladelacamara.es\" \"GoogleDrive:Workspace/Repositorios/loladelacamara.es\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_arch.log\""

# -----------------------------------------------------------------------------
# 3.1. GOOGLE DRIVE (UPLOAD - DRY RUN) - SIMULACIONES DE SUBIDA
# -----------------------------------------------------------------------------

alias gdrive-imagenes-dry="rclone sync \"\$HOME/Imágenes\" \"GoogleDrive:Imágenes\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_imagenes_dry.log\""
alias gdrive-documentos-dry="rclone sync \"\$HOME/Documentos/\" \"GoogleDrive:Documentos\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_linuxhowto_dry.log\""
alias gdrive-videos-dry="rclone sync \"\$HOME/Vídeos\" \"GoogleDrive:Vídeos\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_videos_dry.log\""
alias gdrive-musica-dry="rclone sync \"\$HOME/Música\" \"GoogleDrive:Música\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_musica_dry.log\""
alias gdrive-software-dry="rclone sync \"/run/media/caballero/NVME_EXT/Software\" \"GoogleDrive:Workspace/Software\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_software_dry.log\""
alias gdrive-kdenlive-dry="rclone sync \"\$HOME/Workspace/Kdenlive/\" \"GoogleDrive:Workspace/Kdenlive\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_kdenlive_dry.log\""

# -----------------------------------------------------------------------------
# 4. GOOGLE DRIVE (DOWNLOAD) - BAJAR DE LA NUBE
# -----------------------------------------------------------------------------

alias gdrive-imagenes-down="rclone sync \"GoogleDrive:Imágenes\" \"\$HOME/Imágenes\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_imagenes_down.log\""
alias gdrive-documentos-down="rclone sync \"GoogleDrive:Documentos\" \"\$HOME/Documentos/\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_linuxhowto_down.log\""
alias gdrive-videos-down="rclone sync \"GoogleDrive:Vídeos\" \"\$HOME/Vídeos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_videos_down.log\""
alias gdrive-musica-down="rclone sync \"GoogleDrive:Música\" \"\$HOME/Música\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_musica_down.log\""
alias gdrive-kdenlive-down="rclone sync \"GoogleDrive:Workspace/Kdenlive\" \"\$HOME/Workspace/Kdenlive\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_kdenlive_down.log\""

# -----------------------------------------------------------------------------
# 4.1. GOOGLE DRIVE (DOWNLOAD - DRY RUN) - SIMULACIONES DE BAJADA
# -----------------------------------------------------------------------------

alias gdrive-imagenes-down-dry="rclone sync \"GoogleDrive:Imágenes\" \"\$HOME/Imágenes\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_imagenes_down_dry.log\""
alias gdrive-documentos-down-dry="rclone sync \"GoogleDrive:Documentos\" \"\$HOME/Documentos/\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_linuxhowto_down_dry.log\""
alias gdrive-videos-down-dry="rclone sync \"GoogleDrive:Vídeos\" \"\$HOME/Vídeos\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_videos_down_dry.log\""
alias gdrive-musica-down-dry="rclone sync \"GoogleDrive:Música\" \"\$HOME/Música\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_musica_down_dry.log\""

# -----------------------------------------------------------------------------
# 5. ONEDRIVE (DOWNLOAD) - BAJAR DE LA NUBE
# -----------------------------------------------------------------------------
alias lola-onedrive-documentos-down="rclone sync \"OneDrive:Documentos\" \"/home/caballero/Workspace/loladelacamara/Documentos\" \$RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_lola_onedrive_documentos_down.log\""

unset RCLONE_LOG_DIR
unset RCLONE_OPTS

