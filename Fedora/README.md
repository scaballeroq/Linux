# 🔧 Fedora & Arch Linux Environment Configuration

Este repositorio contiene una colección organizada y modular de scripts de configuración para sistemas **Fedora** y **Arch Linux**. El objetivo es automatizar la puesta a punto de un entorno de desarrollo profesional, optimizado y estéticamente agradable.

---

## 📂 Organización del Repositorio

La configuración se ha reestructurado de forma modular para facilitar el mantenimiento y la legibilidad:

### 🐚 [Bash.Setup](./Bash.Setup/)
El núcleo de la configuración de la terminal Bash.
- **`aliases.sh`**, **`functions.sh`**: Atajos y utilidades potentes.
- **`podman-functions.sh`**: Gestión simplificada de contenedores.
- **`yt-dlp_aliases.sh`**: Descargas multimedia optimizadas.
- **`environment.sh`**, **`history.sh`**, **`options.sh`**: Ajustes de comportamiento de la shell.

### 🐳 [Podman](./Podman/)
Scripts individuales para desplegar servicios comunes en contenedores Podman de forma aislada:
- Bases de datos: Postgres, MySQL, MongoDB, Redis.
- Herramientas: Portainer, Dozzle, Adminer, Minio.
- Desarrollo: Nginx, Keycloak, RabbitMQ, Storybook.

### 🖥️ [Virtualizacion](./Virtualizacion/)
Configuración de bajo nivel para **KVM/QEMU** en Fedora 44.
- Uso de demonios modulares (`virtqemud`, `virtnetworkd`).
- Gestión de permisos mediante ACLs para el usuario actual.
- Controladores VirtIO para máximo rendimiento en Windows.

### ⚙️ [Setup](./Setup/) / [IDE](./IDE/)
- **`post-install.sh`**: Script maestro de post-instalación para Fedora.
- **`fonts.sh`**: Instalación automatizada de **Nerd Fonts**.
- **`seguridad.sh`**: Ajustes de endurecimiento del sistema.
- **`neovim.sh`**, **`vscode.sh`**: Configuración de editores (LazyVim, extensiones).
- **`antigravity_2.0.sh`**, **`antigravity_2.0-IDE.sh`**: Instalación y auto-actualización automática de Google Antigravity 2.0 y Antigravity IDE 2.0 (mediante comandos locales `/usr/local/bin/update-antigravity*`).
- **`fastfetch.sh`**: Información estética del sistema al inicio.

### 🛠️ Otros Directorios
- **`Git/`**: Configuración global de Git (`git.sh`) con mejores prácticas modernas (rama por defecto `develop`, editor por defecto `kate --block` para KDE, visor de diferencias `git-delta`) e instalación de **Lazygit** y **GitHub CLI** (`github-cli.sh`).
- **`AI/`**: Herramientas de Inteligencia Artificial como **Antigravity CLI** (`antigravity-CLI.sh`) que configura la herramienta de terminal oficial `agy` y su actualizador local.
- **`ProgrammingLanguages/`**: Gestión de runtimes con **mise** (`mise.sh`) y scripts para Node.js, Python, Rust, .NET y Angular.
- **`Apps/`**: Scripts para aplicaciones específicas como **Meld** (comparación de archivos).

---

## 🚀 Cómo empezar

### 1. Clonar el repositorio
```bash
git clone https://github.com/scaballeroq/Fedora.Environment-Configuration.git
cd Fedora.Environment-Configuration
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
chmod +x Setup/*.sh Virtualizacion/*.sh
./Setup/fonts.sh       # Instala Fuentes
./Virtualizacion/virtualization.sh # Configura KVM/QEMU
```

---

## ✨ Características Principales
- **Modularidad**: Cada componente es independiente.
- **Optimización**: Servicios modulares en KVM para ahorrar recursos.
- **Productividad**: Cientos de alias y funciones para FFMPEG, Rclone, Podman y YT-DLP.
- **Limpieza**: Uso de ACLs para evitar el uso excesivo de `sudo` en tareas diarias.

---
*Mantenido por [caballero](https://github.com/scaballeroq)*
