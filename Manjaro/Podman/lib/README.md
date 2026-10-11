# podman-utils CLI

`podman-utils` es una herramienta de línea de comandos diseñada para **orquestar y gestionar entornos de desarrollo con Podman, Quadlets y systemd** en modo *rootless* (sin privilegios de root) en Manjaro/Arch Linux.

En lugar de utilizar demonios pesados o scripts de Compose convencionales, gestiona cada contenedor, red y volumen como **servicios nativos de systemd en el espacio de usuario** (`systemctl --user`), permitiendo auto-recuperación, dependencias coordinadas y logs centralizados en `journalctl`.

---

## ⚡ Configuración Inicial (PATH)

Para poder ejecutar `podman-utils` desde cualquier directorio de tu terminal:

### 1. Añadir al PATH
Añade la ruta a tu archivo de configuración de shell (`~/.zshrc` si usas ZSH o `~/.bashrc` si usas Bash):

```bash
# En ~/.zshrc o ~/.bashrc
export PATH="$HOME/Workspace/Repositorios/Linux/Manjaro/Podman/lib:$PATH"
```

O bien, crea un alias directo:

```bash
alias podman-utils="$HOME/Workspace/Repositorios/Linux/Manjaro/Podman/lib/podman-utils.sh"
```

### 2. Recargar la terminal
```bash
source ~/.zshrc    # o source ~/.bashrc
```

---

## 📖 Referencia de Comandos

```text
Uso: podman-utils <comando> [opciones]
```

### 1. Gestión de Proyectos

| Comando | Descripción | Ejemplo |
| :--- | :--- | :--- |
| `create <plantilla> <nombre>` | Crea un nuevo proyecto desde una plantilla y lo enlaza a systemd. | `podman-utils create python-postgres mi-api` |
| `start <nombre>` | Inicia todos los servicios del proyecto de forma coordinada. | `podman-utils start mi-api` |
| `stop <nombre>` | Detiene limpiamente todos los contenedores del proyecto. | `podman-utils stop mi-api` |
| `restart <nombre>` | Reinicia todos los contenedores del proyecto. | `podman-utils restart mi-api` |
| `status <nombre>` | Muestra el estado de los servicios en systemd y contenedores en Podman. | `podman-utils status mi-api` |
| `logs <nombre> [servicio]` | Muestra los logs en tiempo real vía `journalctl` (del proyecto o de un servicio). | `podman-utils logs mi-api`<br>`podman-utils logs mi-api backend` |
| `destroy <nombre>` | Elimina completamente el proyecto: detiene servicios, borra datos, volúmenes y red. | `podman-utils destroy mi-api` |
| `link <nombre>` | Vuelve a enlazar los archivos Quadlet del proyecto a `~/.config/containers/systemd/`. | `podman-utils link mi-api` |
| `unlink <nombre>` | Desenlaza el proyecto de systemd (los archivos del proyecto se conservan). | `podman-utils unlink mi-api` |

---

### 2. Servicios Globales Compartidos

Servicios comunes reutilizables por varios proyectos (ubicados en `services-shared/`).

| Comando | Descripción | Ejemplo |
| :--- | :--- | :--- |
| `install-global <servicio>` | Instala y enlaza un servicio compartido global en systemd. | `podman-utils install-global traefik`<br>`podman-utils install-global postgres-global` |
| `uninstall-global <servicio>` | Detiene y desenlaza un servicio global de systemd. | `podman-utils uninstall-global traefik` |

---

### 3. Descubrimiento e Información

| Comando | Descripción |
| :--- | :--- |
| `list` | Lista todos tus proyectos creados y su estado actual (`[activo]` o `[detenido]`). |
| `list-templates` | Muestra la lista de plantillas disponibles y qué componentes incluyen. |

---

## 🛠️ Flujo de Trabajo Típico (Paso a Paso)

### 1. Ver qué plantillas tienes disponibles
```bash
podman-utils list-templates
```
*Salida:*
- `python-postgres`: API Python (FastAPI/Uvicorn) con recarga en vivo + PostgreSQL 17.
- `python-postgres-redis`: API Python + PostgreSQL + Redis (para Celery, caché, etc.).
- `fullstack`: Front (Node/Vite) + API Python + PostgreSQL + Keycloak Auth + Traefik Proxy.

### 2. Crear tu proyecto
```bash
podman-utils create python-postgres mi-tienda
```
Esto genera el directorio `Podman/projects/mi-tienda/` con todo preconfigurado y enlazado.

### 3. Configurar variables de entorno (opcional)
```bash
nano Podman/projects/mi-tienda/.env
```
Puedes ajustar contraseñas, nombres de base de datos o puertos si lo requieres.

### 4. Iniciar el entorno
```bash
podman-utils start mi-tienda
```

### 5. Desarrollar con Hot-Reload
Todo el código en `Podman/projects/mi-tienda/src/` está montado en vivo en el contenedor. Cualquier cambio que guardes en `main.py` se reflejará inmediatamente sin reiniciar el contenedor.

### 6. Ver logs mientras desarrollas
```bash
# Ver logs de todo el entorno:
podman-utils logs mi-tienda

# Ver solo los logs del backend:
podman-utils logs mi-tienda backend
```

### 7. Parar al terminar la jornada
```bash
podman-utils stop mi-tienda
```

---

## 🚀 Auto-arranque al Encender el PC (Opcional)

Si tienes un proyecto o base de datos que quieres que **esté siempre encendido** (incluso tras reiniciar el equipo), puedes habilitarlo directamente con systemd:

```bash
# Para un proyecto completo:
systemctl --user enable mi-tienda.target

# Para un servicio global (ej. Traefik):
systemctl --user enable traefik.service
```

Para desactivar el auto-arranque:
```bash
systemctl --user disable mi-tienda.target
```

---

## 📂 Estructura de Directorios

```text
Podman/
├── install/                  # Scripts de instalación de Podman y Quadlets
├── lib/
│   ├── podman-utils.sh       # CLI principal
│   └── README.md             # Esta documentación
├── services-shared/          # Definiciones de servicios globales (Traefik, Keycloak, etc.)
├── templates/                # Plantillas base (python-postgres, fullstack, etc.)
└── projects/                 # Directorio donde se crean tus proyectos locales
    └── mi-proyecto/
        ├── .env              # Variables de entorno
        ├── src/              # Tu código fuente (Hot-reload)
        ├── mi-proyecto-backend.container
        ├── mi-proyecto-postgres.container
        ├── mi-proyecto.network
        └── mi-proyecto.target
```
