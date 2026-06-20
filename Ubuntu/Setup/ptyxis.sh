#!/usr/bin/env bash
#
# Configuración e Instalación de Ptyxis para Ubuntu
# 
# Este script instala el emulador de terminal Ptyxis, una alternativa moderna 
# diseñada para GNOME, junto con la extensión "Nautilus Open Any Terminal" 
# para integrarlo directamente en el gestor de archivos Nautilus.
# 
# También configura un atajo de teclado global (Ctrl+Alt+T) para abrir Ptyxis.

# Salir inmediatamente si un comando falla
set -e

echo "==========================================================="
echo "Iniciando instalación y configuración de Ptyxis en Ubuntu"
echo "==========================================================="

# 1. Actualizar repositorios e instalar actualizaciones
echo "[1/6] Actualizando el sistema..."
sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y

# 2. Instalar dependencias necesarias y el paquete ptyxis
# En Ubuntu, 'ptyxis' está disponible en los repositorios oficiales.
echo "[2/6] Instalando dependencias y Ptyxis..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    git \
    make \
    python3-nautilus \
    gir1.2-gtk-4.0 \
    gettext \
    build-essential \
    ptyxis

# 3. Descargar e instalar la extensión "Nautilus Open Any Terminal"
echo "[3/6] Instalando extensión Nautilus Open Any Terminal..."
# Creamos un directorio temporal seguro para la clonación
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

git clone https://github.com/Stunkymonkey/nautilus-open-any-terminal.git
cd nautilus-open-any-terminal
make
sudo make install schema
sudo glib-compile-schemas /usr/share/glib-2.0/schemas

# Limpiar directorio temporal
cd /tmp
rm -rf "$TMP_DIR"

# 4. Establecer Ptyxis como terminal por defecto en Nautilus
echo "[4/6] Configurando Ptyxis como terminal por defecto en Nautilus..."
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal ptyxis
# Opcional: configurar para que abra en una nueva pestaña
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal new-tab true

# 5. Configurar atajo de teclado para abrir Ptyxis (Ctrl + Alt + T)
echo "[5/6] Configurando atajo de teclado (Ctrl+Alt+T)..."
# Para evitar sobrescribir otros atajos personalizados, leemos los actuales y añadimos el de Ptyxis
KEYBINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")
NEW_BINDING="'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ptyxis/'"

if [[ "$KEYBINDINGS" == "@as []" ]] || [[ -z "$KEYBINDINGS" ]]; then
    # Si no hay atajos previos, creamos el array con el nuestro
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[$NEW_BINDING]"
elif [[ "$KEYBINDINGS" != *"$NEW_BINDING"* ]]; then
    # Si existen otros atajos pero no el nuestro, lo añadimos al final
    UPDATED_BINDINGS="${KEYBINDINGS%\]}, $NEW_BINDING]"
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$UPDATED_BINDINGS"
fi

# Definir las propiedades del atajo de Ptyxis
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ptyxis/ name 'Abrir Ptyxis'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ptyxis/ command 'ptyxis'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ptyxis/ binding '<Primary><Alt>t'

# 6. Configurar apariencia de Ptyxis (Moderno y Transparente)
echo "[6/7] Aplicando tema moderno y transparencia a Ptyxis..."
# Obtener el UUID del perfil por defecto
PROFILE_UUID=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'" || true)

if [ -n "$PROFILE_UUID" ]; then
    # Configurar opacidad al 85% (ligeramente transparente)
    gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${PROFILE_UUID}/" opacity 0.85 || true
fi

# Forzar interfaz oscura para un look más moderno
gsettings set org.gnome.Ptyxis interface-style 'dark' || true
# Ocultar la barra de desplazamiento para un diseño más limpio y minimalista
gsettings set org.gnome.Ptyxis scrollbar-policy 'never' || true

# 7. Reiniciar Nautilus para aplicar los cambios
echo "[7/7] Reiniciando Nautilus para aplicar cambios..."
nautilus -q || true

echo "==========================================================="
echo "¡Instalación y configuración completadas con éxito!"
echo "Ptyxis ya está configurado con un look moderno (oscuro y transparente)."
echo "Puedes abrirlo con Ctrl+Alt+T o desde el menú contextual en Nautilus."
echo "==========================================================="