# 🐧 Podman Professional - Quadlets & systemd

Gestión avanzada de contenedores rootless con **Podman + Quadlets + systemd** para **Soplos Linux Tyson** (Debian Testing). Desarrollado para APIs FastAPI, PostgreSQL, Redis, proxies inversos Traefik y autenticación OIDC/OAuth2 con Keycloak.

---

## 📁 Estructura del Proyecto

```
Podman/
├── install/                      # Scripts de instalación y aprovisionamiento
│   ├── podman-install.sh         # Instala Podman rootless, Netavark y dependencias
│   └── quadlets-setup.sh         # Configura el entorno systemd y directorios
│
├── lib/
│   └── podman-utils.sh           # CLI unificado para gestionar el ciclo de vida
│
├── templates/                    # Plantillas de proyectos listas para usar
│   ├── python-postgres/          # FastAPI + PostgreSQL (con volumen persistente)
│   ├── python-postgres-redis/    # FastAPI + PostgreSQL + Redis (Caché / Celery)
│   └── fullstack/                # Vue 3 (Vite) + FastAPI + PostgreSQL + Traefik + Keycloak
│
├── services-shared/              # Servicios globales multi-proyecto
│   ├── proxy-net.network         # Red compartida Quadlet
│   ├── traefik.container         # Proxy inverso con autodescubrimiento
│   ├── traefik-config.volume     # Volumen de configuración de Traefik
│   ├── postgres-global.container # PostgreSQL compartido multi-tenant
│   ├── postgres-global-data.volume
│   ├── redis-global.container    # Redis compartido
│   ├── redis-global-data.volume
│   └── keycloak.container        # Servidor central de autenticación OIDC
│
└── projects/                     # Tus proyectos locales (ignorado en git)
```

---

## 🚀 Instalación y Configuración Inicial

### 1. Instalar Podman y dependencias del sistema

```bash
./install/podman-install.sh
```

Configura Podman en modo **rootless**, habilitando:
- Backend de red **Netavark** y resolución DNS **Aardvark**.
- Driver de almacenamiento **overlayfs**.
- Persistencia de procesos de usuario vía `loginctl enable-linger`.
- Socket de Podman compatible con la API de Docker (`podman.socket`).
- Exportación automática de `DOCKER_HOST` en `~/.bashrc` y `~/.zshrc`.

### 2. Configurar el entorno de Quadlets

```bash
./install/quadlets-setup.sh
```

Prepara los directorios de usuario en `~/.config/containers/systemd/` y recarga el generador de servicios de systemd.

### 3. Añadir el CLI al PATH

Añade la siguiente línea a tu archivo `~/.bashrc` o `~/.zshrc`:

```bash
export PATH="$HOME/Workspace/Repositorios/Linux/SoplosLinuxTyson/Podman/lib:$PATH"
```

O crea un alias si lo prefieres:

```bash
alias podman-utils="$HOME/Workspace/Repositorios/Linux/SoplosLinuxTyson/Podman/lib/podman-utils.sh"
```

---

## 💻 Guía Rápida de Uso

### Crear un nuevo proyecto desde plantilla

```bash
# FastAPI + PostgreSQL
podman-utils create python-postgres mi-api

# FastAPI + PostgreSQL + Redis
podman-utils create python-postgres-redis mi-api-redis

# Aplicación Fullstack con Traefik y Keycloak
podman-utils create fullstack mi-app-web
```

Al crear un proyecto:
1. Se genera la carpeta en `projects/<nombre>/`.
2. Se instancia el archivo `.env` a partir de `.env.example` con los nombres y puertos adaptados.
3. Se configuran y enlazan automáticamente los archivos Quadlet (`.container`, `.volume`, `.network`, `.target`) en `~/.config/containers/systemd/`.
4. Se recarga `systemd --user`.

### Configurar credenciales (.env)

```bash
podman-utils env mi-api
# O directamente: nano projects/mi-api/.env
```

### Iniciar el proyecto

```bash
podman-utils start mi-api
```

Inicia todos los contenedores coordinados por el target `mi-api.target` respetando las dependencias (`Requires=` y `After=`).

### Ver estado y contenedores

```bash
podman-utils status mi-api
# O ver la lista de todos tus proyectos:
podman-utils list
```

### Inspeccionar logs en vivo

```bash
# Ver logs de todo el proyecto (todos los servicios combinados)
podman-utils logs mi-api

# Ver logs de un servicio específico
podman-utils logs mi-api backend
podman-utils logs mi-api postgres
```

