#!/bin/bash
# podman-mailhog.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/podman-common.sh"

ensure_podman_network

echo "ℹ️ Iniciando MailHog..."
podman run -d --replace \
    --name mailhog-dev \
    --network "$PODMAN_NETWORK" \
    -p 1025:1025 -p 8025:8025 \
    docker.io/mailhog/mailhog:latest
echo "✅ MailHog iniciado (SMTP: 1025, Web: http://localhost:8025)"
