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

alias gdrive-bingwallpaper='rclone sync "$HOME/Imágenes/BingWallpaper" "GoogleDrive:Imágenes/BingWallpaper" $RCLONE_OPTS --log-file "$RCLONE_LOG_DIR/rclone_bing.log"'
alias gdrive-wallpaper='rclone sync "$HOME/Imágenes/Wallpaper" "GoogleDrive:Imágenes/Wallpaper" $RCLONE_OPTS --log-file "$RCLONE_LOG_DIR/rclone_wallpaper.log"'
alias gdrive-documentos='rclone sync "$HOME/Documentos/" "GoogleDrive:Documentos" $RCLONE_OPTS --log-file "$RCLONE_LOG_DIR/rclone_linuxhowto.log"'
alias gdrive-avatar='rclone sync "$HOME/Imágenes/Avatar" "GoogleDrive:Avatar" $RCLONE_OPTS --log-file "$RCLONE_LOG_DIR/rclone_avatar.log"'
alias gdrive-videos='rclone sync "$HOME/Vídeos" "GoogleDrive:Vídeos" $RCLONE_OPTS --log-file "$RCLONE_LOG_DIR/rclone_videos.log"'
alias gdrive-musica='rclone sync "$HOME/Música" "GoogleDrive:Música" $RCLONE_OPTS --log-file "$RCLONE_LOG_DIR/rclone_musica.log"'
alias gdrive-software='rclone sync "/media/caballero/NVME_EXT/Software" "GoogleDrive:Software" $RCLONE_OPTS --log-file "$RCLONE_LOG_DIR/rclone_software.log"'

# -----------------------------------------------------------------------------
# 4. GOOGLE DRIVE (DOWNLOAD) - BAJAR DE LA NUBE
# -----------------------------------------------------------------------------

alias gdrive-bingwallpaper-down='rclone sync "GoogleDrive:Imágenes/BingWallpaper" "$HOME/Imágenes/BingWallpaper" $RCLONE_OPTS --log-file "$RCLONE_LOG_DIR/rclone_bing_down.log"'
alias gdrive-wallpaper-down='rclone sync "GoogleDrive:Imágenes/Wallpaper" "$HOME/Imágenes/Wallpaper" $RCLONE_OPTS --log-file "$RCLONE_LOG_DIR/rclone_wallpaper_down.log"'
alias gdrive-documentos-down='rclone sync "GoogleDrive:Documentos" "$HOME/Documentos/" $RCLONE_OPTS --log-file "$RCLONE_LOG_DIR/rclone_linuxhowto_down.log"'
alias gdrive-avatar-down='rclone sync "GoogleDrive:Avatar" "$HOME/Imágenes/Avatar" $RCLONE_OPTS --log-file "$RCLONE_LOG_DIR/rclone_avatar_down.log"'
alias gdrive-videos-down='rclone sync "GoogleDrive:Vídeos" "$HOME/Vídeos" $RCLONE_OPTS --log-file "$RCLONE_LOG_DIR/rclone_videos_down.log"'
alias gdrive-musica-down='rclone sync "GoogleDrive:Música" "$HOME/Música" $RCLONE_OPTS --log-file "$RCLONE_LOG_DIR/rclone_musica_down.log"'

# 5. Limpieza de variables temporales para evitar contaminar la shell
unset RCLONE_LOG_DIR
unset RCLONE_OPTS

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Aliases de rclone cargados"
