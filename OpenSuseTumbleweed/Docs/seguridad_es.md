---
sidebar_position: 1
---

# Endurecimiento de Seguridad y Cortafuegos en openSUSE Tumbleweed (KDE Plasma 6)

Esta guía detalla el proceso de seguridad, red y endurecimiento del sistema (hardening) automatizado en [`Setup/seguridad.sh`](file:///home/caballero/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Setup/seguridad.sh), optimizado específicamente para una estación de trabajo y desarrollo local con **openSUSE Tumbleweed** y **KDE Plasma 6 (Wayland)**.

---

## 1. Cortafuegos Nativo (Firewalld)

Configura Firewalld para proteger el sistema contra conexiones no autorizadas mientras mantiene la integración total con desarrollo (Podman, KVM), KDE Plasma, KDE Connect y red local:

1. **Activación del Servicio**:
   ```bash
   sudo systemctl enable --now firewalld
   ```

2. **Reglas para KDE Plasma, KDE Connect y Desarrollo**:
   - **KDE Connect (`kdeconnect`)**: Permite la sincronización de notificaciones, control multimedia, portapapeles compartido y transferencia de archivos entre tu teléfono y tu PC con KDE.
   - **Descubrimiento Local (`mdns`)**: Permite detectar impresoras (HP LaserJet), dispositivos multimedia y servicios locales.
   - **Acceso Remoto (`ssh`)**: Mantiene el acceso seguro por SSH.
   - **Máquinas Virtuales y Contenedores**:
     - Subredes de Podman Rootless (`podman+` y `cni-podman+`) en la zona `trusted`.
     - Puente de virtualización KVM (`virbr0`) en la zona `trusted` con IP Masquerade activo.

---

## 2. Optimización de Red y Kernel (Sysctl) para Desarrollo

Aplica configuraciones del Kernel en `/etc/sysctl.d/99-development-network.conf` para garantizar compatibilidad completa con Podman Rootless y máquinas virtuales KVM sin necesidad de ejecutar contenedores como root:

```ini
# /etc/sysctl.d/99-development-network.conf

# Reenvío de paquetes para contenedores y VMs
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Permitir a Podman Rootless enlazar puertos HTTP/HTTPS estándar (>=80) sin root
net.ipv4.ip_unprivileged_port_start = 80

# Permitir operaciones ICMP (ping) en contenedores sin privilegios
net.ipv4.ping_group_range = 0 2147483647

# Soporte completo de espacios de nombres de usuario (user namespaces)
kernel.unprivileged_userns_clone = 1
user.max_user_namespaces = 65536

# Protección estándar de red local (reverse path filter y SYN cookies)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
```

---

## 3. Saneamiento para Red Local Doméstica

Para una estación de trabajo de desarrollo en red local de hogar, se eliminan configuraciones que provocan fricción o consumo innecesario de recursos:

- **Estabilidad DHCP y Reservas de IP**: Se retira la aleatorización de MAC (`00-macrandomize.conf`) para evitar que el router cambie la dirección IP local de tu equipo y rompa reservas estáticas o reglas de puertos.
- **Sin sobrecarga de Fail2ban**: Desactiva Fail2ban en LAN privada donde no hay servicios expuestos directamente a internet pública.
- **Resolución DNS Nativa**: Usa el DNS de tu router local para resolver sin problemas nombres de host `.local` o `.lan`.

---

## 4. Auditoría de Permisos Críticos

Asegura que directorios sensibles del sistema no tengan permisos de lectura abiertos para usuarios no autorizados:
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
