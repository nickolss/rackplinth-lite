# Rackplinth Lite

From a bare Proxmox host to Debian VMs in one command: a verified cloud-init template and a Terraform module that creates every VM from a short list.

- **`scripts/create-template.sh`** downloads the official Debian 13 cloud image, checks its SHA512 checksum, installs the QEMU guest agent and turns it into a template.
- **`terraform/modules/vm`** clones that template into a VM with a static IP, your SSH key and no password login.
- **`terraform/example`** describes all VMs in one map and writes an Ansible inventory for them.

Tested on Proxmox VE 9.2 with OpenTofu 1.13 and the `bpg/proxmox` provider 0.122. Terraform 1.6+ works too.

## 1. Build the template

On the Proxmox host, as root:

```bash
sh scripts/create-template.sh                       # template 9000 on local-lvm, bridge vmbr0
sh scripts/create-template.sh 9000 local-zfs vmbr0  # if Proxmox runs on ZFS
```

## 2. Create an API token

```bash
pveum user token add root@pam terraform --privsep 0
```

Proxmox shows the value once. Keep it in the environment, not in a file:

```bash
export PROXMOX_VE_ENDPOINT=https://pve.example.lan:8006/
export PROXMOX_VE_API_TOKEN='root@pam!terraform=THE_VALUE'
```

## 3. Describe the VMs and apply

```bash
cd terraform/example
cp terraform.tfvars.example terraform.tfvars   # edit node, gateway, SSH key and the vms map
terraform init && terraform apply              # or: tofu init && tofu apply
ssh ops@192.168.10.31
```

To add a VM, add a line to `vms`. To remove one, delete its line and apply again.

## Common errors

- **`x509: certificate signed by unknown authority`:** a new Proxmox install uses a self-signed certificate. Issue a real one (Datacenter → ACME) or, on a network you trust, `export PROXMOX_VE_INSECURE=true`.
- **`storage 'local-lvm' does not exist`:** on a ZFS install the storage is `local-zfs`. Set `datastore = "local-zfs"`.
- **`apply` hangs waiting for an IP:** the template has no QEMU guest agent. Build it with the script above.
- **An `apply` that failed halfway:** Proxmox may keep VMs Terraform no longer tracks. Delete them before applying again, or their IDs and IPs will clash.

## Want what runs inside the VMs?

[Rackplinth](https://rackplinth.nickolasmaia.com.br) adds Ansible roles for SSH hardening, firewall and fail2ban, k3s with secrets encryption, Docker and encrypted restic backups, plus a step-by-step guide tested end to end.

Launch price until December 31: [US$ 29 instead of US$ 39](https://nickolasmaia.gumroad.com/l/rackplinth/LAUNCH) (code `LAUNCH`, applied automatically).

## License

MIT. See [LICENSE](LICENSE).

Proxmox® is a registered trademark of Proxmox Server Solutions GmbH. This project is not affiliated with Proxmox Server Solutions GmbH.
