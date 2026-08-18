#!/bin/bash
# plymouth-setup.sh - Instalación, configuración y activación de Splash Screen (Plymouth) en Debian Testing + GNOME
#
# Uso:
#   ./plymouth-setup.sh              -> Instala y activa el tema recomendado (bgrt o ceratopsian)
#   ./plymouth-setup.sh <tema>       -> Instala y activa un tema específico (ej: ceratopsian, spinner, emerald)
#   ./plymouth-setup.sh --list       -> Lista todos los temas disponibles e instalados
#   ./plymouth-setup.sh --preview    -> Previsualiza el splash screen actual en el escritorio
#   ./plymouth-setup.sh --disable    -> Desactiva Plymouth y vuelve al arranque en modo texto

set -euo pipefail

# Comprobar privilegios sudo
if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible. Ejecuta este script como root o instala sudo."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

THEMES_DIR="/usr/share/plymouth/themes"

# Función: Mostrar ayuda
show_help() {
    cat <<EOF
🎨 Gestor y Configurador de Plymouth para Debian Testing

Uso:
  $0 [OPCIÓN | NOMBRE_TEMA]

Opciones:
  (sin argumentos)       Instala paquetes necesarios y activa el tema por defecto ('bgrt' o 'ceratopsian')
  <nombre_tema>          Configura y activa el tema indicado (ej: bgrt, ceratopsian, spinner, emerald)
  -l, --list, list       Muestra los temas de Plymouth disponibles e instalados
  -p, --preview [tema]   Previsualiza el tema de Plymouth en el escritorio durante 6 segundos
  -d, --disable          Desactiva Plymouth y restaura el arranque en texto
  -h, --help             Muestra esta ayuda

Temas destacados en Debian:
  • bgrt        -> OEM UEFI Boot Logo (muestra el logo de Lenovo/Dell/HP/ASUS + spinner moderno)
  • ceratopsian -> Tema oficial artístico de Debian 13 (Trixie / Testing)
  • emerald     -> Tema oficial de Debian 12 (Bookworm)
  • homeworld   -> Tema oficial de Debian 11 (Bullseye)
  • spinner     -> Ruleta de carga minimalista y moderna sobre fondo negro
  • solar       -> Animación de llamaradas solares azules espaciales
  • spinfinity  -> Logo Debian con símbolo infinito animado
EOF
}

