---
description: Estándares de desarrollo, idempotencia y buenas prácticas para scripts Bash en Fedora 45 Workstation (GNOME 51 Wayland).
---

# Estándares de Shell Scripting para Fedora 45 Workstation (`Setup/`, `IDE/`, `ProgrammingLanguages/`, `Podman/`)

Al crear, modificar o auditar cualquier script dentro de `Fedora-Workstation/`, debes cumplir estrictamente las siguientes reglas arquitectónicas:

## 1. Cabecera Estandarizada y Modo Estricto
Todo script ejecutable debe comenzar con `#!/usr/bin/env bash` y activar el modo estricto:
```bash
#!/usr/bin/env bash
set -euo pipefail
```

## 2. Separación de Privilegios (`REAL_USER` vs `root`)
Muchos scripts en `Setup/` modifican tanto el sistema (`/etc/`, `dnf5`, `systemctl`, `firewall-cmd`) como la sesión gráfica de GNOME del usuario (`gsettings`, `dconf`, `~/.config/`, `flatpak --user`).
- Detecta siempre el usuario real e invoca cambios de escritorio en su contexto (con su bus D-Bus activo):
  ```bash
  if [[ $EUID -eq 0 ]]; then
      REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER:-root}")}"
  else
      REAL_USER="${USER:-$(whoami)}"
  fi
  USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
  REAL_UID=$(id -u "$REAL_USER")

  run_as_user() {
      if [[ $EUID -eq 0 && "$REAL_USER" != "root" ]]; then
          sudo -u "$REAL_USER" \
              DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${REAL_UID}/bus" \
              XDG_RUNTIME_DIR="/run/user/${REAL_UID}" \
              "$@"
      else
          "$@"
      fi
  }
  ```
- **Nunca** ejecutes `gsettings`, `dconf`, `gnome-extensions` ni `systemctl --user` directamente como `root` sin pasar por `run_as_user`.

## 3. Idempotencia con DNF5 y RPM Fusion Obligatorio
- **Detección del gestor DNF**: Soporta `dnf5` como binario primario en Fedora 45 (con fallback a `dnf`):
  ```bash
  DNF_BIN="dnf5"
  command -v dnf5 &>/dev/null || DNF_BIN="dnf"
  ```
- **Verificación de paquetes con RPM**: Usa `rpm -q <paquete> &>/dev/null` (nunca `dpkg` ni `apt`):
  ```bash
  is_pkg_installed() {
      rpm -q "$1" &>/dev/null
  }
  ```
- **Instalación obligatoria de RPM Fusion**: Todo script que instale códecs multimedia, drivers VA-API (`mesa-va-drivers-freeworld`), FFmpeg completo, VLC, MPV o Steam **debe verificar e instalar RPM Fusion Free y Non-Free** de forma idempotente antes de instalar los paquetes:
  ```bash
  ensure_rpmfusion() {
      local fed_ver
      fed_ver=$(rpm -E %fedora)
      if ! rpm -q rpmfusion-free-release &>/dev/null || ! rpm -q rpmfusion-nonfree-release &>/dev/null; then
          sudo "$DNF_BIN" install -y \
              "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fed_ver}.noarch.rpm" \
              "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fed_ver}.noarch.rpm"
          sudo "$DNF_BIN" config-manager setopt fedora-cisco-openh264.enabled=1 2>/dev/null || true
      fi
  }
  ```
- Cuando se sustituyan paquetes base limitados (como `ffmpeg-free` o `mesa-va-drivers`) por los paquetes completos de RPM Fusion (`ffmpeg`, `mesa-va-drivers-freeworld`), utiliza `--allowerasing` o `sudo "$DNF_BIN" swap -y`.

## 4. Interfaz CLI Consistente (`--status` y `--help`)
Todos los scripts de aprovisionamiento deben implementar al menos:
- `-s`, `--status`: Diagnóstico de solo lectura (sin `sudo` ni modificaciones) que muestre el estado actual de paquetes RPM, servicios `systemd`, claves `gsettings` y archivos de configuración.
- `-h`, `--help`: Ayuda clara con opciones disponibles y ejemplos de uso.

## 5. Reglas de Seguridad de Sesión Gráfica y Red
- **systemd-logind**: **NUNCA** ejecutes `sudo systemctl restart systemd-logind` dentro de una sesión gráfica activa de GNOME Wayland (cerraría la sesión inmediatamente). Usa `sudo systemctl reload systemd-logind 2>/dev/null || sudo kill -HUP $(pidof systemd-logind)`.
- **Firewalld**: Usa exclusivamente `firewall-cmd`. Verifica que `firewalld` esté activo (`systemctl is-active --quiet firewalld`) antes de aplicar reglas `--permanent` y recarga con `sudo firewall-cmd --reload`.
- **Nautilus Python Extensions**: En Fedora 45, el paquete de integración de extensiones Python para Nautilus se llama `nautilus-python` (en lugar de `python3-nautilus` de Debian) y las extensiones de usuario residen en `~/.local/share/nautilus-python/extensions/`.
