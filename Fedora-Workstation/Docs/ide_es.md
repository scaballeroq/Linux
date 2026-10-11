---
sidebar_position: 5
---

# Entornos de Desarrollo e IDEs en Fedora 44

Esta guía detalla las herramientas de desarrollo, plataformas con soporte de Inteligencia Artificial y utilidades de control de versiones gestionadas en la carpeta `IDE`.

Todas las herramientas están optimizadas para **Fedora 44 Workstation**, el compositor **Wayland**, el entorno **GNOME** y las terminales **Bash** (predeterminada) y **Zsh** (compatible si existe `~/.zshrc`).

---

## 1. Google Antigravity Suite

Google Antigravity es el entorno de desarrollo y asistencia de código con inteligencia artificial.

### Google Antigravity Desktop (`antigravity.sh`)
Instala la aplicación de escritorio de Google Antigravity:
- Despliega en `/opt/antigravity` con permisos `4755` para el sandbox Chromium.
- Crea el acceso directo de escritorio (`antigravity.desktop`).
- Configura integración contextual con **Nautilus**: script para abrir proyectos haciendo clic derecho en cualquier carpeta (`~/.local/share/nautilus/scripts/Abrir con Antigravity`).

### Google Antigravity CLI (`antigravity-cli.sh`)
Instala la interfaz de línea de comandos de Antigravity (`agy`), facilitando la invocación de agentes, flujos de trabajo y tareas de terminal.

### Google Antigravity IDE Engine (`antigravity-ide.sh`)
Instala el motor IDE independiente de Antigravity, vinculando los binarios y el script contextual para Nautilus (`Abrir con Antigravity IDE`).

---

## 2. Herramientas de Control de Versiones Git (`git.sh`)

Instala y optimiza la pila moderna de herramientas para Git en Fedora 44:
- **git**: Sistema de control de versiones vía DNF5.
- **delta** (`git-delta`): Paginador con resaltado de sintaxis moderno para `git diff` y `git show`.
- **lazygit**: Interfaz de terminal (TUI) para operaciones interactivas con Git (instalado vía COPR o binario oficial).
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
