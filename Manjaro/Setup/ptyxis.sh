#!/usr/bin/env bash
# ptyxis.sh - Configuración e Instalación de Ptyxis para Manjaro Linux + GNOME
# 
# Instala Ptyxis, configuración de atajos e integración con Nautilus.
# Preserva la configuración de ZSH existente.

set -euo pipefail

echo "==========================================================="
echo "🚀 Iniciando instalación y configuración de Ptyxis en Manjaro"
echo "==========================================================="

# 1. Instalar Ptyxis y extensión Nautilus vía Pacman (Nativo)
echo "📦 [1/5] Instalando Ptyxis y nautilus-open-any-terminal..."
sudo pacman -S --needed --noconfirm \
    ptyxis \
    nautilus-open-any-terminal

# 2. Establecer Ptyxis como terminal por defecto en Nautilus
echo "️ [2/5] Configurando Ptyxis como terminal por defecto en Nautilus..."
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal ptyxis
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal new-tab true

# 3. Configurar atajo de teclado para abrir Ptyxis (Ctrl + Alt + T)
echo "⌨️ [3/5] Configurando atajo de teclado (Ctrl+Alt+T)..."
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

# 4. Configurar apariencia de Ptyxis (Moderno y Transparente)
echo "🎨 [4/5] Aplicando configuración estética a Ptyxis..."
PROFILE_UUID=$(gsettings get org.gnome.Ptyxis default-profile-uuid 2>/dev/null | tr -d "'" || true)

if [ -n "$PROFILE_UUID" ]; then
    gsettings set "org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${PROFILE_UUID}/" opacity 0.85 || true
fi

gsettings set org.gnome.Ptyxis interface-style 'dark' || true
gsettings set org.gnome.Ptyxis scrollbar-policy 'never' || true

# 5. Reiniciar Nautilus
echo "🔄 [5/5] Reiniciando Nautilus para aplicar cambios..."
nautilus -q 2>/dev/null || true

echo "==========================================================="
echo "✅ ¡Ptyxis instalado y configurado correctamente en Manjaro!"
echo "==========================================================="
