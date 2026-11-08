# Estándares de Shell Scripting (KDEDebianTesting)

Esta regla define los estándares de calidad, robustez, seguridad e idempotencia que deben seguir todos los scripts Bash dentro del repositorio `KDEDebianTesting`.

---

## 1. Modo Estricto y Cabeceras
Todo script ejecutable debe comenzar con el shebang estándar y el modo estricto de Bash:

```bash
#!/bin/bash
set -euo pipefail
```
- `-e`: Detiene la ejecución inmediatamente ante cualquier error no capturado.
- `-u`: Falla si se intenta utilizar una variable no inicializada.
- `-o pipefail`: Propaga el código de salida de un comando que falle en cualquier punto de una tubería (`pipe`).

---

## 2. Gestión de Privilegios y Usuario Real
Dado que muchos scripts configuran aspectos del sistema (`sudo`) pero interactúan con archivos en el directorio del usuario (`$HOME`, `~/.config`, `~/.bashrc.d`):

```bash
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
[ -z "$TARGET_HOME" ] && TARGET_HOME="$HOME"
TARGET_UID=$(id -u "$TARGET_USER" 2>/dev/null || echo "1000")
```

### Reglas críticas de permisos:
- **NUNCA** crees archivos o directorios en `$TARGET_HOME` pertenecientes a `root`. Si un comando debe correr como el usuario, usa `sudo -u "$TARGET_USER"` o asigna la propiedad correspondiente con `chown -R "$TARGET_USER:$TARGET_USER"`.
- Para interactuar con la sesión de systemd o D-Bus del usuario:
  ```bash
  sudo -u "$TARGET_USER" env XDG_RUNTIME_DIR="/run/user/$TARGET_UID" dbus-update-activation-environment --systemd ...
  ```

---

## 3. Idempotencia Obligatoria
Cualquier script debe ser seguro de ejecutar múltiples veces sin duplicar entradas ni producir errores:

1. **Comprobación de paquetes**:
   ```bash
   is_pkg_installed() {
       local pkg="$1"
       dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"
   }
   ```
2. **Edición de ficheros de configuración**:
   - Usa `grep -q` antes de añadir líneas a archivos de configuración.
   - Si usas `sed -i`, mantén expresiones regulares que sustituyan o actualicen valores sin duplicarlos.
3. **Directorios y enlaces**:
   - `mkdir -p` siempre.
   - `ln -sf` para enlaces simbólicos idempotentes.

---

## 4. Soporte Obligatorio de `--status` y `--help`
Todo script de aprovisionamiento o configuración del sistema en `Setup/`, `Virtualizacion/`, o `Podman/` debe incorporar un despachador de argumentos que soporte:
- `--status`, `-s`, `--check`: Diagnóstico en modo solo lectura que valida si la configuración, módulos, servicios o paquetes están aplicados correctamente.
- `--help`, `-h`: Documentación clara de las opciones, propósito del script y requisitos del sistema.

---

## 5. Formato de Salida y Feedback Visual
Utiliza la convención unificada de prefijos visuales del repositorio para facilitar el seguimiento visual:
- `🚀` : Inicio de un proceso o fase general.
- `ℹ️` : Información de contexto o pasos numerados (`[1/5]`).
- `✅` : Comprobación o tarea completada exitosamente.
- `⚡` : Detección o ajuste de alto rendimiento (ZRAM, AMD AVIC, NoCoW, etc.).
- `⚠️` : Advertencia que no bloquea la ejecución pero requiere atención.
- `❌` : Error crítico o componente faltante.

---

## 6. Ecosistema Debian Testing & KDE Plasma 6
- **Wayland y Qt 6**: Prioriza `kwriteconfig6`, `plasma-apply-*`, `kscreen-doctor`, `qdbus` y descarta herramientas de X11 (`xclip`, `xdotool`, `xrandr`).
- **Seguridad**: Reglas de red exclusivas mediante `firewall-cmd`. Prohibido el uso de `ufw` o reglas crudas de `iptables`.
- **APT seguro**: Actualizaciones automáticas con `apt-get install -y --no-install-recommends` o control explícito de dependencias.
