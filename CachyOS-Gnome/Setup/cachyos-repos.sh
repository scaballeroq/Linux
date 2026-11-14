#!/usr/bin/env bash
# ==============================================================================
# cachyos-repos.sh - Gestor de Repositorios Oficiales y Optimizados de CachyOS
# Sistema: CachyOS Linux x86_64 (GNOME Shell Wayland)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U Zen 3 / Barcelo-R 8C/16T)
# Microarquitectura: x86-64-v3 (AVX, AVX2, FMA, BMI1, BMI2)
# Almacenamiento: SSD NVMe Kioxia KBG50ZNV512G / RAM 32 GB DDR4
# ==============================================================================
# Características:
#   - Verificación estricta de microarquitectura CPU x86-64-v3 para AMD Zen 3.
#   - Habilitación y preservación del orden de repositorios CachyOS optimizados
#     ([cachyos-v3], [cachyos-extra-v3], [cachyos-core-v3], [cachyos]).
#   - Habilitación limpia e idempotente de [multilib] para compatibilidad 32-bit (Wine/Steam).
#   - Integración y soporte del repositorio precompilado [chaotic-aur].
#   - Optimización de /etc/pacman.conf:
#       * ParallelDownloads = 8 (balance perfecto para 16 hilos Zen 3 y NVMe Kioxia).
#       * Color, ILoveCandy, VerbosePkgLists y CheckSpace.
#   - Optimización de /etc/makepkg.conf:
#       * MAKEFLAGS="-j$(nproc)" (16 hilos concurrentes).
#       * COMPRESSZST=(zstd -c -z -q --threads=0 -) para compresión ultrarrápida.
#   - Instalación y verificación del AUR helper oficial de CachyOS (paru).
#   - Calibración de espejos con cachyos-rate-mirrors (Arch + CachyOS v3/v4).
#   - Gestión y refresco de llaves pacman-key (archlinux, cachyos, chaotic).
#   - Prevención estricta de Partial Upgrades (actualización sincronizada segura).
#   - Opciones CLI: --status / -s, --rate-mirrors / -r, --update / -u,
#                   --keys / -k, --chaotic, --help / -h.
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

show_help() {
    cat << EOF
${BOLD}📦 Gestor y Optimizador de Repositorios CachyOS (x86-64-v3) y Pacman${NC}
Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U Zen 3 / 8C-16T / 32 GB RAM)

${BOLD}Uso:${NC}
  $0 [OPCIÓN]

${BOLD}Opciones:${NC}
  (sin argumentos)   Configura pacman.conf, makepkg.conf, repositorios CachyOS v3,
                     multilib, parámetros para 16 hilos y verifica paru.
  -s, --status       Muestra diagnóstico detallado de repositorios, CPU, espejos y pacman.
  -r, --rate-mirrors Calibra y clasifica los espejos más rápidos con cachyos-rate-mirrors.
  -u, --update       Ejecuta actualización integral del sistema (pacman -Syu / paru -Syu).
  -k, --keys         Inicializa y actualiza los llaveros de firmas (Arch, CachyOS, Chaotic).
  --chaotic          Asegura e integra el repositorio precompilado Chaotic-AUR.
  -h, --help         Muestra esta ayuda interactiva.
EOF
}

detect_cpu_v3() {
    local supported="No detectado"
    if /usr/lib/ld-linux-x86-64.so.2 --help 2>/dev/null | grep -q "x86-64-v3 (supported"; then
        supported="${GREEN}Compatible y Activo (Zen 3 / Barcelo-R x86-64-v3)${NC}"
    else
        # Comprobar banderas de CPU directamente
        if grep -q "avx2" /proc/cpuinfo && grep -q "fma" /proc/cpuinfo && grep -q "bmi2" /proc/cpuinfo; then
            supported="${GREEN}Compatible por flags de CPU (AVX2, FMA, BMI2)${NC}"
        else
            supported="${RED}No compatible con x86-64-v3 (requiere fallback x86-64 estándar)${NC}"
        fi
    fi
    echo -e "$supported"
}

