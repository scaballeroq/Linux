#!/usr/bin/env bash
# ==============================================================================
# chaotic-aur.sh - Gestor del Repositorio Chaotic-AUR y Optimizador de Pacman
# Sistema: Arch Linux / Omarchy 4.5 (Hyprland Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U Zen 3 / Barcelo-R 8C/16T)
# Almacenamiento: SSD NVMe Kioxia KBG50ZNV512G / RAM 32 GB DDR4
# ==============================================================================
# Características:
#   - Verificación e integración segura del repositorio precompilado [chaotic-aur].
#   - Importación y firma digital local de llaves criptográficas:
#       * Clave primaria Chaotic-AUR: 3056513887B78AEB
#       * Servidores de respaldo: keyserver.ubuntu.com, hkps://keys.openpgp.org, keys.gnupg.net
#   - Instalación segura de paquetes oficiales de firmas y lista de espejos:
#       * chaotic-keyring y chaotic-mirrorlist desde CDN oficial
#   - Habilitación limpia e idempotente de [multilib] previo a [chaotic-aur]
#     para compatibilidad de 32 bits (Wine, Steam, utilidades).
#   - Optimización de /etc/pacman.conf:
#       * ParallelDownloads = 8 (balance óptimo para 16 hilos Zen 3 y NVMe Kioxia).
#       * Color, ILoveCandy, VerbosePkgLists y CheckSpace.
#   - Optimización de /etc/makepkg.conf:
#       * MAKEFLAGS="-j$(nproc)" (16 hilos concurrentes).
#       * COMPRESSZST=(zstd -c -z -q --threads=0 -) para compresión multicore ultrarrápida.
#   - Detección y respeto de AUR Helpers (yay / paru) sin elevación indebida de sudo.
#   - Sincronización segura de bases de datos de paquetes (pacman -Sy).
#   - Opciones CLI: --status / -s, --chaotic, --keys / -k, --update / -u,
#                   --remove / -d, --help / -h.
# ==============================================================================

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

BOLD=$'\033[1m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_ok()   { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_err()  { echo -e "${RED}❌ $1${NC}"; }

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        log_err "'sudo' no está disponible. Ejecuta este script con privilegios de superusuario."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

PACMAN_CONF="/etc/pacman.conf"
MAKEPKG_CONF="/etc/makepkg.conf"
MIRRORS_DIR="/etc/pacman.d"
CHAOTIC_KEY_ID="3056513887B78AEB"

show_help() {
    cat << EOF
${BOLD}📦 Gestor del Repositorio Chaotic-AUR y Optimizador de Pacman (Omarchy)${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U Zen 3 / 8C-16T / 32 GB RAM)

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)   Configura pacman.conf, makepkg.conf, multilib, llaves
                     y activa el repositorio precompilado Chaotic-AUR.
  -s, --status       Muestra diagnóstico detallado de Chaotic-AUR, repositorios y pacman.
  --chaotic          Asegura e integra únicamente el repositorio Chaotic-AUR y sus firmas.
  -k, --keys         Inicializa y actualiza los llaveros de firmas (Arch Linux y Chaotic-AUR).
  -u, --update       Ejecuta actualización integral sincronizada del sistema.
  -d, --remove       Deshabilita de forma limpia el repositorio Chaotic-AUR en pacman.conf.
  -h, --help         Muestra esta ayuda interactiva.
EOF
}

