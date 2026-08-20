#!/bin/bash
# plymouth-setup.sh - Instalación, configuración y activación de Splash Screen (Plymouth) en Manjaro Linux + GNOME
#
# Uso:
#   ./plymouth-setup.sh              -> Instala y activa el tema recomendado (bgrt o manjaro)
#   ./plymouth-setup.sh <tema>       -> Instala y activa un tema específico (ej: bgrt, manjaro, spinner)
#   ./plymouth-setup.sh --list       -> Lista todos los temas disponibles e instalados
#   ./plymouth-setup.sh --preview    -> Previsualiza el splash screen actual en el escritorio
#   ./plymouth-setup.sh --disable    -> Desactiva Plymouth y vuelve al arranque en modo texto

set -euo pipefail

THEMES_DIR="/usr/share/plymouth/themes"

show_help() {
    cat <<EOF
🎨 Gestor y Configurador de Plymouth para Manjaro Linux

Uso:
  $0 [OPCIÓN | NOMBRE_TEMA]

Opciones:
  (sin argumentos)       Instala paquetes necesarios y activa el tema recomendado ('bgrt' o 'manjaro')
  <nombre_tema>          Configura y activa el tema indicado (ej: bgrt, manjaro, spinner, solar)
  -l, --list, list       Muestra los temas de Plymouth disponibles e instalados
  -p, --preview [tema]   Previsualiza el tema de Plymouth en el escritorio durante 6 segundos
  -d, --disable          Desactiva Plymouth y restaura el arranque en texto
  -h, --help             Muestra esta ayuda

Temas destacados en Manjaro:
  • bgrt        -> OEM UEFI Boot Logo (muestra el logo de Lenovo/Dell/HP/ASUS + spinner moderno)
  • manjaro     -> Tema oficial de Manjaro Linux
  • spinner     -> Ruleta de carga minimalista y moderna sobre fondo negro
  • solar       -> Animación de llamaradas solares azules espaciales
  • fade-in     -> Logo con estrellas titilantes
EOF
}

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
        CURRENT_THEME=$(plymouth-set-default-theme 2>/dev/null || true)
    fi

    echo -e "Tema Actual Activo: \033[1;32m${CURRENT_THEME:-Ninguno}\033[0m\n"

    for theme in "$THEMES_DIR"/*; do
        if [ -d "$theme" ]; then
            theme_name=$(basename "$theme")
            description=""
            case "$theme_name" in
                bgrt) description="[Recomendado UEFI] Logo del fabricante (OEM) con spinner de carga" ;;
                manjaro*) description="[Oficial] Tema predeterminado de Manjaro Linux" ;;
                spinner) description="Minimalista: ruleta de carga giratoria en fondo negro" ;;
                solar) description="Sol azul animado con llamaradas solares" ;;
                fade-in) description="Logo con estrellas titilantes y efecto fade" ;;
                glow) description="Gráfico circular de progreso brillante" ;;
                breeze) description="Tema elegante estilo KDE Plasma" ;;
                details) description="Modo texto con información de arranque detallada" ;;
                *) description="Tema del sistema" ;;
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

preview_theme() {
    local target_theme="${1:-}"
    if ! command -v plymouthd &>/dev/null; then
        echo "❌ Error: Plymouth no está instalado."
        exit 1
    fi

    if [ -z "$target_theme" ]; then
        target_theme=$(plymouth-set-default-theme 2>/dev/null || echo "bgrt")
    fi

    echo "🎬 Previsualizando tema '$target_theme' durante 6 segundos (No toques nada)..."
    sudo plymouthd --debug || true
    sudo plymouth --show-splash || true
    for i in {1..6}; do
        sudo plymouth --update="test $i" || true
        sleep 1
    done
    sudo plymouth --quit || true
    echo "✅ Previsualización finalizada."
}

disable_plymouth() {
    echo "ℹ️ Desactivando splash screen de Plymouth en GRUB..."
    if [ -f /etc/default/grub ]; then
        sudo sed -i 's/\bsplash\b//g' /etc/default/grub
        sudo sed -i 's/  */ /g' /etc/default/grub
    fi
    if command -v update-grub &>/dev/null; then
        sudo update-grub
    fi
    echo "✅ Plymouth desactivado. El sistema arrancará en modo texto detallado."
}

# Procesar banderas
case "${1:-}" in
    -h|--help|help)
        show_help
        exit 0
        ;;
    -l|--list|list)
        list_themes
        exit 0
        ;;
    -p|--preview|preview)
        preview_theme "${2:-}"
        exit 0
        ;;
    -d|--disable|disable)
        disable_plymouth
        exit 0
        ;;
esac

# 1. Instalación de Plymouth vía Pacman
echo "📦 [1/4] Instalando Plymouth y temas vía Pacman..."
sudo pacman -S --needed --noconfirm plymouth 2>/dev/null || true

# 2. Configurar mkinitcpio hook
echo "⚙️ [2/4] Verificando hook de plymouth en /etc/mkinitcpio.conf..."
if [ -f /etc/mkinitcpio.conf ]; then
    if ! grep -q "plymouth" /etc/mkinitcpio.conf; then
        echo "ℹ️ Añadiendo hook 'plymouth' después de 'udev' en /etc/mkinitcpio.conf..."
        sudo sed -i 's/\(HOOKS=.*udev\)/\1 plymouth/' /etc/mkinitcpio.conf || true
    fi
fi

# 3. Selección y activación de tema
CHOSEN_THEME="${1:-}"
if [ -z "$CHOSEN_THEME" ]; then
    if [ -d "$THEMES_DIR/bgrt" ]; then
        CHOSEN_THEME="bgrt"
    elif [ -d "$THEMES_DIR/manjaro" ]; then
        CHOSEN_THEME="manjaro"
    elif [ -d "$THEMES_DIR/spinner" ]; then
        CHOSEN_THEME="spinner"
    else
        CHOSEN_THEME="bgrt"
    fi
fi

echo "🎨 [3/4] Activando tema de Plymouth: '$CHOSEN_THEME'..."
sudo plymouth-set-default-theme "$CHOSEN_THEME" 2>/dev/null || true

# 4. Habilitar quiet splash en GRUB y regenerar initramfs
echo "🚀 [4/4] Configurando GRUB y regenerando initramfs (mkinitcpio)..."
if [ -f /etc/default/grub ]; then
    if ! grep -q "splash" /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash /' /etc/default/grub
        sudo sed -i 's/  */ /g' /etc/default/grub
    fi
fi

if command -v mkinitcpio &>/dev/null; then
    sudo mkinitcpio -P || true
fi

if command -v update-grub &>/dev/null; then
    sudo update-grub || true
elif command -v grub-mkconfig &>/dev/null; then
    sudo grub-mkconfig -o /boot/grub/grub.cfg || true
fi

echo "================================================================="
echo "✅ Plymouth configurado y activado con el tema: $CHOSEN_THEME"
echo "💡 Para probarlo ejecuta: ./Setup/plymouth-setup.sh --preview"
echo "================================================================="
