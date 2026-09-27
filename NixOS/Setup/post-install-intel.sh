#!/usr/bin/env bash
# ==============================================================================
# post-install-intel.sh - Configuración Post-Instalación para NixOS (Intel Core)
# Perfil: Sobremesa Centro Multimedia (Intel Haswell / Core i7 + Kodi)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "================================================================="
echo "❄️ INICIANDO POST-INSTALACIÓN: NIXOS - INTEL CORE (desktop-intel)"
echo "================================================================="

# 1. Aplicación de la configuración declarativa de NixOS
if command -v nixos-rebuild &>/dev/null; then
    echo "ℹ️ [1/5] Reconstruyendo y aplicando configuración de NixOS con Flakes..."
    if [ -f "$REPO_ROOT/flake.nix" ]; then
        sudo nixos-rebuild switch --flake "$REPO_ROOT#desktop-intel" || {
            echo "⚠️ Advertencia: Error al aplicar flake automáticamente. Puedes ejecutar 'just switch' manualmente."
        }
    fi
else
    echo "ℹ️ Sistema no NixOS detectado o nixos-rebuild no en PATH. Continuando con configuración de usuario..."
fi

# 2. Configuración de repositorios Flatpak & Flathub
echo "ℹ️ [2/5] Verificando integración con Flatpak y Flathub..."
if command -v flatpak &>/dev/null; then
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    echo "✅ Flathub configurado para usuario y sistema."
fi

# 3. Configuración del prompt Starship y Fastfetch
echo "ℹ️ [3/5] Configurando Fastfetch y Starship prompt..."
"$SCRIPT_DIR/fastfetch.sh" --theme nix 2>/dev/null || true
"$SCRIPT_DIR/starship.sh" --enable 2>/dev/null || true

# 4. Personalización de Terminal Kitty
echo "ℹ️ [4/5] Configurando terminal Kitty..."
"$SCRIPT_DIR/kitty.sh" 2>/dev/null || true

# 5. Optimizaciones de KDE Plasma 6
echo "ℹ️ [5/5] Aplicando personalizaciones de KDE Plasma 6..."
"$SCRIPT_DIR/kde-settings.sh" 2>/dev/null || true

echo "================================================================="
echo "✅ NixOS + KDE Plasma 6 (Intel Core / Media Center) configurado con éxito."
echo "💡 Reinicia la sesión gráfica o el equipo para completar la activación."
echo "================================================================="
