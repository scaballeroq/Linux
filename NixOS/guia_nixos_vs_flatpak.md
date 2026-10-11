# ❄️ Guía Arquitectónica: Nix Packages vs Flatpak en NixOS

Esta guía explica la estrategia híbrida adoptada en este repositorio para combinar la pureza declarativa de **NixOS** con la conveniencia y aislamiento de **Flatpak / Flathub**.

---

## 🎯 1. Filosofía de Separación de Capas

En un sistema inmutable y declarativo como NixOS, la separación clara de responsabilidades garantiza estabilidad a largo plazo:

| Capa | Tecnología | Casos de Uso | Justificación |
|---|---|---|---|
| **Sistema Base & Kernel** | NixOS Modules (`modules/core.nix`, `hardware.nix`) | Kernel, systemd, ZRAM, PipeWire, Drivers AMD/Intel, SDDM, KDE Plasma 6 | Control 100% reproducible y rollbacks inmediatos. |
| **Herramientas de Desarrollo & CLI** | Nixpkgs & DevShells (`modules/development.nix`) | Git, GCC, Rust, Python, Node, Mise, Kitty, Fastfetch, Starship | Rendimiento nativo, integración con terminal y nix-ld. |
| **Servicios & Contenedores** | Podman Rootless + Quadlets (`modules/containers.nix`) | PostgreSQL, Redis, APIs, microservicios locales | Ecosistema OCI estándar compatible con Docker. |
| **Aplicaciones Gráficas de Terceros** | Flatpak / Flathub (`Setup/flatpak.sh`) | Spotify, Vesktop (Discord), VLC, OBS Studio, Obsidian | Aislamiento en sandbox, códecs propios y desacoplamiento del ciclo de vida del sistema. |

---

## 🛡️ 2. ¿Por qué usar Flatpak en NixOS?

1. **Aislamiento de Dependencias Propietarias**:
   Aplicaciones como Discord, Spotify o Steam plugins a menudo requieren dependencias complejas o binarios cerrados que cambian frecuentemente. En Flatpak, se ejecutan en un sandbox con sus propios runtimes (`org.freedesktop.Platform`).

2. **Permisos Granulares con Flatseal**:
   Mediante `Flatseal`, es posible controlar acceso a la cámara, micrófono, sistema de archivos o red sin modificar la configuración del sistema operativo.

3. **Sin Fricción de Dynamic Linking (ELF)**:
   Muchas aplicaciones precompiladas de Linux esperan la jerarquía FHS tradicional (`/lib64/ld-linux-x86-64.so.2`, `/usr/lib`). Aunque este repositorio incluye `nix-ld` para binarios CLI, los Flatpaks gráficos ya resuelven este entorno de ejecución internamente.

---

## 🚀 3. Comandos Útiles

```bash
# Diagnóstico de Flatpak y catálogo
just flatpak-status

# Instalación de la suite recomendada
just flatpak

# Actualización de Flatpaks
just flatpak-update

# Limpieza de runtimes huérfanos
just flatpak-clean
```
