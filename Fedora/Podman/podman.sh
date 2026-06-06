# podman.sh - Optimización de Podman para Fedora Workstation

set -e

echo "🚀 Optimizando Podman (Rootless)..."

# 1. Asegurar paquetes complementarios (Podman ya viene en Fedora)
# Pero podman-compose, podman-docker (emulación docker) y distrobox son muy útiles.
sudo dnf5 install -y podman-compose podman-docker netavark slirp4netns distrobox

# 2. Habilitar socket para el usuario (Permite usar VS Code Docker Extension, DOCKER_HOST, etc)
echo "ℹ️ Habilitando Podman Socket para el usuario..."
systemctl --user enable --now podman.socket

# 3. Optimización de límites de recursos (Rootless)
# Aumentar límites de archivos abiertos para evitar errores en bases de datos pesadas
echo "ℹ️ Ajustando límites de recursos (subuid/subgid)..."
if ! grep -q "$USER" /etc/subuid; then
    sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER"
fi

# 4. Configurar DOCKER_HOST y Distrobox en la shell
mkdir -p ~/.bashrc.d
cat <<EOF > ~/.bashrc.d/podman.sh
# Podman Socket para emulación de Docker
export DOCKER_HOST="unix://\$XDG_RUNTIME_DIR/podman/podman.sock"

# Atajos para Distrobox
alias dbox='distrobox'
alias dbox-fedora='distrobox-create --name fedora-dev --image registry.fedoraproject.org/fedora:44 --home ~/Workspace/Containers/fedora-dev'
alias dbox-enter='distrobox-enter fedora-dev'
EOF

echo "✅ Podman y Distrobox configurados. Socket habilitado y aliases creados en ~/.bashrc.d/podman.sh"