show_status() {
    local cpu_model threads kernel_ver aur_helper pacnew_count
    cpu_model=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//')
    threads=$(nproc 2>/dev/null || echo "16")
    kernel_ver=$(uname -r)

    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🔍 ${BOLD}ESTADO DE REPOSITORIO CHAOTIC-AUR Y PACMAN - OMARCHY 4.5${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "• Estación de Trabajo:           HP ProBook 455 G10"
    echo -e "• Procesador (CPU):              ${CYAN}${cpu_model} (${threads} hilos)${NC}"
    echo -e "• Kernel en Ejecución:           ${CYAN}${kernel_ver}${NC}"
    echo -e "• Arquitectura del Sistema:      $(uname -m)"
    echo "-----------------------------------------------------------------"
    echo -e "${BOLD}• Repositorios Activos en pacman.conf:${NC}"
    if [ -f "$PACMAN_CONF" ]; then
        grep -E "^\[.*\]" "$PACMAN_CONF" | grep -vE "^\[options\]" | while read -r repo; do
            case "$repo" in
                "[omarchy]")
                    echo -e "   - ${GREEN}${repo}${NC} (Repositorio Base Omarchy OS)"
                    ;;
                "[core]"|"[extra]")
                    echo -e "   - ${BLUE}${repo}${NC} (Arch Linux Oficial)"
                    ;;
                "[multilib]")
                    echo -e "   - ${CYAN}${repo}${NC} (Compatibilidad 32-bit / Gaming)"
                    ;;
                "[chaotic-aur]")
                    echo -e "   - ${GREEN}${repo}${NC} (Chaotic-AUR Precompilados - ACTIVO)"
                    ;;
                *)
                    echo -e "   - ${repo}"
                    ;;
            esac
        done
    else
        echo -e "   ${RED}Archivo $PACMAN_CONF no encontrado${NC}"
    fi
    echo "-----------------------------------------------------------------"

    # Diagnóstico específico de Chaotic-AUR
    echo -e "${BOLD}• Estado de Integración de Chaotic-AUR:${NC}"
    if pacman-key --list-keys "$CHAOTIC_KEY_ID" &>/dev/null; then
        echo -e "   - Llave PGP ($CHAOTIC_KEY_ID):   ${GREEN}Importada y firmada localmente${NC}"
    else
        echo -e "   - Llave PGP ($CHAOTIC_KEY_ID):   ${YELLOW}No importada en pacman-key${NC}"
    fi

    if [ -f "$MIRRORS_DIR/chaotic-mirrorlist" ]; then
        local mirror_count
        mirror_count=$(grep -c "^Server" "$MIRRORS_DIR/chaotic-mirrorlist" 2>/dev/null || echo "0")
        echo -e "   - chaotic-mirrorlist:         ${GREEN}Presente (${mirror_count} servidores de réplica)${NC}"
    else
        echo -e "   - chaotic-mirrorlist:         ${YELLOW}No instalado (/etc/pacman.d/chaotic-mirrorlist ausente)${NC}"
    fi

    local keyring_pkg mirror_pkg
    keyring_pkg=$(pacman -Q chaotic-keyring 2>/dev/null || echo "no instalado")
    mirror_pkg=$(pacman -Q chaotic-mirrorlist 2>/dev/null || echo "no instalado")
    echo -e "   - Paquete chaotic-keyring:    $( [[ "$keyring_pkg" != "no instalado" ]] && echo "${GREEN}${keyring_pkg}${NC}" || echo "${YELLOW}no instalado${NC}" )"
    echo -e "   - Paquete chaotic-mirrorlist: $( [[ "$mirror_pkg" != "no instalado" ]] && echo "${GREEN}${mirror_pkg}${NC}" || echo "${YELLOW}no instalado${NC}" )"

    echo "-----------------------------------------------------------------"
    # Opciones de pacman.conf
    local parallel_down colors candy verbose check_space
    parallel_down=$(grep -E "^ParallelDownloads" "$PACMAN_CONF" 2>/dev/null || echo "Por defecto (1)")
    colors=$(grep -q "^Color" "$PACMAN_CONF" 2>/dev/null && echo "${GREEN}Habilitado${NC}" || echo "${YELLOW}Deshabilitado${NC}")
    candy=$(grep -q "^ILoveCandy" "$PACMAN_CONF" 2>/dev/null && echo "${GREEN}Habilitado${NC}" || echo "${YELLOW}Deshabilitado${NC}")
    verbose=$(grep -q "^VerbosePkgLists" "$PACMAN_CONF" 2>/dev/null && echo "${GREEN}Habilitado${NC}" || echo "${YELLOW}Deshabilitado${NC}")
    check_space=$(grep -q "^CheckSpace" "$PACMAN_CONF" 2>/dev/null && echo "${GREEN}Habilitado${NC}" || echo "${YELLOW}Deshabilitado${NC}")

    echo -e "• Descargas concurrentes:        ${CYAN}${parallel_down}${NC}"
    echo -e "• Color / ILoveCandy:            ${colors} / ${candy}"
    echo -e "• VerbosePkgLists:               ${verbose}"
    echo -e "• Verificación de Espacio NVMe:  ${check_space}"

    # makepkg.conf
    local makeflags compress_zstd
    makeflags=$(grep -E "^MAKEFLAGS=" "$MAKEPKG_CONF" 2>/dev/null || echo "Por defecto")
    compress_zstd=$(grep -E "^COMPRESSZST=" "$MAKEPKG_CONF" 2>/dev/null || echo "Por defecto")
    echo -e "• Compilación MAKEFLAGS:         ${CYAN}${makeflags}${NC}"
    echo -e "• Compresión ZSTD makepkg:       ${CYAN}${compress_zstd}${NC}"

    # AUR Helper
    if command -v yay &>/dev/null; then
        aur_helper="${GREEN}yay ($(yay --version 2>/dev/null | head -n1))${NC}"
    elif command -v paru &>/dev/null; then
        aur_helper="${GREEN}paru ($(paru --version 2>/dev/null | head -n1))${NC}"
    else
        aur_helper="${YELLOW}Ninguno instalado (se recomienda 'yay')${NC}"
    fi
    echo -e "• AUR Helper detectado:          ${aur_helper}"

    # Archivos pacnew pendientes
    local pacnew_list=()
    while IFS= read -r f; do
        [ -n "$f" ] && pacnew_list+=("$f")
    done < <(find "$MIRRORS_DIR" -maxdepth 1 -name "*.pacnew" 2>/dev/null)
    [ -f /etc/pacman.conf.pacnew ] && pacnew_list+=("/etc/pacman.conf.pacnew")
    pacnew_count=${#pacnew_list[@]}

    if [ "$pacnew_count" -gt 0 ]; then
        echo -e "• Archivos .pacnew pendientes:   ${YELLOW}${pacnew_count} detectados (${pacnew_list[*]#/etc/})${NC}"
    else
        echo -e "• Archivos .pacnew pendientes:   ${GREEN}0 (Sincronizado)${NC}"
    fi
    echo -e "${BOLD}=================================================================${NC}"
}

