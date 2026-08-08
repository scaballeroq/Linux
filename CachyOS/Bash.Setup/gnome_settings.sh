#!/bin/bash
# =============================================================================
# CONFIGURACIÓN DE GNOME (gnome_settings.sh) - CachyOS Laptop & Desktop
# =============================================================================
# Este archivo contiene configuraciones de entorno para GNOME, optimizaciones
# para portátil (Touchpad, HiDPI, VRR) y aliases útiles.

# -----------------------------------------------------------------------------
# 1. CONFIGURACIONES DE GSETTINGS (Solo si estamos en GNOME)
# -----------------------------------------------------------------------------

if [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]]; then
    # Luz Nocturna (Night Light) - Activar y configurar temperatura (3500K)
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature uint32 3500 2>/dev/null || gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3500 2>/dev/null || true

    # Formato de reloj (24h) y porcentaje de batería
    gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true

    # Mostrar botones de minimizar, maximizar y cerrar en la barra de título
    gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' 2>/dev/null || true

    # Touchpad y gestos para portátil
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true 2>/dev/null || true
    gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true 2>/dev/null || true

    # Escalado Fraccional y Tasa de Refresco Variable (VRR)
    gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer', 'variable-refresh-rate']" 2>/dev/null || true

    # Comportamiento de energía: No suspender cuando está enchufado a la corriente AC
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true
fi

# -----------------------------------------------------------------------------
# 2. ALIASES PARA GNOME Y CACHYOS
# -----------------------------------------------------------------------------

# Listar extensiones instaladas y su estado
alias gnome-extensions-list='gnome-extensions list --enabled'

# Atajos para luz nocturna
alias gnome-night-light-on='gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true'
alias gnome-night-light-off='gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false'

# Cambiar entre tema claro y oscuro
alias gnome-theme-dark='gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"'
alias gnome-theme-light='gsettings set org.gnome.desktop.interface color-scheme "default"'

# Abrir configuración de GNOME directamente en secciones
alias gnome-conf-display='gnome-control-center display'
alias gnome-conf-network='gnome-control-center network'
alias gnome-conf-keyboard='gnome-control-center keyboard'
alias gnome-conf-power='gnome-control-center power'

# Clasificar espejo más rápido para la red Wi-Fi actual
alias rate-mirrors='cachyos-rate-mirrors'

# Reiniciar GNOME Shell (Solo en X11)
alias gnome-restart='busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s "Meta.restart('\''Restarting…'\'')"'

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Optimizaciones de GNOME y Portátil aplicadas"
