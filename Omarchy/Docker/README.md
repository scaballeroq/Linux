# Docker & Lazydocker Professional - Entorno de Desarrollo (Omarchy / Arch Linux)

Infraestructura moderna y profesional para desarrollo en contenedores utilizando **Docker + Docker Compose + Lazydocker**, con soporte para recarga en caliente (Hot Reload), proxy inverso Traefik, autenticación centralizada con Keycloak, bases de datos PostgreSQL y Redis, y CLI automatizado para gestión de proyectos.

---

## 📁 Estructura del Directorio

```
Docker/
├── README.md                 # Guía completa de uso y arquitectura
├── install/                  # Scripts de instalación y configuración
│   ├── docker-setup.sh       # Configuración inicial, permisos de usuario y systemd
│   └── lazydocker-setup.sh   # Configuración estética y atajos para Lazydocker
│
├── lib/
│   └── docker-utils.sh       # CLI principal para gestionar proyectos (alias: dutils / docker-utils)
│
├── templates/                # Plantillas listas para desarrollo
│   ├── python-postgres/      # FastAPI + PostgreSQL 17
│   ├── python-postgres-redis/# FastAPI + PostgreSQL 17 + Redis 7
│   └── fullstack/            # Node.js + FastAPI + PostgreSQL + Keycloak + Traefik
│
├── services-shared/          # Servicios globales reutilizables entre proyectos
│   ├── docker-compose.yml    # Stack global: Traefik v3, Keycloak 26, PostgreSQL 17, Redis 7
│   └── .env.example          # Variables de entorno para servicios globales
│
└── projects/                 # Tus proyectos locales (creados mediante templates)
```

---

## 🚀 Configuración y Puesta a Punto

> [!NOTE]
> **Omarchy** incluye **Docker**, **Docker Compose** y **Lazydocker** instalados por defecto en el sistema operativo.

### 1. Ejecutar el script de configuración inicial

Para habilitar el servicio de Docker, asignar permisos a tu usuario y preparar la red global:

```bash
just docker-setup
# o directamente:
./Docker/install/docker-setup.sh
```

Este script:
- Habilita e inicia el servicio `docker.service` en systemd.
- Agrega tu usuario al grupo `docker` para que no requieras `sudo`.
- Configura rotación de logs (50MB / 3 backups) y `live-restore` en `/etc/docker/daemon.json`.
- Crea la red puente global `proxy-net`.
- Inicializa la configuración de `lazydocker`.

### 2. Aplicar permisos de grupo

Si es la primera vez que se agrega tu usuario al grupo `docker`:

```bash
newgrp docker
# o reinicia tu sesión de usuario
```

### 3. Cargar funciones y alias en Bash

Si utilizas el módulo `Bash.Setup`:

```bash
source ~/.bashrc
# o usa el alias:
reload
```

---

## 🛠️ CLI `docker-utils` (o `dutils`)

El script `docker-utils.sh` te permite crear y controlar tus entornos rápidamente sin tener que recordar largas rutas ni parámetros de Docker Compose.

### Crear un nuevo proyecto

```bash
# Proyecto Python + PostgreSQL
dutils create python-postgres mi-api

# Proyecto Python + PostgreSQL + Redis
dutils create python-postgres-redis mi-api-redis

# Proyecto Fullstack completo (Frontend + Backend + Auth + Proxy)
dutils create fullstack mi-app
```

### Configurar credenciales y variables

Cada proyecto incluye su propio archivo `.env`:

```bash
nano Docker/projects/mi-api/.env
```

### Administrar el ciclo de vida del proyecto

```bash
# Iniciar proyecto en segundo plano
dutils start mi-api

# Recompilar e iniciar (si cambiaste Dockerfile o dependencias)
dutils start mi-api --build

# Ver estado de los contenedores
dutils status mi-api

# Ver logs en tiempo real (todos los servicios)
dutils logs mi-api

# Ver logs de un servicio específico
dutils logs mi-api backend
dutils logs mi-api postgres

# Ejecutar una shell dentro del contenedor
dutils exec mi-api backend /bin/bash

# Detener proyecto
dutils stop mi-api

# Reiniciar proyecto
dutils restart mi-api

# Bajar contenedores y redes
dutils down mi-api

# Eliminar proyecto completamente (contenedores, volúmenes y carpeta)
dutils destroy mi-api
```

---

## 📊 Lazydocker (Interfaz Gráfica en Terminal TUI)

Omarchy integra **Lazydocker** para monitorizar y gestionar contenedores con interfaz visual en el terminal.

### Formas de abrir Lazydocker:

1. **Directo desde cualquier lugar:**
   ```bash
   lzd
   # o
   lazydocker
   ```
