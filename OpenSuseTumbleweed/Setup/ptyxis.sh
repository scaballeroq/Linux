#!/usr/bin/env bash
#
# Configuración e Instalación de Ptyxis para OpenSUSE Tumbleweed + GNOME
# 
# Este script instala el emulador de terminal Ptyxis, una alternativa moderna 
# diseñada para GNOME, junto con la extensión "Nautilus Open Any Terminal" 
# para integrarlo directamente en el gestor de archivos Nautilus.
# 
# También configura un atajo de teclado global (Ctrl+Alt+T) para abrir Ptyxis
# y aplica la configuración estética (tema oscuro, transparencia y ocultamiento de scrollbar).

set -euo pipefail

echo "==========================================================="
echo "🚀 Iniciando instalación y configuración estética de Ptyxis en OpenSUSE Tumbleweed"
echo "==========================================================="

# 1. Actualizar repositorios e instalar paquetes
echo "📦 [1/6] Instalando dependencias y Ptyxis vía Zypper..."
sudo zypper --non-interactive install -y \
    git \
    make \
    python3-nautilus \
    typelib-1_0-Gtk-4_0 \
    gettext-tools \
    ptyxis 2>/dev/null || true

# 2. Descargar e instalar la extensión "Nautilus Open Any Terminal"
echo "📥 [2/6] Instalando extensión Nautilus Open Any Terminal..."
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
cd "$TMP_DIR"

git clone https://github.com/Stunkymonkey/nautilus-open-any-terminal.git
cd nautilus-open-any-terminal
make
sudo make install schema 2>/dev/null || true
sudo glib-compile-schemas /usr/share/glib-2.0/schemas 2>/dev/null || true

# 3. Establecer Ptyxis como terminal por defecto en Nautilus
echo "⚙️ [3/6] Configurando Ptyxis como terminal por defecto en Nautilus..."
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal ptyxis 2>/dev/null || true
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal new-tab true 2>/dev/null || true

# 4. Configurar atajo de teclado para abrir Ptyxis (Ctrl + Alt + T)
echo "⌨️ [4/6] Configurando atajo de teclado (Ctrl+Alt+T)..."
KEYBINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")
NEW_BINDING="'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ptyxis/'"

if [[ "$KEYBINDINGS" == "@as []" ]] || [[ -z "$KEYBINDINGS" ]]; then
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[$NEW_BINDING]" 2>/dev/null || true
elif [[ "$KEYBINDINGS" != *"$NEW_BINDING"* ]]; then
    UPDATED_BINDINGS="${KEYBINDINGS%\]}, $NEW_BINDING]"
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$UPDATED_BINDINGS" 2>/dev/null || true
fi

# Definir las propiedades del atajo de Ptyxis
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ptyxis/ name 'Abrir Ptyxis' 2>/dev/null || true
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ptyxis/ command 'ptyxis' 2>/dev/null || true
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ptyxis/ binding '<Primary><Alt>t' 2>/dev/null || true

# 5. Configurar apariencia de Ptyxis (Moderno y Transparente)
echo "🎨 [5/6] Aplicando configuración estética a Ptyxis (tema oscuro y transparencia)..."
PROFILE_UUID=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'" || true)

if [ -n "$PROFILE_UUID" ]; then
    gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${PROFILE_UUID}/" opacity 0.85 2>/dev/null || true
fi

gsettings set org.gnome.Ptyxis interface-style 'dark' 2>/dev/null || true
gsettings set org.gnome.Ptyxis scrollbar-policy 'never' 2>/dev/null || true

# 6. Reiniciar Nautilus
echo "🔄 [6/6] Reiniciando Nautilus para aplicar cambios..."
nautilus -q 2>/dev/null || true

echo "==========================================================="
echo "✅ ¡Instalación y configuración estética de Ptyxis completada!"
echo "Ptyxis ya está configurado con look oscuro y transparente (Ctrl+Alt+T)."
echo "==========================================================="
