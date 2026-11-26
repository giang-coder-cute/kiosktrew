#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Google Book OS — VirtualBox Automated VM Provisioner
# ==============================================================================
VM_NAME="Google-Book-OS-Test"
ISO_PATH="${1:-./google-book-os-bookworm-amd64.iso}"
RAM_MB="4096"
DISK_MB="24576"
DISK_PATH="${HOME}/VirtualBox VMs/${VM_NAME}/${VM_NAME}.vdi"

if [[ ! -f "$ISO_PATH" ]]; then
  echo "[ERROR] Khong tim thay file ISO tai: $ISO_PATH"
  echo "Cach dung: ./virtualbox-setup.sh /duong/dan/toi/google-book-os-bookworm-amd64.iso"
  exit 1
fi

echo "[1/4] Tao may ao VirtualBox '$VM_NAME'..."
VBoxManage createvm --name "$VM_NAME" --ostype "Debian_64" --register

echo "[2/4] Cau hinh CPU, RAM (${RAM_MB}MB), GPU VMSVGA & Mang co day (82540EM)..."
VBoxManage modifyvm "$VM_NAME" \
  --memory "$RAM_MB" \
  --cpus 4 \
  --vram 128 \
  --graphicscontroller vmsvga \
  --audio-enabled on \
  --usb on \
  --usbehci on \
  --nic1 nat \
  --nictype1 82540EM \
  --cableconnected1 on \
  --boot1 dvd \
  --boot2 disk \
  --boot3 none \
  --boot4 none

echo "[3/4] Tao o cung ao ${DISK_MB}MB va gan file ISO..."
VBoxManage createhd --filename "$DISK_PATH" --size "$DISK_MB" --variant Standard
VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$DISK_PATH"

VBoxManage storagectl "$VM_NAME" --name "IDE Controller" --add ide
VBoxManage storageattach "$VM_NAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$ISO_PATH"

echo "[4/4] Khoi chay Google Book OS tren VirtualBox..."
VBoxManage startvm "$VM_NAME"
