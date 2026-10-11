#!/bin/bash
# podman-mailhog.sh - SMTP Testing & Email Web UI

set -euo pipefail

if ! podman network exists dev-net 2>/dev/null; then podman network create dev-net 2>/dev/null || true; fi

echo "ℹ️ Iniciando MailHog..."
podman run -d --replace \
    --name mailhog-dev \
    --network dev-net \
    -p 1025:1025 \
    -p 8025:8025 \
    docker.io/mailhog/mailhog:latest

echo "✅ MailHog iniciado (SMTP: 1025, Web UI: http://localhost:8025)"
