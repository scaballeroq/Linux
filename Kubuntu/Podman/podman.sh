#!/bin/bash
# podman.sh - Podman Installation for Kubuntu / Ubuntu

set -euo pipefail

echo "ℹ️ Verificando instalación de Podman..."
if ! command -v podman &> /dev/null; then
    echo "ℹ️ Instalando Podman y sus dependencias..."
    sudo apt update
    # - podman-docker: Provee un alias automático de 'docker' -> 'podman'
    # - uidmap: Requerido para mapear subuid/subgid en contenedores rootless
    # - slirp4netns: Stack de red rootless tradicional (compatibilidad hacia atrás)
    # - passt: Nuevo stack de red ('pasta') de altísimo rendimiento, estándar en Podman 5+
    sudo apt install -y podman podman-compose podman-docker uidmap slirp4netns passt
else
    echo "✅ Podman ya está instalado."
fi

echo "ℹ️ Configurando Podman rootless..."
# Permitir que los contenedores del usuario sigan ejecutándose al cerrar sesión
loginctl enable-linger "$USER"

# Habilitar el socket del usuario (emula el de Docker para compatibilidad con Testcontainers, IDEs, etc.)
systemctl --user enable --now podman.socket

# Añadir export de DOCKER_HOST para que herramientas de terceros encuentren el socket rootless
if [ -d "/etc/bashrc.d" ] || [ -d "$HOME/.bashrc.d" ]; then
    mkdir -p "$HOME/.bashrc.d"
    cat <<'EOF' > "$HOME/.bashrc.d/podman.sh"
# Configurar DOCKER_HOST para apuntar al socket rootless de Podman
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
EOF
    echo "✅ Variable DOCKER_HOST configurada en ~/.bashrc.d/podman.sh"
else
    if ! grep -q "DOCKER_HOST=" "$HOME/.bashrc"; then
        echo -e '\n# Configurar DOCKER_HOST para apuntar al socket rootless de Podman\nexport DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"' >> "$HOME/.bashrc"
        echo "✅ Variable DOCKER_HOST añadida a ~/.bashrc"
    fi
fi

echo "✅ Podman configurado correctamente. Reinicia tu terminal o ejecuta 'source ~/.bashrc' para aplicar los cambios de DOCKER_HOST."
