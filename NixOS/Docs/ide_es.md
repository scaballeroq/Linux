---
sidebar_position: 5
---

# Entornos de Desarrollo e IDEs en openSUSE Tumbleweed

Esta guía detalla las herramientas de desarrollo, plataformas con soporte de Inteligencia Artificial y utilidades de control de versiones gestionadas en la carpeta `IDE`.

Todas las herramientas están optimizadas para **openSUSE Tumbleweed**, el compositor **Wayland**, el entorno **KDE Plasma 6** y las terminales **Bash** (predeterminada) y **Zsh** (compatible si existe `~/.zshrc`).

---

## 1. Google Antigravity Suite

Google Antigravity es el entorno de desarrollo y asistencia de código con inteligencia artificial de última generación.

### Google Antigravity Desktop (`antigravity.sh`)
Instala la aplicación de escritorio de Google Antigravity:
- Despliega en `/opt/antigravity` con permisos `4755` para el sandbox Chromium/Electron.
- Crea el acceso directo de escritorio (`antigravity.desktop`) e icono en `/usr/share/pixmaps/antigravity.png`.
- Configura integración contextual con **Dolphin** mediante KIO Servicemenus para abrir carpetas con clic derecho:
  `~/.local/share/kio/servicemenus/open-in-antigravity.desktop`.

### Google Antigravity CLI (`antigravity-cli.sh`)
Instala la interfaz de línea de comandos de Antigravity (`agy`), facilitando la invocación de agentes, flujos de trabajo y tareas de terminal.

### Google Antigravity IDE Engine (`antigravity-ide.sh`)
Instala el motor IDE independiente de Antigravity, vinculando los binarios, el acceso directo en KDE Plasma y el servicemenu contextual para Dolphin (`~/.local/share/kio/servicemenus/open-in-antigravity-ide.desktop`).

---

## 2. Herramientas de Control de Versiones Git (`git.sh`)

Instala y optimiza la pila moderna de herramientas para Git en openSUSE Tumbleweed:
- **git**: Sistema de control de versiones vía Zypper.
- **delta** (`git-delta`): Paginador con resaltado de sintaxis moderno para `git diff` y `git show`.
- **lazygit**: Interfaz de terminal (TUI) para operaciones interactivas con Git.
- **github-cli** (`gh`): Herramienta oficial de línea de comandos de GitHub.

Configura variables globales recomendadas:
```bash
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global init.defaultBranch "main"
```

---

## 3. OpenCode AI CLI (`opencode.sh`)

Instala la herramienta de desarrollo asistido OpenCode AI CLI para terminal, integrando soporte para modelos de lenguaje avanzados directamente en la consola y configurando el `PATH` para Bash y Zsh.

---

## 4. Editores de Texto Nativos de KDE Plasma

- **Kate**: Editor avanzado con resaltado de sintaxis, terminal embebida y soporte de proyectos.
- **KWrite**: Editor ligero y rápido para notas y ediciones rápidas.
- **Dolphin Integration**: Menús contextuales para abrir proyectos directamente en Google Antigravity.

---

## Verificación

Para comprobar el correcto funcionamiento de las herramientas instaladas:

```bash
# Git, Delta, Lazygit y GitHub CLI
git --version
delta --version
lazygit --version
gh --version

# Antigravity CLI
agy --version 2>/dev/null || antigravity --version

# OpenCode
opencode --version 2>/dev/null || true
```
