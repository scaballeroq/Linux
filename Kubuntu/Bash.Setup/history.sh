#!/bin/bash
# =============================================================================
# CONFIGURACIÓN DEL HISTORIAL (history.sh) - Kubuntu
# =============================================================================
# Este archivo optimiza cómo Bash almacena y maneja el historial de comandos,
# aumentando su capacidad, evitando duplicados y guardando marcas de tiempo.

# -----------------------------------------------------------------------------
# 1. TAMAÑO Y CAPACIDAD
# -----------------------------------------------------------------------------
# Número de comandos recordados en memoria durante la sesión
export HISTSIZE=10000

# Número de líneas guardadas permanentemente en el archivo ~/.bash_history
export HISTFILESIZE=20000

# -----------------------------------------------------------------------------
# 2. COMPORTAMIENTO Y FILTRADO
# -----------------------------------------------------------------------------
# ignoredups: No guardar comandos si son iguales al anterior.
# ignorespace: No guardar comandos que comiencen con un espacio (útil para contraseñas).
export HISTCONTROL="ignoredups:ignorespace"

# Formato de fecha y hora para cada comando en 'history' (AAAA-MM-DD HH:MM:SS)
export HISTTIMEFORMAT="%F %T  "

# Comandos comunes que no vale la pena registrar en el historial
export HISTIGNORE="ls:ll:la:cd:pwd:exit:clear:c:h:history"

# -----------------------------------------------------------------------------
# 3. OPCIONES DE SHELL PARA HISTORIAL
# -----------------------------------------------------------------------------
# Añadir al historial en lugar de sobrescribirlo al cerrar la sesión
shopt -s histappend

# Guardar comandos multilínea en una sola entrada del historial
shopt -s cmdhist

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Historial configurado"
