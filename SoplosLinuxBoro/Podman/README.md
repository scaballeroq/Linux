# Podman Professional - Quadlets para Desarrollo (Soplos Linux Boro Workstation)

Gestión de contenedores con **Podman Rootless + Quadlets + Systemd** para proyectos de desarrollo con proxy, autenticación y servicios compartidos.

---

## 📁 Estructura

```
Podman/
├── install/                  # Scripts de instalación
│   ├── podman-install.sh     # Instala y configura Podman rootless, socket, linger y CLI
│   └── quadlets-setup.sh     # Configura systemd para Quadlets y servicios compartidos
│
├── lib/
│   ├── podman-utils.sh       # CLI para gestionar proyectos y templates
│   ├── podman-utils-completion.bash
│   └── podman-utils-completion.zsh
│
├── templates/                # Plantillas de proyectos
│   ├── python-postgres/      # Python + PostgreSQL
│   ├── python-postgres-redis/# Python + PostgreSQL + Redis
│   └── fullstack/            # Front + Back + PostgreSQL + Traefik + Keycloak
│
├── services-shared/          # Servicios globales reutilizables
│   ├── traefik.container     # Proxy inverso
│   ├── keycloak.container    # OAuth2/OIDC
│   ├── postgres-global.container  # PostgreSQL compartido
│   ├── redis-global.container     # Redis compartido
│   └── proxy-net.network     # Red compartida
│
├── scripts-standalone/       # Contenedores individuales autónomos (Adminer, MinIO, Redis, etc.)
└── projects/                 # Proyectos activos de desarrollo (gitignored)
```

---

## 🚀 Instalación y Despliegue

### 1. Instalar y configurar Podman Rootless

```bash
./install/podman-install.sh
```

### 2. Configurar Quadlets de Systemd

```bash
./install/quadlets-setup.sh
```

### 3. CLI `podman-utils`

El script crea automáticamente un enlace simbólico en `~/.local/bin/podman-utils` y registra los autocompletados para Bash y Zsh:

```bash
podman-utils doctor
podman-utils help
```

---

## 🛡️ Integración de Red y Cortafuegos (UFW)

En **Soplos Linux Boro Workstation**, el cortafuegos del sistema es **UFW**. El instalador `podman-install.sh` y el diagnóstico `podman-utils doctor` configuran automáticamente las siguientes reglas para garantizar la conectividad de los contenedores:

1. **Interfaz Podman (`podman+`)**:
   ```bash
   sudo ufw allow in on podman+
   sudo ufw allow out on podman+
   ```
2. **Enrutamiento (Forwarding inter-contenedor y salida WAN)**:
   ```bash
   sudo ufw route allow in on podman+
   sudo ufw route allow out on podman+
   ```
3. **Parámetros del Kernel (`sysctl`)**:
   - `net.ipv4.ip_unprivileged_port_start = 80`: Permite enlazar puertos 80 y 443 en modo rootless (Traefik, Nginx).
   - `net.ipv4.ip_forward = 1`: Habilita el reenvío de paquetes para redes puente de Podman (Netavark / Pasta).

---

## 💡 Uso Rápido

```bash
# Crear proyecto desde plantilla
podman-utils create python-postgres mi-api

# Iniciar servicios del proyecto
podman-utils start mi-api

# Estado y logs
podman-utils status mi-api
podman-utils logs mi-api
```
