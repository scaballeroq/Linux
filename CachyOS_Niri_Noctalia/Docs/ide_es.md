---
sidebar_position: 5
---

# Entornos de Desarrollo e Inteligencia Artificial (IDEs & AI) en CachyOS

Esta guía detalla la instalación, configuración y mantenimiento de los editores, herramientas de desarrollo asistidas por IA y utilidades presentes en la carpeta `IDE`.

El entorno está completamente optimizado para **CachyOS (Arch Linux)**, ejecutándose sobre el compositor Wayland **Niri** con integración en la terminal **Zsh**.

---

## 1. Google Antigravity Desktop (`antigravity.sh`)

Automatiza la instalación de **Google Antigravity Desktop** (versión completa con GUI):

1. **Instalación de Dependencias**:
   ```bash
   sudo pacman -Syu --noconfirm --needed ca-certificates curl tar desktop-file-utils python
   ```

2. **Integración con Niri y Wayland**:
   - Se integra con la variable de entorno `ELECTRON_OZONE_PLATFORM_HINT="auto"` para ejecución nativa en Wayland sin escalado borroso de XWayland.
   - Crea el lanzador de escritorio en `/usr/share/applications/antigravity.desktop` compatible con el lanzador de **Noctalia Shell**.

3. **Script de Actualización del Sistema (`update-antigravity`)**:
   Genera el ejecutable de actualización en `/usr/local/bin/update-antigravity`, accesible mediante el alias:
   ```bash
   update-antigravity
   ```

---

## 2. Google Antigravity CLI (`antigravity-cli.sh`)

Instala la utilidad de línea de comandos de Google Antigravity (`agy`):

1. **Despliegue del Binario**:
   Se descarga e instala el binario en `~/.local/bin/agy`.
2. **Validación**:
   El instalador valida la integridad y las capacidades del ejecutable:
   ```bash
   agy --version
   agy --help
   ```
3. **Actualizaciones**:
   La CLI permite actualizarse directamente mediante su comando interno:
   ```bash
   agy update
   ```

---

## 3. Google Antigravity IDE Engine (`antigravity-ide.sh`)

Despliega el motor de desarrollo de Antigravity IDE para CachyOS:

1. **Instalación y Permisos**:
   Configura el runtime en `/opt/antigravity-ide` y el enlace en `/usr/local/bin/antigravity-ide`.
2. **Helper de Actualización**:
   Instala `/usr/local/bin/update-antigravity-ide` y el alias correspondiente en `ZSH.Setup`:
   ```bash
   update-antigravity-ide
   ```

---

## 4. OpenCode AI CLI (`opencode.sh`)

Instala y enlaza el asistente de desarrollo por terminal **OpenCode AI**:

1. **Instalación**:
   Descarga de forma desatendida el motor de OpenCode:
   ```bash
   curl -fsSL https://opencode.ai/install | bash
   ```
2. **Integración en Zsh**:
   Añade de forma transparente `~/.opencode/bin` al `PATH` en `~/.zshrc`.
3. **Uso**:
   ```bash
   opencode --version
   ```

---

## 5. Control de Versiones Git & Herramientas Modernas (`git.sh`)

Configura el stack moderno de control de versiones con integración en Niri / Wayland:

1. **Paquetes**:
   ```bash
   sudo pacman -S --needed --noconfirm git git-delta lazygit github-cli
   ```
2. **Git-Delta**: Diferencias coloreadas lado a lado (`side-by-side`), con números de línea y visualización clara de conflictos (`zdiff3`).
3. **Lazygit**: Terminal UI para Git accesible escribiendo `lazygit`.
4. **Portapapeles Wayland**: Integrado con `wl-copy` para copiar hashes de commits y diffs al portapapeles.

---

## 6. Automatización con `justfile`

Desde la raíz del proyecto puedes instalar cualquiera de estos componentes:

```bash
just antigravity        # Antigravity Desktop
just antigravity-cli    # Antigravity CLI (agy)
just antigravity-ide    # Antigravity IDE Engine
just opencode           # OpenCode AI CLI
just git-setup          # Git + Delta + Lazygit + GH CLI
just ides               # Instala todos los IDEs y herramientas AI
```

---

## Verificación

- **Antigravity Desktop**: Ábrelo desde el lanzador de Noctalia (`Super` / `noctalia msg panel-toggle launcher`) o ejecutando `antigravity &`.
- **Antigravity CLI**: Comprueba `agy --version`.
- **OpenCode**: Ejecuta `opencode --help`.
- **Git**: Verifica con `git --version` y `lazygit`.
