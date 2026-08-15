#!/bin/bash
# =============================================================================
# CONFIGURACIÓN Y ALIASES PARA KDE PLASMA (kde_settings.sh) - KDEDebian
# =============================================================================
# Este archivo contiene configuraciones de entorno para KDE Plasma 6,
# optimizaciones para portátil (Touchpad, VRR, HiDPI) y aliases útiles.

# -----------------------------------------------------------------------------
# 1. ALIASES PARA KDE PLASMA
# -----------------------------------------------------------------------------

# Reinicio del entorno gráfico / shell de Plasma
alias plasma-restart='systemctl --user restart plasma-plasmashell.service 2>/dev/null || (kquitapp6 plasmashell 2>/dev/null; kstart plasmashell 2>/dev/null &)'
alias kwin-restart='systemctl --user restart plasma-kwin_wayland.service 2>/dev/null || qdbus org.kde.KWin /KWin reconfigure'

# Luz Nocturna (Night Color)
alias kde-night-light-on='(kwriteconfig6 --file kwinrc --group NightColor --key Active true 2>/dev/null || kwriteconfig5 --file kwinrc --group NightColor --key Active true 2>/dev/null || true); qdbus org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.setNightColorActive true 2>/dev/null || qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true'
alias kde-night-light-off='(kwriteconfig6 --file kwinrc --group NightColor --key Active false 2>/dev/null || kwriteconfig5 --file kwinrc --group NightColor --key Active false 2>/dev/null || true); qdbus org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.setNightColorActive false 2>/dev/null || qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true'

# Temas Claro / Oscuro (Brisa Oscuro / Brisa Claro)
alias kde-theme-dark='plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || plasma-apply-colorscheme BreezeDark 2>/dev/null || true'
alias kde-theme-light='plasma-apply-lookandfeel -a org.kde.breeze.desktop 2>/dev/null || plasma-apply-colorscheme BreezeLight 2>/dev/null || true'

# Acceso rápido a módulos de Preferencias del Sistema (KCM)
alias kde-settings='systemsettings'
alias kde-conf-display='kcmshell6 kcm_kscreen 2>/dev/null || systemsettings kcm_kscreen'
alias kde-conf-audio='kcmshell6 kcm_pulseaudio 2>/dev/null || systemsettings kcm_pulseaudio'
alias kde-conf-bluetooth='kcmshell6 kcm_bluetooth 2>/dev/null || systemsettings kcm_bluetooth'
alias kde-conf-network='kcmshell6 kcm_networkmanagement 2>/dev/null || systemsettings kcm_networkmanagement'
alias kde-conf-power='kcmshell6 powerdevilprofilesconfig 2>/dev/null || systemsettings powerdevilprofilesconfig'
alias kde-conf-shortcuts='kcmshell6 kcm_keys 2>/dev/null || systemsettings kcm_keys'
alias kde-conf-touchpad='kcmshell6 kcm_touchpad 2>/dev/null || systemsettings kcm_touchpad'
alias kde-conf-appearance='kcmshell6 kcm_lookandfeel 2>/dev/null || systemsettings kcm_lookandfeel'

echo "✅ Configuración y aliases de KDE Plasma cargados"
