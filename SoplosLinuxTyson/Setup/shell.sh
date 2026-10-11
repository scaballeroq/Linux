#!/bin/bash
# shell.sh - Instalación de herramientas modernas de terminal y prompt Starship para Soplos Linux Tyson (Debian Testing)
# Configura tanto Bash como Zsh compartiendo la misma estética limpia, rápida y moderna.

set -euo pipefail

echo "🚀 Iniciando configuración de entorno de terminal moderno para Soplos Linux Tyson..."

# 1. Instalación de utilidades modernas de terminal
echo "ℹ️ Instalando utilidades CLI modernas y plugins vía APT..."
sudo apt update
sudo apt install -y \
    eza \
    bat \
    fzf \
    zoxide \
    ripgrep \
    fd-find \
    duf \
    zsh-autosuggestions \
    zsh-syntax-highlighting 2>/dev/null || sudo apt install -y eza bat fzf zoxide ripgrep fd-find duf || true

# 2. Configurar symlinks locales para bat y fd
echo "ℹ️ Configurando symlinks locales para bat y fd..."
mkdir -p ~/.local/bin
[ -f /usr/bin/batcat ] && ln -sf /usr/bin/batcat ~/.local/bin/bat
[ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind ~/.local/bin/fd

# 3. Instalación de Starship Prompt
echo "ℹ️ Verificando e instalando prompt ultra-rápido Starship..."
if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    echo "✅ Starship ya está instalado en el sistema."
fi

# 4. Copiar tema personalizado de Starship
mkdir -p ~/.config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/starship.toml" ]; then
    cp "$SCRIPT_DIR/starship.toml" ~/.config/starship.toml
elif [ -f "Setup/starship.toml" ]; then
    cp Setup/starship.toml ~/.config/starship.toml
fi
echo "✅ Tema personalizado de Starship copiado a ~/.config/starship.toml"

# 5. Configurar Bash (~/.bashrc y ~/.bashrc.d)
echo "ℹ️ Configurando Bash..."
mkdir -p ~/.bashrc.d

# Archivo modular de Starship y Zoxide para Bash
cat <<'EOF' > ~/.bashrc.d/00-prompt.sh
# Starship & Zoxide initialization for Bash
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi
EOF

# Asegurar carga modular en ~/.bashrc
if ! grep -q ".bashrc.d" ~/.bashrc 2>/dev/null; then
    cat <<'EOF' >> ~/.bashrc

# Carga modular de configuraciones
if [ -d "$HOME/.bashrc.d" ]; then
    for file in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$file" ] && source "$file"
    done
    unset file
fi
EOF
fi

# 6. Configurar Zsh (~/.zshrc)
echo "ℹ️ Configurando Zsh con Starship y utilidades compartidas..."

# Si no existe ~/.zshrc o queremos asegurar Starship y modularidad
if [ -f ~/.zshrc ]; then
    # Respaldar zshrc original si no está respaldado
    [ ! -f ~/.zshrc.backup ] && cp ~/.zshrc ~/.zshrc.backup
fi

# Asegurar configuración limpia de Starship en ~/.zshrc
mkdir -p ~/.zshrc.d

cat <<'EOF' > ~/.zshrc.d/00-prompt.zsh
# Starship & Zoxide initialization for Zsh
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi
EOF

# Añadir plugins de resaltado y autosugerencias si existen en Debian
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    cat <<'EOF' > ~/.zshrc.d/10-plugins.zsh
# Zsh native plugins
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null || true
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null || true
EOF
fi

# Enlazar o añadir carga modular a ~/.zshrc
if ! grep -q ".zshrc.d" ~/.zshrc 2>/dev/null; then
    cat <<'EOF' >> ~/.zshrc

# Carga modular de configuraciones para Zsh
if [ -d "$HOME/.zshrc.d" ]; then
    for file in "$HOME/.zshrc.d"/*.zsh; do
        [ -r "$file" ] && source "$file"
    done
    unset file
fi

# Carga de alias y funciones compartidas de ~/.bashrc.d
if [ -d "$HOME/.bashrc.d" ]; then
    for file in "$HOME/.bashrc.d"/*.sh; do
        # Omitir scripts de prompt específicos de bash
        [[ "$file" == *"00-prompt.sh"* ]] && continue
        [ -r "$file" ] && source "$file"
    done
    unset file
fi
EOF
fi

# Si el zshrc tenía un PROMPT estático con fondo naranja, asegurar que Starship lo reemplace
if ! grep -q "starship init zsh" ~/.zshrc; then
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc
fi

echo "================================================================="
echo "✅ Configuración de terminal completada para Soplos Linux Tyson."
echo "🐚 Bash y Zsh ahora comparten el mismo prompt Starship moderno y minimalista."
echo "💡 Abre una nueva pestaña de terminal o ejecuta 'exec zsh' / 'exec bash' para aplicar."
echo "================================================================="
