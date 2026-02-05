# Upload cloud-init snippet to Proxmox node
resource "proxmox_virtual_environment_file" "cloud_init_snippet" {
  for_each     = var.virtual_machines
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_host_node

  source_raw {
    data = templatefile("${path.module}/templates/cloud-init-bootstrap.yaml.tftpl", {
      tailscale_auth_key = var.tailscale_auth_key
      hostname           = each.value.tailscale_hostname
      vm_password        = var.vm_password
      ssh_key            = chomp(file(pathexpand(var.ssh_public_key_path)))
    })
    file_name = "cloud-init-${each.value.vm_id}.yaml"
  }
}

# VM resource
resource "proxmox_virtual_environment_vm" "vm-instance" {
  for_each    = var.virtual_machines
  vm_id       = each.value.vm_id
  name        = each.value.vm_name
  node_name   = var.proxmox_host_node
  description = "VM created by Terraform with Docker, Tailscale, and Portainer"

  clone {
    vm_id     = var.template_vm_id
    full      = true
    node_name = var.proxmox_host_node
  }

  cpu {
    cores   = each.value.cores
    sockets = 1
  }

  memory {
    dedicated = each.value.memory
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
    datastore_id = var.storage_volume
    interface    = "scsi0"
    file_format  = "raw"
    size         = each.value.disk_size
  }

  initialization {
    type = "nocloud"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_snippet[each.key].id
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id,
    ]
  }
}