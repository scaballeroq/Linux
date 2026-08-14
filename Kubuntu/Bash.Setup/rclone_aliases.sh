# =============================================================================
# ARCHIVO DE ALIASES PARA RCLONE (rclone_aliases.sh) - Kubuntu
# =============================================================================
# Este archivo contiene atajos para comandos de rclone, facilitando la
# sincronización y copia con servicios en la nube como Google Drive y OneDrive.

# 1. Asegurar que el directorio de logs existe
RCLONE_LOG_DIR="$HOME/Workspace/rclone_logs"
mkdir -p "$RCLONE_LOG_DIR"

# 2. Opciones comunes optimizadas para Google Drive
# - tpslimit 10: Evita errores de límite de tasa (Rate Limit / User Rate Limit Exceeded) de la API de Google.
# - fast-list: Reduce drásticamente el número de llamadas a la API de Google, acelerando el escaneo.
RCLONE_OPTS="--fast-list --transfers 8 --checkers 16 --tpslimit 10 --verbose -P"

# Rutas base configurables
RCLONE_REPOS_BASE="${RCLONE_REPOS_BASE:-$HOME/Workspace/Repositorios}"
RCLONE_EXT_BASE="${RCLONE_EXT_BASE:-/run/media/$USER/NVME_EXT}"

# -----------------------------------------------------------------------------
# 3. GOOGLE DRIVE (UPLOAD - SYNC) - SUBIR Y SINCRONIZAR A LA NUBE (ESPEJO)
# -----------------------------------------------------------------------------

alias gdrive-imagenes="rclone sync \"\$HOME/Imágenes\" \"GoogleDrive:Imágenes\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_imagenes.log\""
alias gdrive-documentos="rclone sync \"\$HOME/Documentos/\" \"GoogleDrive:Documentos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_documentos.log\""
alias gdrive-videos="rclone sync \"\$HOME/Vídeos\" \"GoogleDrive:Vídeos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_videos.log\""
alias gdrive-musica="rclone sync \"\$HOME/Música\" \"GoogleDrive:Música\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_musica.log\""
alias gdrive-software="rclone sync \"$RCLONE_EXT_BASE/Software\" \"GoogleDrive:Workspace/Software\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_software.log\""
alias gdrive-kdenlive="rclone sync \"\$HOME/Workspace/Kdenlive/\" \"GoogleDrive:Workspace/Kdenlive\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_kdenlive.log\""
alias gdrive-repos="rclone sync \"$RCLONE_REPOS_BASE\" \"GoogleDrive:Workspace/Repositorios\" $RCLONE_OPTS --include \"*.zip\" --log-file \"$RCLONE_LOG_DIR/rclone_repos.log\""
alias gdrive-repos-kubuntu="rclone sync \"$RCLONE_REPOS_BASE/Kubuntu\" \"GoogleDrive:Workspace/Repositorios/Kubuntu\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_kubuntu.log\""
alias gdrive-repos-ubuntu="rclone sync \"$RCLONE_REPOS_BASE/Ubuntu\" \"GoogleDrive:Workspace/Repositorios/Ubuntu\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_ubuntu.log\""
alias gdrive-repos-debian="rclone sync \"$RCLONE_REPOS_BASE/Debian\" \"GoogleDrive:Workspace/Repositorios/Debian\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_debian.log\""
alias gdrive-repos-fedora="rclone sync \"$RCLONE_REPOS_BASE/Fedora\" \"GoogleDrive:Workspace/Repositorios/Fedora\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_fedora.log\""
alias gdrive-repos-archlinux="rclone sync \"$RCLONE_REPOS_BASE/ArchLinux\" \"GoogleDrive:Workspace/Repositorios/ArchLinux\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_archlinux.log\""
alias gdrive-repos-loladelacamara="rclone sync \"$RCLONE_REPOS_BASE/loladelacamara.es\" \"GoogleDrive:Workspace/Repositorios/loladelacamara.es\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_loladelacamara.log\""

# -----------------------------------------------------------------------------
# 3.1. GOOGLE DRIVE (UPLOAD - SYNC DRY RUN) - SIMULACIONES DE SUBIDA (SYNC)
# -----------------------------------------------------------------------------

