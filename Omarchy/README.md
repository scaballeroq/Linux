# Omarchy 4.5 ("Quattro RS") - Arch Linux & Hyprland Workstation

Perfil de aprovisionamiento, dotfiles y optimización de **Omarchy 4.5** para el portátil **HP ProBook 455 G10** dentro del monorepo Linux.

---

## 💻 Especificaciones de la Estación de Trabajo

- **Dispositivo:** Portátil HP ProBook 455 G10
- **Procesador (CPU):** AMD Ryzen 7 7730U (8 núcleos / 16 hilos, Zen 3 / Barcelo-R, boost hasta 4.5 GHz)
- **Gráficos (GPU):** AMD Radeon Graphics integrada (Vega 8, driver `amdgpu`, Mesa RADV Vulkan, VA-API hardware decoding)
- **Memoria RAM:** 32 GB DDR4 (3200 MHz) con ZRAM swap dinámico (16 GB, compresión `zstd`)
- **Almacenamiento:** SSD NVMe 512 GB Kioxia KBG50ZNV512G con `fstrim.timer` activo
- **Audio:** PipeWire + WirePlumber (`wpctl`)
- **Cortafuegos:** **Firewalld** (`firewall-cmd`) exclusivo (Zona `home`, reglas para Podman, Libvirt virbr0, Cockpit y dev)
- **Entorno Gráfico:** Wayland Nativo (Hyprland + Omarchy Shell / Quickshell)

---

## 🖥️ Topología Multi-Monitor Triple Pantalla (Full HD 1080p @ 60Hz)

```text
               +---------------------------+  +---------------------------+
               |      LG 32" (DP-3)        |  |      SONY 32" (DP-4)      |
               |        (Principal)        |  |        (Secundaria)       |
               |      1920x1080 @ 60Hz     |  |      1920x1080 @ 60Hz     |
               |      Posición: 0,0        |  |      Posición: 1920,0     |
               |   [ Workspaces: 1..5 ]    |  |   [ Workspaces: 6 y 7 ]   |
               +---------------------------+  +---------------------------+
               |    PORTÁTIL 15.6" (eDP-1) |
               |      1920x1080 @ 60Hz     |
               |      Posición: 0,1080     |
               |   [ Workspaces: 8 y 9 ]   |
               +---------------------------+
```

---

## ✨ Novedades Clave de Omarchy 4.5 ("Quattro RS")

1. **Gestión de Layout por Workspace (`Super + L`):** Alterna instantáneamente cada escritorio entre **Tiling (mosaico)**, **Scrolling** y **Floating Desktop Mode**.
2. **Modo Escritorio Flotante:** Barras de título tematizadas, dock inferior para lanzar/fijar aplicaciones y minimización de ventanas con **`Super + M`**.
3. **Lanzador Visual Grid (`Super + Space`):** Cuadrícula visual de aplicaciones con búsqueda indexada.
4. **Terminal Desplegable (`Super + ~`):** Acceso rápido a una terminal flotante.
5. **Localización a 50 Idiomas:** Soporte nativo de traducción y métodos de entrada (`omarchy language <code>`).
6. **Instalador de Alta Velocidad:** Despliegue en cuestión de segundos sobre base Arch Linux.

---

## 🚀 Despliegue y Orquestación con `just`

El archivo [`justfile`](file:///home/caballero/Proyectos/Linux/Omarchy/justfile) automatiza la configuración completa del sistema de forma modular e idempotente:

```bash
# Ver todas las recetas disponibles
just

# Aprovisionamiento completo del sistema
just setup-all

# Diagnóstico de telemetría del equipo
just status

# Ver estado de pantallas en Hyprland
just monitors
```

### Recetas Individuales

| Comando | Descripción |
| :--- | :--- |
| `just post-install` | Microcode AMD, Mesa RADV, aceleración VA-API, ZRAM, brillo y utilidades |
| `just security` | Cortafuegos Firewalld exclusivo, DNS-over-TLS y endurecimiento sysctl |
| `just fonts` | Instalación de Nerd Fonts (JetBrainsMono, FiraCode, CascadiaCode...) |
| `just bash-setup` | Integración de módulos de Bash (`~/.bashrc.d`) |
| `just virtualization` | KVM/QEMU, Libvirt, virt-manager y aceleración nested KVM |
| `just cockpit` | Panel web de administración Cockpit (puerto 9090 con Firewalld) |
| `just mise` | Instalador del gestor de runtimes Mise |
| `just languages` | Node.js LTS, Python/uv, Rust (cargo-binstall), .NET LTS y OpenJDK |
| `just ides` | Neovim (LazyVim Wayland), VS Code, Google Antigravity y OpenCode |
| `just steam` | Gaming nativo con Steam, GameMode, MangoHud y Vulkan de 32/64 bits |
| `just docker-setup` | Permisos rootless, daemon.json optimizado y red global de Docker |

---

## 🔒 Arquitectura de Seguridad (Firewalld Exclusivo)

Siguiendo el estándar del monorepo, **UFW y reglas crudas de iptables están estrictamente descartados**:
- Motor: `firewalld` con zona por defecto `home`.
- Servicios expuestos localmente: SSH (22), Cockpit (9090), Vite (5173), Next.js (3000), FastAPI (8000), Omarchy/KDE Connect (1714-1764 tcp/udp).
- Redes de virtualización y contenedores: `virbr0` en zona `libvirt` y `docker0`/`podman+` en zona `trusted`.
- Privacidad: DNS-over-TLS mediante `systemd-resolved` con Quad9 y Cloudflare.

---

## 📚 Documentación Adicional

- [Configuración de Monitores y Workspaces en Hyprland](file:///home/caballero/Proyectos/Linux/Omarchy/CONFIGURACION_MONITORES_HYPRLAND.md)
- [Reglas y Perfil del Agente Omarchy](file:///home/caballero/Proyectos/Linux/Omarchy/.agents/AGENTS.md)
