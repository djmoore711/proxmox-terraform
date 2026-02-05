# Proxmox Terraform Configuration

![Hero banner](assets/hero_banner.png)

![Terraform](https://img.shields.io/badge/Terraform-1.5%2B-7B42BC)
![Provider](https://img.shields.io/badge/Provider-bpg%2Fproxmox-0A0A0A)
![GitHub last commit](https://img.shields.io/github/last-commit/djmoore711/proxmox-terraform)
![GitHub issues](https://img.shields.io/github/issues/djmoore711/proxmox-terraform)
![GitHub Repo stars](https://img.shields.io/github/stars/djmoore711/proxmox-terraform)

This Terraform configuration deploys Docker-ready virtual machines on Proxmox VE
using the modern `bpg/proxmox` provider. It is designed for scalability,
supporting both a generic pool of Docker nodes and specialized VMs like the AI
DevBox.

## 🚀 What This Deploys

### 1. Docker VM Pool (`main.tf`)

A scalable collection of VMs (e.g., `prox-docker`) configured for running Docker
containers with:

- **Scalability**: Managed via a `virtual_machines` map in `terraform.tfvars`.
- **Resources**: Configurable per-VM (Default: 2 Cores, 4GB RAM, 60GB Disk).
- **Automation**: Tailscale + Portainer pre-installed via Cloud-Init.

### 2. AI DevBox (`devbox.tf`)

A specialized development environment optimized for AI and agentic workloads (VM
ID: 105):

- **Node**: `proxmox-02`
- **Resources**: 6GB RAM, 50GB SSD (local-lvm), 2 CPU Cores (host type).
- **OS**: Debian 12 (Template-based).
- **Environment**:
  - Hardened production-grade Docker CE installation.
  - Node.js 22 (LTS) pre-installed.
  - Automated Tailscale connectivity with MagicDNS support.
  - Essential build tools (`build-essential`, `python3-venv`, `git`).

## 📋 Prerequisites

> [!WARNING]
> Never commit `terraform.tfvars`, any `*.tfstate*` files, or `.terraform/`.

> [!IMPORTANT]
> **Tailscale SSH Correction**: If your Proxmox API is over Tailscale but the
> nodes have unreachable local IPs, `provider.tf` is configured to map node
> names to MagicDNS addresses for SSH snippet uploads.

1. **Proxmox VE** installation with API access.
2. **Terraform** >= 1.5 installed locally.
3. **Proxmox API token** with appropriate permissions.
4. **Template VM(s)**:
   - Debian 12 Template (e.g., ID 9000).
5. **SSH access to the target Proxmox node**:
   - This repo uses `ssh-agent`. Ensure `ssh-add -L` shows your public key.

## 🛠️ Setup

### 1. Clone the Repository

```bash
git clone https://github.com/djmoore711/proxmox-terraform.git
cd proxmox-terraform
```

### 2. Configure Variables

Copy the example variables file and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to define your infrastructure:

```hcl
# Proxmox API
proxmox_api_url          = "https://proxmox-02.your-tailnet.ts.net:8006/api2/json"
proxmox_api_token_id     = "terraform@pam!terraform"
proxmox_api_token_secret = "your-secret-uuid"
proxmox_host_node        = "proxmox-02"

# VM Pool (main.tf)
virtual_machines = {
  "prox-docker" = {
    vm_id              = 104
    vm_name            = "prox-docker"
    cores              = 2
    memory             = 4096
    disk_size          = 60
    tailscale_hostname = "prox-docker"
    tailscale_tags     = ["tag:homelab"]
  }
}

# AI DevBox (devbox.tf)
devbox_node        = "proxmox-02"
devbox_vm_id       = 105
devbox_vm_name     = "ai-devbox"
debian_template_id = 9000
```

### 3. Initialize and Deploy

```bash
terraform init
terraform plan
terraform apply
```

## 📁 File Structure

```
proxmox-terraform/
├── main.tf                      # Generic VM pool (for_each)
├── devbox.tf                    # Specialized AI DevBox resource
├── provider.tf                  # Provider + Tailscale SSH MagicDNS mapping
├── variables.tf                 # Var definitions (Multi-VM + DevBox)
├── outputs.tf                   # Merged VM maps (IDs and Names)
├── templates/
│   ├── cloud-init-bootstrap.yaml.tftpl  # Docker + Tailscale stack
│   └── cloud-init-devbox.yaml.tftpl     # Hardened Clean Dev environment
└── terraform.tfvars.example     # Template for user configuration
```

## 🚨 Troubleshooting

**"No Route to Host" (SSH)** If Terraform fails to upload cloud-init snippets
while connected over Tailscale, ensure your nodes are mapped in the
`provider.tf` SSH block to use their MagicDNS addresses:

```hcl
ssh {
  node {
    name    = "proxmox-02"
    address = "proxmox-02.your-tailnet.ts.net"
  }
}
```

## 🔄 Manual State Migration

If you are transitioning from an older version of this repo where
`proxmox_virtual_environment_vm.vm-instance` was a single resource, you can
migrate your state manually to avoid recreation:

```bash
terraform state mv 'proxmox_virtual_environment_vm.vm-instance' 'proxmox_virtual_environment_vm.vm-instance["your-new-key"]'
terraform state mv 'proxmox_virtual_environment_file.cloud_init_snippet' 'proxmox_virtual_environment_file.cloud_init_snippet["your-new-key"]'
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test with `terraform plan`
4. Submit a pull request

## 📄 License

This configuration is provided as-is for educational and operational purposes.
