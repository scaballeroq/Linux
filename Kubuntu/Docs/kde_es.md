---
sidebar_position: 8
---

# Personalización y Optimización de KDE Plasma en Kubuntu

Esta guía documenta la configuración, atajos y optimizaciones del entorno de escritorio **KDE Plasma 6 / 5** en Kubuntu.

---

## 1. Ajustes del Sistema y Apariencia (`kde-settings.sh`, `apariencia.sh`)

Kubuntu utiliza KDE Plasma como su entorno gráfico predeterminado. Los scripts de personalización automatizan:

1. **Tema Global y Estilo**:
   - Instalación de la suite de iconos **Papirus** y **Breeze**.
   - Activación automática del tema oscuro oficial **Breeze Dark** vía `lookandfeeltool`.

2. **Luz Nocturna (Night Color)**:
   - Configuración permanente en `3500K` para reducir la fatiga visual.
   - Control dinámico mediante atajos CLI: `kde-night-light-on` / `kde-night-light-off`.

3. **Perfiles de Energía (Powerdevil)**:
   - Prevención de suspensión automática cuando el equipo está conectado a corriente alterna (AC).
   - Ajuste inteligente de suspensión y atenuación de pantalla en batería.

4. **Atajos de Teclado**:
   - **Meta + T**: Lanzamiento directo de la terminal (Konsole).

---

## 2. Herramientas CLI para KDE Plasma

KDE Plasma permite modificar configuraciones en tiempo real mediante herramientas de consola:

```bash
# Leer/Escribir configuración en KDE Plasma 6
kwriteconfig6 --file kwinrc --group NightColor --key Active true

# Recargar compositor KWin sin reiniciar sesión
qdbus6 org.kde.KWin /KWin reconfigure

# Alternar temas Breeze desde la terminal
lookandfeeltool -a org.kde.breezedark.desktop   # Oscuro
lookandfeeltool -a org.kde.breeze.desktop       # Claro
```

---

## 3. Atajos de Shell integrados (`desktop_settings.sh`)

Al cargar el módulo de shell en `~/.bashrc.d/desktop_settings.sh`, se habilitan los siguientes atajos:

| Alias | Descripción |
| :--- | :--- |
| `kde-night-light-on` | Activa la Luz Nocturna en KDE Plasma. |
| `kde-night-light-off` | Desactiva la Luz Nocturna en KDE Plasma. |
| `kde-theme-dark` | Aplica el tema Breeze Dark. |
| `kde-theme-light` | Aplica el tema Breeze Light. |
| `kde-conf` | Abre las Preferencias del Sistema de KDE (`systemsettings`). |
| `kde-restart-kwin` | Recarga el compositor de ventanas KWin. |
