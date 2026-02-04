terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.88.0"
    }
  }
  required_version = ">= 1.5"
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = true

  ssh {
    agent    = true
    username = "root"

    # Force SSH to use MagicDNS for proxmox-02
    node {
      name    = "proxmox-02"
      address = "proxmox-02.crocodile-morray.ts.net"
    }

    # Add proxmox-01 as well for future safety
    node {
      name    = "proxmox-01"
      address = "proxmox-01.crocodile-morray.ts.net"
    }
  }
}