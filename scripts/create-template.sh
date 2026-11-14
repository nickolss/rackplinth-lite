#!/bin/sh
# Creates the cloud-init template the Terraform module clones.
# Run it as root on the Proxmox host:  sh scripts/create-template.sh [VMID] [STORAGE] [BRIDGE]
set -eu

VMID="${1:-9000}"
STORAGE="${2:-local-lvm}"
BRIDGE="${3:-vmbr0}"
BASE="https://cloud.debian.org/images/cloud/trixie/latest"
IMAGE="debian-13-generic-amd64.qcow2"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if qm status "$VMID" >/dev/null 2>&1; then
  echo "VM $VMID already exists. Pick another ID or remove it first." >&2
  exit 1
fi

command -v virt-customize >/dev/null || apt-get install -y libguestfs-tools

cd "$WORK"
wget -q "$BASE/$IMAGE" "$BASE/SHA512SUMS"
grep " $IMAGE\$" SHA512SUMS | sha512sum -c -

# The Terraform module turns the QEMU guest agent on, and Proxmox reads VM addresses through it.
# Debian cloud images do not include it, so it goes into the image before the template is made.
virt-customize -q -a "$IMAGE" --install qemu-guest-agent --truncate /etc/machine-id

qm create "$VMID" --name debian13-cloud --memory 2048 --cores 2 --net0 "virtio,bridge=$BRIDGE" \
  --scsihw virtio-scsi-single --ostype l26 --agent enabled=1 --serial0 socket --vga serial0
qm set "$VMID" --scsi0 "$STORAGE:0,import-from=$WORK/$IMAGE,discard=on,ssd=1"
qm set "$VMID" --ide2 "$STORAGE:cloudinit" --boot order=scsi0
qm template "$VMID"
echo "Template $VMID is ready."