### Ejecutar comandos o entrar a una terminal dentro del contenedor

```bash
# Abrir terminal bash/sh interactiva en el contenedor backend
podman-utils exec mi-api backend

# Ejecutar una consola psql interactiva en la base de datos
podman-utils exec mi-api postgres psql -U postgres

# Ejecutar un comando puntual
podman-utils exec mi-api backend pip list
```

### Habilitar inicio automático en el arranque del equipo (Boot)

```bash
podman-utils enable mi-api
```

Gracias al `loginctl enable-linger`, el proyecto se iniciará en segundo plano aunque el usuario no haya iniciado sesión gráfica todavía. Para deshabilitarlo:

```bash
podman-utils disable mi-api
```

### Detener o reiniciar

```bash
# Detener todos los contenedores del proyecto
podman-utils stop mi-api

# Reiniciar
podman-utils restart mi-api
```

### Destruir proyecto (Limpieza total)

```bash
podman-utils destroy mi-api
```

Detiene los servicios, desenlaza los Quadlets, elimina los contenedores, volúmenes de datos, red y el directorio del proyecto.

---

## 📦 Plantillas Disponibles

### 1. `python-postgres`
- **PostgreSQL 17**: Base de datos con volumen Quadlet persistente `pg-data`.
- **Backend Python 3.13 (FastAPI)**: Con `uvicorn --reload` para desarrollo y hot-reload sobre `src/`.
- **Healthchecks nativos**: Verificación interna mediante la biblioteca estándar de Python y `pg_isready`.

### 2. `python-postgres-redis`
- Incluye todo lo anterior más **Redis 7** para colas de tareas asíncronas (Celery/RQ), caché o publicación/suscripción.

### 3. `fullstack`
- **Traefik v3**: Proxy inverso local que expone los servicios en subdominios virtuales `*.localhost`.
- **Keycloak 26**: Servidor OIDC con soporte para proveedores OAuth2 (Google, Microsoft, GitHub).
- **Backend Python 3.13 (FastAPI)**: Disponible en `http://api.mi-app.localhost`.
- **Frontend Vue 3 (Vite)**: Servidor de desarrollo con hot-reload en `http://app.mi-app.localhost`.
- **PostgreSQL 17**: Persistencia de datos para la aplicación y Keycloak.

---

## 🌐 Servicios Globales Compartidos

Si prefieres tener un único proxy Traefik o base de datos central para múltiples proyectos:

```bash
# Instalar todos los servicios globales compartidos
podman-utils install-global all

# O instalar uno específico:
podman-utils install-global traefik
podman-utils install-global postgres-global
podman-utils install-global redis-global
podman-utils install-global keycloak
```

Iniciar o gestionar servicios globales directamente con `systemd`:

```bash
systemctl --user start traefik.service
systemctl --user status postgres-global.service
```

---

## 📋 Resumen de Comandos de `podman-utils`

| Comando | Parámetros | Descripción |
|---|---|---|
| `create` | `<template> <nombre>` | Crea un nuevo proyecto y genera sus Quadlets |
| `start` | `<nombre>` | Inicia el proyecto con `systemd` |
| `stop` | `<nombre>` | Detiene todos los contenedores del proyecto |
| `restart` | `<nombre>` | Reinicia el proyecto |
| `status` | `<nombre>` | Muestra el estado del target, servicios y Podman |
| `logs` | `<nombre> [servicio]` | Muestra logs en tiempo real vía `journalctl` |
| `exec` | `<nombre> <servicio> [cmd]` | Abre una shell o ejecuta comandos en el contenedor |
| `ps` | `[nombre]` | Lista contenedores activos formateados |
| `enable` | `<nombre>` | Habilita el arranque automático en el boot |
| `disable` | `<nombre>` | Deshabilita el arranque automático en el boot |
| `env` | `<nombre>` | Abre el `.env` del proyecto en el editor |
| `validate` | `<nombre>` | Valida la sintaxis y estado de los archivos Quadlet |
| `destroy` | `<nombre>` | Elimina completamente el proyecto y sus volúmenes |
| `link` | `<nombre>` | Enlaza los archivos Quadlet a `~/.config/containers/systemd` |
| `unlink` | `<nombre>` | Desenlaza los archivos Quadlet de `systemd` |
| `install-global` | `<servicio\|all>` | Instala servicios compartidos en `systemd` |
| `uninstall-global` | `<servicio>` | Desinstala un servicio compartido |
| `list` | | Lista todos los proyectos locales y su estado |
| `list-templates` | | Lista las plantillas disponibles |
