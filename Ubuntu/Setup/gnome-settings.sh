#!/bin/bash
# gnome-settings.sh - Personalización de GNOME vía CLI (gsettings) para Ubuntu
#
# Este script aplica configuraciones recomendadas para GNOME en Ubuntu.

set -e

echo "🚀 Iniciando personalización de GNOME..."

# Verificar si se ejecuta en entorno gráfico GNOME o si podemos correr gsettings
if [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]] || command -v gsettings &>/dev/null; then
    # 1. Luz Nocturna (Night Light) - Activar y configurar temperatura (3500K)
    echo "ℹ️ Configurando Luz Nocturna..."
    gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
    gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3500

    # 2. Formato de reloj (24h) y batería
    echo "ℹ️ Configurando formato de reloj y visualización de batería..."
    gsettings set org.gnome.desktop.interface clock-format '24h'
    gsettings set org.gnome.desktop.interface show-battery-percentage true

    # 3. Mostrar botones de minimizar, maximizar y cerrar en las ventanas
    echo "ℹ️ Habilitando botones de minimizar/maximizar..."
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'

    # 4. Comportamiento de energía: No suspender cuando está enchufado (corriente AC)
    echo "ℹ️ Configurando políticas de energía..."
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

    # 5. Tema oscuro preferido (GNOME 42+)
    echo "ℹ️ Estableciendo esquema de color preferido (Oscuro)..."
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

    echo "✅ Personalización de GNOME completada correctamente."
else
    echo "⚠️ Advertencia: No se detectó un entorno GNOME activo. GSettings no se aplicaron."
fi
