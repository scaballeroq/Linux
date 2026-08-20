#!/bin/bash
# podman.sh - Podman Installation and Rootless Setup for Manjaro Linux

set -euo pipefail

echo "ℹ️ Verificando instalación de Podman..."
if ! command -v podman &> /dev/null; then
    echo "ℹ️ Instalando Podman y sus dependencias vía Pacman..."
    sudo pacman -S --needed --noconfirm podman podman-compose podman-docker shadow netavark slirp4netns passt
else
    echo "✅ Podman ya está instalado."
fi

echo "ℹ️ Configurando Podman rootless..."
# Permitir que los contenedores del usuario sigan ejecutándose al cerrar sesión
loginctl enable-linger "$USER" 2>/dev/null || sudo loginctl enable-linger "$USER" || true

# Habilitar el socket del usuario
systemctl --user enable --now podman.socket

# Configurar DOCKER_HOST para ZSH
mkdir -p "$HOME/.zshrc.d"
cat <<'EOF' > "$HOME/.zshrc.d/podman.zsh"
# Configurar DOCKER_HOST para apuntar al socket rootless de Podman
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
EOF

# Configurar DOCKER_HOST para Bash
mkdir -p "$HOME/.bashrc.d"
cat <<'EOF' > "$HOME/.bashrc.d/podman.sh"
# Configurar DOCKER_HOST para apuntar al socket rootless de Podman
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
EOF

echo "✅ Podman configurado correctamente (ZSH & Bash)."
