#!/bin/bash
# firefox.sh - Instalación de Firefox CachyOS (Optimizado para x86-64-v3/v4)

set -euo pipefail

echo "🚀 Instalando Firefox optimizado para CachyOS..."

if pacman -Si firefox-cachyos &>/dev/null; then
    echo "ℹ️ Instalando firefox-cachyos y soporte de idioma español..."
    sudo pacman -S --needed --noconfirm firefox-cachyos firefox-cachyos-i18n-es-es 2>/dev/null || sudo pacman -S --needed --noconfirm firefox-cachyos firefox-i18n-es-es
else
    echo "ℹ️ Instalando firefox nativo..."
    sudo pacman -S --needed --noconfirm firefox firefox-i18n-es-es
fi

echo "✅ Firefox instalado correctamente en CachyOS."
echo "💡 Verifica la instalación ejecutando: firefox --version"
