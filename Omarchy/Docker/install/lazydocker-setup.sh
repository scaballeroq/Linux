#!/bin/bash
# =============================================================================
# Lazydocker Setup - Configuración y optimizaciones (Omarchy)
# =============================================================================
# Genera configuración personalizada de Lazydocker en ~/.config/lazydocker/config.yml
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}   $1"; }
log_error() { echo -e "${RED}[ERR]${NC}  $1"; }

setup_lazydocker() {
    log_info "Configurando Lazydocker..."

    local config_dir="$HOME/.config/lazydocker"
    local config_file="$config_dir/config.yml"

    mkdir -p "$config_dir"

    if [ ! -f "$config_file" ]; then
        cat > "$config_file" <<'EOF'
gui:
  scrollHeight: 2
  theme:
    activeBorderColor:
      - green
      - bold
    inactiveBorderColor:
      - white
    selectedLineBgColor:
      - blue
  returnImmediately: false
  wrapMainPanel: true
  sidePanelWidth: 0.3333
reporting: "off"
checkForUpdates: false
commandTemplates:
  dockerCompose: docker compose
customCommands:
  containers:
    - name: bash
      attach: true
      command: docker exec -it {{ .Container.ID }} /bin/bash
      serviceNames: []
    - name: sh
      attach: true
      command: docker exec -it {{ .Container.ID }} /bin/sh
      serviceNames: []
EOF
        log_ok "Configuración de Lazydocker creada en $config_file"
    else
        log_info "Configuración de Lazydocker ya existe en $config_file"
    fi
}

main() {
    setup_lazydocker
}

main "$@"
