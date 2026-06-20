#!/bin/bash
# =============================================================================
# CONFIGURACIÓN DE GNOME (gnome_settings.sh)
# =============================================================================
# Este archivo contiene configuraciones de entorno para GNOME y aliases
# para gestionar extensiones y comportamientos del escritorio.

# -----------------------------------------------------------------------------
# 1. CONFIGURACIONES DE GSETTINGS (Solo si estamos en GNOME)
# -----------------------------------------------------------------------------

if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
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
fi

# -----------------------------------------------------------------------------
# 2. ALIASES PARA GNOME
# -----------------------------------------------------------------------------

# Listar extensiones instaladas y su estado
alias gnome-extensions-list='gnome-extensions list --enabled'

# Atajos para luz nocturna
alias gnome-night-light-on='gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true'
alias gnome-night-light-off='gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false'

# Cambiar entre tema claro y oscuro (GNOME 42+)
alias gnome-theme-dark='gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"'
alias gnome-theme-light='gsettings set org.gnome.desktop.interface color-scheme "default"'

# Abrir configuración de GNOME directamente en secciones
alias gnome-conf-display='gnome-control-center display'
alias gnome-conf-network='gnome-control-center network'
alias gnome-conf-keyboard='gnome-control-center keyboard'

# Reiniciar GNOME Shell (Solo en X11)
alias gnome-restart='busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s "Meta.restart('\''Restarting…'\'')"'

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Optimizaciones de GNOME aplicadas"
