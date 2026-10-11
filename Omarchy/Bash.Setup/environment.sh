# =============================================================================
# VARIABLES DE ENTORNO (environment.sh) - Omarchy
# =============================================================================

# -----------------------------------------------------------------------------
# 1. EDITORES DE TEXTO (Respeta la configuración nativa de Omarchy)
# -----------------------------------------------------------------------------
export EDITOR="${EDITOR:-omarchy-launch-editor --inline}"
export VISUAL="${VISUAL:-$EDITOR}"

# -----------------------------------------------------------------------------
# 2. PAGINADOR Y COLORES
# -----------------------------------------------------------------------------
export LESS='-R'

# -----------------------------------------------------------------------------
# 3. PATH (Rutas de ejecutables sin duplicados)
# -----------------------------------------------------------------------------
for p in "$HOME/.local/bin" "$HOME/bin" "$HOME/go/bin" "$HOME/.cargo/bin"; do
    if [ -d "$p" ]; then
        case ":$PATH:" in
            *":$p:"*) ;;
            *) export PATH="$p:$PATH" ;;
        esac
    fi
done

