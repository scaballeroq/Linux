#!/bin/bash
# Juegos/steam.sh - Delegador a Setup/steam.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/../Setup/steam.sh" "$@"
