# =============================================================================
# OPCIONES DE LA SHELL BASH (options.sh) - Manjaro Linux
# =============================================================================

shopt -s cdspell
shopt -s autocd
shopt -s globstar
shopt -s checkwinsize

bind 'set completion-ignore-case on' 2>/dev/null || true
bind 'set show-all-if-ambiguous on' 2>/dev/null || true
bind 'set colored-stats on' 2>/dev/null || true

echo "✅ Opciones de Shell Bash activadas (autocd, globstar, corrección errores...)"
