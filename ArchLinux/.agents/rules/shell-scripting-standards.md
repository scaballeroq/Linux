# Estándares de Shell Scripting (ArchLinux)

Esta regla define los estándares de calidad, robustez, seguridad e idempotencia que deben seguir todos los scripts Bash dentro del subproyecto `ArchLinux`.

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
- NUNCA crees archivos pertenecientes a `root` dentro de `$TARGET_HOME`.

---

## 3. Idempotencia y Paquetes en Arch
```bash
is_pkg_installed() {
    pacman -Q "$1" >/dev/null 2>&1
}
```
- Comprueba siempre antes de añadir líneas a archivos de configuración (`grep -q`).
- `mkdir -p` y `ln -sf` en todas las operaciones del sistema de archivos.

---

## 4. Banderas `--status` y `--help`
Todo script de aprovisionamiento o configuración del sistema en `Setup/`, `Virtualizacion/`, o `Podman/` debe implementar:
- `--status`, `-s`, `--check`: Diagnóstico en modo solo lectura.
- `--help`, `-h`: Documentación clara de parámetros y requisitos.

---

## 5. Salida Visual
- `🚀` : Inicio de proceso.
- `ℹ️` : Información de contexto.
- `✅` : Operación exitosa.
- `⚡` : Ajuste de rendimiento (ZRAM, AMD).
- `⚠️` : Advertencia no bloqueante.
- `❌` : Error crítico.
