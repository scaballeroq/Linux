---
sidebar_position: 3
---

# Configuración de Bash en Fedora 44

Esta guía detalla la configuración del entorno de terminal (Bash) y las utilidades integradas en los scripts modulares de la carpeta `Bash.Setup`.

---

## 1. Carga Modular del Entorno

Los scripts se cargan de forma dinámica añadiendo el siguiente bloque al archivo `~/.bashrc`:

```bash
if [ -d "$HOME/.bashrc.d" ]; then
    for script in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$script" ] && source "$script"
    done
    unset script
fi
```

---

## 2. Atajos y Aliases del Sistema (`aliases.sh`)

Sustituye comandos estándar por alternativas enriquecidas, seguras y de monitorización:

### 📦 Atajos de Paquetes con DNF5
Los comandos principales de DNF5 cuentan con alias simplificados:
- `update` -> `sudo dnf5 update`
- `upgrade` -> `sudo dnf5 upgrade -y`
- `install` -> `sudo dnf5 install`
- `remove` -> `sudo dnf5 remove`
- `search` -> `dnf5 search`
- `clean` -> `sudo dnf5 autoremove -y && sudo dnf5 clean`
- `list` -> `dnf5 list --upgradable`

### 🐧 Monitor de Kernel (`check-kernel`)
La función y alias **`check-kernel`** consulta en tiempo real la API de `kernel.org` y la compara con la versión activa de tu sistema (`uname -r`):
```bash
check-kernel
```
Si detecta una versión estable más reciente en `kernel.org`, te avisa para que puedas ejecutar `just build-kernel`.

### 🛡️ Seguridad
- `rm -i`, `cp -i`, `mv -i` (confirmación interactiva).
- Medida `--preserve-root` activada en comandos destructivos.
