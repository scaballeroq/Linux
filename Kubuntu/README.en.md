# 🔧 Kubuntu Environment Configuration (KDE Plasma)

This repository contains an organized, modular, and automated collection of configuration scripts for **Kubuntu** systems (focused on KDE Plasma 6 and 5 across Kubuntu 24.04 LTS, 24.10, and 26.04 LTS).

The goal is to fully automate the setup of a professional, ultra-fast, secure, and aesthetically refined development environment.

---

## 📂 Repository Organization

The project is structured modularly for maintainability and extensibility:

### 🐚 [Bash.Setup](./Bash.Setup/)
Modular Bash terminal core loaded via `~/.bashrc.d/`:
- **`aliases.sh`**: Shortcuts for common commands, Git, APT, Rust tools, and virtualization.
- **`desktop_settings.sh`**: KDE Plasma optimizations and shortcuts (Night Color, Breeze themes, power).
- **`environment.sh`**: Global environment variables (`EDITOR`, `PATH`, styled `less`/`man`).
- **`functions.sh`**: Utility functions (backups, universal extract, ISO burning, multimedia).
- **`history.sh`**: Optimized persistent history (10k/20k lines, no duplicates, timestamps).
- **`options.sh`**: Advanced shell behaviors (`autocd`, `globstar`, typo autocorrection).
- **`podman-functions.sh`**: Non-colliding functions for streamlined Podman container management.
- **`rclone_aliases.sh`**: Sync, copy, and `--dry-run` shortcuts for Google Drive and OneDrive.
- **`yt-dlp_aliases.sh`**: High quality multimedia downloads with Deno JS engine support.

### ⚙️ [Setup](./Setup/)
Operating system, hardware, customization, and hardening scripts:
- **`post-install.sh`**: Base system setup, universe/multiverse repositories, Flatpak with Discover, and codecs.
- **`kde-settings.sh`**: Complete KDE Plasma CLI customization (Breeze Dark, Night Color, Meta+T shortcut).
- **`apariencia.sh`**: Papirus and Breeze icon and theme installations.
- **`firefox.sh`**: Official native `.deb` Firefox from Mozilla APT with Pin-Priority 900 (no Snap).
- **`laptop-setup.sh`**: Laptop optimizations for Kubuntu (power profiles, tap-to-click, bluetooth).
- **`fingerprint-setup.sh`**: Fingerprint authentication (fprintd, PAM, sudo, polkit, SDDM).
- **`hp-printer-setup.sh`**: HP LaserJet Pro M15w printer configuration (USB/CUPS/HPLIP).
- **`mount-workspace.sh`**: Permanent and safe automounting for Workspace partition in `/etc/fstab`.
- **`cockpit.sh`**: High-performance web administration suite (Storage, KVM, Podman, Network).
- **`fastfetch.sh`** / **`config.jsonc`**: Aesthetic system summary on terminal launch.
- **`fonts.sh`**: Developer Nerd Fonts (JetBrainsMono, FiraCode, CascadiaCode, Meslo, Hack).
- **`seguridad.sh`**: System hardening with strict and container-friendly UFW firewall rules.
- **`shell.sh`** / **`starship.toml`**: Modern Rust CLI utilities (`eza`, `bat`, `fzf`, `zoxide`, `ripgrep`) and Starship prompt.
- **`yt-dlp-setup.sh`**: Multimedia processing and download dependencies.

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Full KVM/QEMU environment with Libvirt, Virt-Manager, `br0` bridge, VirtIO drivers, and tuned.
- **`notas_virtualizacion_kubuntu.md`**: Step-by-step virtualization guide and best practices for Kubuntu.

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity Desktop.
- **`antigravity-cli.sh`**: Google Antigravity CLI (`agy`).
- **`antigravity-ide.sh`**: Google Antigravity IDE Engine.
- **`opencode.sh`**: OpenCode AI CLI and Editor.
- **`neovim.sh`**: Modular Neovim powered by LazyVim and LSPs.
- **`vscode.sh`**: Visual Studio Code from the official Microsoft repository.

### 🛠️ [Git](./Git/)
- **`git.sh`**: Git, Delta (syntax-highlighted diffs), and Lazygit (TUI).
- **`github-cli.sh`**: GitHub CLI (`gh`).

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Modern runtime management via **Mise**:
- **`mise.sh`**: Mise version manager installer.
- **`nodejs.sh`**: Node.js LTS and `pnpm` activation via Corepack.
- **`python.sh`**: Python 3.12 and pip tooling.
- **`rust.sh`**: Rust via rustup and cargo-binstall.
- **`dotnet.sh`**: .NET SDK.
- **`java.sh`**: OpenJDK.
- **`angular.sh`**: Angular CLI.
- **`gemini.sh`**: Gemini CLI.

### 🐳 [Podman](./Podman/)
19 modular scripts for isolated development service deployments:
- **Core**: `podman.sh`
- **Databases**: `podman-postgres.sh`, `podman-mysql.sh`, `podman-mongodb.sh`, `podman-redis.sh`
- **Storage**: `podman-minio.sh`
- **Monitoring**: `podman-grafana.sh`, `podman-prometheus.sh`, `podman-jaeger.sh`, `podman-dozzle.sh`
- **Management**: `podman-portainer.sh`, `podman-adminer.sh`, `podman-keycloak.sh`
- **Web & Testing**: `podman-nginx.sh`, `podman-wordpress.sh`, `podman-rabbitmq.sh`, `podman-mailhog.sh`, `podman-browserless.sh`, `podman-storybook.sh`

### 📦 [Apps](./Apps/) & 🎮 [Juegos](./Juegos/)
- **`meld.sh`**: Visual diff and merge tool.
- **`steam.sh`**: Steam and Proton-GE compatibility via Flatpak.

---

## 🚀 Usage with Justfile

Use [`justfile`](./justfile) to execute tasks quickly:

```bash
# Complete system configuration
just setup-all

# Individual tasks
just post-install    # Base system & repositories
just kde             # KDE Plasma 6 / 5 customization
just shell           # Modern terminal (eza, bat, starship)
just virtualization  # KVM / QEMU / Virt-Manager
just firefox         # Official .deb Firefox (no snap)
just ides            # Neovim, VS Code, Antigravity, OpenCode
just languages       # Node, Python, Rust, .NET, Java
just podman-base     # Podman rootless
```

---

## 🐚 Manual Shell Setup

To source shell modules dynamically:

```bash
mkdir -p ~/.bashrc.d
ln -s $(pwd)/Bash.Setup/*.sh ~/.bashrc.d/
```

Add this to `~/.bashrc`:
```bash
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

---

*Maintained by [caballero](https://github.com/scaballeroq)*