alias gdrive-imagenes-dry="rclone sync \"\$HOME/Imágenes\" \"GoogleDrive:Imágenes\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_imagenes_dry.log\""
alias gdrive-documentos-dry="rclone sync \"\$HOME/Documentos/\" \"GoogleDrive:Documentos\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_documentos_dry.log\""
alias gdrive-videos-dry="rclone sync \"\$HOME/Vídeos\" \"GoogleDrive:Vídeos\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_videos_dry.log\""
alias gdrive-musica-dry="rclone sync \"\$HOME/Música\" \"GoogleDrive:Música\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_musica_dry.log\""
alias gdrive-software-dry="rclone sync \"$RCLONE_EXT_BASE/Software\" \"GoogleDrive:Workspace/Software\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_software_dry.log\""
alias gdrive-kdenlive-dry="rclone sync \"\$HOME/Workspace/Kdenlive/\" \"GoogleDrive:Workspace/Kdenlive\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_kdenlive_dry.log\""
alias gdrive-repos-dry="rclone sync \"$RCLONE_REPOS_BASE\" \"GoogleDrive:Workspace/Repositorios\" $RCLONE_OPTS --include \"*.zip\" --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_repos_dry.log\""
alias gdrive-repos-kubuntu-dry="rclone sync \"$RCLONE_REPOS_BASE/Kubuntu\" \"GoogleDrive:Workspace/Repositorios/Kubuntu\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_repos_kubuntu_dry.log\""
alias gdrive-repos-ubuntu-dry="rclone sync \"$RCLONE_REPOS_BASE/Ubuntu\" \"GoogleDrive:Workspace/Repositorios/Ubuntu\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_repos_ubuntu_dry.log\""
alias gdrive-repos-debian-dry="rclone sync \"$RCLONE_REPOS_BASE/Debian\" \"GoogleDrive:Workspace/Repositorios/Debian\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_repos_debian_dry.log\""
alias gdrive-repos-loladelacamara-dry="rclone sync \"$RCLONE_REPOS_BASE/loladelacamara.es\" \"GoogleDrive:Workspace/Repositorios/loladelacamara.es\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_repos_loladelacamara_dry.log\""

# -----------------------------------------------------------------------------
# 3.2. GOOGLE DRIVE (UPLOAD - COPY) - SUBIR A LA NUBE (SIN ELIMINAR EN DESTINO)
# -----------------------------------------------------------------------------

alias gdrive-imagenes-copy="rclone copy \"\$HOME/Imágenes\" \"GoogleDrive:Imágenes\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_imagenes_copy.log\""
alias gdrive-documentos-copy="rclone copy \"\$HOME/Documentos/\" \"GoogleDrive:Documentos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_documentos_copy.log\""
alias gdrive-videos-copy="rclone copy \"\$HOME/Vídeos\" \"GoogleDrive:Vídeos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_videos_copy.log\""
alias gdrive-musica-copy="rclone copy \"\$HOME/Música\" \"GoogleDrive:Música\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_musica_copy.log\""
alias gdrive-software-copy="rclone copy \"$RCLONE_EXT_BASE/Software\" \"GoogleDrive:Workspace/Software\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_software_copy.log\""
alias gdrive-kdenlive-copy="rclone copy \"\$HOME/Workspace/Kdenlive/\" \"GoogleDrive:Workspace/Kdenlive\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_kdenlive_copy.log\""
alias gdrive-repos-copy="rclone copy \"$RCLONE_REPOS_BASE\" \"GoogleDrive:Workspace/Repositorios\" $RCLONE_OPTS --include \"*.zip\" --log-file \"$RCLONE_LOG_DIR/rclone_repos_copy.log\""
alias gdrive-repos-kubuntu-copy="rclone copy \"$RCLONE_REPOS_BASE/Kubuntu\" \"GoogleDrive:Workspace/Repositorios/Kubuntu\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_kubuntu_copy.log\""
alias gdrive-repos-ubuntu-copy="rclone copy \"$RCLONE_REPOS_BASE/Ubuntu\" \"GoogleDrive:Workspace/Repositorios/Ubuntu\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_ubuntu_copy.log\""
alias gdrive-repos-debian-copy="rclone copy \"$RCLONE_REPOS_BASE/Debian\" \"GoogleDrive:Workspace/Repositorios/Debian\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_debian_copy.log\""
alias gdrive-repos-loladelacamara-copy="rclone copy \"$RCLONE_REPOS_BASE/loladelacamara.es\" \"GoogleDrive:Workspace/Repositorios/loladelacamara.es\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_repos_loladelacamara_copy.log\""

