#!/usr/bin/env bash
set -euo pipefail

echo "=== Google Antigravity Desktop Installer ==="

# --- Dependencies ---
echo "[1/4] Installing dependencies..."
sudo pacman -S --needed --noconfirm ca-certificates curl tar desktop-file-utils python

# --- Helper script ---
echo "[2/4] Creating update helper..."
helper_path='/usr/local/bin/update-antigravity'
helper_marker='# LinuxCapable-Managed: google-antigravity-desktop-helper-v1'

if [ -L "$helper_path" ] || { [ -e "$helper_path" ] && [ ! -f "$helper_path" ]; }; then
  printf '%s is not a regular helper file; move it before continuing.\n' "$helper_path" >&2
  exit 1
fi
recognized_old_helper=no
if [ -f "$helper_path" ] &&
   sudo grep -Fqx 'download_page="https://antigravity.google/download"' "$helper_path" &&
   sudo grep -Fqx 'install_root="/opt/antigravity"' "$helper_path" &&
   sudo grep -Fqx 'command_link="/usr/local/bin/antigravity"' "$helper_path"; then
  recognized_old_helper=yes
elif [ -f "$helper_path" ] && sudo grep -Fq 'antigravity-auto-updater-974169037036' "$helper_path"; then
  recognized_old_helper=yes
fi
if [ -f "$helper_path" ] &&
   ! sudo grep -Fqx "$helper_marker" "$helper_path" &&
   [ "$recognized_old_helper" != yes ]; then
  printf '%s is not a recognized LinuxCapable helper; move it before continuing.\n' "$helper_path" >&2
  exit 1
fi

helper_tmp=$(mktemp "${TMPDIR:-/tmp}/update-antigravity.XXXXXX")
trap 'rm -f -- "$helper_tmp"' EXIT
cat >"$helper_tmp" <<'EOF'
#!/usr/bin/env bash
# LinuxCapable-Managed: google-antigravity-desktop-helper-v1
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
	echo "Run with sudo: sudo update-antigravity" >&2
	exit 1
fi

download_page="https://antigravity.google/download"
install_root="/opt/antigravity"
command_link="/usr/local/bin/antigravity"
desktop_file="/usr/share/applications/antigravity.desktop"
icon_file="/usr/share/icons/hicolor/512x512/apps/antigravity.png"
managed_id="linuxcapable-antigravity-desktop-v1"
root_marker="$install_root/.linuxcapable-managed"

case "$(uname -m)" in
x86_64 | amd64) platform="linux-x64" ;;
aarch64 | arm64) platform="linux-arm" ;;
*)
	echo "Unsupported architecture: $(uname -m)" >&2
	exit 1
	;;
esac

for required_command in curl tar python desktop-file-validate; do
	if ! command -v "$required_command" >/dev/null 2>&1; then
		echo "$required_command is required to install Antigravity." >&2
		exit 1
	fi
done

