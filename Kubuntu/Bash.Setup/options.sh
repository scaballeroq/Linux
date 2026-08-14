#!/bin/bash
# =============================================================================
# OPCIONES DE SHELL (options.sh) - Kubuntu
# =============================================================================
# Este archivo configura opciones de comportamiento de Bash (shopt) para
# hacer la línea de comandos más intuitiva, rápida y tolerante a fallos.

# -----------------------------------------------------------------------------
# 1. NAVEGACIÓN INTELIGENTE
# -----------------------------------------------------------------------------
# Si escribes el nombre de un directorio sin 'cd', entra en él directamente.
shopt -s autocd 2>/dev/null

# Corrige errores tipográficos menores al escribir nombres de directorios en 'cd'.
shopt -s cdspell 2>/dev/null

# Corrige errores tipográficos en variables de directorio durante autocompletado.
shopt -s dirspell 2>/dev/null

# -----------------------------------------------------------------------------
# 2. EXPANSIÓN DE PATRONES (GLOBBING)
# -----------------------------------------------------------------------------
# Permite usar '**' para buscar recursivamente en subdirectorios.
shopt -s globstar 2>/dev/null

# Los patrones de búsqueda no distinguen mayúsculas de minúsculas.
shopt -s nocaseglob 2>/dev/null

# -----------------------------------------------------------------------------
# 3. INTERACCIÓN Y TERMINAL
# -----------------------------------------------------------------------------
# Actualiza automáticamente las variables LINES y COLUMNS al redimensionar la ventana.
shopt -s checkwinsize 2>/dev/null

# Comprueba si hay trabajos en segundo plano antes de salir de la shell.
shopt -s checkjobs 2>/dev/null

# No intentar autocompletar en una línea vacía
shopt -s no_empty_cmd_completion 2>/dev/null

# =============================================================================
# MENSAJE DE CARGA
# =============================================================================
echo "✅ Opciones de Shell activadas"
