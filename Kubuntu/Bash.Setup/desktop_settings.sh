#!/bin/bash
# =============================================================================
# CONFIGURACIÓN DE ESCRITORIO (desktop_settings.sh)
# =============================================================================
# Este archivo contiene configuraciones de entorno y aliases para el escritorio
# detectando si se ejecuta en GNOME o KDE Plasma.

# -----------------------------------------------------------------------------
# 1. CONFIGURACIONES DE ENTORNO (Solo si estamos en GNOME o KDE)
# -----------------------------------------------------------------------------

if [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]]; then
    # Luz Nocturna (Night Light) - Activar y configurar temperatura (3500K)
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3500

    # Formato de reloj (24h)
    gsettings set org.gnome.desktop.interface clock-format '24h'
    gsettings set org.gnome.desktop.interface show-battery-percentage true

    # Mostrar botones de minimizar y maximizar
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

    # Comportamiento de energía: No suspender cuando está enchufado
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
    
    echo "✅ Optimizaciones de GNOME aplicadas"

elif [[ "${XDG_CURRENT_DESKTOP:-}" == *"KDE"* ]]; then
    # Configurar Luz Nocturna (Night Color)
    if command -v kwriteconfig6 &> /dev/null; then
        kwriteconfig6 --file kwinrc --group NightColor --key Active true
        kwriteconfig6 --file kwinrc --group NightColor --key Mode Constant
        kwriteconfig6 --file kwinrc --group NightColor --key NightTemperature 3500
        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    elif command -v kwriteconfig5 &> /dev/null; then
        kwriteconfig5 --file kwinrc --group NightColor --key Active true
        kwriteconfig5 --file kwinrc --group NightColor --key Mode Constant
        kwriteconfig5 --file kwinrc --group NightColor --key NightTemperature 3500
        qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
    fi

    # Configurar ahorro de energía (No suspender en corriente alterna)
    if command -v kwriteconfig6 &> /dev/null; then
        kwriteconfig6 --file powerdevilrc --group AC --group SuspendSession --key suspendType 0
        qdbus6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement.refreshStatus 2>/dev/null || true
    elif command -v kwriteconfig5 &> /dev/null; then
        kwriteconfig5 --file powerdevilrc --group AC --group SuspendSession --key suspendType 0
        qdbus org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement.refreshStatus 2>/dev/null || true
    fi

    echo "✅ Optimizaciones de KDE Plasma aplicadas"
fi

# -----------------------------------------------------------------------------
# 2. ALIASES PARA ESCRITORIO
# -----------------------------------------------------------------------------

# --- Aliases para GNOME ---
alias gnome-extensions-list='gnome-extensions list --enabled'
alias gnome-night-light-on='gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true'
alias gnome-night-light-off='gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false'
alias gnome-theme-dark='gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"'
alias gnome-theme-light='gsettings set org.gnome.desktop.interface color-scheme "default"'
alias gnome-conf-display='gnome-control-center display'
alias gnome-conf-network='gnome-control-center network'
alias gnome-conf-keyboard='gnome-control-center keyboard'
alias gnome-restart='busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s "Meta.restart('\''Restarting…'\'')"'

# --- Aliases para KDE ---
# Atajos para luz nocturna
alias kde-night-light-on='if command -v kwriteconfig6 &>/dev/null; then kwriteconfig6 --file kwinrc --group NightColor --key Active true && qdbus6 org.kde.KWin /KWin reconfigure; else kwriteconfig5 --file kwinrc --group NightColor --key Active true && qdbus org.kde.KWin /KWin reconfigure; fi'
alias kde-night-light-off='if command -v kwriteconfig6 &>/dev/null; then kwriteconfig6 --file kwinrc --group NightColor --key Active false && qdbus6 org.kde.KWin /KWin reconfigure; else kwriteconfig5 --file kwinrc --group NightColor --key Active false && qdbus org.kde.KWin /KWin reconfigure; fi'

# Cambiar entre tema claro y oscuro
alias kde-theme-dark='lookandfeeltool -a org.kde.breezedark.desktop'
alias kde-theme-light='lookandfeeltool -a org.kde.breeze.desktop'

# Configuración del sistema KDE
alias kde-conf='systemsettings'
