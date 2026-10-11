#!/bin/bash
# =============================================================================
# CONFIGURACIÓN Y ALIASES PARA KDE PLASMA 6 (kde_settings.sh)
# OpenSUSE Tumbleweed (KDE Plasma 6 + Wayland)
# =============================================================================
# Configuración de sesión y atajos rápidos para KDE Plasma 6 en Zsh y Bash.
# =============================================================================

# Evitar ejecución en subshells y sesiones no interactivas
[[ $- != *i* ]] && return 0 2>/dev/null || true

# -----------------------------------------------------------------------------
# 1. GESTIÓN DEL ENTORNO Y SHELL DE PLASMA
# -----------------------------------------------------------------------------
# Reinicio del entorno gráfico / shell de Plasma y KWin
alias plasma-restart='systemctl --user restart plasma-plasmashell.service 2>/dev/null || (kquitapp6 plasmashell 2>/dev/null; kstart plasmashell 2>/dev/null &)'
alias kwin-restart='systemctl --user restart plasma-kwin_wayland.service 2>/dev/null || qdbus org.kde.KWin /KWin reconfigure'

# -----------------------------------------------------------------------------
# 2. ACCESOS DIRECTOS A PREFERENCIAS DEL SISTEMA (KCM / SYSTEMSETTINGS)
# -----------------------------------------------------------------------------
alias kde-settings='systemsettings &>/dev/null &'
alias kde-conf-display='kcmshell6 kcm_kscreen &>/dev/null || systemsettings kcm_kscreen &>/dev/null &'
alias kde-conf-audio='kcmshell6 kcm_pulseaudio &>/dev/null || systemsettings kcm_pulseaudio &>/dev/null &'
alias kde-conf-bluetooth='kcmshell6 kcm_bluetooth &>/dev/null || systemsettings kcm_bluetooth &>/dev/null &'
alias kde-conf-network='kcmshell6 kcm_networkmanagement &>/dev/null || systemsettings kcm_networkmanagement &>/dev/null &'
alias kde-conf-power='kcmshell6 powerdevilprofilesconfig &>/dev/null || systemsettings powerdevilprofilesconfig &>/dev/null &'
alias kde-conf-shortcuts='kcmshell6 kcm_keys &>/dev/null || systemsettings kcm_keys &>/dev/null &'
alias kde-conf-touchpad='kcmshell6 kcm_touchpad &>/dev/null || systemsettings kcm_touchpad &>/dev/null &'
alias kde-conf-appearance='kcmshell6 kcm_lookandfeel &>/dev/null || systemsettings kcm_lookandfeel &>/dev/null &'

# -----------------------------------------------------------------------------
# 3. GESTIÓN DE TEMAS Y LUZ NOCTURNA DESDE LA TERMINAL
# -----------------------------------------------------------------------------

# Alternar a modo oscuro completo (Breeze Dark)
kde-theme-dark() {
    plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || \
    plasma-apply-lookandfeel -a org.kde.breeze.dark.desktop 2>/dev/null || \
    plasma-apply-colorscheme BreezeDark 2>/dev/null || true
    echo "🌙 Modo oscuro aplicado en KDE Plasma (Breeze Dark)."
}

# Alternar a modo claro (Breeze Light)
kde-theme-light() {
    plasma-apply-lookandfeel -a org.kde.breeze.desktop 2>/dev/null || \
    plasma-apply-colorscheme BreezeLight 2>/dev/null || true
    echo "☀️ Modo claro aplicado en KDE Plasma (Breeze Light)."
}

# Luz Nocturna (Night Color)
alias kde-night-light-on='(kwriteconfig6 --file kwinrc --group NightColor --key Active true 2>/dev/null || true); qdbus org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.setNightColorActive true 2>/dev/null || qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true; echo "🌙 Luz nocturna activada."'
alias kde-night-light-off='(kwriteconfig6 --file kwinrc --group NightColor --key Active false 2>/dev/null || true); qdbus org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.setNightColorActive false 2>/dev/null || qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true; echo "☀️ Luz nocturna desactivada."'

# -----------------------------------------------------------------------------
# 4. APLICACIONES NATIVAS DE KDE Y WAYLAND
# -----------------------------------------------------------------------------
alias dolphin='dolphin . &>/dev/null &'
alias files='dolphin . &>/dev/null &'
alias kate='kate &>/dev/null &'
alias kwrite='kwrite &>/dev/null &'
alias spectacle='spectacle &>/dev/null &'
alias captura='spectacle -r &>/dev/null &'
alias capture='spectacle -r &>/dev/null &'
alias sysmon='plasma-systemmonitor &>/dev/null &'
alias monitor='plasma-systemmonitor &>/dev/null &'

# Wayland clipboards
if command -v wl-copy &> /dev/null; then
    alias clipcopy='wl-copy'
    alias clippaste='wl-paste'
fi

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Configuración y utilidades de KDE Plasma cargadas"
