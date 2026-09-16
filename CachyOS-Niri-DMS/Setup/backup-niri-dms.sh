#!/usr/bin/env bash
# =============================================================================
# backup-niri-dms.sh - Copia de Seguridad y Restauración de Niri + Dank Material Shell
# =============================================================================
# Permite realizar backups versionados, listar copias existentes y restaurar
# configuraciones de Niri Compositor, Dank Material Shell y herramientas asociadas.
#
# Uso:
#   ./backup-niri-dms.sh                   -> Crea una copia de seguridad timestamped
#   ./backup-niri-dms.sh --list            -> Muestra el listado de copias disponibles
#   ./backup-niri-dms.sh --restore [FILE]  -> Restaura una copia (por defecto la última)
#   ./backup-niri-dms.sh --prune           -> Limpia respaldos antiguos (mantiene 15)
#   ./backup-niri-dms.sh --help            -> Muestra la ayuda
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
BACKUP_DIR="${BACKUP_DIR:-$HOME/Backups/Niri_DMS}"
MAX_KEEP="${MAX_KEEP:-15}" # Número máximo de backups retenidos

# Elementos a respaldar dentro de ~/.config (directorios y archivos clave)
TARGET_ITEMS=(
    "niri"
    "DankMaterialShell"
    "danksearch"
    "dankcal"
    "quickshell"
    "kitty"
    "environment.d"
    "gtk-3.0"
    "gtk-4.0"
    "qt6ct"
    "fastfetch"
    "starship.toml"
)

show_help() {
    echo -e "${BOLD}📦 Gestor de Copias de Seguridad: Niri + Dank Material Shell (DMS)${RESET}"
    echo ""
    echo -e "${BOLD}Uso:${RESET}"
    echo "  $0 [OPCIÓN]"
    echo ""
    echo -e "${BOLD}Opciones:${RESET}"
    echo "  (sin argumentos)           Crea una nueva copia de seguridad comprimida (.tar.gz)."
    echo "  --create, -c               Fuerza la creación de un nuevo respaldo."
    echo "  --list, -l                 Lista todos los respaldos disponibles con fecha y tamaño."
    echo "  --restore, -r [ARCHIVO]    Restaura la copia especificada (o la última 'latest.tar.gz')."
    echo -e "                             ${YELLOW}* Crea automáticamente un snapshot de seguridad antes de restaurar.${RESET}"
    echo "  --prune                    Elimina copias antiguas conservando las últimas ${MAX_KEEP}."
    echo "  --help, -h                 Muestra este mensaje de ayuda."
    echo ""
    echo -e "${BOLD}Ubicación de respaldos:${RESET}"
    echo "  ${BACKUP_DIR}"
    echo ""
    echo -e "${BOLD}Configuraciones respaldadas (dentro de ~/.config):${RESET}"
    echo "  • niri             (config.kdl y subcarpeta dms/)"
    echo "  • DankMaterialShell (settings.json, monitors.json, temas, firefox.css)"
    echo "  • danksearch       (config.toml y ajustes de búsqueda)"
    echo "  • dankcal          (calendario y recordatorios)"
    echo "  • kitty            (kitty.conf, dank-theme.conf, dank-tabs.conf)"
    echo "  • environment.d    (90-dms.conf y variables de sesión Wayland)"
    echo "  • gtk-3.0/gtk-4.0  (dank-colors.css y estilos Material You de apps GTK)"
    echo "  • quickshell       (componentes y estado QML de shell)"
    echo "  • qt6ct            (estilo y paleta Qt6 integrada con Material You)"
    echo "  • fastfetch        (config.jsonc diagnóstico de terminal)"
    echo "  • starship.toml    (estilo y prompt del terminal)"
}

notify() {
    local title="$1"
    local msg="$2"
    local urgency="${3:-normal}"
    if command -v notify-send &>/dev/null; then
        notify-send -u "$urgency" -a "Niri-DMS-Backup" "$title" "$msg" 2>/dev/null || true
    fi
}

