#!/usr/bin/env bash
set -euo pipefail

echo "=== Google Antigravity IDE Installer ==="

# --- 1. Dependencies ---
echo "[1/4] Installing dependencies..."
sudo pacman -S --noconfirm \
  ca-certificates \
  curl \
  tar \
  desktop-file-utils \
  python \
  nss \
  at-spi2-atk \
  at-spi2-core \
  cups \
  libdrm \
  libxkbcommon \
  libxcomposite \
  libxdamage \
  libxrandr \
  mesa \
  alsa-lib \
  libsecret

# --- 2. Helper script ---
echo "[2/4] Creating update helper..."
helper_path='/usr/local/bin/update-antigravity-ide'
helper_marker='# LinuxCapable-Managed: google-antigravity-ide-helper-v1'

if [ -L "$helper_path" ] || { [ -e "$helper_path" ] && [ ! -f "$helper_path" ]; }; then
  printf '%s is not a regular helper file; move it before continuing.\n' "$helper_path" >&2
  exit 1
fi

helper_tmp=$(mktemp "${TMPDIR:-/tmp}/update-antigravity-ide.XXXXXX")
trap 'rm -f -- "$helper_tmp"' EXIT

cat >"$helper_tmp" <<'EOF'
#!/usr/bin/env bash
# LinuxCapable-Managed: google-antigravity-ide-helper-v1
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
	echo "Run with sudo: sudo update-antigravity-ide" >&2
	exit 1
fi

download_page="https://antigravity.google/download"
install_root="/opt/antigravity-ide"
command_link="/usr/local/bin/antigravity-ide"
desktop_file="/usr/share/applications/antigravity-ide.desktop"
icon_file="/usr/share/icons/hicolor/512x512/apps/antigravity-ide.png"
archive_top_dir="Antigravity IDE"
install_dir="Antigravity-IDE"
managed_id="linuxcapable-antigravity-ide-v1"
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
		echo "$required_command is required to install Antigravity IDE." >&2
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
		grep -Fqx 'Icon=antigravity-ide' "$desktop_file" &&
		grep -Fqx 'StartupWMClass=antigravity-ide' "$desktop_file"; then
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
				printf 'The previous Antigravity IDE install remains at %s; restore it before retrying.\n' "$backup_root" >&2
			fi
		else
			printf 'The previous Antigravity IDE install remains at %s because %s is occupied.\n' "$backup_root" "$install_root" >&2
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

tmpdir=$(mktemp -d /var/tmp/antigravity-ide.XXXXXX)
download_html="$tmpdir/download.html"
archive="$tmpdir/Antigravity-IDE.tar.gz"
archive_list="$tmpdir/archive-list.txt"
desktop_staged="$tmpdir/antigravity-ide-staged.desktop"
desktop_backup="$tmpdir/antigravity-ide.desktop.before"
icon_backup="$tmpdir/antigravity-ide.png.before"
if [ "$desktop_preexisting" = yes ]; then
	cp -a -- "$desktop_file" "$desktop_backup"
fi
if [ "$icon_preexisting" = yes ]; then
	cp -a -- "$icon_file" "$icon_backup"
fi

curl -fsSL --compressed --proto '=https' --proto-redir '=https' -A "Mozilla/5.0 (X11; Linux x86_64)" --retry 3 -o "$download_html" "$download_page"
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
    r"https://edgedl\.me\.gvt1\.com/edgedl/release2/j0qc3/antigravity/stable/"
    r"([0-9]+\.[0-9]+\.[0-9]+)-[0-9]+/"
    + re.escape(platform)
    + r"/Antigravity(?:%20|\s)IDE\.tar\.gz"
)
matches = []

# Revisar tanto tags href como URLs dentro del texto de la página
all_urls = [urljoin(page_url, href) for href in parser.hrefs]
all_urls += re.findall(r'https?://[^\s"\'<>]+', html)

for url in all_urls:
    match = pattern.search(url)
    if match:
        clean_url = match.group(0).replace(" ", "%20")
        if clean_url not in {item[1] for item in matches}:
            matches.append((match.group(1), clean_url))

if not matches:
    raise SystemExit(f"Could not find an IDE download for {platform}")

