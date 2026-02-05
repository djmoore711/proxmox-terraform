# devbox.tf

# 1. Cloud-Init Template (Reuses existing ssh_key variable)
locals {
  devbox_cloud_init = templatefile("${path.module}/templates/cloud-init-devbox.yaml.tftpl", {
    vm_password = var.vm_password 
    ssh_key     = chomp(file(pathexpand(var.ssh_public_key_path)))
  })
}

# 2. Upload Cloud-Init Snippet to the specific target node
resource "proxmox_virtual_environment_file" "devbox_cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.devbox_node

  source_raw {
    data      = local.devbox_cloud_init
    file_name = "cloud-init-${var.devbox_vm_id}.yaml"
  }
}

# 3. The DevBox VM Resource
resource "proxmox_virtual_environment_vm" "devbox" {
  vm_id       = var.devbox_vm_id
  name        = var.devbox_vm_name
  node_name   = var.devbox_node
  description = "AI Agent DevBox (Debian 12) - 6GB RAM - 50GB Disk"

  clone {
    vm_id     = var.debian_template_id
    full      = true
    node_name = var.devbox_node
  }

  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = 6144 # 6GB RAM Limit
    floating  = 4096 
  }

  agent {
    enabled = true
  }

  network_device {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = false
  }

  disk {
    datastore_id = var.storage_volume # Uses local-lvm
    interface    = "scsi0"
    file_format  = "raw"
    size         = 50
    ssd          = true
    discard      = "on"
  }

  initialization {
    type = "nocloud"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.devbox_cloud_init.id
  }
  
  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id,
    ]
  }
}