# Función: Listar temas disponibles
list_themes() {
    echo "================================================================="
    echo "📋 Temas de Plymouth disponibles en el sistema:"
    echo "================================================================="
    if [ ! -d "$THEMES_DIR" ]; then
        echo "⚠️ No se encontró el directorio $THEMES_DIR. Instala plymouth primero."
        return
    fi

    CURRENT_THEME=""
    if command -v plymouth-set-default-theme &>/dev/null; then
        CURRENT_THEME=$(/usr/sbin/plymouth-set-default-theme 2>/dev/null || true)
    fi

    echo -e "Tema Actual Activo: \033[1;32m${CURRENT_THEME:-Ninguno}\033[0m\n"

    for theme in "$THEMES_DIR"/*; do
        if [ -d "$theme" ]; then
            theme_name=$(basename "$theme")
            description=""
            case "$theme_name" in
                bgrt) description="[Recomendado UEFI] Logo del fabricante (OEM) con spinner de carga" ;;
                ceratopsian) description="[Oficial] Tema artístico predeterminado de Debian 13 Trixie" ;;
                emerald) description="[Oficial] Tema predeterminado de Debian 12 Bookworm" ;;
                homeworld) description="[Oficial] Tema predeterminado de Debian 11 Bullseye" ;;
                futureprototype) description="[Oficial] Tema de Debian 10 Buster" ;;
                softwaves) description="[Oficial] Tema de Debian 9 Stretch" ;;
                lines) description="[Oficial] Tema de Debian 8 Jessie" ;;
                joy) description="[Oficial] Tema de Debian 7 Wheezy" ;;
                spacefun) description="[Oficial] Tema de Debian 6 Squeeze" ;;
                moonlight) description="[Oficial] Tema alternativo con diseño lunar" ;;
                spinner) description="Minimalista: ruleta de carga giratoria en fondo negro" ;;
                spinfinity) description="Logo centrado con spinner en forma de infinito" ;;
                solar) description="Sol azul animado con llamaradas solares" ;;
                fade-in) description="Logo con estrellas titilantes y efecto fade" ;;
                glow) description="Gráfico circular de progreso brillante" ;;
                breeze) description="Tema elegante estilo KDE Plasma" ;;
                details) description="Modo texto con información de arranque detallada" ;;
                text|tribar) description="Modos texto / barras ligeras" ;;
                debian-theme) description="Enlace simbólico al tema activo del sistema Debian" ;;
                *) description="Tema personalizado" ;;
            esac

            if [ "$theme_name" = "$CURRENT_THEME" ]; then
                printf "  \033[1;32m● %-18s\033[0m - %s \033[1;32m(ACTIVO)\033[0m\n" "$theme_name" "$description"
            else
                printf "  ○ %-18s - %s\n" "$theme_name" "$description"
            fi
        fi
    done
    echo "================================================================="
}

# Función: Previsualizar tema en escritorio
preview_theme() {
    local target_theme="${1:-}"

    if [ -z "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
        echo "❌ Error: La previsualización requiere una sesión gráfica activa (X11 o Wayland)."
        exit 1
    fi

    if ! dpkg -l | grep -q "plymouth-x11"; then
        echo "ℹ️ Instalando plymouth-x11 para soporte de previsualización..."
        $SUDO apt update
        $SUDO apt install -y plymouth-x11
    fi

    if [ -n "$target_theme" ]; then
        if [ ! -d "$THEMES_DIR/$target_theme" ]; then
            echo "❌ Error: El tema '$target_theme' no está instalado en $THEMES_DIR."
            echo "💡 Usa '$0 --list' para ver los temas disponibles."
            exit 1
        fi
        echo "🎬 Previsualizando tema '$target_theme' durante 6 segundos..."
        $SUDO plymouthd --debug --mode=boot --theme="$target_theme"
    else
        echo "🎬 Previsualizando tema activo actual durante 6 segundos..."
        $SUDO plymouthd --debug --mode=boot
    fi

    $SUDO plymouth --show-splash
    for i in {1..6}; do
        $SUDO plymouth --update="Iniciando entorno gráfico... ($i/6)"
        sleep 1
    done
    $SUDO plymouth --quit
    echo "✅ Previsualización finalizada."
}

# Función: Desactivar Plymouth
disable_plymouth() {
    echo "ℹ️ Desactivando Plymouth y restaurando arranque en texto estándar..."
    
    if [ -f /etc/default/grub.d/99-plymouth.cfg ]; then
        $SUDO rm -f /etc/default/grub.d/99-plymouth.cfg
    fi

    if [ -f /etc/initramfs-tools/conf.d/splash ]; then
        $SUDO rm -f /etc/initramfs-tools/conf.d/splash
    fi

    echo "ℹ️ Regenerando configuración de GRUB e Initramfs..."
    $SUDO update-initramfs -u
    $SUDO update-grub
    echo "✅ Plymouth ha sido desactivado. El sistema arrancará en modo texto normal."
}

# Función: Instalar y Configurar Plymouth
install_and_configure() {
    local target_theme="${1:-bgrt}"

    echo "🎨 ================================================================="
    echo "🚀 Configurando Plymouth Boot Splash en Debian Testing (Trixie)..."
    echo "================================================================="

    # 1. Instalación de paquetes necesarios
    echo "📦 1/5 Instalando paquetes de Plymouth y colecciones de temas..."
    $SUDO apt update
    $SUDO apt install -y \
        plymouth \
        plymouth-themes \
        plymouth-label \
        plymouth-x11 \
        desktop-base \
        initramfs-tools

    # 2. Configurar initramfs para activar el framebuffer gráfico temprano
    echo "⚙️ 2/5 Asegurando soporte Framebuffer en initramfs (/etc/initramfs-tools/conf.d/splash)..."
    $SUDO mkdir -p /etc/initramfs-tools/conf.d
    echo "FRAMEBUFFER=y" | $SUDO tee /etc/initramfs-tools/conf.d/splash > /dev/null

    # 3. Configurar parámetros del Kernel en GRUB (arranque suave y silencioso)
    echo "⚙️ 3/5 Configurando parámetros de arranque en GRUB (/etc/default/grub.d/99-plymouth.cfg)..."
    $SUDO mkdir -p /etc/default/grub.d
    $SUDO tee /etc/default/grub.d/99-plymouth.cfg > /dev/null << 'EOF'
# Configuración optimizada de Plymouth Boot Splash para Debian Testing
GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT:-quiet} splash loglevel=3 udev.log_level=3 vt.global_cursor_default=0"
GRUB_GFXMODE="auto"
EOF

    # 4. Validar y seleccionar tema
    echo "🎨 4/5 Configurando tema de Plymouth seleccionado: '$target_theme'..."
    if [ ! -d "$THEMES_DIR/$target_theme" ]; then
        echo "⚠️ El tema '$target_theme' no fue encontrado en $THEMES_DIR."
        if [ -d "$THEMES_DIR/bgrt" ]; then
            echo "ℹ️ Usando tema por defecto alternativo: 'bgrt'"
            target_theme="bgrt"
        elif [ -d "$THEMES_DIR/ceratopsian" ]; then
            echo "ℹ️ Usando tema por defecto oficial de Debian Testing: 'ceratopsian'"
            target_theme="ceratopsian"
        else
            echo "ℹ️ Usando tema por defecto del sistema: 'spinner'"
            target_theme="spinner"
        fi
    fi

    # Activar tema y actualizar initramfs
    $SUDO /usr/sbin/plymouth-set-default-theme -R "$target_theme"

    # 5. Actualizar GRUB
    echo "🔄 5/5 Regenerando menú y configuración de arranque GRUB..."
    $SUDO update-grub

    echo "================================================================="
    echo "✅ Plymouth configurado y activado con éxito."
    echo "🎯 Tema activo: $target_theme"
    echo "💡 Puedes probar el arranque visual ejecutando: ./Setup/plymouth-setup.sh --preview"
    echo "💡 Puedes cambiar de tema en cualquier momento ejecutando: ./Setup/plymouth-setup.sh <nombre_tema>"
    echo "💡 Puedes listar los temas disponibles con: ./Setup/plymouth-setup.sh --list"
    echo "================================================================="
}

# Control de flujo principal según argumentos
ACTION="${1:-}"

case "$ACTION" in
    -h|--help|help)
        show_help
        ;;
    -l|--list|list)
        list_themes
        ;;
    -p|--preview|preview)
        preview_theme "${2:-}"
        ;;
    -d|--disable|disable)
        disable_plymouth
        ;;
    *)
        # Si se pasa un argumento que no empieza por '-', interpretarlo como nombre de tema
        # Si no se pasa ningún argumento, target_theme por defecto será 'bgrt'
        THEME_NAME="${ACTION:-bgrt}"
        install_and_configure "$THEME_NAME"
        ;;
esac
