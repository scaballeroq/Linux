#!/bin/bash
# =============================================================================
# shell.sh - CONFIGURACIÓN DEL ENTORNO DE TERMINAL (Kubuntu / Ubuntu)
# =============================================================================
# Este script instala y configura herramientas de CLI modernas (principalmente
# escritas en Rust y optimizadas para rendimiento) y el prompt Starship.
#
# Herramientas instaladas:
#   - eza: Reemplazo moderno y configurable de 'ls'.
#   - bat: Reemplazo enriquecido de 'cat' con resaltado de sintaxis.
#   - fzf: Buscador difuso (fuzzy finder) para autocompletado y búsquedas.
#   - zoxide: Comando 'cd' inteligente que recuerda tus directorios frecuentes.
#   - ripgrep (rg): Buscador de texto en archivos extremadamente rápido.
#   - fd-find (fd): Buscador de ficheros rápido e intuitivo.
#   - tealdeer (tldr): Hojas de trucos rápidas en sustitución de las páginas man.
#   - duf: Información de uso de disco en tablas legibles y claras.
#   - du-dust (dust): Visualización gráfica del tamaño de carpetas y ficheros.
#   - procs: Listado y búsqueda avanzada de procesos activos en el sistema.
# =============================================================================

set -e

echo "🚀 Iniciando configuración de herramientas de terminal modernas..."

# 1. Instalar herramientas CLI modernas vía APT
echo "ℹ️ Actualizando base de datos de paquetes e instalando utilidades..."
sudo apt update
sudo apt install -y \
    eza \
    bat \
    fzf \
    zoxide \
    ripgrep \
    fd-find \
    tealdeer \
    duf \
    du-dust \
    procs

# 2. Configurar enlaces simbólicos (Symlinks) para bat y fd
# En distribuciones Kubuntu/Ubuntu, los ejecutables de 'bat' y 'fd' se instalan
# como 'batcat' y 'fdfind' para evitar colisiones de nombres históricos.
# Creamos enlaces simbólicos en ~/.local/bin para poder usarlos como 'bat' y 'fd'.
echo "ℹ️ Configurando symlinks para bat y fd en ~/.local/bin..."
mkdir -p ~/.local/bin
[ -f /usr/bin/batcat ] && ln -sf /usr/bin/batcat ~/.local/bin/bat
[ -f /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind ~/.local/bin/fd

echo "✅ Utilidades de terminal instaladas correctamente."

# 3. Instalación de Starship Prompt
echo "ℹ️ Instalando el Prompt de Starship..."
# Instalación local en ~/.local/bin para evitar requerir permisos de sudo interactivos en la descarga
curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir "$HOME/.local/bin" -y

# 4. Configuración del inicio de Starship en la Shell
# Si existe el directorio modular de scripts de bashrc, añadimos el archivo de inicio ahí.
if [ -d "/etc/bashrc.d" ] || [ -d "$HOME/.bashrc.d" ]; then
    mkdir -p ~/.bashrc.d
    cat <<'EOF' > ~/.bashrc.d/starship.sh
# Starship Prompt Configuration
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi
EOF
    echo "✅ Configuración modular de Starship creada en ~/.bashrc.d/starship.sh"
else
    # Si no hay soporte para configuración modular, se añade directamente a ~/.bashrc
    if ! grep -q "starship init bash" ~/.bashrc; then
        echo -e '\n# Starship Prompt\nif command -v starship &> /dev/null; then eval "$(starship init bash)"; fi' >> ~/.bashrc
        echo "✅ Configuración de Starship añadida a ~/.bashrc"
    fi
fi

# 5. Asegurar e inicializar configuraciones del tema/Starship
mkdir -p ~/.config

# Copiar archivo de configuración personalizado 'starship.toml' si se encuentra en el repositorio
if [ -f "starship.toml" ]; then
    cp starship.toml ~/.config/starship.toml
    echo "✅ Archivo starship.toml copiado a ~/.config/"
elif [ -f "Setup/starship.toml" ]; then
    cp Setup/starship.toml ~/.config/starship.toml
    echo "✅ Archivo Setup/starship.toml copiado a ~/.config/starship.toml"
fi

echo "🎉 Instalación de la shell y utilidades CLI completada. Reinicia tu sesión de terminal."
