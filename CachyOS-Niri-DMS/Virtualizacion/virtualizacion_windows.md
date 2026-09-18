# Guía Técnica: Virtualización de Windows (10 / 11 / LTSC) en CachyOS con KVM/QEMU

Manual técnico de arquitectura, aprovisionamiento, optimización e integración de **Windows 10 Enterprise LTSC / Windows 11** en **CachyOS Linux**, diseñado específicamente para portátiles **AMD Ryzen** (HP EliteBook con Ryzen 7 PRO 4750U, Vega 7), almacenamiento Btrfs y el compositor **Niri (Wayland)**.

---

## 1. ¿Por qué Windows 10 Enterprise LTSC en una Máquina Virtual?

Para entornos de virtualización de trabajo y desarrollo bajo Linux, **Windows 10 Enterprise LTSC (Long-Term Servicing Channel)** o **IoT Enterprise LTSC** es la opción más recomendada frente a las ediciones *Home* o *Pro*:

* **Huella mínima de recursos**: Consume entre **1.2 GB y 1.5 GB de RAM** en reposo (frente a los más de 3.5 GB de Windows 10/11 Pro).
* **Sin bloatware ni telemetría pesada**: No incluye Cortana, Candy Crush, feeds de noticias ni aplicaciones de la Microsoft Store consumiendo ciclos de CPU en segundo plano.
* **Estabilidad sin reinicios forzados**: Solo recibe parches críticos de seguridad mensuales; no altera la configuración del sistema ni los drivers con actualizaciones semestrales de características.
* **Arranque instantáneo**: Con discos VirtIO y kernel KVM optimizado, arranca en 4-6 segundos.

---

## 2. Aprovisionamiento Previo con `virtualization.sh`

El repositorio incluye el script modular [`virtualization.sh`](./virtualization.sh) que automatiza toda la configuración del hipervisor en CachyOS.

Para preparar el sistema con soporte completo para Windows:

```bash
./Virtualizacion/virtualization.sh --with-windows
```

### Lo que este comando prepara automáticamente:
1. **Controladores VirtIO para Windows**: Descarga la versión oficial estable de `virtio-win.iso` en `~/Descargas/virtio-drivers/virtio-win.iso`.
2. **Optimizaciones AMD KVM**: Configura `/etc/modprobe.d/kvm_amd.conf` con `nested=1`, `avic=1` (interrupciones avanzadas por hardware) y `npt=1` (Nested Page Tables).
3. **Aceleración de red y sockets en el Kernel**: Carga `vhost_net`, `vhost_vsock` y `tun`.
4. **Almacenamiento optimizado (Btrfs NOCOW)**: Crea y asegura el pool de libvirt `MaquinasVirtuales` en `~/Workspace/MaquinasVirtuales` con el atributo `+C` (Copy-on-Write desactivado) para eliminar la fragmentación y la latencia de disco.
5. **Firewalld y Red NAT**: Asigna `virbr0` a la zona `libvirt` y aplica masquerading sin colisiones de firewall.
6. **Reglas para Niri Compositor**: Evita esquinas recortadas y ajusta el comportamiento flotante de los visores de VM en Wayland.

---

## 3. Dimensionamiento y Parámetros de Hardware Óptimos

Configuración recomendada para exprimir la arquitectura **AMD Ryzen 7 PRO 4750U** (8C / 16T) y **32 GB de RAM**:

| Componente | Ajuste Óptimo | Razón Técnica |
| :--- | :--- | :--- |
| **vCPUs** | **6 vCPUs** (1 socket, 3 cores, 2 threads) | Deja 10 hilos libres para CachyOS, Niri y procesos host sin estrangular la VM. |
| **Modelo de CPU** | `host-passthrough` | Traspasa instrucciones nativas AVX2, AES, SSE4a del procesador Zen 2. |
| **Memoria RAM** | **8192 MB** (8 GB) o **12288 MB** (12 GB) | Sobrado para cualquier flujo de trabajo Windows dejando 20+ GB libres en el host. |
| **Chipset y Firmware** | **Q35** + **UEFI (OVMF)** | Arquitectura moderna PCI Express y particionamiento GPT seguro. |
| **Módulo TPM** | **TPM 2.0 Emulado (`swtpm`)** | Requerido por Windows 11 y recomendado en Win10 para BitLocker/credenciales. |
| **Bus de Disco** | **VirtIO** (`virtio`) | Elimina la sobrecarga de emulación SATA/IDE multiplicando el ancho de banda IOPS. |
| **Caché / Descarte** | Caché `writeback` (o `none`), Descarte `unmap` | `unmap` permite que TRIM libere espacio real en el SSD host. |
| **Tarjeta de Red** | Modelo **VirtIO** (`virtio`) | Enrutamiento a través del módulo del kernel `vhost_net` a 10 Gbps virtuales. |
| **Vídeo / Pantalla** | **QXL** o **VirtIO** con Servidor SPICE | Compatible con el agente SPICE (redimensionamiento automático y portapapeles). |

---

## 4. Método 1: Creación Paso a Paso con `virt-manager` (GUI)