2. **En el contexto de un proyecto específico:**
   ```bash
   dutils lazy mi-api
   ```
3. **En el contexto de los servicios globales:**
   ```bash
   dutils lazy shared
   ```

### Atajos útiles en Lazydocker:
- `m`: Ver logs del contenedor seleccionado
- `e`: Abrir terminal / shell interactiva
- `r`: Reiniciar contenedor
- `d`: Detener contenedor
- `s`: Iniciar contenedor
- `c`: Ejecutar comando personalizado (Bash / Sh)
- `x`: Menú de acciones del contenedor
- `b`: Limpiar imágenes/contenedores huérfanos (Prune)
- `q`: Salir de Lazydocker

---

## 📦 Plantillas Disponibles (Templates)

### 1. `python-postgres`
- **Backend:** Python 3.13 con FastAPI y Uvicorn (Hot Reload automático en `./src/main.py`).
- **Base de Datos:** PostgreSQL 17 Alpine con volumen persistente.
- **Ideal para:** Microservicios, APIs REST rápidas.

### 2. `python-postgres-redis`
- **Backend:** FastAPI con soporte para PostgreSQL y cliente Redis.
- **Base de Datos:** PostgreSQL 17 Alpine.
- **Caché / Colas:** Redis 7 Alpine (`appendonly yes`).
- **Ideal para:** APIs con rate limiting, caché en memoria o colas Celery/Arq.

### 3. `fullstack`
- **Proxy Inverso:** Traefik v3.2 con Dashboard en `http://localhost:8080`.
- **Frontend:** Node.js 22 + Vite dev server en `http://app.mi-app.localhost/` (puerto 3000).
- **Backend:** FastAPI en `http://api.mi-app.localhost/` (puerto 8000).
- **Autenticación:** Keycloak 26 en `http://auth.mi-app.localhost/auth/` (puerto 8083).
- **Base de Datos:** PostgreSQL 17 Alpine.
- **Ideal para:** Aplicaciones completas con autenticación OAuth2/OIDC y enrutamiento por subdominios locales.

---

## 🌐 Servicios Globales Compartidos (`services-shared`)

Si deseas tener un Traefik, PostgreSQL, Redis o Keycloak compartidos entre múltiples proyectos sin levantarlos por cada repositorio:

```bash
# Iniciar servicios globales
dutils shared up

# Ver estado
dutils shared status

# Ver logs
dutils shared logs

# Abrir en Lazydocker
dutils lazy shared

# Detener servicios globales
dutils shared down
```

---

## ⌨️ Funciones y Atajos en Bash (`Bash.Setup`)

El módulo `Bash.Setup/docker-functions.sh` incluye los siguientes atajos en tu terminal:

| Atajo / Función | Comando Equivalente / Descripción |
| :--- | :--- |
| `d` | `docker` |
| `dc` | `docker compose` |
| `dcu` | `docker compose up -d` |
| `dcd` | `docker compose down` |
| `dcr` | `docker compose restart` |
| `dcl` | `docker compose logs -f` |
| `dps` | `docker ps` |
| `dpsa` | `docker ps -a` |
| `dimg` | `docker images` |
| `dsh <contenedor> [shell]` | Entra a la consola interactiva del contenedor (`/bin/bash` o `/bin/sh`) |
| `dlogs <contenedor>` | Sigue los logs en tiempo real del contenedor |
| `drmf <contenedor>` | Detiene y elimina un contenedor |
| `dpsf` | Tabla limpia y formateada de contenedores activos |
| `dpsaf` | Tabla formateada de todos los contenedores |
| `dstats` | Estadísticas formateadas de CPU, Memoria e I/O |
| `dclean-total` | Limpieza total de contenedores, imágenes y volúmenes huérfanos |
| `lzd` o `ldocker` | Abre **Lazydocker** |
| `dutils` o `docker-utils`| Invoca el CLI de utilidades de Docker |

---

## 🔧 Resolución de Problemas (Troubleshooting)

### Error de permisos: `permission denied while trying to connect to the docker API`
Ejecuta en tu terminal actual:
```bash
newgrp docker
```
O verifica que tu usuario esté en el grupo:
```bash
sudo usermod -aG docker "$USER"
```

### El servicio de Docker no está activo
Inicia y habilita el daemon:
```bash
sudo systemctl enable --now docker.service
```

### Puerto ocupado
Comprueba qué proceso ocupa el puerto:
```bash
ss -tlnp | grep <puerto>
```
Modifica el puerto correspondiente en el archivo `.env` de tu proyecto (por ejemplo `BACKEND_PORT=8001`).
