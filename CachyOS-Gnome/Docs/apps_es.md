---
sidebar_position: 9
---

# Aplicaciones, Flatpak y Juegos en CachyOS Workstation

Esta guía detalla la instalación de aplicaciones de escritorio, herramientas visuales y plataformas de juegos en **CachyOS Workstation (GNOME Wayland)** combinando **Pacman / Paru**, los repositorios optimizados en **x86-64-v3 / multilib** y **Flatpak / Flathub**.

---

## 1. Catálogo Desacoplado Flatpak (`./Setup/flatpak.sh`)

El script `./Setup/flatpak.sh` habilita el repositorio oficial **Flathub** sin filtros y despliega perfiles modulares de aplicaciones con overrides para GNOME (cursores Bibata, integración PipeWire, Wayland y aceleración gráfica GPU/DRI):

```bash
./Setup/flatpak.sh            # Perfil estándar recomendado
./Setup/flatpak.sh --all      # Catálogo completo (Esenciales, Desarrollo, Multimedia, Productividad)
./Setup/flatpak.sh --status   # Diagnóstico rápido del catálogo instalado
```

---

## 2. Steam, GameMode, MangoHud y Proton-GE (`./Setup/steam.sh`)

En **CachyOS Workstation**, Steam se instala de forma nativa desde los repositorios oficiales de CachyOS junto con el soporte multilib de 32 bits (`lib32-vulkan-radeon`, `lib32-mesa`), **GameMode**, **MangoHud** y la capa de compatibilidad **Proton-GE**:

```bash
# Instalación automatizada mediante el script del repositorio o Justfile:
./Setup/steam.sh
# o bien:
just steam
```

### Comandos manuales equivalentes (Pacman):
```bash
sudo pacman -S --needed --noconfirm steam gamemode mangohud lib32-vulkan-radeon lib32-mesa lib32-pipewire
flatpak install --user -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE
```