# -----------------------------------------------------------------------------
# 3.3. GOOGLE DRIVE (UPLOAD - COPY DRY RUN) - SIMULACIONES DE COPIA DE SUBIDA
# -----------------------------------------------------------------------------

alias gdrive-imagenes-copy-dry="rclone copy \"\$HOME/Imágenes\" \"GoogleDrive:Imágenes\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_imagenes_copy_dry.log\""
alias gdrive-documentos-copy-dry="rclone copy \"\$HOME/Documentos/\" \"GoogleDrive:Documentos\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_documentos_copy_dry.log\""
alias gdrive-videos-copy-dry="rclone copy \"\$HOME/Vídeos\" \"GoogleDrive:Vídeos\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_videos_copy_dry.log\""
alias gdrive-musica-copy-dry="rclone copy \"\$HOME/Música\" \"GoogleDrive:Música\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_musica_copy_dry.log\""
alias gdrive-software-copy-dry="rclone copy \"$RCLONE_EXT_BASE/Software\" \"GoogleDrive:Workspace/Software\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_software_copy_dry.log\""
alias gdrive-kdenlive-copy-dry="rclone copy \"\$HOME/Workspace/Kdenlive/\" \"GoogleDrive:Workspace/Kdenlive\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_kdenlive_copy_dry.log\""
alias gdrive-repos-copy-dry="rclone copy \"$RCLONE_REPOS_BASE\" \"GoogleDrive:Workspace/Repositorios\" $RCLONE_OPTS --include \"*.zip\" --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_repos_copy_dry.log\""
alias gdrive-repos-kubuntu-copy-dry="rclone copy \"$RCLONE_REPOS_BASE/Kubuntu\" \"GoogleDrive:Workspace/Repositorios/Kubuntu\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_repos_kubuntu_copy_dry.log\""
alias gdrive-repos-ubuntu-copy-dry="rclone copy \"$RCLONE_REPOS_BASE/Ubuntu\" \"GoogleDrive:Workspace/Repositorios/Ubuntu\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_repos_ubuntu_copy_dry.log\""
alias gdrive-repos-debian-copy-dry="rclone copy \"$RCLONE_REPOS_BASE/Debian\" \"GoogleDrive:Workspace/Repositorios/Debian\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_repos_debian_copy_dry.log\""
alias gdrive-repos-loladelacamara-copy-dry="rclone copy \"$RCLONE_REPOS_BASE/loladelacamara.es\" \"GoogleDrive:Workspace/Repositorios/loladelacamara.es\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_repos_loladelacamara_copy_dry.log\""

# -----------------------------------------------------------------------------
# 4. GOOGLE DRIVE (DOWNLOAD - SYNC) - BAJAR DE LA NUBE (ESPEJO)
# -----------------------------------------------------------------------------

alias gdrive-imagenes-down="rclone sync \"GoogleDrive:Imágenes\" \"\$HOME/Imágenes\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_imagenes_down.log\""
alias gdrive-documentos-down="rclone sync \"GoogleDrive:Documentos\" \"\$HOME/Documentos/\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_documentos_down.log\""
alias gdrive-videos-down="rclone sync \"GoogleDrive:Vídeos\" \"\$HOME/Vídeos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_videos_down.log\""
alias gdrive-musica-down="rclone sync \"GoogleDrive:Música\" \"\$HOME/Música\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_musica_down.log\""
alias gdrive-kdenlive-down="rclone sync \"GoogleDrive:Workspace/Kdenlive\" \"\$HOME/Workspace/Kdenlive\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_kdenlive_down.log\""

# -----------------------------------------------------------------------------
# 4.1. GOOGLE DRIVE (DOWNLOAD - SYNC DRY RUN) - SIMULACIONES DE BAJADA (SYNC)
# -----------------------------------------------------------------------------

