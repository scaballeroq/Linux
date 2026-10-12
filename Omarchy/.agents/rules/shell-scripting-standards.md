# Estándares de Shell Scripting (Omarchy)

Esta regla define los estándares de calidad, robustez, seguridad e idempotencia que deben seguir todos los scripts Bash dentro del subproyecto `Omarchy`.

---

## 1. Modo Estricto y Cabeceras
```bash
#!/bin/bash
set -euo pipefail
```

---

## 2. Gestión de Privilegios y Usuario Real
```bash
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)
[ -z "$TARGET_HOME" ] && TARGET_HOME="$HOME"
TARGET_UID=$(id -u "$TARGET_USER" 2>/dev/null || echo "1000")
```

---

## 3. Idempotencia y Paquetes en Arch
```bash
is_pkg_installed() {
    pacman -Q "$1" >/dev/null 2>&1
}
```

---

## 4. Banderas `--status` y `--help`
Todo script de setup debe implementar `--status` y `--help`.

---

## 5. Salida Visual
- `🚀` : Inicio de proceso.
- `ℹ️` : Información de contexto.
- `✅` : Operación exitosa.
- `⚡` : Rendimiento / ZRAM.
- `⚠️` : Advertencia.
- `❌` : Error crítico.
