variable "name" {
  type        = string
  description = "VM hostname"
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.name))
    error_message = "Use a valid lowercase hostname."
  }
}

variable "node" {
  type        = string
  description = "Proxmox node that hosts the VM"
}

variable "template_id" {
  type        = number
  description = "ID of the cloud-init template to clone"
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory_mb" {
  type    = number
  default = 4096
}

variable "disk_gb" {
  type    = number
  default = 40
}

variable "datastore" {
  type    = string
  default = "local-lvm"
}

variable "bridge" {
  type    = string
  default = "vmbr0"
}

variable "vlan_id" {
  type    = number
  default = null
}

variable "ipv4_cidr" {
  type        = string
  description = "Static address such as 192.168.10.21/24"
}

variable "gateway" {
  type = string
}

variable "dns_servers" {
  type    = list(string)
  default = ["1.1.1.1", "9.9.9.9"]
}

variable "admin_user" {
  type    = string
  default = "ops"
}

variable "ssh_public_keys" {
  type        = list(string)
  description = "Keys allowed to log in. Password login is never configured."
  validation {
    condition     = length(var.ssh_public_keys) > 0
    error_message = "Provide at least one SSH public key."
  }
}

variable "tags" {
  type    = list(string)
  default = ["rackplinth"]
}
