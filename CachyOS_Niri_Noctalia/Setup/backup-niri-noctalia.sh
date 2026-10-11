#!/usr/bin/env bash
# =============================================================================
# backup-niri-noctalia.sh - Copia de Seguridad y Restauración de Niri + Noctalia
# =============================================================================
# Permite realizar backups versionados, listar copias existentes y restaurar
# configuraciones de Niri Compositor, Noctalia Shell y herramientas asociadas.
#
# Uso:
#   niri-backup                   -> Crea una copia de seguridad timestamped
#   niri-backup --list            -> Muestra el listado de copias disponibles
#   niri-backup --restore [FILE]  -> Restaura una copia (por defecto la última)
#   niri-backup --help            -> Muestra la ayuda
# =============================================================================

set -euo pipefail

# Colores y estilo
BOLD="\033[1m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
RESET="\033[0m"

# Directorios objetivo
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/Backups/Niri_Noctalia}"
MAX_KEEP="${MAX_KEEP:-15}" # Número máximo de backups retenidos

# Carpetas a respaldar dentro de ~/.config
TARGET_DIRS=("niri" "noctalia" "nirimod")

show_help() {
    echo -e "${BOLD}📦 Gestor de Copias de Seguridad: Niri + Noctalia Shell${RESET}

${BOLD}Uso:${RESET}
  $0 [OPCIÓN]

${BOLD}Opciones:${RESET}
  (sin argumentos)           Crea una nueva copia de seguridad comprimida (.tar.gz).
  --create, -c               Fuerza la creación de un nuevo respaldo.
  --list, -l                 Lista todos los respaldos disponibles con fecha y tamaño.
  --restore, -r [ARCHIVO]    Restaura la copia especificada (o la última 'latest.tar.gz').
                             ${YELLOW}* Crea automáticamente un snapshot de seguridad antes de restaurar.${RESET}
  --prune                    Elimina copias antiguas conservando las últimas ${MAX_KEEP}.
  --help, -h                 Muestra este mensaje de ayuda.

${BOLD}Ubicación de respaldos:${RESET}
  ${BACKUP_DIR}

${BOLD}Configuraciones respaldadas:${RESET}
  • ${CONFIG_DIR}/niri
  • ${CONFIG_DIR}/noctalia
  • ${CONFIG_DIR}/nirimod (si existe)"
}

notify() {
    local title="$1"
    local msg="$2"
    local urgency="${3:-normal}"
    if command -v notify-send &>/dev/null; then
        notify-send -u "$urgency" -a "Niri-Backup" "$title" "$msg" 2>/dev/null || true
    fi
}

