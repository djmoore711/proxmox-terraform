# variables.tf

variable "proxmox_api_url" {
  description = "The endpoint for the Proxmox API (e.g., https://192.168.1.100:8006/)"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "The API Token ID (e.g., root@pam!terraform)"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "The Secret UUID for the API Token"
  type        = string
  sensitive   = true
}

variable "proxmox_host_node" {
  description = "The name of the Proxmox node to deploy VMs on"
  type        = string
  default     = "proxmox-01" # You can set a default if you usually use the same node
}

variable "template_vm_id" {
  description = "The VM ID of the template to clone from"
  type        = number
  default     = 9001
}

variable "virtual_machines" {
  description = "A map of virtual machines to create"
  type = map(object({
    vm_id              = number
    vm_name            = string
    cores              = optional(number, 2)
    memory             = optional(number, 4096)
    disk_size          = optional(number, 60)
    tailscale_hostname = string
    tailscale_tags     = optional(list(string), [])
  }))
  default = {}
}

variable "devbox_node" {
  description = "Target node for DevBox"
  type        = string
  default     = "proxmox-02"
}

variable "devbox_vm_id" {
  description = "VM ID for DevBox"
  type        = number
}

variable "devbox_vm_name" {
  description = "Name of the DevBox VM"
  type        = string
  default     = "ai-devbox"
}

variable "debian_template_id" {
  description = "ID of the Debian 12 Cloud-Init Template"
  type        = number
  default     = 9000
}

variable "vm_password" {
  description = "Password for VM cloud-init user"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for VM access"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "storage_volume" {
  description = "Storage volume for VM disk"
  type        = string
  default     = "local-lvm"
}

variable "tailscale_auth_key" {
  description = "Tailscale authentication key"
  type        = string
  sensitive   = true
}
