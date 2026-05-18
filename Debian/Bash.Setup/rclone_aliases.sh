# =============================================================================
# ARCHIVO DE ALIASES PARA RCLONE (rclone_aliases.sh)
# =============================================================================
# Este archivo contiene atajos para comandos de rclone, facilitando la
# sincronización con servicios en la nube como Google Drive.

# -----------------------------------------------------------------------------
# 1. GOOGLE DRIVE
# -----------------------------------------------------------------------------

# Sincronización de BingWallpaper con Google Drive
alias gdrive-bingwallpaper='rclone sync /home/caballero/Imágenes/BingWallpaper GoogleDrive:Imágenes/BingWallpaper \
  --fast-list \
  --transfers 8 \
  --checkers 16 \
  --tpslimit 10 \
  --verbose \
  --log-file /home/caballero/Workspace/rclone_logs/rclone_bing.log \
  -P'

# Sincronización de Wallpaper con Google Drive
alias gdrive-wallpaper='rclone sync /home/caballero/Imágenes/Wallpaper GoogleDrive:Imágenes/Wallpaper \
  --fast-list \
  --transfers 8 \
  --checkers 16 \
  --tpslimit 10 \
  --verbose \
  --log-file /home/caballero/Workspace/rclone_logs/rclone_wallpaper.log \
  -P'

# Sincronización de Documentos con Google Drive
alias gdrive-documentos='rclone sync "/home/caballero/Documentos/" "GoogleDrive:Documentos" \
  --fast-list \
  --transfers 8 \
  --checkers 16 \
  --tpslimit 10 \
  --verbose \
  --log-file /home/caballero/Workspace/rclone_logs/rclone_linuxhowto.log \
  -P'

# Sincronización de Avatar con Google Drive
alias gdrive-avatar='rclone sync /home/caballero/Imágenes/Avatar GoogleDrive:Avatar \
  --fast-list \
  --transfers 8 \
  --checkers 16 \
  --tpslimit 10 \
  --verbose \
  --log-file /home/caballero/Workspace/rclone_logs/rclone_avatar.log \
  -P'

# Sincronización de Vídeos con Google Drive
alias gdrive-videos='rclone sync /home/caballero/Vídeos GoogleDrive:Vídeos \
  --fast-list \
  --transfers 8 \
  --checkers 16 \
  --tpslimit 10 \
  --verbose \
  --log-file /home/caballero/Workspace/rclone_logs/rclone_videos.log \
  -P'

# Sincronización de Música con Google Drive
alias gdrive-musica='rclone sync /home/caballero/Música GoogleDrive:Música \
  --fast-list \
  --transfers 8 \
  --checkers 16 \
  --tpslimit 10 \
  --verbose \
  --log-file /home/caballero/Workspace/rclone_logs/rclone_musica.log \
  -P'

# Sincronizar Carpeta Software disco externo NVME
alias gdrive-software='rclone sync /media/caballero/NVME_EXT/Software GoogleDrive:Software \
  --fast-list \
  --transfers 8 \
  --checkers 16 \
  --tpslimit 10 \
  --verbose \
  --log-file /home/caballero/Workspace/rclone_logs/rclone_software.log \
  -P'

# -----------------------------------------------------------------------------
# 2. GOOGLE DRIVE (DOWNLOAD) - BAJAR DE LA NUBE
# -----------------------------------------------------------------------------

# Bajada de BingWallpaper de Google Drive a local
alias gdrive-bingwallpaper-down='rclone sync GoogleDrive:Imágenes/BingWallpaper /home/caballero/Imágenes/BingWallpaper \
  --fast-list \
  --transfers 8 \
  --checkers 16 \
  --tpslimit 10 \
  --verbose \
  --log-file /home/caballero/Workspace/rclone_logs/rclone_bing_down.log \
  -P'

# Bajada de Wallpaper de Google Drive a local
alias gdrive-wallpaper-down='rclone sync GoogleDrive:Imágenes/Wallpaper /home/caballero/Imágenes/Wallpaper \
  --fast-list \
  --transfers 8 \
  --checkers 16 \
  --tpslimit 10 \
  --verbose \
  --log-file /home/caballero/Workspace/rclone_logs/rclone_wallpaper_down.log \
  -P'

# Bajada de Documentos de Google Drive a local
alias gdrive-documentos-down='rclone sync "GoogleDrive:Documentos" "/home/caballero/Documentos/" \
  --fast-list \
  --transfers 8 \
  --checkers 16 \
  --tpslimit 10 \
  --verbose \
  --log-file /home/caballero/Workspace/rclone_logs/rclone_linuxhowto_down.log \
  -P'

# Bajada de Avatar de Google Drive a local
alias gdrive-avatar-down='rclone sync GoogleDrive:Avatar /home/caballero/Imágenes/Avatar \
  --fast-list \
  --transfers 8 \
  --checkers 16 \
  --tpslimit 10 \
  --verbose \
  --log-file /home/caballero/Workspace/rclone_logs/rclone_avatar_down.log \
  -P'

# Bajada de Vídeos de Google Drive a local
alias gdrive-videos-down='rclone sync GoogleDrive:Vídeos /home/caballero/Vídeos \
  --fast-list \
  --transfers 8 \
  --checkers 16 \
  --tpslimit 10 \
  --verbose \
  --log-file /home/caballero/Workspace/rclone_logs/rclone_videos_down.log \
  -P'

# Bajada de Música de Google Drive a local
alias gdrive-musica-down='rclone sync GoogleDrive:Música /home/caballero/Música \
  --fast-list \
  --transfers 8 \
  --checkers 16 \
  --tpslimit 10 \
  --verbose \
  --log-file /home/caballero/Workspace/rclone_logs/rclone_musica_down.log \
  -P'


# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Aliases de rclone cargados"
