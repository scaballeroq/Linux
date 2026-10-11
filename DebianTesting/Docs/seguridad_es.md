---
sidebar_position: 1
---

# Configuración de Seguridad en Debian 13

Esta guía detalla el proceso de endurecimiento de seguridad (hardening) optimizado para un portátil de desarrollador en Debian 13, tal y como se automatiza en [`Setup/seguridad.sh`](file:///home/caballero/Workspace/Repositorios/Linux/Debian/Setup/seguridad.sh).

El proceso cubre la configuración del firewall compatible con KVM/Podman y el blindaje de conexiones en redes Wi-Fi públicas.

---

## 1. Configuración de Firewall (UFW) y Enrutamiento KVM/Podman

Se utiliza Uncomplicated Firewall (UFW) optimizado para portátiles y entornos de desarrollo móvil:

1. **Instalación de UFW y GUFW (Interfaz gráfica)**:
   ```bash
   sudo apt update
   sudo apt install -y ufw gufw
   ```

2. **Compatibilidad con KVM (`virbr0`) y Podman (`DEFAULT_FORWARD_POLICY`)**:
   Para evitar que UFW bloquee el acceso a Internet dentro de las MVs de KVM o contenedores Podman, se habilita el reenvío de paquetes en `/etc/default/ufw`:
   ```bash
   sudo sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw
   sudo ufw route allow in on virbr0
   ```

3. **Políticas de Seguridad**:
   - Denegar todo tráfico entrante no solicitado (`sudo ufw default deny incoming`).
   - Permitir todo el tráfico saliente (`sudo ufw default allow outgoing`).
   - Blindaje total sin puertos abiertos innecesarios en redes Wi-Fi públicas.
   - Sin demonios pesados en segundo plano (ahorro de batería y recursos).