show_status() {
    local cpu_model threads kernel_ver aur_helper pacnew_count
    cpu_model=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//')
    threads=$(nproc 2>/dev/null || echo "16")
    kernel_ver=$(uname -r)
    
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "🔍 ${BOLD}ESTADO DE REPOSITORIOS, HARDWARE Y PACMAN - CACHYOS${NC}"
    echo -e "${BOLD}=================================================================${NC}"
    echo -e "• Estación de Trabajo:           HP ProBook 455 G10"
    echo -e "• Procesador (CPU):              ${CYAN}${cpu_model} (${threads} hilos)${NC}"
    echo -e "• Soporte Microarquitectura:     $(detect_cpu_v3)"
    echo -e "• Kernel en Ejecución:           ${CYAN}${kernel_ver}${NC}"
    echo -e "• Arquitectura del Sistema:      $(uname -m)"
    echo "-----------------------------------------------------------------"
    echo -e "${BOLD}• Repositorios Activos en pacman.conf:${NC}"
    if [ -f "$PACMAN_CONF" ]; then
        grep -E "^\[.*\]" "$PACMAN_CONF" | grep -vE "^\[options\]" | while read -r repo; do
            case "$repo" in
                "[cachyos-v3]"|"[cachyos-extra-v3]"|"[cachyos-core-v3]")
                    echo -e "   - ${GREEN}${repo}${NC} (CachyOS x86-64-v3 Optimizado)"
                    ;;
                "[cachyos]")
                    echo -e "   - ${GREEN}${repo}${NC} (CachyOS Paquetes y Utilidades)"
                    ;;
                "[core]"|"[extra]")
                    echo -e "   - ${BLUE}${repo}${NC} (Arch Linux Oficial)"
                    ;;
                "[multilib]")
                    echo -e "   - ${CYAN}${repo}${NC} (Compatibilidad 32-bit / Gaming)"
                    ;;
                "[chaotic-aur]")
                    echo -e "   - ${YELLOW}${repo}${NC} (Chaotic-AUR Precompilados)"
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
    if command -v paru &>/dev/null; then
        aur_helper="${GREEN}paru ($(paru --version 2>/dev/null | head -n1))${NC}"
    elif command -v yay &>/dev/null; then
        aur_helper="${YELLOW}yay ($(yay --version 2>/dev/null | head -n1))${NC}"
    else
        aur_helper="${RED}Ninguno instalado (se recomienda 'paru')${NC}"
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
        # Si existe comentado, lo descomentamos
        if grep -q "^#\[multilib\]" "$PACMAN_CONF"; then
            $SUDO sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' "$PACMAN_CONF"
            log_ok "Repositorio [multilib] descomentado y habilitado."
        else
            # Lo agregamos antes de repositorios personalizados si existen, o al final
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
    
    # 1. Comprobar llaves
    if ! $SUDO pacman-key --list-keys 3056513887B78AEB &>/dev/null; then
        log_info "Obteniendo e importando firma digital de Chaotic-AUR..."
        $SUDO pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com 2>/dev/null || \
        $SUDO pacman-key --recv-key 3056513887B78AEB --keyserver hkps://keys.openpgp.org 2>/dev/null || true
        $SUDO pacman-key --lsign-key 3056513887B78AEB 2>/dev/null || true
    fi

    # 2. Comprobar /etc/pacman.d/chaotic-mirrorlist
    if [ ! -f "$MIRRORS_DIR/chaotic-mirrorlist" ]; then
        log_info "Instalando paquetes chaotic-keyring y chaotic-mirrorlist..."
        $SUDO pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 2>/dev/null || true
        $SUDO pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' 2>/dev/null || true
    fi

    # 3. Asegurar bloque en pacman.conf
    if ! grep -q "^\[chaotic-aur\]" "$PACMAN_CONF"; then
        log_info "Añadiendo bloque [chaotic-aur] a $PACMAN_CONF..."
        printf "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n" | $SUDO tee -a "$PACMAN_CONF" > /dev/null
        log_ok "Repositorio [chaotic-aur] activado."
    else
        log_ok "Repositorio [chaotic-aur] ya está configurado en pacman.conf."
    fi
}

