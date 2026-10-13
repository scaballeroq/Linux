---
sidebar_position: 5
---

# Entornos de Desarrollo e IDEs en Fedora 44 (KDE Plasma 6)

Esta guía detalla las herramientas de desarrollo, plataformas con soporte de Inteligencia Artificial y utilidades de control de versiones gestionadas en la carpeta `IDE`.

Todas las herramientas están optimizadas para **Fedora 44**, el gestor de paquetes **DNF5**, el compositor **Wayland**, el entorno **KDE Plasma 6** y la terminal **Bash** (con soporte modular en `~/.bashrc.d/` y `~/.config/environment.d/`).

---

## 1. Google Antigravity Suite

Google Antigravity es el entorno de desarrollo y asistencia de código con inteligencia artificial de última generación.

### Google Antigravity Desktop (`antigravity.sh`)
Instala la aplicación de escritorio de Google Antigravity:
- Despliega en `/opt/antigravity` con permisos `4755` para el sandbox Chromium/Electron (`chrome-sandbox`).
- Verifica dependencias nativas de Fedora (`nss`, `libdrm`, `mesa-libgbm`, `libsecret`, `python3`).
- Crea el acceso directo de escritorio (`antigravity.desktop`) e icono en `/usr/share/pixmaps/antigravity.png`.
- Configura integración contextual con **Dolphin** mediante KIO Servicemenus para abrir carpetas con clic derecho:
  `~/.local/share/kio/servicemenus/open-in-antigravity.desktop`.
- Incluye el actualizador atómico `/usr/local/bin/update-antigravity` y opciones `--status`, `--check`, `--force`, `--uninstall`.

### Google Antigravity CLI (`antigravity-cli.sh`)
Instala la interfaz de línea de comandos de Antigravity (`agy`), facilitando la invocación de agentes, flujos de trabajo y tareas de terminal:
- Instalación rootless en `~/.local/bin/agy`.
- Integración en `~/.bashrc.d/antigravity-cli.sh` y sesión gráfica en `~/.config/environment.d/10-antigravity-cli.conf`.
- Comandos CLI: `--status`, `--check`, `--update`, `--force`, `--uninstall`.

### Google Antigravity IDE Engine (`antigravity-ide.sh`)
Instala el motor IDE independiente de Antigravity:
- Vincula los binarios en `/usr/local/bin/antigravity-ide`.
- Acceso directo en KDE Plasma 6 y servicemenu contextual para Dolphin (`~/.local/share/kio/servicemenus/open-in-antigravity-ide.desktop`).
- Configuración de fuentes Nerd Font (`JetBrainsMono Nerd Font Mono`) en `settings.json`.

---

## 2. Herramientas de Control de Versiones Git (`git.sh`)

Instala y optimiza la pila moderna de herramientas para Git en Fedora 44:
- **git**: Sistema de control de versiones vía DNF5.
- **delta** (`git-delta`): Paginador con resaltado de sintaxis moderno para `git diff` y `git show`.
- **lazygit**: Interfaz de terminal (TUI) con integración de Delta y tema adaptado a KDE Breeze Dark.
- **github-cli** (`gh`): Herramienta oficial de línea de comandos de GitHub.

Configura variables globales recomendadas:
```bash
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global init.defaultBranch "main"
git config --global merge.conflictstyle "zdiff3"
```

---

## 3. OpenCode AI CLI (`opencode.sh`)

Instala la herramienta de desarrollo asistido OpenCode AI CLI para terminal:
- Instalación 100% rootless en `~/.opencode/bin/` y enlace simbólico en `~/.local/bin/opencode`.
- Integración modular de PATH en `~/.bashrc.d/opencode.sh` y sesión Wayland en `~/.config/environment.d/10-opencode.conf`.
- Soporte para versiones específicas (`-v 1.18.32`), última versión (`-l`) y diagnóstico (`--status`).

---

## 4. Editores de Texto Nativos de KDE Plasma

- **Kate**: Editor avanzado con resaltado de sintaxis, terminal embebida y soporte de proyectos.
- **KWrite**: Editor ligero y rápido para notas y ediciones rápidas.
- **Dolphin Integration**: Menús contextuales para abrir proyectos directamente en Google Antigravity y Antigravity IDE.

---

## 5. Automatización de IDEs con Just

Para desplegar o gestionar los entornos mediante `just`:

```bash
just ides             # Despliega Antigravity, Antigravity CLI, Antigravity IDE y OpenCode
just git-setup        # Despliega y configura Git, Delta, Lazygit y GitHub CLI
just antigravity      # Instala/actualiza Antigravity Desktop
just antigravity-cli  # Instala/actualiza Antigravity CLI
just antigravity-ide  # Instala/actualiza Antigravity IDE Engine
just opencode         # Instala/actualiza OpenCode AI CLI
```

---

## Verificación

Para comprobar el correcto funcionamiento de las herramientas instaladas:

```bash
# Git, Delta, Lazygit y GitHub CLI
./IDE/git.sh --status

# Antigravity Suite
./IDE/antigravity.sh --status
./IDE/antigravity-cli.sh --status
./IDE/antigravity-ide.sh --status

# OpenCode
./IDE/opencode.sh --status
```
