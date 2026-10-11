#!/bin/bash
# install-agents-profile.sh - Instala y enlaza las reglas y skills de Antigravity globalmente
# en ~/.agents y ~/.gemini/config para Antigravity IDE, CLI (agy) y Desktop.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_AGENTS="$REPO_DIR/.agents"
TARGET_AGENTS="$HOME/.agents"
TARGET_GEMINI_CONFIG="$HOME/.gemini/config"

echo "================================================================="
echo "CONFIGURANDO AGENTES Y SKILLS DE ANTIGRAVITY (GLOBAL)"
echo "================================================================="

# 1. Asegurar directorios de destino
mkdir -p "$TARGET_AGENTS/skills" "$TARGET_AGENTS/rules"
mkdir -p "$TARGET_GEMINI_CONFIG/skills" "$TARGET_GEMINI_CONFIG/rules"

# 2. Sincronizar / enlazar archivos en ~/.agents
echo "📁 [1/3] Copiando perfil y reglas a $TARGET_AGENTS..."
cp -u "$SOURCE_AGENTS/AGENTS.md" "$TARGET_AGENTS/AGENTS.md"
cp -u "$SOURCE_AGENTS/rules/"*.md "$TARGET_AGENTS/rules/" 2>/dev/null || true
cp -ru "$SOURCE_AGENTS/skills/"* "$TARGET_AGENTS/skills/"

# 3. Registrar skills en ~/.gemini/config para Antigravity IDE y CLI
echo "⚙️ [2/3] Registrando skills globalmente en $TARGET_GEMINI_CONFIG/skills.json..."
cat << 'EOF' > "$TARGET_GEMINI_CONFIG/skills.json"
{
  "entries": [
    {
      "path": "~/.agents/skills"
    }
  ]
}
EOF

# 4. Enlazar AGENTS.md en ~/.gemini/config para carga de reglas global
echo "🔗 [3/3] Enlazando AGENTS.md en $TARGET_GEMINI_CONFIG..."
cp -u "$SOURCE_AGENTS/AGENTS.md" "$TARGET_GEMINI_CONFIG/AGENTS.md"
cp -u "$SOURCE_AGENTS/rules/"*.md "$TARGET_GEMINI_CONFIG/rules/" 2>/dev/null || true

echo "================================================================="
echo "✅ Instalación completada con éxito."
echo "Tanto antigravity-ide, antigravity como antigravity-cli cargarán:"
echo "  - Perfil Experto Linux & Hardware HP EliteBook 855 G7"
echo "  - Skill: niri-dms-control"
echo "  - Skill: arch-system-maintenance"
echo "================================================================="
