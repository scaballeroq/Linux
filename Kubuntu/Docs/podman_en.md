---
sidebar_position: 8
---

# Container Management with Podman on Kubuntu

This guide details the installation of the **Podman** container platform and the list of pre-configured services inside the `Podman` folder.

Unlike Docker, Podman runs by default in a secure, **daemonless**, and **rootless** mode, keeping user containers securely isolated in user-space.

---

## 1. Configuring Podman Core (`podman.sh`)

Installs Podman, its `compose` orchestration helper, and modern network stacks native to Kubuntu/Ubuntu:

1. **Component Installation**:
   ```bash
   sudo apt update
   sudo apt install -y podman podman-compose podman-docker uidmap slirp4netns passt
   ```
   * **`podman-docker`**: Installs a symlink helper to automatically forward `docker` commands directly to `podman`.
   * **`uidmap`**: Critical for mapping sub-UIDs and sub-GIDs in user space to execute secure rootless containers.
   * **`passt` / `pasta`**: High-performance network stack for rootless containers, built-in by default starting with Podman 5 (standard in Kubuntu/Ubuntu).

2. **User Session Persistence (Linger)**:
   Configures systemd to keep user containers running in the background even after the terminal session closes:
   ```bash
   loginctl enable-linger "$USER"
   ```

3. **User Socket and Compatibility**:
   Enables the user's Podman socket that emulates the Docker socket API, allowing native integrations with developer tools (like IDEs or Testcontainers):
   ```bash
   systemctl --user enable --now podman.socket
   ```

4. **DOCKER_HOST Variable**:
   Exposes the user socket path inside `~/.bashrc.d/podman.sh` so third-party tools locate Podman automatically:
   ```bash
   export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
   ```

---

## 2. Integrated Development Network

All auxiliary containers and infrastructure are deployed on a common Podman bridge network named `devfed-net`. The scripts create it automatically if it's not present:
```bash
if ! podman network exists devfed-net; then
    podman network create devfed-net
fi
```

---

## 3. Catalog of Developer Services

The scripts use Podman's `--replace` flag to stop and clean up any previous instance of the container. The services are organized as follows:

### Databases
* **PostgreSQL** (`podman-postgres.sh`): Starts PostgreSQL on port `5432` (default credentials: `postgres/postgres`).
* **MySQL** (`podman-mysql.sh`): Starts MySQL on port `3306` (credentials: `root/root`).
* **MongoDB** (`podman-mongodb.sh`): Starts MongoDB on port `27017` (rootless without initial password).
* **Redis** (`podman-redis.sh`): Starts a Redis in-memory key-value store on port `6379`.

### Administration, Monitoring, and Tracing
* **Portainer CE** (`podman-portainer.sh`): Graphical container management UI exposed securely at `https://localhost:9443`.
* **Adminer** (`podman-adminer.sh`): Lightweight database manager for SQL/NoSQL databases on `http://localhost:8080`.
* **Dozzle** (`podman-dozzle.sh`): Lightweight real-time log viewer available on `http://localhost:8888`.
* **Grafana** (`podman-grafana.sh`): Analytics and monitoring dashboard exposed on `http://localhost:3000`.
* **Prometheus** (`podman-prometheus.sh`): Metrics scraper database available on `http://localhost:9090`.
* **Jaeger** (`podman-jaeger.sh`): Distributed tracing platform UI exposed on `http://localhost:16686`.

### Infrastructure and Utilities
* **Nginx** (`podman-nginx.sh`): Web server exposed on standard ports `80` (HTTP) and `443` (HTTPS).
* **Keycloak** (`podman-keycloak.sh`): Identity and Access Management (IAM) provider exposed on `http://localhost:8081` (credentials: `admin/admin`).
* **RabbitMQ** (`podman-rabbitmq.sh`): Message broker exposed on `5672` (management UI on `http://localhost:15672` with `guest/guest`).
* **MinIO** (`podman-minio.sh`): Object Storage compatible with AWS S3 (API on `9000`, dashboard Console on `http://localhost:9001` with `minioadmin/minioadmin`).
* **MailHog** (`podman-mailhog.sh`): Development SMTP server to intercept outgoing emails in testing (SMTP on `1025`, Web interface on `http://localhost:8025`).
* **Browserless** (`podman-browserless.sh`): Headless Chrome browser managed via APIs on port `3001`.

### Frameworks and CMS
* **WordPress** (`podman-wordpress.sh`): Launches a WordPress site on port `8082`, configured to hook into the local MySQL container.
* **Storybook** (`podman-storybook.sh`): Starts Storybook component playground on port `6006`.

---

## Verification

- **Podman Status**: Run `podman info` (should display rootless details).
- **Socket**: Run `curl --unix-socket $XDG_RUNTIME_DIR/podman/podman.sock http://d/info` to check socket replies.
- **Services**: Run any helper script (e.g. `./podman-postgres.sh`) and verify execution using `podman ps`.
