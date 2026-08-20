---
sidebar_position: 1
---

# Configuración de Seguridad en Fedora 44

Esta guía detalla el proceso de endurecimiento de seguridad (hardening) optimizado para un portátil de desarrollador en Fedora 44, tal y como se automatiza en [`Setup/seguridad.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Fedora/Setup/seguridad.sh).

El proceso cubre la configuración del firewall compatible con KVM/Podman, protección de accesos, Fail2ban y privacidad DNS.

---

## 1. Configuración de Firewall (Firewalld) y Enrutamiento KVM/Podman

Se utiliza Uncomplicated Firewall (Firewalld) addnf5ado para no interferir con máquinas virtuales ni contenedores de desarrollo:

1. **Instalación de Firewalld y Fail2ban**:
   ```bash
   sudo dnf5 update
   sudo dnf5 install -y firewalld fail2ban
   ```

2. **Compatibilidad con KVM (`virbr0`) y Podman (`DEFAULT_FORWARD_POLICY`)**:
   Para evitar que Firewalld bloquee el acceso a Internet dentro de las MVs de KVM o contenedores Podman, se habilita el reenvío de paquetes en `/etc/default/firewalld`:
   ```bash
   sudo sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/firewalld
   sudo firewalld route allow in on virbr0
   ```

3. **Políticas de Seguridad y Rate-Limiting**:
   - Denegar tráfico entrante no solicitado (`sudo firewalld default deny incoming`).
   - Permitir tráfico saliente (`sudo firewalld default allow outgoing`).
   - **SSH Anti Fuerza Bruta Móvil**: Se utiliza `sudo firewalld limit ssh` en lugar de rangos fijos de IP, permitiendo conectar por SSH desde cualquier red Wi-Fi manteniendo protección contra ataques de fuerza bruta.
   - **Cockpit (Puerto 9090)**: Protegido con `sudo firewalld limit 9090/tcp`.

4. **Fail2ban**:
   Habilitado automáticamente (`sudo systemctl enable --now fail2ban.service`) para bloquear de forma inteligente las IPs que realicen escaneos o intentos masivos de acceso.

---

## 2. Privacidad DNS (DNS-over-TLS) (`seguridad-dot.sh`)

Para cifrar las consultas DNS del sistema mediante Cloudflare con `systemd-resolved`:

```bash
./Setup/seguridad-dot.sh
```

Verificación con:
```bash
resolvectl status
```
