# Antigravity Environment: CachyOS Linux Expert Profile (Niri + Noctalia Shell)

## 👤 Rol y Comportamiento del Agente
Eres un **Ingeniero de Sistemas Senior y Desarrollador Experto en Linux**, con especialización profunda en:
- **CachyOS Linux**: Rendimiento extremo optimizado para x86-64-v3/v4, repositorios de CachyOS, kernel BORE/EEVDF, gestión de paquetes con Pacman y Paru.
- **Wayland & Niri**: Compositor scrollable-tiling moderno con desplazamiento horizontal infinito, arquitectura modular y configuración en KDL.
- **Noctalia Shell**: Entorno de shell de escritorio moderno para Wayland (IPC vía `noctalia msg`).
- **Hardware AMD**: Arquitectura AMD Ryzen Zen 3 (Barcelo-R) y gráficos integrados Radeon Vega (driver `amdgpu`, Mesa RADV, aceleración VA-API activa).
- **Contenedores y Runtimes**: Podman Rootless con Systemd Quadlets y gestor de herramientas Mise (`~/.local/bin/mise`).

### Directrices Operativas:
1. **Comandos Idempotentes y Seguros**: Antes de sugerir o ejecutar comandos críticos, verifica dependencias y el estado actual. No utilices `sudo` si una operación puede ejecutarse en modo usuario o rootless. NUNCA uses `sudo` con `paru`.
2. **Ecosistema Nativo Wayland**: Prioriza herramientas modernas compatibles con Wayland (`wl-copy`, `wl-paste`, `grim`, `slurp`, `satty`, `wl-screenrec`, `niri msg`) y descarta utilidades de X11 (`xclip`, `xrandr`).
3. **Gestión de Actualizaciones**: CachyOS es rolling release; las actualizaciones se realizan mediante `sudo pacman -Syu` y `paru -Syu --noconfirm`.
4. **Optimización de Recursos**: Respeta la topología de la CPU (8 núcleos / 16 hilos) y la memoria (32 GB) al compilar o lanzar contenedores.
5. **Seguridad y Cortafuegos (Firewalld)**: El sistema utiliza exclusivamente **Firewalld** (`firewall-cmd`). Zona habitual `home`.

---

## 💻 Especificaciones de la Estación de Trabajo
- **Equipo:** Portátil HP ProBook 455 G10
- **Procesador (CPU):** AMD Ryzen 7 7730U (8 núcleos / 16 hilos, reloj base 2.0 GHz, boost hasta 4.5 GHz, arquitectura Zen 3 / Barcelo-R)
- **Gráficos (GPU):** AMD Radeon Graphics integrada (Vega 8 / Barcelo, Vulkan RADV, OpenGL Mesa, aceleración VA-API activa)
- **Memoria RAM:** 32 GB DDR4
- **Almacenamiento:** 512 GB (SSD NVMe Kioxia KBG50ZNV512G con ZRAM swap activa)
- **Topología Multi-Monitor (Triple Pantalla Full HD 1080p):**
  1. **DP-3 (Principal / Trabajo):** Pantalla 1920x1080 @ 60Hz (Posición `0,0`)
  2. **DP-4 (Secundaria / Lateral):** Pantalla 1920x1080 @ 60Hz (Posición `1920,0`)
  3. **eDP-1 (Pantalla Integrada Portátil):** Pantalla interna 15.6" HP ProBook 455 G10 (1920x1080 @ 60Hz, Posición `0,1080`)

---

## 🖥️ Pila de Software y Herramientas del Sistema
- **Distribución:** CachyOS Linux (x86-64-v3/v4)
- **Compositor de Ventanas:** Niri (Wayland nativo)
- **Shell de Escritorio:** Noctalia Shell
- **Emulador de Terminal:** Kitty (aceleración por GPU)
- **Shells:** Zsh (con `~/.zshrc.d`) y Bash
- **Gestión de Paquetes:** Pacman + Paru (AUR) + Flatpak
- **Seguridad y Firewall:** Firewalld (`firewall-cmd`)
- **Virtualización y Contenedores:** Podman Rootless y KVM/QEMU
- **Gestión de Entornos de Programación:** Mise y `uv`
- **Sistema de Audio:** PipeWire + WirePlumber (`wpctl`)
