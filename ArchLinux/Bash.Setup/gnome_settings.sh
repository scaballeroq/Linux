#!/bin/bash
# =============================================================================
# CONFIGURACIÓN DE GNOME (gnome_settings.sh)
# =============================================================================

if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 6000

    gsettings set org.gnome.desktop.interface clock-format '24h'
    gsettings set org.gnome.desktop.interface show-battery-percentage true

    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'


fi

# -----------------------------------------------------------------------------
# ALIASES PARA GNOME
# -----------------------------------------------------------------------------

alias gnome-extensions-list='gnome-extensions list --enabled'

alias gnome-night-light-on='gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true'
alias gnome-night-light-off='gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false'

alias gnome-theme-dark='gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"'
alias gnome-theme-light='gsettings set org.gnome.desktop.interface color-scheme "default"'

alias gnome-conf-display='gnome-control-center display'
alias gnome-conf-network='gnome-control-center network'
alias gnome-conf-keyboard='gnome-control-center keyboard'

alias gnome-restart='busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s "Meta.restart('\''Restarting…'\'')"'

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Optimizaciones de GNOME aplicadas"
