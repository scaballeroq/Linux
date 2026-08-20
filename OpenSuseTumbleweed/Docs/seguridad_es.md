---
sidebar_position: 7
---

# Seguridad y Hardening en OpenSUSE Tumbleweed

Esta guía detalla la configuración de seguridad aplicada mediante `Setup/seguridad.sh` y `Setup/seguridad-dot.sh` en **OpenSUSE Tumbleweed + GNOME**.

---

## 1. Cortafuegos (Firewalld)

En openSUSE Tumbleweed, la seguridad de red está gestionada mediante **Firewalld** (`firewall-cmd`), configurado para:
- Permitir conexiones SSH con limitación de intentos.
- Asignar la interfaz virtual `virbr0` (KVM/QEMU) y Podman en zonas seguras para no interrumpir la conectividad en máquinas virtuales o contenedores.
- Habilitar acceso protegido a la consola Cockpit (puerto 9090).

```bash
just security
```

---

## 2. Protección Anti Fuerza Bruta (Fail2ban)

Protege contra ataques de denegación de servicio o intentos repetidos de acceso mediante `fail2ban.service`.

---

## 3. Privacidad Wi-Fi (MAC Randomization)

Configurado en NetworkManager (`/etc/NetworkManager/conf.d/00-macrandomize.conf`) para generar direcciones MAC aleatorias en escaneos de redes inalámbricas.

---

## 4. Endurecimiento del Kernel (Sysctl)

Restricciones de `dmesg`, punteros del kernel (`kptr_restrict`), filtros de ruta inversa (`rp_filter`) y cookies TCP Syncookies.

---

## 5. DNS-over-TLS (`seguridad-dot.sh`)

Cifrado de consultas DNS mediante `systemd-resolved` para evitar la inspección de tráfico DNS por parte de intermediarios.

```bash
just security-dot
```
