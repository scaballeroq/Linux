# Estándares de Shell Scripting (NixOS)

Esta regla define los estándares de calidad, robustez, seguridad e idempotencia que deben seguir todos los scripts auxiliares dentro de `NixOS`.

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

## 3. Idempotencia y Flakes
- Verificar sintaxis Nix: `nix flake check`.
- Banderas `--status` y `--help` en scripts complementarios de `Bash.Setup/` o `Setup/`.

---

## 4. Salida Visual
- `🚀` : Inicio de proceso / reconstrucción.
- `ℹ️` : Información de contexto.
- `✅` : Operación exitosa.
- `⚡` : Rendimiento / ZRAM / nix-store.
- `⚠️` : Advertencia.
- `❌` : Error crítico.
