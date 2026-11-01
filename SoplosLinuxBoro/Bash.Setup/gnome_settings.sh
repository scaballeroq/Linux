#!/bin/bash
# =============================================================================
# CONFIGURACIÓN Y ALIASES PARA GNOME SHELL (gnome_settings.sh)
# Soplos Linux Boro Workstation (GNOME Shell + Wayland / Mutter)
# Hardware: HP ProBook 455 G10 (AMD Ryzen 7 7730U / Radeon Graphics Vega 8)
# =============================================================================
# Adaptación nativa para Soplos Linux Boro:
#  - Branding oficial: Temas Orchis-Orange, iconos kora-soplos, Future-cursors.
#  - Mutter Wayland: optimizaciones multi-pantalla, centrado de ventanas.
#  - Accesos rápidos al Centro de Control de GNOME y utilidades Wayland.
#  - Operación idempotente: gsettings en caché para no ralentizar la terminal.
# =============================================================================

# Evitar ejecución en subshells y sesiones no interactivas
[[ $- != *i* ]] && return 0 2>/dev/null || true

# -----------------------------------------------------------------------------
# 1. GESTIÓN DEL ENTORNO GNOME Y WAYLAND
# -----------------------------------------------------------------------------
# En Wayland, GNOME Shell está gestionado como servicio de usuario por Systemd
alias gnome-restart='systemctl --user restart gnome-session.target 2>/dev/null || echo "💡 En GNOME Wayland las aplicaciones gestionan su propio ciclo de vida."'
alias mutter-reload='echo "ℹ️ En GNOME Wayland el compositor Mutter corre integrado en gnome-shell y no puede reiniciarse sin cerrar sesión."'

# Atajos al orquestador maestro de personalización de Soplos
alias soplos-gnome-setup='~/Workspace/Repositorios/Linux/SoplosLinuxBoro/Setup/gnome-settings.sh'
alias soplos-gnome-status='~/Workspace/Repositorios/Linux/SoplosLinuxBoro/Setup/gnome-settings.sh --status'
alias soplos-gnome-keybindings='~/Workspace/Repositorios/Linux/SoplosLinuxBoro/Setup/gnome-settings.sh --keybindings'

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
# 3. GESTIÓN DE TEMAS OFICIALES DE SOPLOS Y SALUD VISUAL
# -----------------------------------------------------------------------------

# Alternar a modo oscuro oficial de Soplos Linux Boro (Orchis-Orange / Dark)
gnome-theme-dark() {
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    local target_gtk="adw-gtk3-dark"
    if [ -d "/usr/share/themes/Orchis-Orange-Dark-Compact" ]; then
        target_gtk="Orchis-Orange-Dark-Compact"
    elif [ -d "/usr/share/themes/Orchis-Orange-Dark" ]; then
        target_gtk="Orchis-Orange-Dark"
    fi
    gsettings set org.gnome.desktop.interface gtk-theme "$target_gtk" 2>/dev/null || true

    if gsettings list-schemas 2>/dev/null | grep -q "org.gnome.shell.extensions.user-theme"; then
        if [ -d "/usr/share/themes/Orchis-Orange-Dark-Compact" ]; then
            gsettings set org.gnome.shell.extensions.user-theme name 'Orchis-Orange-Dark-Compact' 2>/dev/null || true
        elif [ -d "/usr/share/themes/Orchis-Orange-Dark" ]; then
            gsettings set org.gnome.shell.extensions.user-theme name 'Orchis-Orange-Dark' 2>/dev/null || true
        fi
    fi

    local target_icons="Adwaita"
    if [ -d "/usr/share/icons/kora-soplos-dark" ]; then
        target_icons="kora-soplos-dark"
    elif [ -d "/usr/share/icons/Papirus-Dark" ]; then
        target_icons="Papirus-Dark"
    fi
    gsettings set org.gnome.desktop.interface icon-theme "$target_icons" 2>/dev/null || true

    if [ -d "/usr/share/icons/Future-cursors" ]; then
        gsettings set org.gnome.desktop.interface cursor-theme 'Future-cursors' 2>/dev/null || true
    fi
    echo "🌙 Modo oscuro aplicado (GTK: $target_gtk | Iconos: $target_icons | Soplos Linux Boro)."
}

