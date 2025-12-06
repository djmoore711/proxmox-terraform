resource "proxmox_virtual_environment_vm" "vm-instance" {
    vm_id       = 100
    name        = "vm-instance"
    node_name   = var.proxmox_host_node
    description = "VM created by Terraform"
    
    clone {
      vm_id     = var.template_vm_id
      full      = true
      node_name = "proxmox-01" // source node where the template (vm_id) lives
    }
    
    cpu {
      cores   = 2
      sockets = 1
    }
    
    memory {
      dedicated = 4096
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
      size         = 60
    }
    
    initialization {
      user_account {
        username = "debian"
        password = var.vm_password
      }
      ip_config {
        ipv4 {
          address = "dhcp"
        }
      }
    }
}