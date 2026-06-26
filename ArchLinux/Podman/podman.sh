# podman.sh - Optimización de Podman para Arch Linux

set -e

echo "🚀 Optimizando Podman (Rootless)..."

sudo pacman -S --noconfirm podman podman-compose netavark slirp4netns distrobox

echo "ℹ️ Habilitando Podman Socket para el usuario..."
systemctl --user enable --now podman.socket

echo "ℹ️ Ajustando límites de recursos (subuid/subgid)..."
if ! grep -q "$USER" /etc/subuid; then
    sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER"
fi

mkdir -p ~/.bashrc.d
cat <<EOF > ~/.bashrc.d/podman.sh
# Podman Socket para emulación de Docker
export DOCKER_HOST="unix://\$XDG_RUNTIME_DIR/podman/podman.sock"

# Atajos para Distrobox
alias dbox='distrobox'
alias dbox-arch='distrobox-create --name arch-dev --image docker.io/library/archlinux:latest --home ~/Workspace/Containers/arch-dev'
alias dbox-enter='distrobox-enter arch-dev'
EOF

echo "✅ Podman y Distrobox configurados. Socket habilitado y aliases creados en ~/.bashrc.d/podman.sh"
