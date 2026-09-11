#!/bin/bash
# podman-mailhog.sh

set -e

if ! podman network exists dev-net; then podman network create dev-net; fi

echo "ℹ️ Iniciando MailHog..."
podman run -d --replace \
    --name mailhog-dev \
    --network dev-net \
    -p 1025:1025 -p 8025:8025 \
    docker.io/mailhog/mailhog:latest
echo "✅ MailHog iniciado (SMTP: 1025, Web: http://localhost:8025)"