### Paso 1: Asistente inicial de creación
1. Abre **Gestor de máquinas virtuales** (`virt-manager`).
2. Pulsa en **Crear una nueva máquina virtual** (primer icono de la barra de herramientas).
3. Selecciona **Medio de instalación local (imagen ISO)** -> *Adelante*.
4. Pulsa **Explorar...** y selecciona la imagen ISO de Windows 10 Enterprise LTSC.
5. Desmarca la detección automática si no detecta la versión exacta y escribe `Microsoft Windows 10` en el buscador.

### Paso 2: Recursos del sistema
* **Memoria**: `8192` MB.
* **CPUs**: `6`.

### Paso 3: Disco Virtual
* Selecciona **Seleccione o cree almacenamiento personalizado** -> *Gestionar...*.
* Abre el pool **`MaquinasVirtuales`** (ubicado en `~/Workspace/MaquinasVirtuales`).
* Pulsa en **Nuevo volumen (+)**:
  * Nombre: `win10-ltsc.qcow2`
  * Formato: `qcow2`
  * Capacidad máxima: `60` GB.

### Paso 4: Configuración avanzada (CRÍTICO)
* Nombra la máquina: `win10-ltsc`.
* **Marca la casilla obligatoria**: `[x] Personalizar configuración antes de instalar` y pulsa **Finalizar**.

### Paso 5: Ajuste fino de dispositivos antes de encender:
En la ventana de personalización que aparece:

1. **Visión general**:
   - **Chipset**: `Q35`.
   - **Firmware**: `UEFI x86_64: /usr/share/edk2/x64/OVMF_CODE.secboot.4m.fd` (o similar).
2. **CPUs**:
   - Desmarca la casilla predeterminada y en **Modelo** escribe: `host-passthrough`.
   - Despliega **Topología**: Marca `[x] Manually set CPU topology` -> Sockets: `1`, Cores: `3`, Threads: `2`.
3. **Disco 1** (tu volumen recién creado):
   - **Bus del disco**: Cambia de `SATA` a **`VirtIO`**.
   - En **Opciones de rendimiento**:
     - *Modo de caché*: `writeback` (o `none`).
     - *Modo de descarte*: `unmap`.
     - *Motor de E/S*: `io_uring` (o `threads`).
4. **NIC** (Tarjeta de red):
   - **Modelo de dispositivo**: Cambia de `e1000e` a **`virtio`**.
5. **Añadir la ISO de drivers VirtIO**:
   - Pulsa en **Añadir hardware** (abajo a la izquierda).
   - Selecciona **Almacenamiento**.
   - Tipo de dispositivo: **Unidad de CDROM**.
   - Ruta: `~/Descargas/virtio-drivers/virtio-win.iso` (o pulsa Explorar).
   - Pulsa *Finalizar*.
6. **Vídeo y Pantalla**:
   - Pantalla: `Servidor SPICE`, Tipo de escucha: `Ninguno`.
   - Vídeo: `QXL` o `VirtIO`.
7. Pulsa arriba a la izquierda en **Iniciar la instalación**.

---

## 5. Método 2: Despliegue Automatizado por Terminal (`virt-install`)

Si prefieres aprovisionar la máquina virtual mediante un único comando en consola:

```bash
virt-install \
  --name win10-ltsc \
  --os-variant win10 \
  --vcpus 6,sockets=1,cores=3,threads=2 \
  --cpu host-passthrough \
  --memory 8192 \
  --boot uefi \
  --features smm=on,hyperv_relaxed=on,hyperv_vapic=on,hyperv_spinlocks=on \
  --disk path=$HOME/Workspace/MaquinasVirtuales/win10-ltsc.qcow2,format=qcow2,size=60,bus=virtio,cache=writeback,discard=unmap,io=threads \
  --cdrom /ruta/hacia/tu/ISO_WINDOWS_10_LTSC.iso \
  --disk path=$HOME/Descargas/virtio-drivers/virtio-win.iso,device=cdrom \
  --network network=default,model=virtio \
  --graphics spice,listen=none \
  --video qxl \
  --channel spicevmc \
  --noautoconsole
```

---

## 6. Proceso de Instalación de Windows (Carga del Driver VirtIO)

1. En cuanto se abra la ventana del visor, pulsa cualquier tecla para confirmar el arranque desde el CD de instalación.
2. Sigue el asistente de idioma y selecciona **Instalar ahora**.
3. Acepta el acuerdo de licencia y selecciona **Personalizada: instalar solo Windows (avanzado)**.
4. **Paso Clave**: El asistente mostrará: *"No encontramos ninguna unidad de disco"*. Esto se debe a que el instalador de Windows no incluye por defecto drivers de almacenamiento VirtIO.
5. Pulsa en **Cargar controlador** -> **Examinar**:
   - Localiza la unidad de CD llamada **`virtio-win`**.
   - Entra en la carpeta `viostor` -> `w10` -> `amd64`.
   - Pulsa **Aceptar**.