print(*matches[0], sep="\t")
PY
)
IFS=$'\t' read -r version download_url <<<"$download_fields"

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
   [[ ! "$download_url" =~ ^https://edgedl\.me\.gvt1\.com/edgedl/release2/j0qc3/antigravity/stable/[0-9]+\.[0-9]+\.[0-9]+-[0-9]+/${platform}/Antigravity(%20|\ )IDE\.tar\.gz$ ]]; then
	echo "Could not parse the Antigravity IDE download page." >&2
	exit 1
fi

expected_target="$install_root/$install_dir/antigravity-ide"
legacy_expected_target="$install_root/$archive_top_dir/antigravity-ide"
sandbox_path="$install_root/$install_dir/chrome-sandbox"
root_owned=no
root_legacy_owned=no
if [ -L "$install_root" ] || { [ -e "$install_root" ] && [ ! -d "$install_root" ]; }; then
	echo "$install_root is not a regular install directory. Move it before rerunning this helper." >&2
	exit 1
elif [ -d "$install_root" ]; then
	if [ -f "$root_marker" ] && [ "$(cat "$root_marker")" = "$managed_id" ]; then
		root_owned=yes
	elif [ -f "$install_root/.linuxcapable-version" ] &&
		{ [ -x "$expected_target" ] || [ -x "$legacy_expected_target" ]; }; then
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
	grep -q '^Icon=antigravity-ide$' "$desktop_file" &&
	grep -q '^StartupWMClass=antigravity-ide$' "$desktop_file"; then
	desktop_matches=yes
fi

printf 'Downloading Antigravity IDE %s for %s...\n' "$version" "$platform"
curl -fsSL --proto '=https' --proto-redir '=https' --retry 3 -o "$archive" "$download_url"

tar -tzf "$archive" >"$archive_list"
top_dir=$(sed -n '1{s#/.*##;p;q}' "$archive_list")

tar --no-same-owner --no-same-permissions -xzf "$archive" -C "$tmpdir"
chmod -R a-s -- "$tmpdir/$top_dir"

cat >"$desktop_staged" <<DESKTOP
[Desktop Entry]
Name=Antigravity IDE
Comment=Google Antigravity IDE
Exec=$command_link %U
Icon=antigravity-ide
Terminal=false
Type=Application
Categories=Development;IDE;
MimeType=x-scheme-handler/antigravity-ide;application/x-antigravity-workspace;
StartupNotify=true
StartupWMClass=antigravity-ide
X-LinuxCapable-Managed=$managed_id
DESKTOP
desktop-file-validate "$desktop_staged"

stage_root=$(mktemp -d "${install_root}.new.XXXXXX")
chmod 0755 "$stage_root"
printf '%s\n' "$managed_id" >"$stage_root/.linuxcapable-managed"
mkdir -p "$stage_root/$install_dir"
cp -a "$tmpdir/$top_dir/." "$stage_root/$install_dir/"
chmod -R a+rX -- "$stage_root/$install_dir"
chown root:root "$stage_root/$install_dir"
chmod 0755 "$stage_root/$install_dir"
printf '%s\n' "$version" >"$stage_root/.linuxcapable-version"

# Sandbox permissions
if [ -f "$stage_root/$install_dir/chrome-sandbox" ]; then
	chown root:root "$stage_root/$install_dir/chrome-sandbox"
	chmod 4755 "$stage_root/$install_dir/chrome-sandbox"
fi

# Locate icon
icon_source=""
for possible_icon in \
  "$stage_root/$install_dir/resources/app/resources/linux/code.png" \
  "$stage_root/$install_dir/antigravity-ide.png" \
  "$stage_root/$install_dir/resources/app/resources/linux/antigravity.png"; do
	if [ -f "$possible_icon" ]; then
		icon_source="$possible_icon"
		break
	fi
done

mkdir -p "$(dirname "$icon_file")"
if [ -n "$icon_source" ]; then
	install -m 0644 "$icon_source" "$icon_file"
fi
install -m 0644 "$desktop_staged" "$desktop_file"

if [ -d "$install_root" ]; then
	backup_root=$(mktemp -d "${install_root}.previous.XXXXXX")
	rmdir -- "$backup_root"
	mv -- "$install_root" "$backup_root"
fi
mv -- "$stage_root" "$install_root"
stage_root=''
new_root_installed=yes
ln -sfn "$install_root/$install_dir/antigravity-ide" "$command_link"

# Desktop caches refresh
if command -v update-desktop-database >/dev/null 2>&1; then
	update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
	gtk-update-icon-cache -q /usr/share/icons/hicolor 2>/dev/null || true
fi

committed=yes
printf 'Installed Antigravity IDE %s at %s\n' "$version" "$install_root/$install_dir"
EOF

bash -n "$helper_tmp"
sudo install -m 0755 "$helper_tmp" "$helper_path"
echo "Helper installed at $helper_path"

# --- 3. Install / Update ---
echo "[3/4] Installing Antigravity IDE..."
sudo /usr/local/bin/update-antigravity-ide

# --- 4. Verification ---
echo "[4/4] Verifying installation..."
launcher=$(readlink -f /usr/local/bin/antigravity-ide)
if test -x "$launcher"; then
  echo "  Launcher: $launcher (OK)"
else
  echo "  Launcher: NOT FOUND" >&2
  exit 1
fi

if test -f /usr/share/icons/hicolor/512x512/apps/antigravity-ide.png; then
  echo "  Icon: installed (OK)"
else
  echo "  Icon: NOT FOUND (desktop icon may fallback)"
fi

echo "=== Antigravity IDE installed successfully ==="
