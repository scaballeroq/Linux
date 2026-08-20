#!/bin/bash
# =============================================================================
# CONFIGURACIÓN Y ALIASES PARA GNOME (gnome_settings.sh) - Manjaro Linux (Bash)
# =============================================================================

if [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]]; then
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature uint32 3500 2>/dev/null || gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3500 2>/dev/null || true

    gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true

    gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' 2>/dev/null || true

    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true

    gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'variable-refresh-rate']" 2>/dev/null || true

    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true
fi

alias gnome-extensions-list='gnome-extensions list --enabled'

alias gnome-night-light-on='gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true'
alias gnome-night-light-off='gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false'

alias gnome-theme-dark='gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"'
alias gnome-theme-light='gsettings set org.gnome.desktop.interface color-scheme "default"'

alias gnome-conf-display='gnome-control-center display'
alias gnome-conf-network='gnome-control-center network'
alias gnome-conf-keyboard='gnome-control-center keyboard'
alias gnome-conf-power='gnome-control-center power'

alias gnome-restart='busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s "Meta.restart('\''Restarting…'\'')"'

echo "✅ Configuración y aliases de GNOME para Bash cargados"
