---
sidebar_position: 1
---

# Endurecimiento de Seguridad y Cortafuegos en openSUSE Tumbleweed (KDE Plasma 6)

Esta guía detalla el proceso de seguridad, privacidad y endurecimiento del sistema (hardening) automatizado en [`Setup/seguridad.sh`](file:///home/caballero/Workspace/Repositorios/Linux/OpenSuseTumbleweed/Setup/seguridad.sh), optimizado para una estación de trabajo y portátil de desarrollo con **openSUSE Tumbleweed** y **KDE Plasma 6 (Wayland)**.

---

## 1. Cortafuegos Nativo (Firewalld)

Configura Firewalld para proteger el sistema contra conexiones no autorizadas mientras mantiene la integración con herramientas de desarrollo, KDE Plasma, KDE Connect y redes locales:

1. **Activación del Servicio**:
   ```bash
   sudo systemctl enable --now firewalld
   ```

2. **Limpieza de Servicios Innecesarios**:
   Elimina servicios obsoletos o inseguros en redes públicas/domésticas:
   ```bash
   sudo firewall-cmd --permanent --zone=public --remove-service=samba-client 2>/dev/null || true
   ```

3. **Reglas para KDE Plasma, KDE Connect y Desarrollo**:
   - **KDE Connect (`kdeconnect`)**: Permite la sincronización de notificaciones, control multimedia, portapapeles compartido y transferencia de archivos entre tu teléfono y tu PC con KDE.
   - **Descubrimiento Local (`mdns`)**: Permite detectar impresoras (HP LaserJet), dispositivos multimedia y servicios locales.
   - **Acceso Remoto (`ssh`)**: Mantiene el acceso seguro por SSH.
   - **Máquinas Virtuales y Contenedores**: Interfaz `virbr0` en zona `libvirt` y subredes `podman+` en zona `trusted`.
   ```bash
   sudo firewall-cmd --permanent --zone=public --add-service=kdeconnect
   sudo firewall-cmd --permanent --zone=public --add-service=mdns
   sudo firewall-cmd --permanent --zone=public --add-service=ssh
   sudo firewall-cmd --permanent --zone=trusted --add-interface=podman+ 2>/dev/null || true
   sudo firewall-cmd --permanent --zone=libvirt --add-interface=virbr0 2>/dev/null || true
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

Configura NetworkManager para utilizar direcciones MAC aleatorias al escanear y conectarse a redes Wi-Fi, evitando el rastreo físico del portátil HP EliteBook:

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

# Puertos sin privilegios y soporte para Podman rootless
net.ipv4.ip_unprivileged_port_start=80
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
