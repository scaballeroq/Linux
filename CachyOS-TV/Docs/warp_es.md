---
sidebar_position: 2
---

# Cloudflare WARP: Bypass de Bloqueos de ISP y La Liga para Stremio

Esta guía detalla la instalación y uso de **Cloudflare WARP** en **CachyOS TV** mediante el script [`Setup/cloudflare-warp.sh`](file:///home/televisor/Proyectos/Linux/CachyOS-TV/Setup/cloudflare-warp.sh) para evitar que los bloqueos dinámicos judiciales de operadoras en España impidan reproducir contenido en **Stremio** o Kodi.

---

## ⚽ El Problema: Bloqueos dinámicos en España ("La Liga")

En España, las resoluciones judiciales autorizan a LaLiga a enviar listados dinámicos semanales de direcciones IP y nombres de dominio a los principales proveedores de internet (Movistar, Vodafone, Orange, Digi, MásMóvil, etc.) para bloquearlos en tiempo real durante los partidos de fútbol.

### ¿Por qué afecta a Stremio y Torrentio?
Aunque estés viendo una película o serie completamente legal o no relacionada con el fútbol:
1. **Bloqueo de CDNs y servidores compartidos:** Muchos addons comunitarios (Torrentio, MediaFusion, servidores Real-Debrid/AllDebrid o trackers P2P) comparten rangos de direcciones IP en nubes como Hetzner, OVH u Oracle Cloud con emisiones deportivas.
2. **DNS Hijacking y filtrado SNI:** El router o servidor DNS de la operadora redirige la petición a una página de aviso judicial (`127.0.0.1` o `bloqueado.por.orden.judicial`) o interrumpe la negociación TLS mediante reseteo de paquetes TCP (RST).
3. **Resultado:** Stremio se queda en bucle de carga infinito o muestra *"Error loading stream"*.

---

## 🛡️ La Solución: Cloudflare WARP

**Cloudflare WARP** no es un proxy web convencional, sino un túnel basado en **WireGuard** que conecta tu equipo directamente con la red global Anycast de Cloudflare.

* **Cifrado de todo el tráfico:** El proveedor de internet (ISP) solo ve una conexión UDP cifrada hacia Cloudflare; no puede inspeccionar el dominio (SNI) ni la IP final de destino.
* **Máxima velocidad:** Al usar la infraestructura Anycast de Cloudflare con servidores locales en Madrid y Barcelona, la latencia es prácticamente idéntica a la conexión nativa y permite streaming 1080p sin pérdidas de ancho de banda.
* **Sin coste:** A diferencia de VPNs comerciales, el modo básico de WARP es 100% gratuito e ilimitado.
* **Integración con Firewalld:** La interfaz virtual `CloudflareWARP` se asigna automáticamente a la zona `trusted` para garantizar el tráfico sin interferir con la red local del televisor.

---

## 🚀 Uso Rápido

### 1. Instalación y Puesta en Marcha
Ejecuta el script sin argumentos para instalar el paquete nativo `cloudflare-warp-bin`, iniciar el daemon, registrar la cuenta y conectar el túnel:

```bash
sudo ./Setup/cloudflare-warp.sh
# o mediante Justfile:
just warp
```

### 2. Comandos Diarios

```bash
# Conectar el túnel WARP antes de usar Stremio
./Setup/cloudflare-warp.sh --connect
# o con just:
just warp-on

# Desconectar el túnel y volver a la conexión directa de tu ISP
./Setup/cloudflare-warp.sh --disconnect
# o con just:
just warp-off

# Alternar conexión (conectar si está desconectado, o viceversa)
./Setup/cloudflare-warp.sh --toggle

# Comprobar el estado y verificar que el túnel está activo
./Setup/cloudflare-warp.sh --status
# o con just:
just warp-status
```

---

## 🔍 Verificación

Cuando el túnel está conectado, `warp-status` confirmará:
- **Túnel WARP:** `ACTIVO (on)`
- **Protección Stremio:** Bloqueos de ISP y La Liga eludidos con éxito.
- Tu IP pública saldrá identificada a través de la red de Cloudflare en lugar de los rangos bloqueados de tu proveedor de fibra.

