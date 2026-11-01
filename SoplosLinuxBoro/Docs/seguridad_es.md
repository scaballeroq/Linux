---
sidebar_position: 1
---

# Endurecimiento de Seguridad y Cortafuegos en Soplos Linux Boro (GNOME Shell)

Esta guía detalla el proceso de seguridad, red y endurecimiento del sistema (hardening) automatizado en [`Setup/seguridad.sh`](file:///home/caballero/Workspace/Repositorios/Linux/SoplosLinuxBoro/Setup/seguridad.sh), optimizado específicamente para una estación de trabajo y desarrollo local con **Soplos Linux Boro** y **GNOME Shell (Wayland)**.

---

## 1. Cortafuegos Nativo Obligatorio (Firewalld)

En cumplimiento de las políticas del monorepo, **UFW queda permanentemente desactivado** y se utiliza exclusivamente **Firewalld** (`firewall-cmd`):

1. **Desactivación de UFW e Inicio de Firewalld**:
   ```bash
   sudo ufw disable
   sudo systemctl disable --now ufw
   sudo systemctl mask ufw
   sudo systemctl enable --now firewalld
   ```

2. **Reglas para GNOME Shell, GSConnect y Desarrollo**:
   - **GSConnect (`kdeconnect` service en Firewalld)**: Permite la sincronización de notificaciones, control multimedia, portapapeles compartido y transferencia de archivos entre tu teléfono y tu PC sin dependencias de KDE/Qt.
   - **Descubrimiento Local (`mdns`)**: Permite detectar impresoras (HP LaserJet), dispositivos multimedia y servicios locales.
   - **Acceso Remoto (`ssh`)**: Mantiene el acceso seguro por SSH.
   - **Máquinas Virtuales y Contenedores**:
     - Subredes de Podman Rootless (`podman+` y `cni-podman+`) en la zona `trusted`.
     - Puente de virtualización KVM (`virbr0` y `virbr+`) en la zona `trusted` con IP Masquerade activo.

---

## 2. Optimización de Red y Kernel (Sysctl) para Desarrollo

Aplica configuraciones del Kernel en `/etc/sysctl.d/99-development-network.conf` para garantizar compatibilidad completa con Podman Rootless y máquinas virtuales KVM sin necesidad de ejecutar contenedores como root:

```ini
# /etc/sysctl.d/99-development-network.conf

# Reenvío de paquetes para contenedores y VMs
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Preservar recepción de Router Advertisements (SLAAC) con forwarding activo
net.ipv6.conf.all.accept_ra = 2
net.ipv6.conf.default.accept_ra = 2

# Permitir a Podman Rootless enlazar puertos HTTP/HTTPS estándar (>=80) sin root
net.ipv4.ip_unprivileged_port_start = 80

# Permitir operaciones ICMP (ping) en contenedores sin privilegios
net.ipv4.ping_group_range = 0 2147483647

# Soporte completo de espacios de nombres de usuario (user namespaces)
kernel.unprivileged_userns_clone = 1
user.max_user_namespaces = 262144
```

---

## 3. Saneamiento para Red Local Doméstica

Para una estación de trabajo de desarrollo en red local de hogar:
- **Estabilidad DHCP y Reservas de IP**: Se evita la aleatorización de MAC para prevenir que el router cambie la dirección IP local del equipo y rompa reservas estáticas.
- **Sin sobrecarga de Fail2ban**: Desactivado en LAN privada donde no hay servicios expuestos directamente a internet pública.

---

## 4. Auditoría de Permisos Críticos

Asegura que directorios sensibles del sistema no tengan permisos de lectura abiertos:
```bash
sudo chmod 700 /root
```

---

## 5. Ejecución y Diagnóstico con Just

```bash
# Aplicar configuración de seguridad y red
just security

# Diagnosticar estado de cortafuegos, interfaces y parámetros sysctl
just security-status
```