command_preexisting=no
command_target_before=''
if [ -L "$command_link" ]; then
	command_preexisting=yes
	command_target_before=$(readlink -- "$command_link")
	command_target=$(readlink -f "$command_link" || true)
	case "$command_target" in
	"$install_root"/*) ;;
	*)
		echo "$command_link points to $command_target. Move it before rerunning this helper." >&2
		exit 1
		;;
	esac
elif [ -e "$command_link" ]; then
	echo "$command_link exists and is not a symlink. Move it before rerunning this helper." >&2
	exit 1
fi

desktop_preexisting=no
desktop_legacy_owned=no
if [ -L "$desktop_file" ] || { [ -e "$desktop_file" ] && [ ! -f "$desktop_file" ]; }; then
	echo "$desktop_file is not a regular desktop file. Move it before rerunning this helper." >&2
	exit 1
elif [ -f "$desktop_file" ]; then
	desktop_preexisting=yes
	if grep -Fqx "X-LinuxCapable-Managed=$managed_id" "$desktop_file"; then
		:
	elif grep -Fqx "Exec=$command_link %U" "$desktop_file" &&
		grep -Fqx 'Icon=antigravity' "$desktop_file" &&
		grep -Fqx 'StartupWMClass=Antigravity' "$desktop_file"; then
		desktop_legacy_owned=yes
	else
		echo "$desktop_file is not a recognized LinuxCapable launcher. Move it before rerunning this helper." >&2
		exit 1
	fi
fi

icon_preexisting=no
if [ -L "$icon_file" ] || { [ -e "$icon_file" ] && [ ! -f "$icon_file" ]; }; then
	echo "$icon_file is not a regular icon file. Move it before rerunning this helper." >&2
	exit 1
elif [ -f "$icon_file" ]; then
	icon_preexisting=yes
	if [ "$desktop_preexisting" != yes ]; then
		echo "$icon_file exists without a recognized launcher. Move it before rerunning this helper." >&2
		exit 1
	fi
fi

tmpdir=''
stage_root=''
backup_root=''
desktop_backup=''
icon_backup=''
desktop_staged=''
new_root_installed=no
committed=no
cleanup() {
	status=$?
	trap - EXIT
	if [ "$committed" != yes ] && [ "$new_root_installed" = yes ]; then
		if [ "$command_preexisting" = yes ]; then
			ln -sfn -- "$command_target_before" "$command_link"
		elif [ -L "$command_link" ]; then
			command_target=$(readlink -f "$command_link" || true)
			case "$command_target" in "$install_root"/*) rm -f -- "$command_link" ;; esac
		fi
		if [ "$desktop_preexisting" = yes ] && [ -f "$desktop_backup" ]; then
			cp -a -- "$desktop_backup" "$desktop_file"
		elif [ "$desktop_preexisting" = no ] && [ -f "$desktop_file" ] &&
			grep -Fqx "X-LinuxCapable-Managed=$managed_id" "$desktop_file"; then
			rm -f -- "$desktop_file"
		fi
		if [ "$icon_preexisting" = yes ] && [ -f "$icon_backup" ]; then
			cp -a -- "$icon_backup" "$icon_file"
		elif [ "$icon_preexisting" = no ] && [ -f "$icon_file" ]; then
			rm -f -- "$icon_file"
		fi
		if [ -f "$root_marker" ] && [ "$(cat "$root_marker")" = "$managed_id" ]; then
			rm -rf -- "$install_root"
		fi
		if command -v update-desktop-database >/dev/null 2>&1; then
			update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
		fi
		if command -v gtk-update-icon-cache >/dev/null 2>&1; then
			gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true
		fi
	fi
	if [ "$committed" != yes ] && [ -n "$backup_root" ] && [ -d "$backup_root" ]; then
		if [ ! -e "$install_root" ] && [ ! -L "$install_root" ]; then
			if mv -- "$backup_root" "$install_root"; then
				backup_root=''
			else
				printf 'The previous Antigravity install remains at %s; restore it before retrying.\n' "$backup_root" >&2
			fi
		else
			printf 'The previous Antigravity install remains at %s because %s is occupied.\n' "$backup_root" "$install_root" >&2
		fi
	fi
	if [ -n "$stage_root" ] && [ -d "$stage_root" ]; then
		rm -rf -- "$stage_root"
	fi
	if [ -n "$tmpdir" ] && [ -d "$tmpdir" ]; then
		rm -rf -- "$tmpdir"
	fi
	if [ "$committed" = yes ] && [ -n "$backup_root" ] && [ -d "$backup_root" ]; then
		rm -rf -- "$backup_root"
	fi
	exit "$status"
}
trap cleanup EXIT

tmpdir=$(mktemp -d /var/tmp/antigravity.XXXXXX)
download_html="$tmpdir/download.html"
archive="$tmpdir/Antigravity.tar.gz"
archive_list="$tmpdir/archive-list.txt"
icon_staged="$tmpdir/antigravity.png"
desktop_staged="$tmpdir/antigravity-staged.desktop"
desktop_backup="$tmpdir/antigravity.desktop.before"
icon_backup="$tmpdir/antigravity.png.before"
if [ "$desktop_preexisting" = yes ]; then
	cp -a -- "$desktop_file" "$desktop_backup"
fi
if [ "$icon_preexisting" = yes ]; then
	cp -a -- "$icon_file" "$icon_backup"
fi

curl -fsSL --proto '=https' --proto-redir '=https' --compressed --retry 3 -o "$download_html" "$download_page"
download_fields=$(
	python3 - "$download_html" "$download_page" "$platform" <<'PY'
import re
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urljoin

class LinkParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.hrefs = []

    def handle_starttag(self, tag, attrs):
        if tag != "a":
            return
        href = dict(attrs).get("href")
        if href:
            self.hrefs.append(href)

html = Path(sys.argv[1]).read_text(errors="replace")
page_url = sys.argv[2]
platform = sys.argv[3]
parser = LinkParser()
parser.feed(html)
pattern = re.compile(
    r"https://storage\.googleapis\.com/antigravity-public/antigravity-hub/"
    r"([0-9]+\.[0-9]+\.[0-9]+)-[0-9]+/"
    + re.escape(platform)
    + r"/Antigravity\.tar\.gz"
)
matches = []
for href in parser.hrefs:
    url = urljoin(page_url, href)
    match = pattern.fullmatch(url)
    if match and url not in {item[1] for item in matches}:
        matches.append((match.group(1), url))

if len(matches) != 1:
    raise SystemExit(f"Could not find a download for {platform}")

print(*matches[0], sep="\t")
PY
)
IFS=$'\t' read -r version download_url <<<"$download_fields"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
   [[ ! "$download_url" =~ ^https://storage\.googleapis\.com/antigravity-public/antigravity-hub/[0-9]+\.[0-9]+\.[0-9]+-[0-9]+/${platform}/Antigravity\.tar\.gz$ ]]; then
	echo "Could not parse the Antigravity download page." >&2
	exit 1
fi

case "$platform" in
linux-x64) expected_top_dir="Antigravity-x64" ;;
linux-arm) expected_top_dir="Antigravity-arm64" ;;
esac

expected_target="$install_root/$expected_top_dir/antigravity"
sandbox_path="$install_root/$expected_top_dir/chrome-sandbox"
root_owned=no
root_legacy_owned=no
if [ -L "$install_root" ] || { [ -e "$install_root" ] && [ ! -d "$install_root" ]; }; then
	echo "$install_root is not a regular install directory. Move it before rerunning this helper." >&2
	exit 1
elif [ -d "$install_root" ]; then
	if [ -f "$root_marker" ] && [ "$(cat "$root_marker")" = "$managed_id" ]; then
		root_owned=yes
	elif [ -f "$install_root/.linuxcapable-version" ] && [ -x "$expected_target" ]; then
		root_owned=yes
		root_legacy_owned=yes
	else
		echo "$install_root is not a recognized LinuxCapable install. Move it before rerunning this helper." >&2
		exit 1
	fi
fi

installed_version=$(cat "$install_root/.linuxcapable-version" 2>/dev/null || true)
desktop_matches=no
if [ -f "$desktop_file" ] &&
	grep -Fqx "Exec=$command_link %U" "$desktop_file" &&
	grep -q '^Icon=antigravity$' "$desktop_file" &&
	grep -q '^StartupWMClass=Antigravity$' "$desktop_file"; then
	desktop_matches=yes
fi
payload_permissions_ok=no
if [ -d "$install_root/$expected_top_dir" ] &&
	! find "$install_root/$expected_top_dir" -xdev \
		\( -type d ! -perm -0005 -o -type f ! -perm -0004 \) \
		-print -quit | grep -q . &&
	find "$expected_target" -maxdepth 0 -type f -perm -0001 -print -quit | grep -q .; then
	payload_permissions_ok=yes
fi
if [ "$installed_version" = "$version" ] &&
	[ -x "$expected_target" ] &&
	[ "$(stat -c '%U:%G:%a' "$install_root/$expected_top_dir")" = "root:root:755" ] &&
	[ "$payload_permissions_ok" = yes ] &&
	[ -L "$command_link" ] &&
	[ "$(readlink -f "$command_link")" = "$expected_target" ] &&
	[ "$desktop_matches" = yes ] &&
	[ -f "$icon_file" ]; then
	if [ -f "$sandbox_path" ] && [ ! -L "$sandbox_path" ] &&
	   [ "$(stat -c '%U:%G:%a' "$sandbox_path")" = "root:root:4755" ]; then
		if [ "$root_legacy_owned" = yes ]; then
			printf '%s\n' "$managed_id" >"$root_marker"
		fi
		if [ "$desktop_legacy_owned" = yes ]; then
			printf 'X-LinuxCapable-Managed=%s\n' "$managed_id" >>"$desktop_file"
		fi
		printf 'Antigravity %s is already installed at %s\n' "$version" "$install_root/$expected_top_dir"
		exit 0
	fi
fi

printf 'Downloading Antigravity %s for %s...\n' "$version" "$platform"
curl -fsSL --proto '=https' --proto-redir '=https' --retry 3 -o "$archive" "$download_url"
python3 - "$archive" "$expected_top_dir" <<'PY'
import sys
import tarfile
from pathlib import PurePosixPath

archive_path, expected_top = sys.argv[1:]
top_dirs = set()
with tarfile.open(archive_path, "r:gz") as archive:
    for member in archive.getmembers():
        path = PurePosixPath(member.name)
        if path.is_absolute() or ".." in path.parts or not path.parts:
            raise SystemExit(f"Unsafe archive member: {member.name}")
        top_dirs.add(path.parts[0])
        if not (member.isfile() or member.isdir() or member.issym() or member.islnk()):
            raise SystemExit(f"Unsupported archive member type: {member.name}")
        if member.issym() or member.islnk():
            target = PurePosixPath(member.linkname)
            if target.is_absolute() or ".." in target.parts:
                raise SystemExit(f"Unsafe archive link: {member.name} -> {member.linkname}")
if top_dirs != {expected_top}:
    raise SystemExit(f"Unexpected archive roots: {sorted(top_dirs)}")
PY
tar -tzf "$archive" >"$archive_list"
top_dir=$(sed -n '1{s#/.*##;p;q}' "$archive_list")
case "$top_dir" in
Antigravity-*) ;;
*)
	echo "Unexpected archive layout: $top_dir" >&2
	exit 1
	;;
esac
if [ "$top_dir" != "$expected_top_dir" ]; then
	echo "Unexpected archive directory: $top_dir" >&2
	exit 1
fi

tar --no-same-owner --no-same-permissions -xzf "$archive" -C "$tmpdir"
chmod -R a-s -- "$tmpdir/$top_dir"
if find "$tmpdir/$top_dir" -xdev -perm /6000 -print -quit | grep -q .; then
	echo 'The extracted Antigravity archive still contains a set-ID path.' >&2
	exit 1
fi
if [ ! -x "$tmpdir/$top_dir/antigravity" ]; then
	echo "The Antigravity launcher was not found in the archive." >&2
	exit 1
fi

python3 - "$tmpdir/$top_dir/resources/app.asar" "$icon_staged" <<'PY'
import json
import struct
import sys
from pathlib import Path

asar = Path(sys.argv[1])
output = Path(sys.argv[2])
with asar.open("rb") as archive:
    archive.read(4)
    header_size = struct.unpack("<I", archive.read(4))[0]
    archive.read(4)
    json_size = struct.unpack("<I", archive.read(4))[0]
    header = json.loads(archive.read(json_size).decode())

icon = header["files"]["icon.png"]
with asar.open("rb") as archive:
    archive.seek(8 + header_size + int(icon["offset"]))
    output.write_bytes(archive.read(int(icon["size"])))
PY

cat >"$desktop_staged" <<DESKTOP
[Desktop Entry]
Name=Antigravity
Comment=Google Antigravity 2.0 agent platform
Exec=$command_link %U
Icon=antigravity
Terminal=false
Type=Application
Categories=Development;IDE;
StartupNotify=true
StartupWMClass=Antigravity
X-LinuxCapable-Managed=$managed_id
DESKTOP
desktop-file-validate "$desktop_staged"

stage_root=$(mktemp -d "${install_root}.new.XXXXXX")
chmod 0755 "$stage_root"
printf '%s\n' "$managed_id" >"$stage_root/.linuxcapable-managed"
cp -a "$tmpdir/$top_dir" "$stage_root/"
chmod -R a+rX -- "$stage_root/$top_dir"
chown root:root "$stage_root/$top_dir"
chmod 0755 "$stage_root/$top_dir"
printf '%s\n' "$version" >"$stage_root/.linuxcapable-version"
if [ ! -f "$stage_root/$top_dir/chrome-sandbox" ] || [ -L "$stage_root/$top_dir/chrome-sandbox" ]; then
	echo 'The staged Antigravity Chromium sandbox helper is missing or invalid.' >&2
	exit 1
fi
chown root:root "$stage_root/$top_dir/chrome-sandbox"
chmod 4755 "$stage_root/$top_dir/chrome-sandbox"
if [ ! -x "$stage_root/$top_dir/antigravity" ]; then
	echo 'The staged Antigravity launcher is not executable.' >&2
	exit 1
fi
if [ -d "$install_root" ]; then
	backup_root=$(mktemp -d "${install_root}.previous.XXXXXX")
	rmdir -- "$backup_root"
	mv -- "$install_root" "$backup_root"
fi
mv -- "$stage_root" "$install_root"
stage_root=''
new_root_installed=yes
ln -sfn "$install_root/$top_dir/antigravity" "$command_link"

mkdir -p "$(dirname "$icon_file")"
install -m 0644 "$icon_staged" "$icon_file"
install -m 0644 "$desktop_staged" "$desktop_file"

if command -v update-desktop-database >/dev/null 2>&1; then
	update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
	gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true
fi

payload_permissions_ok=no
if ! find "$install_root/$top_dir" -xdev \
	\( -type d ! -perm -0005 -o -type f ! -perm -0004 \) \
	-print -quit | grep -q . &&
	find "$install_root/$top_dir/antigravity" -maxdepth 0 \
		-type f -perm -0001 -print -quit | grep -q .; then
	payload_permissions_ok=yes
fi
if [ ! -x "$install_root/$top_dir/antigravity" ] ||
   [ "$(stat -c '%U:%G:%a' "$install_root/$top_dir")" != "root:root:755" ] ||
   [ "$payload_permissions_ok" != yes ] ||
   [ ! -L "$command_link" ] ||
   [ "$(readlink -f "$command_link")" != "$install_root/$top_dir/antigravity" ] ||
   ! grep -Fqx "X-LinuxCapable-Managed=$managed_id" "$desktop_file" ||
   [ ! -f "$icon_file" ]; then
  echo 'Final Antigravity integration checks failed.' >&2
  exit 1
fi
if [ ! -f "$sandbox_path" ] || [ -L "$sandbox_path" ] ||
   [ "$(stat -c '%U:%G:%a' "$sandbox_path")" != 'root:root:4755' ]; then
  echo 'Final Antigravity sandbox check failed.' >&2
  exit 1
fi

committed=yes
printf 'Installed Antigravity %s at %s\n' "$version" "$install_root/$top_dir"
EOF

bash -n "$helper_tmp"
sudo install -m 0755 "$helper_tmp" "$helper_path"
echo "Helper installed at $helper_path"

# --- Install / Update Antigravity ---
echo "[3/4] Installing Antigravity..."
sudo /usr/local/bin/update-antigravity

# --- Verification ---
echo "[4/4] Verifying installation..."
launcher=$(readlink -f /usr/local/bin/antigravity)
if test -x "$launcher"; then
  echo "  Launcher: $launcher (OK)"
else
  echo "  Launcher: NOT FOUND" >&2
  exit 1
fi

if test -f /usr/share/icons/hicolor/512x512/apps/antigravity.png; then
  echo "  Icon: installed (OK)"
else
  echo "  Icon: NOT FOUND" >&2
  exit 1
fi

echo ""
echo "Desktop file entries:"
grep -E '^(Name|Exec|Icon|Categories|StartupWMClass)=' /usr/share/applications/antigravity.desktop

echo ""
echo "Sandbox permissions:"
stat -c '%U %G %a %n' /opt/antigravity/Antigravity-*/chrome-sandbox

echo ""
echo "=== Antigravity installed successfully ==="
