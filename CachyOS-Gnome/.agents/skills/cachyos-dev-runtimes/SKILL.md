---
name: cachyos-dev-runtimes
description: Gestión de lenguajes de programación y runtimes con Mise (Node.js, Rust, Go, Java, .NET, Angular), entornos aislados de Python con uv respetando PEP 668 en CachyOS Workstation con GNOME, orquestación mediante Justfile y configuración de IDEs (Google Antigravity, OpenCode).
---

# Entornos de Desarrollo, Lenguajes y Runtimes (Mise, uv, Just) - CachyOS Workstation

Esta skill define las pautas, herramientas y flujos de trabajo estándar para la gestión de lenguajes de programación, entornos virtuales desacoplados y automatización de compilaciones en **CachyOS Workstation (GNOME Shell Wayland)**.

---

## 1. Filosofía de Aislamiento y Cumplimiento de PEP 668

CachyOS y Arch Linux protegen la integridad de los paquetes del sistema y de los módulos de GNOME Shell contra modificaciones involuntarias mediante la directiva **PEP 668** (`/usr/lib/python3.*/EXTERNALLY-MANAGED`).

### Principios Fundamentales:
- **NUNCA** utilices `sudo pip install` ni `pip install` globalmente contra `/usr/bin/python3`.
- Todo desarrollo en Python se realiza dentro de entornos virtuales creados y gestionados por **`uv`** (`pacman -S uv` o instalador oficial).
- La gestión de versiones de herramientas y lenguajes polyglot (Node.js, Rust, Java, .NET, Go) se realiza a través de **Mise** (`~/.local/bin/mise`).

---

## 2. Gestor Políglota de Versiones: Mise

Instalado en `~/.local/bin/mise` y configurado con paralelismo adaptado a los 16 hilos del Ryzen 7 7730U (`jobs = 16`):
```bash
# Diagnóstico de Mise
mise doctor
mise ls

# Instalación de plugins/runtimes
mise use -g node@lts
mise use -g rust@latest
mise use -g go@latest
```

---

## 3. Python Aislado con `uv`

- Inicialización de proyectos ultrarrápidos: `uv init mi-proyecto`
- Creación de entornos virtuales: `uv venv`
- Instalación de dependencias: `uv pip install <paquetes>`
- Variable `UV_LINK_MODE="copy"` en `~/.config/environment.d/` para compatibilidad transparente con snapshots de almacenamiento.

---

## 4. Orquestación con `just`

Todas las tareas de configuración y compilación se orquestan mediante el `justfile` local:
```bash
just --list
just status
just setup-all
```
