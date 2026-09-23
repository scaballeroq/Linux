#!/bin/bash
# ==============================================================================
# apariencia.sh - Temas, Iconos e Integración Visual para openSUSE Tumbleweed
# Entorno: KDE Plasma 6 + Wayland (Modo Oscuro, Papirus-Dark, GTK/Qt)
# ==============================================================================

set -euo pipefail

echo "================================================================="
echo "🎨 Configurando temas, iconos y homogeneización visual GTK/Qt..."
echo "================================================================="

if [ "$EUID" -ne 0 ]; then
    if ! command -v sudo &> /dev/null; then
        echo "❌ Error: 'sudo' no está disponible."
        exit 1
    fi
    SUDO="sudo"
else
    SUDO=""
fi

# Detectar usuario real en caso de ejecución con sudo
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    REAL_USER="$SUDO_USER"
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_USER="${USER:-$(id -un)}"
    USER_HOME="${HOME:-/home/$REAL_USER}"
fi

run_as_user() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$REAL_USER" env HOME="$USER_HOME" "$@"
    else
        "$@"
    fi
}

# 1. Instalar paquetes de temas e iconos
echo "📦 [1/3] Instalando temas de iconos e integración GTK/Qt..."
$SUDO zypper --non-interactive install -y \
    papirus-icon-theme \
    breeze6-icons \
    breeze6-style 2>/dev/null || true

# 2. Configurar tema oscuro e iconos en KDE Plasma 6
echo "🌙 [2/3] Aplicando tema oscuro Breeze Dark e iconos Papirus-Dark..."
run_as_user plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || \
run_as_user plasma-apply-lookandfeel -a org.kde.breeze.dark.desktop 2>/dev/null || \
run_as_user plasma-apply-colorscheme BreezeDark 2>/dev/null || true

run_as_user kwriteconfig6 --file kdeglobals --group Icons --key Theme "Papirus-Dark" 2>/dev/null || true

# 3. Integración para aplicaciones GTK 3 y GTK 4 en KDE
echo "⚙️ [3/3] Homogeneizando aplicaciones GTK3 y GTK4 con Breeze-Dark..."
run_as_user mkdir -p "$USER_HOME/.config/gtk-3.0" "$USER_HOME/.config/gtk-4.0"

cat <<'EOF' | run_as_user tee "$USER_HOME/.config/gtk-3.0/settings.ini" > /dev/null
[Settings]
gtk-theme-name=Breeze-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
gtk-font-name=Noto Sans 10
EOF

cat <<'EOF' | run_as_user tee "$USER_HOME/.config/gtk-4.0/settings.ini" > /dev/null
[Settings]
gtk-theme-name=Breeze-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
gtk-font-name=Noto Sans 10
EOF

echo "================================================================="
echo "✅ Apariencia, iconos e integración GTK/Qt configurados con éxito."
echo "================================================================="
