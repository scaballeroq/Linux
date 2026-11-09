---
description: Estándares de desarrollo, idempotencia y buenas prácticas para scripts Bash en CachyOS Workstation (GNOME Wayland).
---

# Estándares de Shell Scripting para CachyOS Workstation (`Setup/`, `IDE/`, `ProgrammingLanguages/`, `Podman/`)

Al crear, modificar o auditar cualquier script dentro de `CachyOS-Gnome/`, debes cumplir estrictamente las siguientes reglas arquitectónicas:

## 1. Cabecera Estandarizada y Modo Estricto
Todo script ejecutable debe comenzar con `#!/usr/bin/env bash` y activar el modo estricto:
```bash
#!/usr/bin/env bash
set -euo pipefail
```

## 2. Separación de Privilegios (`REAL_USER` vs `root`)
Muchos scripts en `Setup/` modifican tanto el sistema (`/etc/`, `pacman`, `systemctl`, `firewall-cmd`) como la sesión gráfica de GNOME del usuario (`gsettings`, `dconf`, `~/.config/`, `flatpak --user`).
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

## 3. Idempotencia con Pacman y Paru
- **Verificación de paquetes con Pacman**: Usa `pacman -Q <paquete> &>/dev/null` (nunca `rpm`, `dpkg` ni `apt`):
  ```bash
  is_pkg_installed() {
      pacman -Q "$1" &>/dev/null
  }
  ```
- **Instalación idempotente**:
  ```bash
  install_packages() {
      local pkgs=("$@")
      local missing=()
      for p in "${pkgs[@]}"; do
          is_pkg_installed "$p" || missing+=("$p")
      done
      if [[ ${#missing[@]} -gt 0 ]]; then
          if [[ $EUID -eq 0 ]]; then
              pacman -S --needed --noconfirm "${missing[@]}"
          else
              sudo pacman -S --needed --noconfirm "${missing[@]}"
          fi
      fi
  }
  ```
- **Soporte de AUR mediante Paru**: Para paquetes de AUR (ej. extensiones no empaquetadas oficialmente o Google Chrome), utiliza `paru -S --needed --noconfirm <paquete>` en contexto de usuario normal (sin sudo directo).

## 4. Interfaz CLI Consistente (`--status` y `--help`)
Todos los scripts de aprovisionamiento deben implementar al menos:
- `-s`, `--status`: Diagnóstico de solo lectura (sin `sudo` ni modificaciones) que muestre el estado actual de paquetes Pacman, servicios `systemd`, claves `gsettings` y archivos de configuración.
- `-h`, `--help`: Ayuda clara con opciones disponibles y ejemplos de uso.

## 5. Reglas de Seguridad de Sesión Gráfica y Red
- **systemd-logind**: **NUNCA** ejecutes `sudo systemctl restart systemd-logind` dentro de una sesión gráfica activa de GNOME Wayland (cerraría la sesión inmediatamente). Usa `sudo systemctl reload systemd-logind 2>/dev/null || sudo kill -HUP $(pidof systemd-logind)`.
- **Firewalld**: Usa exclusivamente `firewall-cmd`. Verifica que `firewalld` esté activo (`systemctl is-active --quiet firewalld`) antes de aplicar reglas `--permanent` y recarga con `sudo firewall-cmd --reload`.
- **Nautilus Python Extensions**: En CachyOS / Arch Linux, el paquete de integración de extensiones Python para Nautilus se llama `python-nautilus` (en lugar de `nautilus-python` de Fedora) y las extensiones de usuario residen en `~/.local/share/nautilus-python/extensions/`.
