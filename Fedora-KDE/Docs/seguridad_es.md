---
sidebar_position: 1
---

# Endurecimiento de Seguridad y Cortafuegos en Fedora 44 (KDE Plasma 6)

Esta guía detalla el proceso de seguridad, privacidad y endurecimiento del sistema (hardening) automatizado en [`Setup/seguridad.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora/Setup/seguridad.sh), optimizado para una estación de trabajo y portátil de desarrollo con **Fedora 44** y **KDE Plasma 6**.

---

## 1. Cortafuegos Nativo (Firewalld - Zona `FedoraWorkstation`)

Configura Firewalld para proteger el sistema contra conexiones no autorizadas mientras mantiene la integración con herramientas de desarrollo, KDE Plasma y redes locales:

1. **Activación del Servicio**:
   ```bash
   sudo systemctl enable --now firewalld
   ```

2. **Limpieza de Servicios Innecesarios**:
   Elimina servicios obsoletos o inseguros en redes públicas/domésticas:
   ```bash
   sudo firewall-cmd --permanent --zone=FedoraWorkstation --remove-service=samba-client
   ```

3. **Reglas para KDE Plasma y Desarrollo**:
   - **KDE Connect (`kdeconnect`)**: Permite la sincronización, control multimedia y transferencia de archivos entre tu teléfono y tu PC.
   - **Descubrimiento Local (`mdns`)**: Permite detectar impresoras (HP LaserJet), dispositivos multimedia y servicios locales.
   - **Acceso Remoto (`ssh`)**: Mantiene el acceso seguro por SSH.
   ```bash
   sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=kdeconnect
   sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=mdns
   sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=ssh
   sudo firewall-cmd --reload
   ```

---

## 2. Privacidad DNS (DNS-over-TLS con `systemd-resolved`)

Cifra las consultas DNS del sistema para proteger tu navegación contra escuchas e intercepciones en redes Wi-Fi:

```ini
# /etc/systemd/resolved.conf.d/dot.conf
[Resolve]
DNSOverTLS=opportunity
DNSSEC=allow-downgrade
```

Activación inmediata:
```bash
sudo systemctl restart systemd-resolved
```

---

## 3. Privacidad en Redes Wi-Fi (MAC Randomization)

Configura NetworkManager para utilizar direcciones MAC aleatorias al escanear y conectarse a redes Wi-Fi, evitando el rastreo físico del dispositivo:

```ini
# /etc/NetworkManager/conf.d/00-macrandomize.conf
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=stable
```

---

## 4. Endurecimiento del Kernel (Sysctl) y Podman Rootless

Aplica restricciones de seguridad en el Kernel mientras garantiza compatibilidad completa con contenedores rootless de Podman:

```ini
# /etc/sysctl.d/99-security.conf
# Restricciones de kernel
kernel.dmesg_restrict=1
kernel.kptr_restrict=2

# Protección de red (Anti-spoofing y SYN Cookies)
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1

# Soporte esencial para contenedores rootless (Podman / Quadlets)
kernel.unprivileged_userns_clone=1
user.max_user_namespaces=28633
```

---

## 5. Auditoría de Permisos Críticos

Asegura que directorios sensibles del sistema no tengan permisos de lectura abiertos para usuarios no autorizados:
```bash
sudo chmod 700 /root
```

---

## 6. Ejecución y Automatización con Just

```bash
just security
# o ./Setup/seguridad.sh
```

---

## Verificación

El script muestra automáticamente al finalizar el estado de cada componente:
- **Firewalld**: `sudo firewall-cmd --state`
- **DNS-over-TLS**: Comprueba la directiva en `systemd-resolved`.
- **MAC Randomization**: Comprueba la directiva en NetworkManager.
- **User Namespaces**: `sysctl user.max_user_namespaces`.
