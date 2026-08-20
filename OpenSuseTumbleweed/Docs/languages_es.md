---
sidebar_position: 3
---

# Lenguajes de Programación y Runtimes en OpenSUSE Tumbleweed

Esta guía detalla la instalación y gestión de entornos de desarrollo y lenguajes en `ProgrammingLanguages/`.

La gestión de versiones se realiza principalmente mediante **Mise** (herramienta moderna en Rust), complementada con paquetes oficiales de Zypper.

---

## 1. Gestor de Versiones Mise (`mise.sh`)

Permite instalar y alternar versiones de múltiples lenguajes:

```bash
just mise
```

---

## 2. Lenguajes Soportados

- **Node.js LTS (22)** (`nodejs.sh`): Incluye `npm` y `corepack` (`pnpm`, `yarn`).
  ```bash
  just node
  ```
- **Python 3.13** (`python.sh`): Cabeceras C y desarrollo con soporte pip.
  ```bash
  just python
  ```
- **Rust Toolchain** (`rust.sh`): `rustup`, `cargo` y `cargo-binstall`.
  ```bash
  just rust
  ```
- **.NET SDK 10** (`dotnet.sh`):
  ```bash
  just dotnet
  ```
- **Java OpenJDK 21** (`java.sh`): OpenJDK 21 y herramientas NSS para certificados digitales y AutoFirma.
  ```bash
  just java
  ```
- **Herramientas de IA y Web**:
  - Gemini CLI: `just gemini`
  - Angular CLI: `just angular`

---

## 3. Instalación de Todos los Lenguajes

```bash
just languages
```