setup_multilib() {
    if ! grep -q "^\[multilib\]" "$PACMAN_CONF"; then
        log_info "Habilitando repositorio [multilib] para compatibilidad de 32 bits..."
        if grep -q "^#\[multilib\]" "$PACMAN_CONF"; then
            $SUDO sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' "$PACMAN_CONF"
            log_ok "Repositorio [multilib] descomentado y habilitado."
        else
            if grep -q "^\[chaotic-aur\]" "$PACMAN_CONF"; then
                $SUDO sed -i '/^\[chaotic-aur\]/i [multilib]\nInclude = /etc/pacman.d/mirrorlist\n' "$PACMAN_CONF"
            else
                printf "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" | $SUDO tee -a "$PACMAN_CONF" > /dev/null
            fi
            log_ok "Repositorio [multilib] agregado con éxito."
        fi
    else
        log_ok "Repositorio [multilib] ya se encuentra activo."
    fi
}

setup_chaotic() {
    log_info "Verificando repositorio precompilado Chaotic-AUR..."

    # 1. Comprobar e importar llaves criptográficas
    if ! $SUDO pacman-key --list-keys "$CHAOTIC_KEY_ID" &>/dev/null; then
        log_info "Obteniendo e importando firma digital de Chaotic-AUR ($CHAOTIC_KEY_ID)..."
        $SUDO pacman-key --recv-key "$CHAOTIC_KEY_ID" --keyserver keyserver.ubuntu.com 2>/dev/null || \
        $SUDO pacman-key --recv-key "$CHAOTIC_KEY_ID" --keyserver hkps://keys.openpgp.org 2>/dev/null || \
        $SUDO pacman-key --recv-key "$CHAOTIC_KEY_ID" --keyserver keys.gnupg.net 2>/dev/null || true
        $SUDO pacman-key --lsign-key "$CHAOTIC_KEY_ID" 2>/dev/null || true
    else
        log_ok "Firma digital de Chaotic-AUR ($CHAOTIC_KEY_ID) ya verificada."
    fi

    # 2. Comprobar e instalar paquetes del llavero y mirrorlist
    if [ ! -f "$MIRRORS_DIR/chaotic-mirrorlist" ] || ! pacman -Q chaotic-keyring &>/dev/null; then
        log_info "Instalando paquetes oficiales chaotic-keyring y chaotic-mirrorlist..."
        $SUDO pacman -U --needed --noconfirm \
            'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 2>/dev/null || true
        $SUDO pacman -U --needed --noconfirm \
            'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' 2>/dev/null || true
    else
        log_ok "Paquetes chaotic-keyring y chaotic-mirrorlist presentes."
    fi

    # 3. Asegurar bloque [chaotic-aur] en pacman.conf
    if ! grep -q "^\[chaotic-aur\]" "$PACMAN_CONF"; then
        log_info "Añadiendo bloque [chaotic-aur] a $PACMAN_CONF..."
        printf "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n" | $SUDO tee -a "$PACMAN_CONF" > /dev/null
        log_ok "Repositorio [chaotic-aur] activado exitosamente."
    else
        log_ok "Repositorio [chaotic-aur] ya está configurado en pacman.conf."
    fi
}

