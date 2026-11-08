# Podman - Contenedores Rootless con Quadlets

## Estructura

```
Podman/
├── install/           # Scripts de instalacion y configuracion
│   ├── podman-install.sh
│   └── quadlets-setup.sh
├── lib/               # Utilidades CLI
│   └── podman-utils.sh
├── projects/          # Proyectos activos (gitignored)
├── services-shared/   # Servicios globales compartidos
│   ├── postgres-global.container
│   ├── redis-global.container
│   ├── traefik.container
│   └── keycloak.container
└── templates/         # Plantillas de proyectos
    ├── python-postgres/
    ├── python-postgres-redis/
    └── fullstack/
```

## Uso rapido

```bash
# Instalar Podman rootless
just podman-setup

# Crear un proyecto desde plantilla
podman-utils create python-postgres mi-api

# Iniciar proyecto
podman-utils start mi-api

# Ver estado
podman-utils status mi-api

# Ver logs
podman-utils logs mi-api

# Detener proyecto
podman-utils stop mi-api

# Eliminar proyecto
podman-utils destroy mi-api
```

## Servicios globales

```bash
# Instalar servicio compartido
podman-utils install-global postgres

# Desinstalar servicio compartido
podman-utils uninstall-global postgres
```

## Diagnostico

```bash
podman-utils doctor
```
