#!/usr/bin/env bash
set -euo pipefail

echo "=== Google Antigravity CLI Installer ==="

# --- Dependencies ---
echo "[1/3] Installing dependencies..."
sudo pacman -S --needed --noconfirm curl

# --- Initial CLI install ---
echo "[2/3] Installing Antigravity CLI..."
agy_file="$HOME/.local/bin/agy"
marker_file="$HOME/.local/bin/.linuxcapable-antigravity-cli"
marker_value='google-antigravity-cli-v1'

validate_agy() {
  local version help_output
  version=$("$agy_file" --version 2>/dev/null || true)
  help_output=$("$agy_file" --help 2>&1 || true)
  if [ ! -x "$agy_file" ] || [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
     ! grep -Fq 'Usage of agy:' <<<"$help_output" ||
     ! grep -Fq 'Available subcommands:' <<<"$help_output" ||
     ! grep -Fq 'update          Update CLI' <<<"$help_output"; then
    return 1
  fi
  return 0
}

agy_already_installed=no
if [ -e "$agy_file" ] || [ -L "$agy_file" ]; then
  if validate_agy; then
    echo "  agy already installed at $agy_file"
    agy_already_installed=yes
  else
    printf '%s exists but is not a valid Antigravity CLI; move it before continuing.\n' "$agy_file" >&2
    exit 1
  fi
fi

if [ -L "$marker_file" ] || { [ -e "$marker_file" ] && [ ! -f "$marker_file" ]; }; then
  printf '%s is not a regular marker file; move it before continuing.\n' "$marker_file" >&2
  exit 1
fi
if [ -f "$marker_file" ] && ! grep -Fqx "$marker_value" "$marker_file"; then
  printf '%s is not a recognized LinuxCapable marker; move it before continuing.\n' "$marker_file" >&2
  exit 1
fi

if [ "$agy_already_installed" = no ]; then
  installer=$(mktemp "${TMPDIR:-/tmp}/antigravity-cli-installer.XXXXXX")
  trap 'rm -f -- "$installer"' EXIT
  curl -fsSL --proto '=https' --proto-redir '=https' --retry 3 -o "$installer" https://antigravity.google/cli/install.sh
  bash -n "$installer"
  bash "$installer" --dir "$HOME/.local/bin"
  if ! validate_agy; then
    echo 'The installed agy binary did not pass its identity checks.' >&2
    exit 1
  fi
fi
umask 077
printf '%s\n' "$marker_value" >"$marker_file"

export PATH="$HOME/.local/bin:$PATH"

# --- Update helper ---
echo "[3/3] Creating update helper..."
helper_path="$HOME/.local/bin/update-antigravity-cli"
helper_marker='# LinuxCapable-Managed: google-antigravity-cli-helper-v1'

if [ -L "$helper_path" ]; then
  printf '%s is a symlink; move it before creating the LinuxCapable helper.\n' "$helper_path" >&2
  exit 1
fi
if [ -e "$helper_path" ] && [ ! -f "$helper_path" ]; then
  printf '%s exists and is not a regular file.\n' "$helper_path" >&2
  exit 1
fi
recognized_old_helper=no
if [ -f "$helper_path" ] &&
   grep -Fq 'agy_file="$HOME/.local/bin/agy"' "$helper_path" &&
   grep -Fq 'https://antigravity.google/cli/install.sh' "$helper_path" &&
   grep -Fq 'Installed Antigravity CLI %s at %s' "$helper_path"; then
  recognized_old_helper=yes
fi
if [ -f "$helper_path" ] &&
   ! grep -Fqx "$helper_marker" "$helper_path" &&
   [ "$recognized_old_helper" != yes ]; then
  printf '%s is not a recognized LinuxCapable helper; move it before continuing.\n' "$helper_path" >&2
  exit 1
fi

helper_tmp=$(mktemp "${TMPDIR:-/tmp}/update-antigravity-cli.XXXXXX")
trap 'rm -f -- "$helper_tmp"' EXIT
cat >"$helper_tmp" <<'EOF'
#!/usr/bin/env bash
# LinuxCapable-Managed: google-antigravity-cli-helper-v1
set -euo pipefail

export PATH="$HOME/.local/bin:$PATH"
agy_file="$HOME/.local/bin/agy"
marker_file="$HOME/.local/bin/.linuxcapable-antigravity-cli"
marker_value='google-antigravity-cli-v1'
installer=''
update_result=installed

cleanup() {
  status=$?
  trap - EXIT
  if [ -n "$installer" ]; then
    rm -f -- "$installer"
  fi
  exit "$status"
}
trap cleanup EXIT

if [ -L "$agy_file" ] || { [ -e "$agy_file" ] && [ ! -f "$agy_file" ]; }; then
  printf '%s is not a regular CLI binary; move it before continuing.\n' "$agy_file" >&2
  exit 1
fi
if [ -e "$agy_file" ] && [ ! -x "$agy_file" ]; then
  printf '%s exists but is not executable; move it before continuing.\n' "$agy_file" >&2
  exit 1
fi
if [ -L "$marker_file" ] || { [ -e "$marker_file" ] && [ ! -f "$marker_file" ]; }; then
  printf '%s is not a regular marker file; move it before continuing.\n' "$marker_file" >&2
  exit 1
fi
if [ -f "$marker_file" ] && ! grep -Fqx "$marker_value" "$marker_file"; then
  printf '%s is not a recognized LinuxCapable marker; move it before continuing.\n' "$marker_file" >&2
  exit 1
fi

if [ -x "$agy_file" ]; then
  installed_version=$("$agy_file" --version 2>/dev/null || true)
  help_output=$("$agy_file" --help 2>&1 || true)
  if [[ ! "$installed_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
     ! grep -Fq 'Usage of agy:' <<<"$help_output" ||
     ! grep -Fq 'Available subcommands:' <<<"$help_output" ||
     ! grep -Fq 'update          Update CLI' <<<"$help_output"; then
    printf '%s is not a recognized Antigravity CLI binary.\n' "$agy_file" >&2
    exit 1
  fi
  "$agy_file" update
  current_version=$("$agy_file" --version)
  if [ "$installed_version" = "$current_version" ]; then
    update_result=current
  fi
else
  installer=$(mktemp "${TMPDIR:-/tmp}/antigravity-cli-installer.XXXXXX")
  curl -fsSL --proto '=https' --proto-redir '=https' --retry 3 -o "$installer" https://antigravity.google/cli/install.sh
  bash -n "$installer"
  bash "$installer" --dir "$HOME/.local/bin"
fi

if [ ! -x "$agy_file" ]; then
  printf "Google's installer did not create %s.\n" "$agy_file" >&2
  exit 1
fi
resolved_agy=$(command -v agy || true)
if [ "$resolved_agy" != "$agy_file" ]; then
  printf 'agy resolved to %s instead of %s.\n' "${resolved_agy:-nothing}" "$agy_file" >&2
  exit 1
fi
final_version=$("$agy_file" --version)
help_output=$("$agy_file" --help 2>&1 || true)
if [[ ! "$final_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
   ! grep -Fq 'Usage of agy:' <<<"$help_output" ||
   ! grep -Fq 'Available subcommands:' <<<"$help_output" ||
   ! grep -Fq 'update          Update CLI' <<<"$help_output"; then
  echo 'The installed agy binary did not pass its identity check.' >&2
  exit 1
fi
umask 077
printf '%s\n' "$marker_value" >"$marker_file"
if [ "$update_result" = current ]; then
  printf 'Antigravity CLI %s is already up to date at %s\n' "$final_version" "$agy_file"
else
  printf 'Installed Antigravity CLI %s at %s\n' "$final_version" "$agy_file"
fi
EOF

bash -n "$helper_tmp"
install -m 0755 "$helper_tmp" "$helper_path"
echo "Helper installed at $helper_path"

# --- Run update helper ---
update-antigravity-cli

# --- Verification ---
echo ""
echo "=== Verifying installation ==="
command -v agy
agy --version

echo ""
echo "=== Antigravity CLI installed successfully ==="
