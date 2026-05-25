---
sidebar_position: 9
---

# Applications and Games on Kubuntu

This guide details the installation of desktop applications, utility tools, and digital gaming platforms managed in the `Apps` and `Juegos` folders.

The Kubuntu ecosystem allows installing system utilities through traditional package managers (APT) and application environments like gaming platforms in sandbox environments using universal formats (Flatpak).

---

## 1. Meld: Visual Diff and Merge Tool (`meld.sh`)

Meld is a graphical tool for comparing and merging files, directories, and version control repositories. It is highly recommended for visual resolution of Git merge conflicts.

* **Installation**:
  ```bash
  sudo apt update
  sudo apt install -y meld
  ```

---

## 2. Steam: Gaming Platform and Compatibility (`steam.sh`)

To ensure the host operating system remains stable and avoid adding 32-bit (i386) multi-arch libraries at the system APT level, Steam is installed as a sandboxed application using Flatpak/Flathub.

1. **Steam Installation**:
   ```bash
   flatpak install flathub com.valvesoftware.Steam
   ```

2. **Compatibility Layer (Proton-GE)**:
   Installs **Proton GloriousEggroll (Proton-GE)** to improve game performance, compatibility, and stability for running Windows games on Linux:
   ```bash
   flatpak install flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE
   ```

---

## Verification

To verify that the applications are correctly installed:

- **Meld**: Run `meld` in the terminal or launch it from your desktop application menu.
- **Steam**: Open Steam from your desktop environment launcher (e.g. KDE Application Launcher). Once logged in, you can activate Proton-GE in Steam's compatibility settings (Steam > Settings > Compatibility > Enable Steam Play).
