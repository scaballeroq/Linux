#!/bin/bash
# =============================================================================
# VARIABLES DE ENTORNO (environment.sh) - Kubuntu
# =============================================================================
# Este archivo define variables globales de entorno para la sesión del usuario.
# Controla el editor por defecto, rutas personalizadas en el PATH y opciones
# de formato para comandos de terminal.

# -----------------------------------------------------------------------------
# 1. EDITOR PREDETERMINADO
# -----------------------------------------------------------------------------
# Define el editor de texto a utilizar por herramientas como git, crontab, etc.
if command -v nvim &> /dev/null; then
    export EDITOR="nvim"
    export VISUAL="nvim"
elif command -v nano &> /dev/null; then
    export EDITOR="nano"
    export VISUAL="nano"
fi

# -----------------------------------------------------------------------------
# 2. EXTENSIÓN DEL PATH
# -----------------------------------------------------------------------------
# Añade directorios personalizados al PATH si existen, garantizando que los
# binarios locales del usuario tengan prioridad.

# Binarios locales del usuario (~/.local/bin)
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Binarios de usuario estándar (~/bin)
if [ -d "$HOME/bin" ]; then
    export PATH="$HOME/bin:$PATH"
fi

# Cargo / Rust binarios (~/.cargo/bin)
if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Go binarios (~/go/bin)
if [ -d "$HOME/go/bin" ]; then
    export PATH="$HOME/go/bin:$PATH"
fi

# Mise (Gestor de versiones de lenguajes)
if [ -d "$HOME/.local/share/mise/shims" ]; then
    export PATH="$HOME/.local/share/mise/shims:$PATH"
fi

# -----------------------------------------------------------------------------
# 3. COLORES Y FORMATO PARA 'LESS' Y 'MAN'
# -----------------------------------------------------------------------------
# Mejora la legibilidad de las páginas man con resaltado de sintaxis en color.
export LESS_TERMCAP_mb=$'\e[1;31m'      # Inicio de parpadeo (rojo)
export LESS_TERMCAP_md=$'\e[1;36m'      # Inicio de negrita (cian)
export LESS_TERMCAP_me=$'\e[0m'         # Fin de formato
export LESS_TERMCAP_so=$'\e[01;33m'     # Inicio de modo destacado (amarillo)
export LESS_TERMCAP_se=$'\e[0m'         # Fin de modo destacado
export LESS_TERMCAP_us=$'\e[1;32m'      # Inicio de subrayado (verde)
export LESS_TERMCAP_ue=$'\e[0m'         # Fin de subrayado

# Opciones por defecto para 'less' (soporte de colores raw, no limpiar pantalla)
export LESS="-R -F -X"

# Paginador por defecto
export PAGER="less"

# -----------------------------------------------------------------------------
# 4. IDIOMA Y LOCALIZACIÓN
# -----------------------------------------------------------------------------
export LANG="${LANG:-es_ES.UTF-8}"
export LC_ALL="${LC_ALL:-es_ES.UTF-8}"

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Variables de entorno aplicadas"
