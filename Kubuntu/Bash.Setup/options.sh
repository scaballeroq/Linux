# =============================================================================
# OPCIONES DE SHELL (options.sh) - Kubuntu
# =============================================================================
# Configuración de shopt para autocompletado, autocd y tolerancia a fallos.
# =============================================================================

# 1. NAVEGACIÓN INTELIGENTE
shopt -s autocd 2>/dev/null
shopt -s cdspell 2>/dev/null
shopt -s dirspell 2>/dev/null

# 2. EXPANSIÓN DE PATRONES (GLOBBING)
shopt -s globstar 2>/dev/null
shopt -s nocaseglob 2>/dev/null

# 3. INTERACCIÓN Y TERMINAL
shopt -s checkwinsize 2>/dev/null
shopt -s checkjobs 2>/dev/null
shopt -s no_empty_cmd_completion 2>/dev/null
