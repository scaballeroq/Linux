#!/bin/bash
# =============================================================================
# CONFIGURACIÓN Y ALIASES PARA GNOME (gnome_settings.sh) - Fedora 44
# =============================================================================
# Este archivo contiene configuraciones de entorno para GNOME, optimizaciones
# para portátil (Touchpad, HiDPI, VRR) y aliases útiles.

# -----------------------------------------------------------------------------
# 1. CONFIGURACIONES DE GSETTINGS (Solo si estamos en GNOME)
# -----------------------------------------------------------------------------

if [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]]; then
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature uint32 3500 2>/dev/null || gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3500 2>/dev/null || true

    gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close' 2>/dev/null || true

    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true
fi

# -----------------------------------------------------------------------------
# 2. ALIASES PARA EXTENSIONES DE GNOME
# -----------------------------------------------------------------------------

alias ext-list="gnome-extensions list --enabled"
alias ext-all="gnome-extensions list"
alias ext-prefs="gnome-extensions prefs"
alias ext-disable="gnome-extensions disable"
alias ext-enable="gnome-extensions enable"
alias ext-info="gnome-extensions info"

# Reiniciar GNOME Shell (Solo funciona en sesión X11; en Wayland requiere cerrar sesión)
if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
    alias gnome-restart="echo 'En Wayland no se puede reiniciar GNOME Shell en caliente. Guarda tu trabajo y cierra sesión.'"
else
    alias gnome-restart="killall -3 gnome-shell"
fi

# -----------------------------------------------------------------------------
# 3. ACCESOS DIRECTOS A PANELES DE CONFIGURACIÓN
# -----------------------------------------------------------------------------

alias gnome-pantallas="gnome-control-center display"
alias gnome-wifi="gnome-control-center wifi"
alias gnome-audio="gnome-control-center sound"
alias gnome-bluetooth="gnome-control-center bluetooth"
alias gnome-teclado="gnome-control-center keyboard"
alias gnome-apps="gnome-control-center applications"
alias gnome-fondo="gnome-control-center background"

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Configuración y aliases de GNOME cargados"
