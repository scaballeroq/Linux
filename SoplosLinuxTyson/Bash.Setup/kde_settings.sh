#!/bin/bash
# =============================================================================
# CONFIGURACIÓN Y ALIASES PARA KDE PLASMA 6 (kde_settings.sh) - Soplos Linux Tyson
# =============================================================================
# Este archivo contiene accesos directos, reinicio de servicios gráficos y
# utilidades de configuración integradas con KDE Plasma 6, Wayland y Qt 6.

# -----------------------------------------------------------------------------
# 1. REINICIO DE SUBSISTEMAS GRÁFICOS (SYSTEMD / KWIN / PLASMASHELL)
# -----------------------------------------------------------------------------
alias plasma-restart='systemctl --user restart plasma-plasmashell.service 2>/dev/null || (kquitapp6 plasmashell 2>/dev/null; kstart6 plasmashell 2>/dev/null &)'
alias kwin-restart='systemctl --user restart plasma-kwin_wayland.service 2>/dev/null || qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || qdbus org.kde.KWin /KWin reconfigure 2>/dev/null'

# -----------------------------------------------------------------------------
# 2. LUZ NOCTURNA (NIGHT COLOR)
# -----------------------------------------------------------------------------
alias kde-night-light-on='(kwriteconfig6 --file kwinrc --group NightColor --key Active true 2>/dev/null || true); (qdbus6 org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.setNightColorActive true 2>/dev/null || qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true)'
alias kde-night-light-off='(kwriteconfig6 --file kwinrc --group NightColor --key Active false 2>/dev/null || true); (qdbus6 org.kde.KWin /ColorCorrect org.kde.kwin.ColorCorrect.setNightColorActive false 2>/dev/null || qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true)'

# -----------------------------------------------------------------------------
# 3. TEMAS CLARO / OSCURO (LOOK AND FEEL & COLOR SCHEME)
# -----------------------------------------------------------------------------
alias kde-theme-dark='plasma-apply-lookandfeel -a org.kde.breezedark.desktop 2>/dev/null || plasma-apply-colorscheme BreezeDark 2>/dev/null || true'
alias kde-theme-light='plasma-apply-lookandfeel -a org.kde.breeze.desktop 2>/dev/null || plasma-apply-colorscheme BreezeLight 2>/dev/null || true'

# -----------------------------------------------------------------------------
# 4. ACCESO RÁPIDO A MÓDULOS DE PREFERENCIAS (KCM - PLASMA 6)
# -----------------------------------------------------------------------------
alias kde-settings='systemsettings'
alias kde-conf-display='kcmshell6 kcm_kscreen 2>/dev/null || systemsettings kcm_kscreen'
alias kde-conf-audio='kcmshell6 kcm_pulseaudio 2>/dev/null || systemsettings kcm_pulseaudio'
alias kde-conf-bluetooth='kcmshell6 kcm_bluetooth 2>/dev/null || systemsettings kcm_bluetooth'
alias kde-conf-network='kcmshell6 kcm_networkmanagement 2>/dev/null || systemsettings kcm_networkmanagement'
alias kde-conf-power='kcmshell6 powerdevilprofilesconfig 2>/dev/null || kcmshell6 kcm_powerdevilprofilesconfig 2>/dev/null || systemsettings powerdevilprofilesconfig'
alias kde-conf-shortcuts='kcmshell6 kcm_keys 2>/dev/null || systemsettings kcm_keys'
alias kde-conf-touchpad='kcmshell6 kcm_touchpad 2>/dev/null || systemsettings kcm_touchpad'
alias kde-conf-appearance='kcmshell6 kcm_lookandfeel 2>/dev/null || systemsettings kcm_lookandfeel'

# -----------------------------------------------------------------------------
# 5. INFORMACIÓN DEL ENTORNO
# -----------------------------------------------------------------------------
plasma-info() {
    echo "================================================================="
    echo "🐧 Entorno Gráfico: KDE Plasma 6"
    echo "🖥️  Tipo de Sesión:  ${XDG_SESSION_TYPE:-Desconocido}"
    if command -v plasmashell &>/dev/null; then
        echo "📦 Versión Plasma:  $(plasmashell --version 2>/dev/null || echo 'KDE Plasma 6')"
    fi
    if command -v kf6-config &>/dev/null; then
        echo "🔧 KDE Frameworks:  $(kf6-config --version | head -n1 2>/dev/null)"
    elif command -v kreadconfig6 &>/dev/null; then
        echo "🔧 KDE Frameworks:  $(kreadconfig6 --version 2>/dev/null | head -n1)"
    fi
    echo "================================================================="
}

# =============================================================================
# MENSAJE DE CARGA (Solo en sesiones interactivas)
# =============================================================================
[[ $- == *i* ]] && [ -t 1 ] && echo "✅ Configuración y utilidades de KDE Plasma 6 cargadas" || true

