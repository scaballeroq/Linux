#!/usr/bin/env bash
# ==============================================================================
# post-install-amd.sh - Configuración Post-Instalación para NixOS (AMD Ryzen)
# Perfil: Portátil de desarrollo (HP EliteBook 855 G7 / AMD Ryzen 7 PRO 4750U)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "================================================================="
echo "❄️ INICIANDO POST-INSTALACIÓN: NIXOS - AMD RYZEN (laptop-amd)"
echo "================================================================="

# 1. Aplicación de la configuración declarativa de NixOS
if command -v nixos-rebuild &>/dev/null; then
    echo "ℹ️ [1/6] Reconstruyendo y aplicando configuración de NixOS con Flakes..."
    if [ -f "$REPO_ROOT/flake.nix" ]; then
        sudo nixos-rebuild switch --flake "$REPO_ROOT#laptop-amd" || {
            echo "⚠️ Advertencia: Error al aplicar flake automáticamente. Puedes ejecutar 'just switch' manualmente."
        }
    fi
else
    echo "ℹ️ Sistema no NixOS detectado o nixos-rebuild no en PATH. Continuando con configuración de usuario..."
fi

# 2. Configuración de repositorios Flatpak & Flathub
echo "ℹ️ [2/6] Verificando integración con Flatpak y Flathub..."
if command -v flatpak &>/dev/null; then
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    echo "✅ Flathub configurado para usuario y sistema."
fi

# 3. Instalación de aplicaciones Flatpak esenciales
echo "ℹ️ [3/6] Desplegando suite básica Flatpak (VLC)..."
if command -v flatpak &>/dev/null; then
    flatpak install -y --user --noninteractive flathub org.videolan.VLC 2>/dev/null || true
fi

# 4. Configuración del prompt Starship y Fastfetch
echo "ℹ️ [4/6] Configurando Fastfetch y Starship prompt..."
"$SCRIPT_DIR/fastfetch.sh" --theme nix 2>/dev/null || true
"$SCRIPT_DIR/starship.sh" --enable 2>/dev/null || true

# 5. Personalización de Terminal Kitty
echo "ℹ️ [5/6] Configurando terminal Kitty..."
"$SCRIPT_DIR/kitty.sh" 2>/dev/null || true

# 6. Optimizaciones de KDE Plasma 6 y Portátil
echo "ℹ️ [6/6] Aplicando optimizaciones de KDE Plasma 6 y portátil..."
"$SCRIPT_DIR/kde-settings.sh" 2>/dev/null || true
"$SCRIPT_DIR/laptop-setup.sh" 2>/dev/null || true

echo "================================================================="
echo "✅ NixOS + KDE Plasma 6 (AMD Ryzen) configurado con éxito."
echo "💡 Se recomienda reiniciar la sesión gráfica o el equipo para disfrutar del entorno completo."
echo "================================================================="
