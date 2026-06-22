#!/bin/bash
# =============================================================================
# ALIASES PARA GNOME (gnome_settings.sh)
# =============================================================================
# Este archivo contiene aliases para gestionar extensiones y comportamientos
# del escritorio GNOME. Se sourcea desde .bashrc.
# Para la configuración inicial de gsettings, usar Setup/gnome-settings.sh
# =============================================================================

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

echo "✅ Aliases de GNOME cargados"