# 1. Función para crear backup
create_backup() {
    mkdir -p "$BACKUP_DIR"

    local existing_targets=()
    for item in "${TARGET_ITEMS[@]}"; do
        if [ -e "$CONFIG_DIR/$item" ]; then
            existing_targets+=("$item")
        fi
    done

    if [ ${#existing_targets[@]} -eq 0 ]; then
        echo -e "${RED}❌ Error: No se encontraron elementos de configuración para respaldar en $CONFIG_DIR.${RESET}"
        exit 1
    fi

    local timestamp
    timestamp="$(date +'%Y-%m-%d_%H-%M-%S')"
    local archive_name="niri_dms_${timestamp}.tar.gz"
    local archive_path="$BACKUP_DIR/$archive_name"
    local latest_link="$BACKUP_DIR/latest.tar.gz"

    echo -e "${CYAN}===========================================================${RESET}"
    echo -e "${BOLD}📦 Creando copia de seguridad de Niri y Dank Material Shell...${RESET}"
    echo -e "${CYAN}===========================================================${RESET}"
    echo -e "📁 Origen:      ${CONFIG_DIR}/{$(IFS=,; echo "${existing_targets[*]}")}"
    echo -e "💾 Destino:     ${archive_path}"

    tar -czf "$archive_path" -C "$CONFIG_DIR" "${existing_targets[@]}"

    # Actualizar enlace simbólico latest
    ln -sf "$archive_name" "$latest_link"

    local size
    size="$(du -h "$archive_path" | awk '{print $1}')"

    echo -e "${GREEN}✅ Copia de seguridad completada con éxito.${RESET} (Tamaño: ${size})"
    echo -e "🔗 Enlace rápido: ${latest_link}"

    notify "Copia de Seguridad Completada" "Archivo: $archive_name ($size)"

    # Limpiar automáticamente copias antiguas si superan MAX_KEEP
    prune_backups
}

# 2. Función para listar backups
list_backups() {
    echo -e "${CYAN}===========================================================${RESET}"
    echo -e "${BOLD}📋 Copias de seguridad disponibles en:${RESET} $BACKUP_DIR"
    echo -e "${CYAN}===========================================================${RESET}"

    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(find "$BACKUP_DIR" -maxdepth 1 -name "niri_dms_*.tar.gz*" 2>/dev/null)" ]; then
        echo -e "${YELLOW}ℹ️  No hay respaldos registrados aún.${RESET}"
        return 0
    fi

    printf "${BOLD}%-5s  %-40s  %-10s  %-20s${RESET}\n" "#" "Nombre del Archivo" "Tamaño" "Fecha de Creación"
    echo "--------------------------------------------------------------------------------------"

    local count=1
    while IFS= read -r file; do
        local filename size mod_date
        filename="$(basename "$file")"
        size="$(du -h "$file" | awk '{print $1}')"
        mod_date="$(date -r "$file" +'%Y-%m-%d %H:%M:%S')"
        printf "%-5s  %-40s  %-10s  %-20s\n" "[$count]" "$filename" "$size" "$mod_date"
        count=$((count + 1))
    done < <(find "$BACKUP_DIR" -maxdepth 1 -name "niri_dms_*.tar.gz*" -type f | sort -r)

    if [ -L "$BACKUP_DIR/latest.tar.gz" ]; then
        local target
        target="$(readlink "$BACKUP_DIR/latest.tar.gz")"
        if [ -e "$BACKUP_DIR/latest.tar.gz" ]; then
            echo -e "\n⭐ ${CYAN}latest.tar.gz${RESET} -> ${target} (${GREEN}válido${RESET})"
        else
            echo -e "\n⭐ ${CYAN}latest.tar.gz${RESET} -> ${target} (${RED}enlace roto${RESET})"
        fi
    fi
}

# 3. Función para restaurar backup
restore_backup() {
    local target_archive="${1:-}"

    # Si no se indica archivo, usar latest.tar.gz por defecto
    if [ -z "$target_archive" ]; then
        target_archive="$BACKUP_DIR/latest.tar.gz"
    fi

    # Si se pasó un nombre relativo dentro de BACKUP_DIR
    if [ ! -f "$target_archive" ] && [ -f "$BACKUP_DIR/$target_archive" ]; then
        target_archive="$BACKUP_DIR/$target_archive"
    fi

    # Si se pasó sin extensión o con variación .tar.gz
    if [ ! -f "$target_archive" ] && [ -f "${target_archive}.tar.gz" ]; then
        target_archive="${target_archive}.tar.gz"
    fi

    # Recuperación inteligente si el objetivo no existe o latest.tar.gz es un enlace roto
    if [ ! -f "$target_archive" ]; then
        if [ -L "$target_archive" ]; then
            local broken_target
            broken_target="$(readlink "$target_archive" 2>/dev/null || true)"
            echo -e "${YELLOW}⚠️  Aviso: El enlace simbólico '$target_archive' apunta a '$broken_target', que no existe.${RESET}"
            
            # Comprobar si el archivo existe con sufijo adicional (ej. doble .tar.gz)
            if [ -f "$BACKUP_DIR/${broken_target}.tar.gz" ]; then
                echo -e "${CYAN}ℹ️  Detectado archivo con extensión repetida: ${broken_target}.tar.gz${RESET}"
                target_archive="$BACKUP_DIR/${broken_target}.tar.gz"
                ln -sf "$(basename "$target_archive")" "$BACKUP_DIR/latest.tar.gz"
            fi
        fi

        # Si aún no existe y el usuario no especificó archivo concreto, buscar el más reciente en BACKUP_DIR
        if [ ! -f "$target_archive" ] && [ -z "${1:-}" ]; then
            local latest_found
            latest_found="$(find "$BACKUP_DIR" -maxdepth 1 -name "niri_dms_*.tar.gz*" -type f 2>/dev/null | sort -r | head -n 1)"
            if [ -n "$latest_found" ] && [ -f "$latest_found" ]; then
                echo -e "${CYAN}ℹ️  Seleccionando automáticamente el respaldo más reciente: $(basename "$latest_found")${RESET}"
                target_archive="$latest_found"
                ln -sf "$(basename "$latest_found")" "$BACKUP_DIR/latest.tar.gz"
            fi
        fi
    fi

    if [ ! -f "$target_archive" ]; then
        echo -e "${RED}❌ Error: El archivo de copia de seguridad no existe: $target_archive${RESET}"
        exit 1
    fi

    echo -e "${YELLOW}⚠️  ATENCIÓN: Se va a restaurar la configuración desde:${RESET}"
    echo -e "   ${BOLD}$target_archive${RESET}"
    echo -e "${YELLOW}   Las carpetas existentes en ~/.config serán reemplazadas por las del archivo.${RESET}"
    echo ""
    read -rp ">> ¿Deseas continuar? [s/N]: " confirm
    if [[ ! "$confirm" =~ ^[sS]$ ]]; then
        echo "Operación cancelada."
        exit 0
    fi

    # 3.1. Snapshot de seguridad previo
    echo -e "\n${BLUE}🛡️ Creando snapshot de seguridad previo de tu configuración actual...${RESET}"
    local snapshot_time
    snapshot_time="$(date +'%Y-%m-%d_%H-%M-%S')"
    local snapshot_file="$BACKUP_DIR/pre_restore_snapshot_${snapshot_time}.tar.gz"

    local current_targets=()
    for item in "${TARGET_ITEMS[@]}"; do
        if [ -e "$CONFIG_DIR/$item" ]; then
            current_targets+=("$item")
        fi
    done

    if [ ${#current_targets[@]} -gt 0 ]; then
        tar -czf "$snapshot_file" -C "$CONFIG_DIR" "${current_targets[@]}"
        echo -e "${GREEN}   Snapshot previo guardado en: $snapshot_file${RESET}"
    fi

    # 3.2. Extraer el archivo de respaldo
    echo -e "\n${BOLD}🔄 Descomprimiendo y restaurando configuraciones en $CONFIG_DIR...${RESET}"
    tar -xzf "$target_archive" -C "$CONFIG_DIR"

    echo -e "${GREEN}✅ Restauración finalizada con éxito.${RESET}"

    # 3.3. Recargar Niri y DMS si están en ejecución
    if command -v systemctl &>/dev/null; then
        systemctl --user daemon-reload 2>/dev/null || true
    fi

    if command -v niri &>/dev/null && pgrep -x niri &>/dev/null; then
        echo "🔄 Recargando Niri Compositor..."
        niri msg action reload-config 2>/dev/null || true
    fi

    if command -v dms &>/dev/null; then
        echo "🔄 Recargando Dank Material Shell..."
        dms restart 2>/dev/null || systemctl --user restart dms.service 2>/dev/null || true
    fi

    notify "Restauración Completada" "Configuración de Niri y DMS restablecida"
}

# 4. Función de limpieza de copias antiguas
prune_backups() {
    local count
    count=$(find "$BACKUP_DIR" -maxdepth 1 -name "niri_dms_*.tar.gz*" -type f | wc -l)
    if [ "$count" -gt "$MAX_KEEP" ]; then
        echo -e "${BLUE}🧹 Limpiando copias antiguas (conservando las últimas ${MAX_KEEP})...${RESET}"
        find "$BACKUP_DIR" -maxdepth 1 -name "niri_dms_*.tar.gz*" -type f | sort | head -n -"$MAX_KEEP" | while read -r old_file; do
            rm -f "$old_file"
            echo "   Eliminado: $(basename "$old_file")"
        done
    fi
}

# Enrutador principal de opciones
case "${1:-create}" in
    create|-c|--create)
        create_backup
        ;;
    list|-l|--list)
        list_backups
        ;;
    restore|-r|--restore)
        restore_backup "${2:-}"
        ;;
    prune|--prune)
        prune_backups
        echo -e "${GREEN}✅ Limpieza de respaldos finalizada.${RESET}"
        ;;
    help|-h|--help)
        show_help
        ;;
    *)
        echo -e "${RED}Opción no reconocida: $1${RESET}"
        show_help
        exit 1
        ;;
esac
