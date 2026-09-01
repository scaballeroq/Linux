# =============================================================================
# CONFIGURACIÓN DE ESCRITORIO (desktop_settings.sh) - Kubuntu (KDE Plasma 6)
# =============================================================================
# Atajos y funciones de control rápido para KDE Plasma en Wayland
# =============================================================================

# --- Atajos para Luz Nocturna (KWin Night Color) ---
alias kde-night-light-on='if command -v kwriteconfig6 &>/dev/null; then kwriteconfig6 --file kwinrc --group NightColor --key Active true && qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null; elif command -v kwriteconfig5 &>/dev/null; then kwriteconfig5 --file kwinrc --group NightColor --key Active true && qdbus org.kde.KWin /KWin reconfigure 2>/dev/null; fi && echo "Luz nocturna activada."'

alias kde-night-light-off='if command -v kwriteconfig6 &>/dev/null; then kwriteconfig6 --file kwinrc --group NightColor --key Active false && qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null; elif command -v kwriteconfig5 &>/dev/null; then kwriteconfig5 --file kwinrc --group NightColor --key Active false && qdbus org.kde.KWin /KWin reconfigure 2>/dev/null; fi && echo "Luz nocturna desactivada."'

# --- Conmutación de Temas de Kubuntu (Kubuntu Dark / Breeze) ---
alias kde-theme-dark='lookandfeeltool -a org.kubuntudark.desktop 2>/dev/null || lookandfeeltool -a org.kde.breezedark.desktop 2>/dev/null || echo "Tema oscuro aplicado."'
alias kde-theme-light='lookandfeeltool -a org.kubuntulight.desktop 2>/dev/null || lookandfeeltool -a org.kde.breeze.desktop 2>/dev/null || echo "Tema claro aplicado."'

# --- Preferencias del Sistema y Componentes ---
alias kde-conf='systemsettings'

# --- Recargar KWin Compositor ---
alias kde-restart-kwin='if command -v qdbus6 &>/dev/null; then qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null; elif command -v qdbus &>/dev/null; then qdbus org.kde.KWin /KWin reconfigure 2>/dev/null; fi && echo "KWin reconfigurado."'

# --- Reiniciar Shell de Plasma (Wayland / Systemd) ---
alias kde-restart-plasma='systemctl --user restart plasma-plasmashell.service 2>/dev/null || echo "Reiniciando plasmashell..."'