remove_chaotic() {
    log_info "Deshabilitando repositorio Chaotic-AUR de $PACMAN_CONF..."
    if grep -q "^\[chaotic-aur\]" "$PACMAN_CONF"; then
        # Eliminar sección [chaotic-aur] y su Include
        $SUDO sed -i '/^\[chaotic-aur\]/,+1d' "$PACMAN_CONF"
        # Limpiar líneas vacías consecutivas al final
        $SUDO sed -i '${/^$/d;}' "$PACMAN_CONF"
        log_ok "Repositorio [chaotic-aur] retirado de $PACMAN_CONF."
        log_info "Sincronizando índices de pacman..."
        $SUDO pacman -Sy
    else
        log_ok "El repositorio [chaotic-aur] no estaba activo en $PACMAN_CONF."
    fi
}

setup_pacman() {
    log_info "Optimizando /etc/pacman.conf para HP ProBook 455 G10 (16 hilos / NVMe Kioxia)..."

    # ParallelDownloads = 8
    if grep -q "^#\?ParallelDownloads" "$PACMAN_CONF"; then
        $SUDO sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 8/' "$PACMAN_CONF"
    else
        $SUDO sed -i '/^\[options\]/a ParallelDownloads = 8' "$PACMAN_CONF"
    fi

    # Color
    if grep -q "^#Color" "$PACMAN_CONF"; then
        $SUDO sed -i 's/^#Color/Color/' "$PACMAN_CONF"
    elif ! grep -q "^Color" "$PACMAN_CONF"; then
        $SUDO sed -i '/^\[options\]/a Color' "$PACMAN_CONF"
    fi

    # ILoveCandy (Estética visual en terminales Wayland: Kitty / Ghostty / Ptyxis)
    if ! grep -q "^ILoveCandy" "$PACMAN_CONF"; then
        $SUDO sed -i '/^Color/a ILoveCandy' "$PACMAN_CONF" 2>/dev/null || true
    fi

    # VerbosePkgLists
    if grep -q "^#VerbosePkgLists" "$PACMAN_CONF"; then
        $SUDO sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' "$PACMAN_CONF"
    elif ! grep -q "^VerbosePkgLists" "$PACMAN_CONF"; then
        $SUDO sed -i '/^\[options\]/a VerbosePkgLists' "$PACMAN_CONF"
    fi

    # CheckSpace (Garantiza integridad de almacenamiento en el SSD NVMe Kioxia 512GB)
    if grep -q "^#CheckSpace" "$PACMAN_CONF"; then
        $SUDO sed -i 's/^#CheckSpace/CheckSpace/' "$PACMAN_CONF"
    elif ! grep -q "^CheckSpace" "$PACMAN_CONF"; then
        $SUDO sed -i '/^\[options\]/a CheckSpace' "$PACMAN_CONF"
    fi

    # Asegurar repositorio multilib
    setup_multilib

    # Optimización de makepkg.conf para AMD Ryzen 7 7730U (8 núcleos / 16 hilos)
    if [ -f "$MAKEPKG_CONF" ]; then
        log_info "Afinando /etc/makepkg.conf para compilación concurrente (16 hilos Zen 3)..."
        if grep -q "^#\?MAKEFLAGS=" "$MAKEPKG_CONF"; then
            $SUDO sed -i 's/^#\?MAKEFLAGS=.*/MAKEFLAGS="-j$(nproc)"/' "$MAKEPKG_CONF"
        else
            echo 'MAKEFLAGS="-j$(nproc)"' | $SUDO tee -a "$MAKEPKG_CONF" > /dev/null
        fi

        if grep -q "^COMPRESSZST=" "$MAKEPKG_CONF"; then
            $SUDO sed -i 's/^COMPRESSZST=.*/COMPRESSZST=(zstd -c -z -q --threads=0 -)/' "$MAKEPKG_CONF"
        fi
        log_ok "makepkg.conf afinado con MAKEFLAGS=\"-j$(nproc)\" y compresión ZSTD multicore."
    fi

    # Integración de Chaotic-AUR
    setup_chaotic

    # Sincronización de bases de datos de paquetes
    log_info "Sincronizando bases de datos de Pacman con Chaotic-AUR..."
    $SUDO pacman -Sy
    log_ok "Configuración de Chaotic-AUR y Pacman completada con éxito."
}

