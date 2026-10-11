#!/bin/bash
# =============================================================================
# CONFIGURACIÓN Y ALIASES PARA GNOME (gnome_settings.sh) - Fedora 44
# =============================================================================
# Configuración de sesión y atajos rápidos para GNOME en Zsh y Bash.
# NOTA: Cero extensiones añadidas en esta fase.

# Evitar ejecución en subshells y sesiones no interactivas
[[ $- != *i* ]] && return 0 2>/dev/null || true

# -----------------------------------------------------------------------------
# 1. AJUSTES BASE DE GNOME (Sesión interactiva)
# -----------------------------------------------------------------------------
# Las preferencias globales de GNOME (tema oscuro, botones, reloj) se gestionan
# de forma persistente a través del instalador Setup/gnome-settings.sh.

# -----------------------------------------------------------------------------
# 2. ACCESOS DIRECTOS A PANELES DE CONFIGURACIÓN (GNOME CONTROL CENTER)
# -----------------------------------------------------------------------------
alias gnome-settings='gnome-control-center &>/dev/null &'
alias gnome-extensiones='extension-manager &>/dev/null &'
alias extensiones='extension-manager &>/dev/null &'
alias gnome-pantallas='gnome-control-center display &>/dev/null &'
alias gnome-wifi='gnome-control-center wifi &>/dev/null &'
alias gnome-audio='gnome-control-center sound &>/dev/null &'
alias gnome-bluetooth='gnome-control-center bluetooth &>/dev/null &'
alias gnome-teclado='gnome-control-center keyboard &>/dev/null &'
alias gnome-energia='gnome-control-center power &>/dev/null &'
alias gnome-red='gnome-control-center network &>/dev/null &'
alias gnome-info='gnome-control-center info-overview &>/dev/null &'

# -----------------------------------------------------------------------------
# 3. GESTIÓN DE TEMAS Y LUZ NOCTURNA DESDE LA TERMINAL
# -----------------------------------------------------------------------------

# Alternar a modo oscuro
gnome-theme-dark() {
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || \
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" 2>/dev/null || true
    echo "🌙 Modo oscuro aplicado en GNOME."
}

# Alternar a modo claro
gnome-theme-light() {
    gsettings set org.gnome.desktop.interface color-scheme 'default' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3' 2>/dev/null || \
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
    dconf write /org/gnome/desktop/interface/color-scheme "'default'" 2>/dev/null || true
    echo "☀️ Modo claro aplicado en GNOME."
}

# Luz nocturna
alias gnome-night-light-on='gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true'
alias gnome-night-light-off='gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false'

# -----------------------------------------------------------------------------
# 4. CAPTURAS Y HERRAMIENTAS WAYLAND NATIVAS
# -----------------------------------------------------------------------------
if command -v grim &>/dev/null && command -v slurp &>/dev/null; then
    if command -v satty &>/dev/null; then
        alias captura='grim -g "$(slurp)" - | satty --filename - &>/dev/null &'
    elif command -v wl-copy &>/dev/null; then
        alias captura='grim -g "$(slurp)" - | wl-copy'
    fi
fi

if command -v wl-screenrec &>/dev/null; then
    alias grabacion='wl-screenrec'
fi

# Navegación y explorador de archivos Nautilus
alias nautilus='nautilus . &>/dev/null &'
alias files='nautilus . &>/dev/null &'

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Configuración y utilidades de GNOME cargadas"
