# =============================================================================
# OPCIONES DE LA SHELL (options.sh) - Omarchy
# =============================================================================

shopt -s cdspell
shopt -s autocd
shopt -s globstar
shopt -s checkwinsize

if [[ $- == *i* ]]; then
    bind 'set completion-ignore-case on' 2>/dev/null || true
    bind 'set show-all-if-ambiguous on' 2>/dev/null || true
    bind 'set colored-stats on' 2>/dev/null || true
fi

