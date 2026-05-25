# 🔧 Kubuntu Environment Configuration

Este repositorio contiene una colección organizada y modular de scripts de configuración para sistemas **Kubuntu** (enfocado en 26.04 LTS y posteriores). El objetivo es automatizar la puesta a punto de un entorno de desarrollo profesional, optimizado y estéticamente agradable.

---

## 📂 Organización del Repositorio

La configuración se ha reestructurado de forma modular para facilitar el mantenimiento y la legibilidad:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración de la terminal Bash.
- **`aliases.sh`**: Atajos comunes para comandos frecuentemente utilizados.
- **`environment.sh`**: Variables globales que afectan el comportamiento de la shell.
- **`functions.sh`**: Colección de funciones avanzadas y utilidades.
- **`desktop_settings.sh`**: Configuraciones de entorno para GNOME/KDE y aliases.
- **`history.sh`**: Controla cómo bash recuerda los comandos.
- **`options.sh`**: Configura el comportamiento interno de Bash mediante 'shopt' y 'bind'.
- **`podman-functions.sh`**: Funciones para gestión simplificada de contenedores.
- **`rclone_aliases.sh`**: Atajos para facilitar la sincronización en la nube.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas.

### 🐳 [Podman](./Podman/)
Scripts para instalar y desplegar servicios en contenedores Podman de forma aislada:
- **Core**: `podman.sh` (Instalación principal en Kubuntu)
- **Bases de Datos**: `podman-postgres.sh`, `podman-mysql.sh`, `podman-mongodb.sh`, `podman-redis.sh`
- **Gestión y Monitoreo**: `podman-portainer.sh`, `podman-adminer.sh`, `podman-dozzle.sh`, `podman-grafana.sh`, `podman-prometheus.sh`, `podman-jaeger.sh`
- **Infraestructura**: `podman-nginx.sh`, `podman-keycloak.sh`, `podman-rabbitmq.sh`, `podman-minio.sh`, `podman-mailhog.sh`, `podman-browserless.sh`
- **Frameworks/CMS**: `podman-wordpress.sh`, `podman-storybook.sh`

### 🖥️ [Virtualizacion](./Virtualizacion/)
- **`virtualization.sh`**: Instalación y configuración de Virtualización (KVM/QEMU, libvirtd) optimizada para Kubuntu.

### ⚙️ [Setup](./Setup/)
Scripts de configuración del sistema operativo, personalización y endurecimiento:
- **`post-install.sh`**: Script maestro de post-instalación para Kubuntu.
- **`apariencia.sh`**: Instalación de temas e iconos.
- **`kde-settings.sh`**: Configuración del entorno de escritorio KDE Plasma.
- **`cockpit.sh`**: Instalación y configuración de Cockpit (administración web).
- **`fastfetch.sh`**: Información estética del sistema al inicio (Fastfetch).
- **`firefox.sh`**: Instalación y configuración de Mozilla Firefox.
- **`fonts.sh`**: Instalación automatizada de fuentes de desarrollo (Nerd Fonts).
- **`ptyxis.sh`**: Instalación del emulador de terminal moderno Ptyxis.
- **`seguridad.sh`**: Endurecimiento (hardening), configuración de UFW y Fail2ban.
- **`shell.sh`**: Herramientas modernas de terminal y prompt (Starship).
- **`yt-dlp-setup.sh`**: Dependencias para manejo multimedia (yt-dlp, ffmpeg).

### 💻 [IDE](./IDE/)
- **`antigravity.sh`**: Instalación de la herramienta de Google Antigravity.
- **`neovim.sh`**: Instalación de Neovim y LazyVim.
- **`vscode.sh`**: Instalación de Visual Studio Code.

### 🛠️ [Git](./Git/)
- **`git.sh`**: Instalación y configuración de Git, Delta y Lazygit.
- **`github-cli.sh`**: Instalación de GitHub CLI.

### ⚡ [ProgrammingLanguages](./ProgrammingLanguages/)
Gestión de entornos y runtimes de lenguajes usando **mise**.
- **`mise.sh`**: Instalador del gestor de versiones Mise.
- **`angular.sh`**: Angular CLI.
- **`dotnet.sh`**: .NET SDK.
- **`gemini.sh`**: Gemini CLI.
- **`java.sh`**: OpenJDK (compatible con AutoFirma).
- **`nodejs.sh`**: Node.js.
- **`python.sh`**: Python.
- **`rust.sh`**: Rust.

### 📦 [Apps](./Apps/) y 🎮 [Juegos](./Juegos/)
- **`meld.sh`**: Herramienta de diff/merge visual.
- **`steam.sh`**: Instalación de la plataforma de juegos Steam.

---

## 🚀 Cómo empezar

### 1. Clonar el repositorio
```bash
git clone https://github.com/scaballeroq/Kubuntu.git
cd Kubuntu
```

### 2. Configurar la Shell (Bash)
Se recomienda el uso de un directorio `.bashrc.d/` para cargar los scripts de forma modular.

```bash
mkdir -p ~/.bashrc.d
ln -s $(pwd)/Bash.Setup/*.sh ~/.bashrc.d/
```

Y añade lo siguiente a tu `~/.bashrc`:
```bash
# Carga modular de scripts de Bash.Setup
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

### 3. Ejecutar Scripts de System Setup
Puedes ejecutar scripts específicos según tu necesidad (asegúrate de darles permisos de ejecución):
```bash
chmod +x Setup/*.sh Virtualizacion/*.sh ProgrammingLanguages/*.sh IDE/*.sh Podman/*.sh Git/*.sh
./Setup/fonts.sh       # Instala Fuentes
./ProgrammingLanguages/mise.sh # Instala Mise
```

---

## ✨ Características Principales
- **Modularidad**: Cada componente y script es independiente.
- **Estándares de Kubuntu**: Uso de repositorios oficiales, `apt` y configuraciones nativas de Ubuntu.
- **Productividad**: Multiples alias y funciones precargadas (Podman, Git, Rclone).
- **Actualizado**: Herramientas modernas como Fastfetch, Starship, Lazygit y Mise.

---
*Mantenido por [caballero](https://github.com/scaballeroq)*
