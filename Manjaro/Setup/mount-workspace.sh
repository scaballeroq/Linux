#!/bin/bash
# mount-workspace.sh - Configuración de automontaje permanente de la partición Workspace en /etc/fstab para Manjaro Linux

set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(eval echo "~$TARGET_USER")
MOUNT_POINT="$TARGET_HOME/Workspace"
KNOWN_UUID="74A413DE-2268-4F03-998C-68A3ABA151CF"

echo "🚀 Configurando montaje automático de la partición Workspace en Manjaro..."

# 1. Identificar la partición por Etiqueta "Workspace" o por el UUID conocido
PART_DEV=$(blkid -L "Workspace" 2>/dev/null || blkid -U "$KNOWN_UUID" 2>/dev/null || lsblk -no PATH,UUID 2>/dev/null | grep "$KNOWN_UUID" | awk '{print $1}' | head -n1 || true)

if [ -z "$PART_DEV" ]; then
    # Buscar una partición ext4 secundaria (distinta de la raíz /)
    PART_DEV=$(lsblk -lno PATH,FSTYPE,MOUNTPOINT 2>/dev/null | grep "ext4" | grep -v " /$" | awk '{print $1}' | head -n1 || true)
fi

if [ -z "$PART_DEV" ]; then
    echo "⚠️ No se encontró la partición de Workspace en el sistema."
    exit 0
fi

# Asignar la etiqueta 'Workspace' a la partición ext4 si no la tiene
CURRENT_LABEL=$(sudo e2label "$PART_DEV" 2>/dev/null || true)
if [ "$CURRENT_LABEL" != "Workspace" ]; then
    echo "ℹ️ Asignando etiqueta de disco 'Workspace' a $PART_DEV..."
    sudo e2label "$PART_DEV" "Workspace" 2>/dev/null || true
fi

# Obtener UUID y tipo de sistema de archivos
PART_UUID=$(sudo blkid -s UUID -o value "$PART_DEV" || true)
FS_TYPE=$(sudo blkid -s TYPE -o value "$PART_DEV" || echo "ext4")

if [ -z "$PART_UUID" ]; then
    PART_UUID="$KNOWN_UUID"
fi

echo "✅ Partición Workspace detectada: $PART_DEV (UUID: $PART_UUID, FS: $FS_TYPE)"

# 2. Crear punto de montaje si no existe
sudo mkdir -p "$MOUNT_POINT"

# 3. Configurar automontaje seguro en /etc/fstab
FSTAB_LINE="UUID=$PART_UUID $MOUNT_POINT $FS_TYPE defaults,noatime,nofail 0 2"

if ! grep -q "$PART_UUID" /etc/fstab && ! grep -q "$MOUNT_POINT" /etc/fstab; then
    echo "ℹ️ Añadiendo entrada de montaje automático en /etc/fstab..."
    echo "# Partición de Datos Workspace" | sudo tee -a /etc/fstab > /dev/null
    echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null
    echo "✅ Entrada añadida a /etc/fstab con opción nofail (Arranque seguro)."
else
    echo "✅ La entrada para Workspace ya existe en /etc/fstab."
fi

# 4. Montar partición y asignar permisos al usuario
echo "ℹ️ Montando partición y asegurando permisos de usuario..."
sudo mount -a 2>/dev/null || sudo mount "$MOUNT_POINT" 2>/dev/null || true
sudo chown -R "$TARGET_USER:$TARGET_USER" "$MOUNT_POINT"

echo "================================================================="
echo "✅ Partición Workspace configurada para montarse automáticamente en:"
echo "👉 $MOUNT_POINT"
echo "================================================================="
