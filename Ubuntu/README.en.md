# 🔧 Ubuntu Environment Configuration

This repository contains an organized and modular collection of configuration scripts for **Ubuntu** systems (focused on 26.04 LTS and newer). The goal is to automate the setup of a professional, optimized, and aesthetically pleasing development environment.

---

## 📂 Repository Organization

The configuration has been restructured in a modular way to facilitate maintenance and readability:

### 🐚 [Bash.Setup](./Bash.Setup/)
The core of the Bash terminal configuration.
- **`aliases.sh`**: Common shortcuts for frequently used commands.
- **`environment.sh`**: Global environment variables that affect shell behavior.
- **`functions.sh`**: Collection of advanced functions and utilities.
- **`gnome_settings.sh`**: Environment configurations for GNOME and aliases.
- **`history.sh`**: Controls how bash remembers commands.
- **`options.sh`**: Configures internal Bash behavior using 'shopt' and 'bind'.
- **`podman-functions.sh`**: Functions for simplified Podman container management.
- **`rclone_aliases.sh`**: Shortcuts to facilitate cloud synchronization.
- **`yt-dlp_aliases.sh`**: Optimized multimedia downloads.

### 🐳 [Podman](./Podman/)
Scripts to install and deploy services in isolated Podman containers:
- **Core**: `podman.sh` (Main installation for Ubuntu 26.04)
- **Databases**: `podman-postgres.sh`, `podman-mysql.sh`, `podman-mongodb.sh`, `podman-redis.sh`
- **Management & Monitoring**: `podman-portainer.sh`, `podman-adminer.sh`, `podman-dozzle.sh`, `podman-grafana.sh`, `podman-prometheus.sh`, `podman-jaeger.sh`
- **Infrastructure**: `podman-nginx.sh`, `podman-keycloak.sh`, `podman-rabbitmq.sh`, `podman-minio.sh`, `podman-mailhog.sh`, `podman-browserless.sh`
- **Frameworks/CMS**: `podman-wordpress.sh`, `podman-storybook.sh`

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Sincronización and configuration of Virtualización (KVM/QEMU, libvirtd) optimized for Ubuntu.

### ⚙️ [Setup](./Setup/)
Scripts for operating system configuration, customization, and hardening:
- **`post-install.sh`**: Master post-installation script for Ubuntu.
- **`apariencia.sh`**: Installation of themes and icons.
- **`cockpit.sh`**: Installation and configuration of Cockpit (web administration).
- **`fastfetch.sh`**: Aesthetic system information on startup (Fastfetch).
- **`firefox.sh`**: Installation and configuration of Mozilla Firefox.
- **`fonts.sh`**: Automated installation of development fonts (Nerd Fonts).
- **`ptyxis.sh`**: Installation of the modern Ptyxis terminal emulator.
- **`seguridad.sh`**: System hardening, UFW, and Fail2ban configuration.
- **`shell.sh`**: Modern terminal tools and prompt (Starship).
- **`yt-dlp-setup.sh`**: Dependencies for multimedia handling (yt-dlp, ffmpeg).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Google Antigravity tool installation.
- **`neovim.sh`**: Neovim and LazyVim installation.
- **`vscode.sh`**: Visual Studio Code installation.

### 🛠️ [Git](./Git/)
- **`git.sh`**: Git, Delta, and Lazygit installation and configuration.
- **`github-cli.sh`**: GitHub CLI installation.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Language environment and runtime management using **mise**.
- **`mise.sh`**: Installation of the Mise version manager.
- **`angular.sh`**: Angular CLI.
- **`dotnet.sh`**: .NET SDK.
- **`gemini.sh`**: Gemini CLI.
- **`java.sh`**: OpenJDK (compatible with AutoFirma).
- **`nodejs.sh`**: Node.js.
- **`python.sh`**: Python.
- **`rust.sh`**: Rust.

### 📦 [Apps](./Apps/) & 🎮 [Juegos](./Juegos/)
- **`meld.sh`**: Visual diff/merge tool.
- **`steam.sh`**: Steam gaming platform installation.

---

## 🚀 Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/scaballeroq/Environment-Configuration.git
cd Repos-Linux/Ubuntu
```

### 2. Configure the Shell (Bash)
Using a `.bashrc.d/` directory is recommended for loading scripts modularly.

```bash
mkdir -p ~/.bashrc.d
ln -s $(pwd)/Bash.Setup/*.sh ~/.bashrc.d/
```

And add the following to your `~/.bashrc`:
```bash
# Modular loading of Bash.Setup scripts
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

### 3. Run System Setup Scripts
You can run specific scripts according to your needs (make sure to give them execution permissions):
```bash
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/*.sh Git/*.sh
./Setup/fonts.sh       # Install Fonts
./ProgrammingLanguages/mise.sh # Install Mise
```

---

## ✨ Key Features
- **Modularity**: Each component and script is independent.
- **Ubuntu Standards**: Use of official repositories, `apt`, and native configurations.
- **Productivity**: Multiple pre-loaded aliases and functions (Podman, Git, Rclone).
- **Up-to-date**: Modern tools like Fastfetch, Starship, Lazygit, and Mise.

---
*Maintained by [caballero](https://github.com/scaballeroq)*
