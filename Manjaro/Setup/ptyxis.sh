#!/usr/bin/env bash
# ptyxis.sh - Configuración e Instalación de Ptyxis para Manjaro Linux + GNOME
# 
# Instala el emulador de terminal Ptyxis con la extensión "Nautilus Open Any Terminal",
# atajo de teclado global (Ctrl+Alt+T) y aspecto oscuro con transparencia (85%).

set -euo pipefail

echo "==========================================================="
echo "🚀 Iniciando instalación y configuración de Ptyxis en Manjaro"
echo "==========================================================="

# 1. Instalar Ptyxis y dependencias vía Pacman
echo "📦 [1/6] Instalando dependencias y Ptyxis..."
sudo pacman -S --needed --noconfirm \
    git \
    make \
    python-nautilus \
    gettext \
    base-devel \
    ptyxis

# 2. Descargar e instalar la extensión "Nautilus Open Any Terminal"
echo "📥 [2/6] Instalando extensión Nautilus Open Any Terminal..."
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
cd "$TMP_DIR"

git clone https://github.com/Stunkymonkey/nautilus-open-any-terminal.git
cd nautilus-open-any-terminal
make
sudo make install schema
sudo glib-compile-schemas /usr/share/glib-2.0/schemas

# 3. Establecer Ptyxis como terminal por defecto en Nautilus
echo "⚙️ [3/6] Configurando Ptyxis como terminal por defecto en Nautilus..."
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal ptyxis
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal new-tab true

# 4. Configurar atajo de teclado para abrir Ptyxis (Ctrl + Alt + T)
echo "⌨️ [4/6] Configurando atajo de teclado (Ctrl+Alt+T)..."
KEYBINDINGS=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || echo "@as []")
NEW_BINDING="'/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ptyxis/'"

if [[ "$KEYBINDINGS" == "@as []" ]] || [[ -z "$KEYBINDINGS" ]]; then
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[$NEW_BINDING]"
elif [[ "$KEYBINDINGS" != *"$NEW_BINDING"* ]]; then
    UPDATED_BINDINGS="${KEYBINDINGS%\]}, $NEW_BINDING]"
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$UPDATED_BINDINGS"
fi

gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ptyxis/ name 'Abrir Ptyxis'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ptyxis/ command 'ptyxis'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ptyxis/ binding '<Primary><Alt>t'

# 5. Configurar apariencia de Ptyxis (Moderno y Transparente)
echo "🎨 [5/6] Aplicando configuración estética a Ptyxis..."
PROFILE_UUID=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'" || true)

if [ -n "$PROFILE_UUID" ]; then
    gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${PROFILE_UUID}/" opacity 0.85 || true
fi

gsettings set org.gnome.Ptyxis interface-style 'dark' || true
gsettings set org.gnome.Ptyxis scrollbar-policy 'never' || true

# 6. Reiniciar Nautilus
echo "🔄 [6/6] Reiniciando Nautilus para aplicar cambios..."
nautilus -q 2>/dev/null || true

echo "==========================================================="
echo "✅ ¡Ptyxis instalado y configurado correctamente en Manjaro!"
echo "==========================================================="