# 1. Función para crear backup
create_backup() {
    mkdir -p "$BACKUP_DIR"

    local existing_targets=()
    for dir_name in "${TARGET_DIRS[@]}"; do
        if [ -d "$CONFIG_DIR/$dir_name" ]; then
            existing_targets+=("$dir_name")
        fi
    done

    if [ ${#existing_targets[@]} -eq 0 ]; then
        echo -e "${RED}❌ Error: No se encontraron directorios de configuración para respaldar en $CONFIG_DIR.${RESET}"
        exit 1
    fi

    local timestamp
    timestamp="$(date +'%Y-%m-%d_%H-%M-%S')"
    local archive_name="niri_noctalia_${timestamp}.tar.gz"
    local archive_path="$BACKUP_DIR/$archive_name"
    local latest_link="$BACKUP_DIR/latest.tar.gz"

    echo -e "${CYAN}===========================================================${RESET}"
    echo -e "${BOLD}📦 Creando copia de seguridad de Niri y Noctalia Shell...${RESET}"
    echo -e "${CYAN}===========================================================${RESET}"
    echo -e "📁 Origen:      ${CONFIG_DIR}/{$(IFS=,; echo "${existing_targets[*]}")}"
    echo -e "💾 Destino:     ${archive_path}"

    tar -czf "$archive_path" -C "$CONFIG_DIR" "${existing_targets[@]}"

    # Actualizar enlace simbólico latest
    ln -sf "$archive_name" "$latest_link"

    local size
    size=$(du -sh "$archive_path" | awk '{print $1}')
    local files_count
    files_count=$(tar -tzf "$archive_path" | wc -l)

    echo -e "${GREEN}✅ Copia de seguridad completada con éxito!${RESET}"
    echo -e "📊 Tamaño:      ${BOLD}${size}${RESET} (${files_count} ficheros empaquetados)"
    echo -e "🔗 Enlace:      ${latest_link} -> ${archive_name}"

    # Rotación automática
    prune_backups

    notify "Copia de seguridad completada" "Niri + Noctalia respaldados (${size})" "low"
}

# 2. Función para listar backups
list_backups() {
    echo -e "${CYAN}===========================================================${RESET}"
    echo -e "${BOLD}📋 Copias de seguridad disponibles en:${RESET} ${BACKUP_DIR}"
    echo -e "${CYAN}===========================================================${RESET}"

    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR"/*.tar.gz 2>/dev/null)" ]; then
        echo -e "${YELLOW}ℹ️ No se han encontrado copias de seguridad todavía.${RESET}"
        echo -e "   Ejecuta 'niri-backup' para crear la primera."
        return 0
    fi

    printf "${BOLD}%-4s %-32s %-12s %-20s${RESET}\n" "NUM" "ARCHIVO" "TAMAÑO" "FECHA"
    echo "----------------------------------------------------------------------"

    local count=0
    # Listar ordenados del más reciente al más antiguo (excluyendo enlaces simbólicos)
    while IFS= read -r file; do
        if [ -f "$file" ] && [ ! -L "$file" ]; then
            count=$((count + 1))
            local fname
            fname=$(basename "$file")
            local size
            size=$(du -sh "$file" | awk '{print $1}')
            local mtime
            mtime=$(date -r "$file" "+%Y-%m-%d %H:%M:%S")

            local is_latest=""
            if [ -L "$BACKUP_DIR/latest.tar.gz" ] && [ "$(readlink "$BACKUP_DIR/latest.tar.gz")" = "$fname" ]; then
                is_latest=" ${GREEN}(latest)${RESET}"
            fi

            printf "%-4d %-32s %-12s %-20s%b\n" "$count" "$fname" "$size" "$mtime" "$is_latest"
        fi
    done < <(ls -1t "$BACKUP_DIR"/niri_noctalia_*.tar.gz 2>/dev/null)

    echo "----------------------------------------------------------------------"
    echo -e "Total de copias: ${BOLD}${count}${RESET} (Límite de rotación: ${MAX_KEEP})"
}

# 3. Función para restaurar backup
restore_backup() {
    local target_archive="${1:-}"

    if [ -z "$target_archive" ]; then
        if [ -L "$BACKUP_DIR/latest.tar.gz" ]; then
            target_archive="$BACKUP_DIR/latest.tar.gz"
        else
            echo -e "${RED}❌ Error: No se especificó archivo y no existe 'latest.tar.gz'.${RESET}"
            list_backups
            exit 1
        fi
    fi

    # Resolver ruta si se pasó un nombre relativo
    if [ ! -f "$target_archive" ] && [ -f "$BACKUP_DIR/$target_archive" ]; then
        target_archive="$BACKUP_DIR/$target_archive"
    fi

    if [ ! -f "$target_archive" ]; then
        echo -e "${RED}❌ Error: El archivo de copia '$target_archive' no existe.${RESET}"
        exit 1
    fi

    local real_target
    real_target=$(readlink -f "$target_archive")
    local archive_name
    archive_name=$(basename "$real_target")

    echo -e "${YELLOW}===========================================================${RESET}"
    echo -e "${BOLD}⚠️ RESTAURACIÓN DE CONFIGURACIÓN NIRI + NOCTALIA${RESET}"
    echo -e "${YELLOW}===========================================================${RESET}"
    echo -e "Archivo a restaurar: ${BOLD}${archive_name}${RESET}"
    echo -e "Destino:             ${BOLD}${CONFIG_DIR}${RESET}"
    echo ""
    echo -e "Se sobreescribirán las configuraciones actuales de:"
    for dir_name in "${TARGET_DIRS[@]}"; do
        [ -d "$CONFIG_DIR/$dir_name" ] && echo -e "  • ${CONFIG_DIR}/$dir_name"
    done
    echo ""

    if [ -t 0 ]; then
        read -rp "¿Estás seguro de restaurar esta copia? (s/N): " confirm
        case "$confirm" in
            [sS]|[yY]|[sS][iI]) ;;
            *)
                echo -e "${BLUE}Operación cancelada.${RESET}"
                exit 0
                ;;
        esac
    fi

    # Snapshot de seguridad previo a la restauración
    echo -e "\n🛡️ Creando snapshot de seguridad del estado actual antes de restaurar..."
    local pre_restore_archive="$BACKUP_DIR/pre_restore_$(date +'%Y-%m-%d_%H-%M-%S').tar.gz"
    local existing_targets=()
    for dir_name in "${TARGET_DIRS[@]}"; do
        [ -d "$CONFIG_DIR/$dir_name" ] && existing_targets+=("$dir_name")
    done
    if [ ${#existing_targets[@]} -gt 0 ]; then
        tar -czf "$pre_restore_archive" -C "$CONFIG_DIR" "${existing_targets[@]}"
        echo -e "   Snapshot guardado en: $(basename "$pre_restore_archive")"
    fi

    # Extraer respaldo
    echo -e "📦 Desempaquetando configuración..."
    tar -xzf "$target_archive" -C "$CONFIG_DIR"

    echo -e "${GREEN}✅ Configuración restaurada con éxito!${RESET}"

    # Recargar entornos si están activos
    if command -v niri &>/dev/null; then
        echo -e "🔄 Recargando Niri Compositor..."
        niri msg action reload-config 2>/dev/null || true
    fi

    if command -v noctalia &>/dev/null; then
        echo -e "🔄 Recargando Noctalia Shell..."
        noctalia msg reload 2>/dev/null || true
    fi

    notify "Restauración completada" "Configuración restaurada desde $(basename "$archive_name")" "normal"
}

# 4. Función de rotación (mantener solo MAX_KEEP)
prune_backups() {
    if [ ! -d "$BACKUP_DIR" ]; then
        return 0
    fi

    local count
    count=$(ls -1t "$BACKUP_DIR"/niri_noctalia_*.tar.gz 2>/dev/null | grep -v "pre_restore_" | wc -l)
    if [ "$count" -gt "$MAX_KEEP" ]; then
        local to_delete=$((count - MAX_KEEP))
        echo -e "🧹 Rotación: Eliminando las $to_delete copias más antiguas..."
        ls -1rt "$BACKUP_DIR"/niri_noctalia_*.tar.gz 2>/dev/null | grep -v "pre_restore_" | head -n "$to_delete" | while read -r old_file; do
            rm -f "$old_file"
            echo -e "   - Eliminado: $(basename "$old_file")"
        done
    fi
}

# Procesar parámetros
case "${1:-}" in
    --help|-h|help)
        show_help
        exit 0
        ;;
    --list|-l|list)
        list_backups
        exit 0
        ;;
    --restore|-r|restore)
        shift
        restore_backup "${1:-}"
        exit 0
        ;;
    --prune|prune)
        prune_backups
        exit 0
        ;;
    --create|-c|create|"")
        create_backup
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Opción no reconocida: $1${RESET}"
        show_help
        exit 1
        ;;
esac
