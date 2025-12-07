# Template for cloud-init user data
locals {
  cloud_init_content = templatefile("${path.module}/templates/cloud-init-bootstrap.yaml.tftpl", {
    tailscale_auth_key = var.tailscale_auth_key
    tailscale_hostname = var.tailscale_hostname
    tailscale_tags     = join(",", var.tailscale_tags)
    vm_password        = var.vm_password
  })
}

# Upload cloud-init snippet to Proxmox node
resource "null_resource" "cloud_init_snippet" {
  triggers = {
    hash = sha1(local.cloud_init_content)
  }

  provisioner "local-exec" {
    command = <<EOF
      # Render the template to a temporary file
      echo '${replace(local.cloud_init_content, "'", "'\"'\"'")}' > /tmp/cloud-init-${var.vm_id}.yaml
      
      # Upload to Proxmox node
      scp -o StrictHostKeyChecking=no /tmp/cloud-init-${var.vm_id}.yaml root@${var.proxmox_node}:/var/lib/vz/snippets/cloud-init-${var.vm_id}.yaml
      
      # Clean up
      rm /tmp/cloud-init-${var.vm_id}.yaml
    EOF
  }
}

# VM resource
resource "proxmox_virtual_environment_vm" "vm-instance" {
  vm_id       = var.vm_id
  name        = var.vm_name
  node_name   = var.proxmox_host_node
  description = "VM created by Terraform with Docker, Tailscale, and Portainer"
  
  clone {
    vm_id     = var.template_vm_id
    full      = true
    node_name = var.template_source_node
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
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = "${var.snippet_storage}:snippets/cloud-init-${var.vm_id}.yaml"
  }

  depends_on = [null_resource.cloud_init_snippet]
}