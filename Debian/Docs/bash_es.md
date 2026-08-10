---
sidebar_position: 3
---

# Configuración de Bash en Debian 13

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

### 📦 Atajos de Paquetes con Nala
Si `nala` está instalado en el sistema, los comandos principales de APT se redirigen a Nala manteniendo `apt` nativo y 100% activo:
- `update` -> `sudo nala update`
- `upgrade` -> `sudo nala upgrade -y`
- `install` -> `sudo nala install`
- `remove` -> `sudo nala remove`
- `search` -> `nala search`

### 🐧 Monitor de Kernel (`check-kernel`)
La función y alias **`check-kernel`** consulta en tiempo real la API de `kernel.org` y la compara con la versión activa de tu sistema (`uname -r`):
```bash
check-kernel
```
Si detecta una versión estable más reciente en `kernel.org`, te avisa para que puedas ejecutar `just build-kernel`.

### 🛡️ Seguridad
- `rm -i`, `cp -i`, `mv -i` (confirmación interactiva).
- Medida `--preserve-root` activada en comandos destructivos.