refresh_keys() {
    log_info "Inicializando y refrescando llaveros de firmas de Pacman..."
    $SUDO pacman-key --init
    log_info "Poblando firmas oficiales de Arch Linux..."
    $SUDO pacman-key --populate archlinux 2>/dev/null || true

    log_info "Refrescando firma digital de Chaotic-AUR ($CHAOTIC_KEY_ID)..."
    $SUDO pacman-key --recv-key "$CHAOTIC_KEY_ID" --keyserver keyserver.ubuntu.com 2>/dev/null || \
    $SUDO pacman-key --recv-key "$CHAOTIC_KEY_ID" --keyserver hkps://keys.openpgp.org 2>/dev/null || true
    $SUDO pacman-key --lsign-key "$CHAOTIC_KEY_ID" 2>/dev/null || true

    if pacman -Q chaotic-keyring &>/dev/null; then
        log_info "Poblando llavero de Chaotic-AUR..."
        $SUDO pacman-key --populate chaotic 2>/dev/null || true
    fi
    log_ok "Llaveros de firmas actualizados y validados."
}

update_system() {
    log_info "Iniciando actualización completa del sistema para Omarchy..."
    if [ "$EUID" -ne 0 ]; then
        if command -v yay &>/dev/null; then
            log_info "Actualizando mediante yay (repositorios oficiales + Chaotic-AUR + AUR)..."
            yay -Syu --noconfirm
        elif command -v paru &>/dev/null; then
            log_info "Actualizando mediante paru (repositorios oficiales + Chaotic-AUR + AUR)..."
            paru -Syu --noconfirm
        else
            log_info "Actualizando mediante pacman..."
            $SUDO pacman -Syu --noconfirm
        fi
    else
        local run_user="${SUDO_USER:-}"
        if [ -n "$run_user" ] && [ "$run_user" != "root" ] && command -v yay &>/dev/null; then
            log_info "Actualizando mediante yay como usuario $run_user..."
            sudo -u "$run_user" yay -Syu --noconfirm
        elif [ -n "$run_user" ] && [ "$run_user" != "root" ] && command -v paru &>/dev/null; then
            log_info "Actualizando mediante paru como usuario $run_user..."
            sudo -u "$run_user" paru -Syu --noconfirm
        else
            log_info "Actualizando mediante pacman..."
            pacman -Syu --noconfirm
        fi
    fi
    log_ok "Sistema actualizado completamente."
}

ACTION="${1:-setup}"
case "$ACTION" in
    -s|--status)
        show_status
        ;;
    --chaotic)
        setup_chaotic
        ;;
    -k|--keys)
        refresh_keys
        ;;
    -u|--update)
        update_system
        ;;
    -d|--remove)
        remove_chaotic
        ;;
    -h|--help)
        show_help
        ;;
    setup|"")
        setup_pacman
        ;;
    *)
        log_err "Opción no reconocida: $ACTION"
        show_help
        exit 1
        ;;
esac
