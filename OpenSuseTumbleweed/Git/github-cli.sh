#!/bin/bash
# Git/github-cli.sh - Integrado en IDE/git.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/../IDE/git.sh" "$@"