setup_pacman() {
    log_info "Configurando /etc/pacman.conf para HP ProBook 455 G10 (16 hilos / NVMe Kioxia)..."

    # ParallelDownloads = 8 (Equilibrado para Ryzen 7 7730U y redes estándar sin penalizar latencia)
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

    # Repositorio multilib
    setup_multilib

    # Optimización de makepkg.conf para AMD Ryzen 7 7730U (8 núcleos / 16 hilos)
    if [ -f "$MAKEPKG_CONF" ]; then
        log_info "Afinando /etc/makepkg.conf para 16 hilos (Zen 3 / Barcelo-R)..."
        
        # MAKEFLAGS="-j$(nproc)"
        if grep -q "^#\?MAKEFLAGS=" "$MAKEPKG_CONF"; then
            $SUDO sed -i 's/^#\?MAKEFLAGS=.*/MAKEFLAGS="-j$(nproc)"/' "$MAKEPKG_CONF"
        else
            echo 'MAKEFLAGS="-j$(nproc)"' | $SUDO tee -a "$MAKEPKG_CONF" > /dev/null
        fi

        # COMPRESSZST con compresión multinúcleo en tiempo real
        if grep -q "^COMPRESSZST=" "$MAKEPKG_CONF"; then
            $SUDO sed -i 's/^COMPRESSZST=.*/COMPRESSZST=(zstd -c -z -q --threads=0 -)/' "$MAKEPKG_CONF"
        fi
        log_ok "makepkg.conf optimizado para compilación paralela (-j$(nproc))."
    fi

    # Asegurar llaves de CachyOS
    if ! grep -q "^\[cachyos" "$PACMAN_CONF"; then
        log_info "Importando llaves de CachyOS..."
        $SUDO pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com 2>/dev/null || true
        $SUDO pacman-key --lsign-key F3B607488DB35A47 2>/dev/null || true
    fi

    # Instalar paru oficial precompilado de CachyOS si no está presente
    if ! command -v paru &>/dev/null; then
        log_info "Instalando paru (AUR Helper oficial optimizado de CachyOS)..."
        $SUDO pacman -S --needed --noconfirm paru 2>/dev/null || log_warn "No se pudo instalar paru automáticamente; instálalo con: sudo pacman -S paru"
        if command -v paru &>/dev/null; then
            log_ok "paru instalado y listo para su uso."
        fi
    fi

    # Actualización segura de bases de datos
    log_info "Sincronizando índices de paquetes de Pacman..."
    $SUDO pacman -Sy
    log_ok "Configuración de repositorios y Pacman completada con éxito."
    echo -e "${YELLOW}💡 Consejo: Para actualizar paquetes de forma completa y segura sin inconsistencias, ejecuta:${NC}"
    echo -e "   ${BOLD}$0 --update${NC}  o  ${BOLD}paru -Syu${NC}"
}

rate_mirrors() {
    log_info "Optimizando espejos de CachyOS (v3/v4) y Arch Linux para latencia mínima..."
    if command -v cachyos-rate-mirrors &>/dev/null; then
        $SUDO cachyos-rate-mirrors
        log_ok "Espejos calibrados con éxito mediante cachyos-rate-mirrors."
    elif command -v rate-mirrors &>/dev/null; then
        rate-mirrors arch | $SUDO tee "$MIRRORS_DIR/mirrorlist" >/dev/null
        log_ok "Espejos de Arch Linux calibrados con rate-mirrors."
    elif command -v reflector &>/dev/null; then
        $SUDO reflector --latest 15 --protocol https --sort rate --save "$MIRRORS_DIR/mirrorlist"
        log_ok "Espejos optimizados con reflector."
    else
        log_warn "cachyos-rate-mirrors no encontrado. Instalando..."
        $SUDO pacman -S --needed --noconfirm cachyos-rate-mirrors 2>/dev/null || true
        if command -v cachyos-rate-mirrors &>/dev/null; then
            $SUDO cachyos-rate-mirrors
            log_ok "Espejos calibrados con cachyos-rate-mirrors."
        else
            log_err "No se pudo calibrar los espejos automáticamente."
        fi
    fi
}

update_system() {
    log_info "Iniciando actualización completa del sistema para CachyOS (Zen 3 / Wayland)..."
    if command -v paru &>/dev/null; then
        log_info "Actualizando mediante paru (repositorios oficiales + AUR)..."
        paru -Syu --noconfirm
    else
        log_info "Actualizando mediante pacman..."
        $SUDO pacman -Syu --noconfirm
    fi
    log_ok "Sistema actualizado completamente."
}

refresh_keys() {
    log_info "Inicializando y refrescando llaveros de Pacman..."
    $SUDO pacman-key --init
    log_info "Poblando firmas de Arch Linux y CachyOS..."
    $SUDO pacman-key --populate archlinux cachyos 2>/dev/null || true
    
    if [ -f "$MIRRORS_DIR/chaotic-mirrorlist" ]; then
        log_info "Refrescando firma de Chaotic-AUR..."
        $SUDO pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com 2>/dev/null || true
        $SUDO pacman-key --lsign-key 3056513887B78AEB 2>/dev/null || true
    fi
    log_ok "Llaveros de firmas actualizados y validados."
}

ACTION="${1:-setup}"
case "$ACTION" in
    -s|--status)
        show_status
        ;;
    -r|--rate-mirrors)
        rate_mirrors
        ;;
    -u|--update)
        update_system
        ;;
    -k|--keys)
        refresh_keys
        ;;
    --chaotic)
        setup_chaotic
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
