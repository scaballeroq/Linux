---
sidebar_position: 1
---

# Configuración de Seguridad en Soplos Linux Tyson

Esta guía detalla el proceso de endurecimiento de seguridad (hardening) optimizado para un portátil de desarrollo en **Soplos Linux Tyson**, tal y como se automatiza en [Setup/seguridad.sh](file:///home/caballero/Workspace/Repositorios/Linux/SoplosLinuxTyson/Setup/seguridad.sh).

El proceso cubre la configuración del firewall compatible con Podman, KVM, KDE Connect, Fail2ban y servicios de red local.

---

## 1. Configuración de Firewall (UFW) para Portátil y Podman

Se utiliza Uncomplicated Firewall (UFW) adaptado para no interferir con contenedores de desarrollo ni redes locales:

1. **Instalación de UFW y Fail2ban**:
   ```bash
   sudo apt update
   sudo apt install -y ufw fail2ban
   ```

2. **Compatibilidad con Podman y KVM (`DEFAULT_FORWARD_POLICY`)**:
   Para permitir la comunicación y salida a Internet de contenedores Podman (netavark/pasta) y MVs en KVM (`virbr0`):
   ```bash
   sudo sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
   sudo ufw allow in on podman+
   sudo ufw route allow in on podman+
   sudo ufw route allow out on podman+
   sudo ufw allow in on virbr0
   sudo ufw route allow in on virbr0
   ```

3. **Desarrollo en Localhost e Integraciones KDE**:
   - Tráfico total permitido en interfaz local `lo` para servidores web de pruebas (`localhost`, `127.0.0.1`).
   - Reglas para **KDE Connect** (`1714:1764` TCP/UDP).
   - Descubrimiento de impresoras y mDNS Avahi (`5353/udp`, `631/udp`).

4. **Políticas de Seguridad y Rate-Limiting**:
   - Denegar tráfico entrante no solicitado (`sudo ufw default deny incoming`).
   - Permitir tráfico saliente (`sudo ufw default allow outgoing`).
   - **SSH Anti Fuerza Bruta**: `sudo ufw limit ssh`.
   - **Cockpit (Puerto 9090)**: `sudo ufw limit 9090/tcp`.

5. **Fail2ban con systemd**:
   Habilitado y supervisado automáticamente mediante systemd:
   ```bash
   sudo systemctl enable --now fail2ban.service
   ```
