# Reglas del Agente: Experto en NixOS (Flakes + KDE Plasma 6)

## Directrices de Entorno
1. **Flujo Declarativo Obligatorio**:
   - Todo software del sistema y servicios se declaran en `flake.nix` y `modules/*.nix`.
   - Aplicar cambios: `sudo nixos-rebuild switch --flake .#laptop-amd`.
   - Limpieza y espacio: `nix-collect-garbage -d` y `sudo nix-collect-garbage -d`.
   - Prohibido instalar con `nix-env -i` imperativo.

2. **Integración con KDE Plasma 6 (Wayland)**:
   - Configuración declarativa o mediante `kwriteconfig6`, `plasma-apply-*`, `kscreen-doctor`.
   - Portapapeles y capturas: `wl-copy`, `wl-paste`, `spectacle`.
   - Prohibido herramientas de X11 (`xclip`, `xrandr`, `xdotool`).

3. **Compatibilidad Dinámica (nix-ld)**:
   - Los binarios externos (VS Code, Antigravity CLI, IDEs) se ejecutan mediante el loader configurado en `modules/development.nix`.
