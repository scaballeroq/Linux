# =============================================================================
# ARCHIVO DE ALIASES PARA RCLONE (rclone_aliases.sh)
# =============================================================================
# Este archivo contiene atajos para comandos de rclone, facilitando la
# sincronización con servicios en la nube como Google Drive.

# 1. Asegurar que el directorio de logs existe
RCLONE_LOG_DIR="$HOME/Workspace/rclone_logs"
mkdir -p "$RCLONE_LOG_DIR"

# 2. Opciones comunes optimizadas para Google Drive
# - tpslimit 10: Evita errores de límite de tasa (Rate Limit / User Rate Limit Exceeded) de la API de Google.
# - fast-list: Reduce drásticamente el número de llamadas a la API de Google, acelerando el escaneo.
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
alias gdrive-repos="rclone sync \"\$HOME/Workspace/Repos-Linux\" \"GoogleDrive:Workspace/Repos-Linux\" $RCLONE_OPTS --include \"*.zip\" --log-file \"$RCLONE_LOG_DIR/rclone_repos.log\""
alias gdrive-repos-debian="rclone sync \"\$HOME/Workspace/Repos-Linux/Debian\" \"GoogleDrive:Workspace/Repos-Linux/Debian\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_debian.log\""
alias gdrive-repos-ubuntu="rclone sync \"\$HOME/Workspace/Repos-Linux/Ubuntu\" \"GoogleDrive:Workspace/Repos-Linux/Ubuntu\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_ubuntu.log\""
alias gdrive-repos-kubuntu="rclone sync \"\$HOME/Workspace/Repos-Linux/Kubuntu\" \"GoogleDrive:Workspace/Repos-Linux/Kubuntu\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_kubuntu.log\""
alias gdrive-repos-fedora="rclone sync \"\$HOME/Workspace/Repos-Linux/Fedora\" \"GoogleDrive:Workspace/Repos-Linux/Fedora\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_fedora.log\""
alias gdrive-repos-loladelacamara="rclone sync \"\$HOME/Workspace/Repos-Linux/loladelacamara.es\" \"GoogleDrive:Workspace/Repos-Linux/loladelacamara.es\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_fedora.log\""

# -----------------------------------------------------------------------------
# 4. GOOGLE DRIVE (DOWNLOAD) - BAJAR DE LA NUBE
# -----------------------------------------------------------------------------

alias gdrive-imagenes-down="rclone sync \"GoogleDrive:Imágenes\" \"\$HOME/Imágenes\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_imagenes_down.log\""
alias gdrive-documentos-down="rclone sync \"GoogleDrive:Documentos\" \"\$HOME/Documentos/\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_linuxhowto_down.log\""
alias gdrive-videos-down="rclone sync \"GoogleDrive:Vídeos\" \"\$HOME/Vídeos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_videos_down.log\""
alias gdrive-musica-down="rclone sync \"GoogleDrive:Música\" \"\$HOME/Música\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_musica_down.log\""
alias gdrive-kdenlive-down="rclone sync \"GoogleDrive:Workspace/Kdenlive\" \"\$HOME/Workspace/Kdenlive\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_kdenlive_down.log\""

# -----------------------------------------------------------------------------
# 5. ONEDRIVE (DOWNLOAD) - BAJAR DE LA NUBE
# -----------------------------------------------------------------------------
alias lola-onedrive-documentos-down="rclone sync \"OneDrive:Documentos\" \"/home/caballero/Workspace/loladelacamara/Documentos\" \$RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_lola_onedrive_documentos_down.log\""

# 6. Limpieza de variables temporales para evitar contaminar la shell
unset RCLONE_LOG_DIR
unset RCLONE_OPTS

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Aliases de rclone cargados"
