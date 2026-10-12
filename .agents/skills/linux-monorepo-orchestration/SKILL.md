---
name: linux-monorepo-orchestration
description: >-
  Use this skill when auditing, validating, executing, or navigating cross-distribution configurations, Justfile recipes, Bash.Setup/Zsh.Setup shell dotfiles, Git repository status, or system setup scripts across the Linux monorepo.
---

# Linux Monorepo Orchestration & Maintenance Skill

Esta skill contiene los procedimientos y flujos de trabajo estándar para operar, validar y sincronizar configuraciones en el repositorio unificado multi-distribución **Linux Monorepo**.

---

## 1. Mapa de Rutas del Monorepo

Cada distribución conserva una estructura modular consistente:
- **`Bash.Setup/` o `Zsh.Setup/`**: Módulos de configuración de shell (`aliases.sh`, `environment.sh`, `functions.sh`, `history.sh`, `options.sh`, `podman-functions.sh`, `rclone_aliases.sh`).
- **`Setup/`**: Scripts de aprovisionamiento del sistema operativo, kernels, repositorios y temas gráficos.
- **`Podman/`**: Despliegues de contenedores rootless, perfiles de desarrollo y Quadlets de systemd.
- **`Virtualizacion/`**: Scripts para pila KVM/QEMU/Libvirt y aceleración de virtualización.
- **`ProgrammingLanguages/`**: Integración con Mise, Python (`uv`), Node.js, Rust, Go y .NET.
- **`justfile`**: Punto de entrada de comandos y automatizaciones locales de cada subdirectorio.

---

## 2. Auditoría y Validación de Scripts de Shell

Para validar la sintaxis e idempotencia de scripts en cualquier subdirectorio:

```bash
# Comprobación de sintaxis bash en todo un subdirectorio
find <directorio> -type f -name "*.sh" -exec bash -n {} +

# Detección de permisos de ejecución en scripts de Setup y Bash.Setup
find <directorio> -type f -name "*.sh" ! -executable

# Comprobación con shellcheck si está disponible
shellcheck <directorio>/Setup/*.sh 2>/dev/null || true
```

---

## 3. Ejecución de Tareas mediante Just

La mayoría de distribuciones incluyen un archivo `justfile` para automatizar tareas repetitivas:

```bash
# Listar recetas disponibles en una distribución concreta
just -d <directorio> --list

# Ejecutar diagnóstico o estado (receta de comprobación habitual)
just -d <directorio> status 2>/dev/null || just -d <directorio> check 2>/dev/null

# Ejecutar una receta específica dentro de un subdirectorio
just -d KDEDebianTesting update
```

---

## 4. Sincronización y Comparación entre Distribuciones

Para auditar diferencias entre dotfiles de dos distribuciones (ej. `DebianTesting` vs `KDEDebianTesting` o `Fedora` vs `Ubuntu`):

```bash
# Comparar aliases de shell
diff -u Fedora/Bash.Setup/aliases.sh Ubuntu/Bash.Setup/aliases.sh || true

# Comparar recetas de justfile
diff -u KDEDebianTesting/justfile OpenSuseTumbleweed/justfile || true
```

---

## 5. Control de Git en el Monorepo

```bash
# Estado general de cambios en el monorepo
git status -s

# Ver cambios pendientes en un subdirectorio concreto
git status -- Fedora/

# Ver último commit que afectó a una distribución específica
git log -n 1 -- <directorio>/
```