6. Aparecerá el controlador: **`Red Hat VirtIO SCSI controller`**. Selecciónalo y pulsa **Siguiente**.
7. Inmediatamente se reconocerá tu disco virtual (`Drive 0 Unallocated Space: 60.0 GB`).
8. Pulsa **Siguiente** para que Windows copie archivos, instale y se reinicie automáticamente.

---

## 7. Post-Instalación y Herramientas del Huésped (Guest Tools)

Una vez en el escritorio de Windows 10 LTSC:

1. Abre el **Explorador de archivos** y accede a la unidad de CD **`virtio-win`**.
2. Ejecuta el instalador global con doble clic:
   ```text
   virtio-win-guest-tools.exe
   ```
3. Acepta la instalación de todos los paquetes de controladores firmados. Esto configurará:
   - **NetKVM**: Controlador de red de 10 Gbps con aceleración de hardware.
   - **Balloon Service (`blnsvr`)**: Gestión elástica de memoria RAM para devolver memoria no usada a CachyOS.
   - **VirtIO Serial**: Canal de comunicación directo entre el host y la VM.
   - **SPICE VDAgent**: Portapapeles compartido (copiar y pegar texto/imágenes entre CachyOS y Windows) y adaptación automática de la resolución de pantalla al redimensionar la ventana.
   - **QEMU Guest Agent**: Permite al host apagar, suspender e inspeccionar IPs de la VM limpiamente.
4. Reinicia la máquina virtual.
5. En `virt-manager`, puedes expulsar y retirar los dos lectores de CD-ROM.

---

## 8. Máximo Rendimiento Gráfico en Niri: Conexión RDP (60 FPS)

El visor gráfico SPICE de `virt-manager` es ideal para mantenimiento, pero para trabajar diariamente con software ofimático o de diseño, el protocolo **RDP (Remote Desktop Protocol)** ofrece una aceleración por hardware y fluidez de puntero enormemente superior bajo Wayland.

### A. Habilitar RDP en Windows 10 LTSC
1. Abre el menú Inicio -> *Configuración* -> *Sistema* -> **Escritorio remoto**.
2. Activa el interruptor **Habilitar Escritorio remoto** y confirma.
3. Asegúrate de que tu usuario de Windows tenga una contraseña configurada.
4. Consulta la dirección IP asignada a la VM (ej. `192.168.122.145`) abriendo `cmd` y escribiendo `ipconfig`.

### B. Conectar desde CachyOS con FreeRDP 3 (`wlfreerdp3` o `sdl-freerdp3`)
En CachyOS, FreeRDP 3 instala los ejecutables con sufijo `3`: **`wlfreerdp3`** (Wayland) o **`sdl-freerdp3`** (nuevo cliente SDL3 de alto rendimiento con aceleración por GPU):

```bash
# Instalar FreeRDP en CachyOS si no está presente
sudo pacman -S --needed freerdp

# Conexión fluida a 60 FPS con Wayland, aceleración gráfica y portapapeles
wlfreerdp3 /v:192.168.122.18 \
           /u:caballero \
           /dynamic-resolution \
           +clipboard \
           /gdi:hw \
           /network:lan \
           /cert:ignore

# O alternativamente con el nuevo cliente SDL3 (máxima fluidez y renderizado por GPU):
sdl-freerdp3 /v:192.168.122.18 /u:caballero +clipboard /dynamic-resolution /gdi:hw /network:lan /cert:ignore
```

### C. Alias recomendado para Zsh / DMS (`~/.zshrc.d/virtualization.zsh`)
```bash
alias winvm='wlfreerdp3 /v:$(virsh domifaddr win10-ltsc | awk "/ipv4/ {print \$4}" | cut -d/ -f1) /u:caballero +clipboard /dynamic-resolution /gdi:hw /network:lan /cert:ignore'
```

---

## 9. Compartir Archivos entre CachyOS y Windows

### Opción A: Mediante RDP (Inmediato)
Al conectar con FreeRDP, puedes montar cualquier carpeta del host como unidad en Windows:
```bash
wlfreerdp3 /v:192.168.122.18 /u:caballero /drive:Compartido,$HOME/Workspace +clipboard /cert:ignore
```
Aparecerá en el Explorador de Windows bajo *Este equipo* como una unidad de red local.

### Opción B: Mediante VirtIO-FS (Nativo ultrarrápido)
1. En `virt-manager`, añade hardware -> **Sistema de archivos**:
   - Modo: `virtiofs`.
   - Ruta origen: `/home/caballero/Workspace`.
   - Etiqueta destino: `workspace`.
2. Dentro de Windows, instala **WinFsp** ([winfsp.dev](https://winfsp.dev/)) y activa el servicio `VirtioFsSvc` incluido en la carpeta `virtiofs` del CD VirtIO.

---

## 10. Diagnóstico y Comandos de Gestión Rápida

```bash
# Listar máquinas virtuales activas y apagadas
virsh list --all

# Iniciar la VM de Windows
virsh start win10-ltsc

# Ver la IP asignada por DHCP en la red default
virsh domifaddr win10-ltsc

# Apagar de forma limpia (vía QEMU Guest Agent)
virsh shutdown win10-ltsc

# Forzar apagado inmediato
virsh destroy win10-ltsc
```