# Alternar a modo claro oficial de Soplos Linux Boro
gnome-theme-light() {
    gsettings set org.gnome.desktop.interface color-scheme 'default' 2>/dev/null || true
    local target_gtk="Adwaita"
    if [ -d "/usr/share/themes/Orchis-Orange-Light-Compact" ]; then
        target_gtk="Orchis-Orange-Light-Compact"
    elif [ -d "/usr/share/themes/Orchis-Orange-Light" ]; then
        target_gtk="Orchis-Orange-Light"
    elif [ -d "/usr/share/themes/Orchis-Orange" ]; then
        target_gtk="Orchis-Orange"
    fi
    gsettings set org.gnome.desktop.interface gtk-theme "$target_gtk" 2>/dev/null || true

    if gsettings list-schemas 2>/dev/null | grep -q "org.gnome.shell.extensions.user-theme"; then
        if [ -d "/usr/share/themes/Orchis-Orange-Light-Compact" ]; then
            gsettings set org.gnome.shell.extensions.user-theme name 'Orchis-Orange-Light-Compact' 2>/dev/null || true
        elif [ -d "/usr/share/themes/Orchis-Orange-Light" ]; then
            gsettings set org.gnome.shell.extensions.user-theme name 'Orchis-Orange-Light' 2>/dev/null || true
        fi
    fi

    local target_icons="Adwaita"
    if [ -d "/usr/share/icons/kora-soplos-light" ]; then
        target_icons="kora-soplos-light"
    elif [ -d "/usr/share/icons/Papirus" ]; then
        target_icons="Papirus"
    fi
    gsettings set org.gnome.desktop.interface icon-theme "$target_icons" 2>/dev/null || true

    echo "☀️ Modo claro aplicado (GTK: $target_gtk | Iconos: $target_icons | Soplos Linux Boro)."
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
# 6. CONFIGURACIONES BASE DE SESIÓN GNOME (IDEMPOTENTES VÍA CACHÉ)
# -----------------------------------------------------------------------------
# Aplica parámetros de escritorio optimizados sin ralentizar el arranque de la terminal
soplos-gnome-defaults() {
    if [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]] || [[ "${DESKTOP_SESSION:-}" == *"gnome"* ]]; then
        # Botones de ventana completos a la derecha: minimizar, maximizar, cerrar
        gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close' 2>/dev/null || true

        # Formato de reloj y barra superior
        gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface clock-show-weekday true 2>/dev/null || true
        gsettings set org.gnome.desktop.interface clock-show-date true 2>/dev/null || true
        gsettings set org.gnome.desktop.interface show-battery-percentage true 2>/dev/null || true

        # Localización rápida de cursor multimonitor con tecla Ctrl
        gsettings set org.gnome.desktop.interface locate-pointer true 2>/dev/null || true

        # Mutter Wayland: Centrado de ventanas y cuadros modales
        gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true
        gsettings set org.gnome.mutter attach-modal-dialogs true 2>/dev/null || true

        # Nautilus: Vista de lista y borrado directo
        gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view' 2>/dev/null || true
        gsettings set org.gnome.nautilus.preferences show-delete-permanent true 2>/dev/null || true

        # Energía: Suspender desactivado en corriente alterna
        gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' 2>/dev/null || true

        mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}" 2>/dev/null || true
        touch "${XDG_CACHE_HOME:-$HOME/.cache}/.soplos_gnome_defaults_v1" 2>/dev/null || true
    fi
}

# Ejecutar una sola vez por usuario o si se invoca manualmente
if [ ! -f "${XDG_CACHE_HOME:-$HOME/.cache}/.soplos_gnome_defaults_v1" ]; then
    soplos-gnome-defaults
fi

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
[[ $- == *i* ]] && echo "✅ Configuración y utilidades de GNOME cargadas (Soplos Linux Boro)"
