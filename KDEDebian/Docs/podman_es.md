---
sidebar_position: 8
---

# Gestión de Contenedores con Podman en Debian 13

Esta guía detalla la instalación de la plataforma de contenedores **Podman** y el listado de servicios preconfigurados en la carpeta `Podman`.

A diferencia de Docker, Podman funciona por defecto de manera segura **sin demonio (daemonless)** y **sin privilegios de root (rootless)**, aislando los contenedores del usuario de manera nativa.

---

## 1. Configuración de Podman Core (`podman.sh`)

Instala Podman, su herramienta de orquestación `compose` y las dependencias de red avanzadas nativas de Debian 13:

1. **Instalación de Componentes**:
   ```bash
   sudo apt update
   sudo apt install -y podman podman-compose podman-docker uidmap slirp4netns passt
   ```
   * **`podman-docker`**: Instala un script de enlace para responder de manera automática al comando `docker` traduciéndolo a `podman`.
   * **`uidmap`**: Esencial para mapear sub-UIDs y sub-GIDs en el sistema, permitiendo contenedores rootless seguros.
   * **`passt` / `pasta`**: Pila de red de alto rendimiento para contenedores rootless, integrada por defecto a partir de Podman 5 (estándar en Debian 13).

2. **Persistencia del Usuario (Linger)**:
   Se configura el sistema para que los contenedores del usuario sigan ejecutándose en segundo plano incluso cuando el usuario cierre su sesión de terminal:
   ```bash
   loginctl enable-linger "$USER"
   ```

3. **Socket de Usuario y Compatibilidad**:
   Habilita el socket del usuario de Podman que emula la API del socket de Docker, permitiendo la integración automática con herramientas de desarrollo (como IDEs o Testcontainers):
   ```bash
   systemctl --user enable --now podman.socket
   ```

4. **Variable DOCKER_HOST**:
   Se expone en `~/.bashrc.d/podman.sh` la ruta del socket de usuario para que herramientas externas localicen a Podman de forma automática:
   ```bash
   export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
   ```

---

## 2. Red de Desarrollo Integrada

Todos los contenedores auxiliares e infraestructura se despliegan sobre una red puente común de Podman llamada `devfed-net`. Los scripts crean automáticamente esta red si no está presente:
```bash
if ! podman network exists devfed-net; then
    podman network create devfed-net
fi
```

---

## 3. Catálogo de Servicios Auxiliares

Los scripts usan la flag `--replace` de Podman para detener y reemplazar limpiamente cualquier versión previa del contenedor. El catálogo está organizado de la siguiente manera:

### Bases de Datos
* **PostgreSQL** (`podman-postgres.sh`): Levanta PostgreSQL en el puerto `5432` (credenciales por defecto: `postgres/postgres`).
* **MySQL** (`podman-mysql.sh`): Levanta MySQL en el puerto `3306` (credenciales: `root/root`).
* **MongoDB** (`podman-mongodb.sh`): Levanta MongoDB en el puerto `27017` (rootless sin contraseña inicial).
* **Redis** (`podman-redis.sh`): Levanta un almacén clave-valor en memoria Redis en el puerto `6379`.

### Administración, Monitoreo y Trazabilidad
* **Portainer CE** (`podman-portainer.sh`): Interfaz web gráfica de administración de contenedores expuesta de forma segura en `https://localhost:9443`.
* **Adminer** (`podman-adminer.sh`): Administrador web ligero para bases de datos SQL y NoSQL expuesto en `http://localhost:8080`.
* **Dozzle** (`podman-dozzle.sh`): Visualizador ligero de logs de contenedores en tiempo real disponible en `http://localhost:8888`.
* **Grafana** (`podman-grafana.sh`): Suite de analítica y monitorización expuesta en `http://localhost:3000`.
* **Prometheus** (`podman-prometheus.sh`): Base de datos de métricas disponible en `http://localhost:9090`.
* **Jaeger** (`podman-jaeger.sh`): Sistema de trazabilidad distribuido expuesto en `http://localhost:16686` (UI).

### Infraestructura y Desarrollo
* **Nginx** (`podman-nginx.sh`): Servidor web expuesto en los puertos estándar `80` (HTTP) y `443` (HTTPS).
* **Keycloak** (`podman-keycloak.sh`): Proveedor de gestión de identidad y accesos (IAM) expuesto en `http://localhost:8081` (credenciales: `admin/admin`).
* **RabbitMQ** (`podman-rabbitmq.sh`): Gestor de colas de mensajería expuesto en `5672` (gestión web en `http://localhost:15672` con `guest/guest`).
* **MinIO** (`podman-minio.sh`): Almacenamiento de objetos compatible con AWS S3 (API en `9000`, Consola de control en `http://localhost:9001` con `minioadmin/minioadmin`).
* **MailHog** (`podman-mailhog.sh`): Servidor SMTP de desarrollo para interceptar envíos de correo en pruebas (SMTP en `1025`, Interfaz web en `http://localhost:8025`).
* **Browserless** (`podman-browserless.sh`): Navegador Chrome headless gestionable mediante APIs expuesto en el puerto `3001`.

### Frameworks y CMS
* **WordPress** (`podman-wordpress.sh`): Despliega un CMS WordPress en el puerto `8082`, autoconfigurado para conectar a un contenedor de MySQL.
* **Storybook** (`podman-storybook.sh`): Levanta el catálogo Storybook de componentes UI en el puerto `6006`.

---

## Verificación

- **Estado de Podman**: Ejecuta `podman info` (debe indicar que corre en modo rootless).
- **Socket**: Ejecuta `curl --unix-socket $XDG_RUNTIME_DIR/podman/podman.sock http://d/info` para verificar el socket local.
- **Servicios**: Ejecuta cualquier script auxiliar (ej. `./podman-postgres.sh`) y comprueba su ejecución mediante `podman ps`.
