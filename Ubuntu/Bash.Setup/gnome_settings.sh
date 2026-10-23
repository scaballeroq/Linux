#!/bin/bash
# =============================================================================
# CONFIGURACIÓN Y ALIASES PARA GNOME SHELL 51 (gnome_settings.sh)
# Ubuntu Workstation (GNOME Shell 51 + Wayland / Mutter)
# =============================================================================
# Adaptación completa y sin residuos de KDE para el entorno nativo GNOME.
# Proporciona atajos rápidos, control de apariencia, luz nocturna y accesos
# directos al Centro de Control de GNOME y utilidades Wayland.
# =============================================================================

# Evitar ejecución en subshells y sesiones no interactivas
[[ $- != *i* ]] && return 0 2>/dev/null || true

# -----------------------------------------------------------------------------
# 1. GESTIÓN DEL ENTORNO Y RECARGA DE GNOME SHELL
# -----------------------------------------------------------------------------
# En Wayland, GNOME Shell está gestionado como servicio por Systemd
alias gnome-restart='systemctl --user restart gnome-session.target 2>/dev/null || echo "💡 En GNOME Wayland las aplicaciones gestionan su propio ciclo de vida."'
alias mutter-reload='pkill -HUP mutter 2>/dev/null || true'

# -----------------------------------------------------------------------------
# 2. ACCESOS DIRECTOS AL CENTRO DE CONTROL DE GNOME (gnome-control-center)
# -----------------------------------------------------------------------------
alias gnome-settings='gnome-control-center &>/dev/null &'
alias gnome-conf-display='gnome-control-center display &>/dev/null &'
alias gnome-conf-audio='gnome-control-center sound &>/dev/null &'
alias gnome-conf-sound='gnome-control-center sound &>/dev/null &'
alias gnome-conf-bluetooth='gnome-control-center bluetooth &>/dev/null &'
alias gnome-conf-network='gnome-control-center network &>/dev/null &'
alias gnome-conf-wifi='gnome-control-center wifi &>/dev/null &'
alias gnome-conf-power='gnome-control-center power &>/dev/null &'
alias gnome-conf-shortcuts='gnome-control-center keyboard &>/dev/null &'
alias gnome-conf-keyboard='gnome-control-center keyboard &>/dev/null &'
alias gnome-conf-touchpad='gnome-control-center mouse &>/dev/null &'
alias gnome-conf-mouse='gnome-control-center mouse &>/dev/null &'
alias gnome-conf-appearance='gnome-control-center appearance &>/dev/null &'
alias gnome-conf-apps='gnome-control-center applications &>/dev/null &'
alias gnome-conf-users='gnome-control-center system &>/dev/null || gnome-control-center user-accounts &>/dev/null &'
alias gnome-conf-printers='gnome-control-center printers &>/dev/null &'

# -----------------------------------------------------------------------------
# 3. GESTIÓN DE TEMAS Y LUZ NOCTURNA DESDE LA TERMINAL
# -----------------------------------------------------------------------------

# Alternar a modo oscuro completo (Adwaita Dark / Prefer Dark)
gnome-theme-dark() {
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || \
        gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-dark' 2>/dev/null || \
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
    echo "🌙 Modo oscuro aplicado en GNOME (prefer-dark)."
}

# Alternar a modo claro (Default)
gnome-theme-light() {
    gsettings set org.gnome.desktop.interface color-scheme 'default' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Yaru' 2>/dev/null || \
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
    echo "☀️ Modo claro aplicado en GNOME (default)."
}

# Luz Nocturna (Night Light)
alias gnome-night-light-on='gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true 2>/dev/null; gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 4000 2>/dev/null; echo "🌙 Luz nocturna activada (4000K)."'
alias gnome-night-light-off='gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false 2>/dev/null; echo "☀️ Luz nocturna desactivada."'

# -----------------------------------------------------------------------------
# 4. GESTIÓN DE EXTENSIONES DE GNOME SHELL
# -----------------------------------------------------------------------------
alias gnome-extensions-list='gnome-extensions list --enabled'
alias gnome-extensions-all='gnome-extensions list'
alias gnome-extensions-prefs='gnome-extensions prefs'
if command -v extension-manager &>/dev/null; then
    alias gnome-ext-manager='extension-manager &>/dev/null &'
fi

# -----------------------------------------------------------------------------
# 5. APLICACIONES NATIVAS DE GNOME Y WAYLAND
# -----------------------------------------------------------------------------
alias nautilus='nautilus . &>/dev/null &'
alias files='nautilus . &>/dev/null &'

if command -v gnome-text-editor &>/dev/null; then
    alias text-editor='gnome-text-editor &>/dev/null &'
    alias editor='gnome-text-editor &>/dev/null &'
elif command -v gedit &>/dev/null; then
    alias text-editor='gedit &>/dev/null &'
    alias editor='gedit &>/dev/null &'
fi

alias sysmon='gnome-system-monitor &>/dev/null &'
alias monitor='gnome-system-monitor &>/dev/null &'
alias calc='gnome-calculator &>/dev/null &'

# Portapapeles Wayland nativo (wl-clipboard)
if command -v wl-copy &> /dev/null; then
    alias clipcopy='wl-copy'
    alias clippaste='wl-paste'
fi

# -----------------------------------------------------------------------------
# 6. CONFIGURACIONES BASE DE SESIÓN GNOME (GSETTINGS)
# -----------------------------------------------------------------------------
if [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]] || [[ "${DESKTOP_SESSION:-}" == *"gnome"* ]]; then
    # Botones de ventana completos a la derecha: minimizar, maximizar, cerrar
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close' 2>/dev/null || true

    # Formato de reloj y estado superior
    gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface clock-show-weekday true 2>/dev/null || true
    gsettings set org.gnome.desktop.interface clock-show-date true 2>/dev/null || true
    gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true

    # Comportamiento de ventanas y diálogos
    gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true
    gsettings set org.gnome.mutter attach-modal-dialogs true 2>/dev/null || true

    # Nautilus: Vista detallada y borrado permanente
    gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' 2>/dev/null || true
    gsettings set org.gnome.nautilus.preferences show-delete-permanent true 2>/dev/null || true

    # Energía: No suspender en corriente alterna
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true
fi

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
[[ $- == *i* ]] && echo "✅ Configuración y utilidades de GNOME cargadas"
