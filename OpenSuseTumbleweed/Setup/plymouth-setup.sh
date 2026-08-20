#!/bin/bash
# plymouth-setup.sh - Instalación, configuración y activación de Splash Screen (Plymouth) en OpenSUSE Tumbleweed + GNOME
#
# Uso:
#   ./plymouth-setup.sh              -> Instala y activa el tema recomendado (bgrt o openSUSE)
#   ./plymouth-setup.sh <tema>       -> Instala y activa un tema específico (ej: bgrt, openSUSE, spinner)
#   ./plymouth-setup.sh --list       -> Lista todos los temas disponibles e instalados
#   ./plymouth-setup.sh --preview    -> Previsualiza el splash screen actual en el escritorio
#   ./plymouth-setup.sh --disable    -> Desactiva Plymouth y vuelve al arranque en modo texto

set -euo pipefail

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
🎨 Gestor y Configurador de Plymouth para OpenSUSE Tumbleweed

Uso:
  $0 [OPCIÓN | NOMBRE_TEMA]

Opciones:
  (sin argumentos)       Instala paquetes necesarios y activa el tema por defecto ('bgrt' o 'openSUSE')
  <nombre_tema>          Configura y activa el tema indicado (ej: bgrt, openSUSE, spinner)
  -l, --list, list       Muestra los temas de Plymouth disponibles e instalados
  -p, --preview [tema]   Previsualiza el tema de Plymouth en el escritorio durante 6 segundos
  -d, --disable          Desactiva Plymouth y restaura el arranque en texto
  -h, --help             Muestra esta ayuda

Temas destacados en OpenSUSE:
  • bgrt        -> OEM UEFI Boot Logo (muestra el logo de Lenovo/Dell/HP/ASUS + spinner moderno)
  • openSUSE    -> Tema oficial de openSUSE Tumbleweed con Geeko
  • spinner     -> Ruleta de carga minimalista y moderna sobre fondo negro
  • solar       -> Animación de llamaradas solares azules espaciales
  • spinfinity  -> Animación con símbolo infinito
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
        CURRENT_THEME=$(/usr/sbin/plymouth-set-default-theme 2>/dev/null || plymouth-set-default-theme 2>/dev/null || true)
    fi

    echo -e "Tema Actual Activo: \033[1;32m${CURRENT_THEME:-Ninguno}\033[0m\n"

    for theme in "$THEMES_DIR"/*; do
        if [ -d "$theme" ]; then
            theme_name=$(basename "$theme")
            description=""
            case "$theme_name" in
                bgrt) description="[Recomendado UEFI] Logo del fabricante (OEM) con spinner de carga" ;;
                openSUSE|opensuse) description="[Oficial] Tema artístico oficial de openSUSE Tumbleweed" ;;
                spinner) description="Minimalista: ruleta de carga giratoria en fondo negro" ;;
                spinfinity) description="Logo centrado con spinner en forma de infinito" ;;
                solar) description="Sol azul animado con llamaradas solares" ;;
                fade-in) description="Logo con estrellas titilantes y efecto fade" ;;
                glow) description="Gráfico circular de progreso brillante" ;;
                breeze) description="Tema elegante estilo KDE Plasma" ;;
                details) description="Modo texto con información de arranque detallada" ;;
                text|tribar) description="Modos texto / barras ligeras" ;;
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

    if ! rpm -q plymouth-x11 &>/dev/null; then
        echo "ℹ️ Instalando plymouth-x11 para soporte de previsualización..."
        $SUDO zypper --non-interactive install -y plymouth-x11 2>/dev/null || true
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
        $SUDO plymouth --update="Iniciando OpenSUSE Tumbleweed... ($i/6)"
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

    echo "ℹ️ Regenerando Initramfs con Dracut y menú GRUB2..."
    $SUDO dracut -f
    $SUDO grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || $SUDO update-bootloader --refresh || true
    echo "✅ Plymouth ha sido desactivado. El sistema arrancará en modo texto normal."
}

# Función: Instalar y Configurar Plymouth
install_and_configure() {
    local target_theme="${1:-bgrt}"

    echo "🎨 ================================================================="
    echo "🚀 Configurando Plymouth Boot Splash en OpenSUSE Tumbleweed..."
    echo "================================================================="

    # 1. Instalación de paquetes necesarios
    echo "📦 1/4 Instalando paquetes de Plymouth y colecciones de temas..."
    $SUDO zypper --non-interactive install -y \
        plymouth \
        plymouth-theme-spinner \
        plymouth-theme-bgrt \
        plymouth-branding-openSUSE \
        plymouth-dracut \
        plymouth-x11 2>/dev/null || true

    # 2. Configurar parámetros del Kernel en GRUB
    echo "⚙️ 2/4 Configurando parámetros de arranque silencioso en GRUB..."
    $SUDO mkdir -p /etc/default/grub.d
    $SUDO tee /etc/default/grub.d/99-plymouth.cfg > /dev/null << 'EOF'
# Configuración optimizada de Plymouth Boot Splash para OpenSUSE Tumbleweed
GRUB_CMDLINE_LINUX_DEFAULT="${GRUB_CMDLINE_LINUX_DEFAULT:-quiet} splash loglevel=3 udev.log_level=3 vt.global_cursor_default=0"
GRUB_GFXMODE="auto"
EOF

    # 3. Validar y seleccionar tema
    echo "🎨 3/4 Configurando tema de Plymouth seleccionado: '$target_theme'..."
    if [ ! -d "$THEMES_DIR/$target_theme" ]; then
        echo "⚠️ El tema '$target_theme' no fue encontrado en $THEMES_DIR."
        if [ -d "$THEMES_DIR/bgrt" ]; then
            echo "ℹ️ Usando tema alternativo: 'bgrt'"
            target_theme="bgrt"
        elif [ -d "$THEMES_DIR/openSUSE" ]; then
            echo "ℹ️ Usando tema oficial: 'openSUSE'"
            target_theme="openSUSE"
        else
            echo "ℹ️ Usando tema por defecto: 'spinner'"
            target_theme="spinner"
        fi
    fi

    # Activar tema y regenerar initramfs con dracut
    if command -v plymouth-set-default-theme &>/dev/null; then
        $SUDO plymouth-set-default-theme -R "$target_theme"
    else
        $SUDO /usr/sbin/plymouth-set-default-theme -R "$target_theme"
    fi

    # 4. Actualizar GRUB2
    echo "🔄 4/4 Regenerando menú y configuración de arranque GRUB2..."
    $SUDO grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || $SUDO update-bootloader --refresh || true

    echo "================================================================="
    echo "✅ Plymouth configurado y activado con éxito en OpenSUSE Tumbleweed."
    echo "🎯 Tema activo: $target_theme"
    echo "💡 Puedes probar el arranque visual con: ./Setup/plymouth-setup.sh --preview"
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
        THEME_NAME="${ACTION:-bgrt}"
        install_and_configure "$THEME_NAME"
        ;;
esac
