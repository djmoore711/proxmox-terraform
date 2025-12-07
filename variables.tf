# variables.tf

variable "proxmox_api_url" {
  description = "The URL for the Proxmox API (e.g., https://192.168.1.100:8006/api2/json)"
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

variable "vm_id" {
  description = "Unique VM ID for the new VM (must be between 100-999999999)"
  type        = number
  default     = 100
}

variable "vm_password" {
  description = "Password for VM cloud-init user"
  type        = string
  sensitive   = true
}

variable "storage_volume" {
  description = "Storage volume for VM disk"
  type        = string
  default     = "local-lvm"
}

variable "vm_name" {
  description = "Name of the VM instance"
  type        = string
  default     = "docker-node-01"
}

variable "tailscale_auth_key" {
  description = "Tailscale authentication key"
  type        = string
  sensitive   = true
}

variable "tailscale_hostname" {
  description = "Hostname for the Tailscale node"
  type        = string
  default     = "docker-node-01"
}

variable "tailscale_tags" {
  description = "List of Tailscale tags for ACLs"
  type        = list(string)
  default     = ["tag:homelab"]
}

variable "proxmox_node" {
  description = "Proxmox node name for snippet storage"
  type        = string
  default     = "proxmox-01"
}

variable "template_source_node" {
  description = "Proxmox node where the template VM resides"
  type        = string
  default     = "proxmox-01"
}

variable "snippet_storage" {
  description = "Storage ID for cloud-init snippets (e.g., 'local', 'local-lvm')"
  type        = string
  default     = "local"
}