alias gdrive-imagenes-down-dry="rclone sync \"GoogleDrive:Imágenes\" \"\$HOME/Imágenes\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_imagenes_down_dry.log\""
alias gdrive-documentos-down-dry="rclone sync \"GoogleDrive:Documentos\" \"\$HOME/Documentos/\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_documentos_down_dry.log\""
alias gdrive-videos-down-dry="rclone sync \"GoogleDrive:Vídeos\" \"\$HOME/Vídeos\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_videos_down_dry.log\""
alias gdrive-musica-down-dry="rclone sync \"GoogleDrive:Música\" \"\$HOME/Música\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_musica_down_dry.log\""
alias gdrive-kdenlive-down-dry="rclone sync \"GoogleDrive:Workspace/Kdenlive\" \"\$HOME/Workspace/Kdenlive\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_kdenlive_down_dry.log\""

# -----------------------------------------------------------------------------
# 4.2. GOOGLE DRIVE (DOWNLOAD - COPY) - BAJAR DE LA NUBE (SIN ELIMINAR EN DESTINO)
# -----------------------------------------------------------------------------

alias gdrive-imagenes-down-copy="rclone copy \"GoogleDrive:Imágenes\" \"\$HOME/Imágenes\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_imagenes_down_copy.log\""
alias gdrive-documentos-down-copy="rclone copy \"GoogleDrive:Documentos\" \"\$HOME/Documentos/\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_documentos_down_copy.log\""
alias gdrive-videos-down-copy="rclone copy \"GoogleDrive:Vídeos\" \"\$HOME/Vídeos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_videos_down_copy.log\""
alias gdrive-musica-down-copy="rclone copy \"GoogleDrive:Música\" \"\$HOME/Música\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_musica_down_copy.log\""
alias gdrive-kdenlive-down-copy="rclone copy \"GoogleDrive:Workspace/Kdenlive\" \"\$HOME/Workspace/Kdenlive\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_kdenlive_down_copy.log\""

# -----------------------------------------------------------------------------
# 4.3. GOOGLE DRIVE (DOWNLOAD - COPY DRY RUN) - SIMULACIONES DE BAJADA (COPY)
# -----------------------------------------------------------------------------

alias gdrive-imagenes-down-copy-dry="rclone copy \"GoogleDrive:Imágenes\" \"\$HOME/Imágenes\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_imagenes_down_copy_dry.log\""
alias gdrive-documentos-down-copy-dry="rclone copy \"GoogleDrive:Documentos\" \"\$HOME/Documentos/\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_documentos_down_copy_dry.log\""
alias gdrive-videos-down-copy-dry="rclone copy \"GoogleDrive:Vídeos\" \"\$HOME/Vídeos\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_videos_down_copy_dry.log\""
alias gdrive-musica-down-copy-dry="rclone copy \"GoogleDrive:Música\" \"\$HOME/Música\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_musica_down_copy_dry.log\""
alias gdrive-kdenlive-down-copy-dry="rclone copy \"GoogleDrive:Workspace/Kdenlive\" \"\$HOME/Workspace/Kdenlive\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_kdenlive_down_copy_dry.log\""

# -----------------------------------------------------------------------------
# 5. ONEDRIVE (DOWNLOAD) - BAJAR DE LA NUBE
# -----------------------------------------------------------------------------

alias lola-onedrive-documentos-down="rclone sync \"OneDrive:Documentos\" \"\$HOME/Workspace/loladelacamara/Documentos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_lola_onedrive_documentos_down.log\""
alias lola-onedrive-documentos-down-dry="rclone sync \"OneDrive:Documentos\" \"\$HOME/Workspace/loladelacamara/Documentos\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_lola_onedrive_documentos_down_dry.log\""
alias lola-onedrive-documentos-down-copy="rclone copy \"OneDrive:Documentos\" \"\$HOME/Workspace/loladelacamara/Documentos\" $RCLONE_OPTS --log-file \"$RCLONE_LOG_DIR/rclone_lola_onedrive_documentos_down_copy.log\""
alias lola-onedrive-documentos-down-copy-dry="rclone copy \"OneDrive:Documentos\" \"\$HOME/Workspace/loladelacamara/Documentos\" $RCLONE_OPTS --dry-run --log-file \"$RCLONE_LOG_DIR/rclone_lola_onedrive_documentos_down_copy_dry.log\""

# 6. Limpieza de variables temporales para evitar contaminar la shell
unset RCLONE_LOG_DIR
unset RCLONE_OPTS
unset RCLONE_REPOS_BASE
unset RCLONE_EXT_BASE

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Aliases de rclone cargados"
