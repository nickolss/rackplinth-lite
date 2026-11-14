terraform {
  required_version = ">= 1.6"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.122.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Credentials come from the environment, never from files:
#   export PROXMOX_VE_ENDPOINT=https://pve.example.lan:8006/
#   export PROXMOX_VE_API_TOKEN='root@pam!terraform=...'
provider "proxmox" {}

variable "node" {
  type        = string
  description = "Proxmox node that hosts the VMs"
}

variable "template_id" {
  type        = number
  default     = 9000
  description = "ID of the template made by scripts/create-template.sh"
}

variable "gateway" { type = string }
variable "ssh_public_keys" { type = list(string) }

variable "datastore" {
  type        = string
  default     = "local-lvm"
  description = "Storage for the VM disks: local-lvm on a default install, local-zfs on ZFS"
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "vms" {
  description = "One entry per VM. Add a line to create a VM, delete it to destroy the VM."
  type = map(object({
    ipv4_cidr = string
    cores     = optional(number, 2)
    memory_mb = optional(number, 2048)
    disk_gb   = optional(number, 20)
  }))
}

module "vm" {
  source   = "../modules/vm"
  for_each = var.vms

  name            = each.key
  node            = var.node
  template_id     = var.template_id
  gateway         = var.gateway
  ssh_public_keys = var.ssh_public_keys
  ipv4_cidr       = each.value.ipv4_cidr
  datastore       = var.datastore
  bridge          = var.bridge
  cores           = each.value.cores
  memory_mb       = each.value.memory_mb
  disk_gb         = each.value.disk_gb
}

# An Ansible inventory with every VM, ready for: ansible all -i inventory.yml -m ping
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/inventory.yml"
  file_permission = "0640"
  content = yamlencode({
    all = {
      vars  = { ansible_user = "ops" }
      hosts = { for k, v in var.vms : k => { ansible_host = split("/", v.ipv4_cidr)[0] } }
    }
  })
}

output "addresses" {
  value = { for k, m in module.vm : k => m.ipv4 }
}
