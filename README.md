# Proxmox Terraform Configuration

This Terraform configuration deploys a Docker-ready virtual machine on Proxmox VE using the modern `bpg/proxmox` provider.

## 🚀 What This Deploys

A single VM configured for running 5-10 Docker containers with the following specifications:

- **VM ID**: 100 (configurable)
- **Name**: vm-instance (configurable)
- **Target Node**: Your chosen Proxmox node
- **Source Template**: Your template VM ID
- **Resources**:
  - CPU: 2 cores, 1 socket
  - Memory: 4GB dedicated
  - Disk: 60GB on your storage (scsi0 interface, raw format)
  - Network: virtio on vmbr0 bridge (configurable)
  - Cloud-Init: Debian user with DHCP networking

## 📋 Prerequisites

1. **Proxmox VE** installation with API access
2. **Terraform** >= 1.5 installed locally
3. **Proxmox API token** with appropriate permissions:
   - `VM.Clone`, `VM.Config.Disk`, `VM.Config.CPU`, `VM.Config.Memory`
   - `VM.Config.Network`, `VM.Config.Options`
   - `Datastore.Audit`, `Pool.Allocate`
4. **Template VM** with Cloud-Init configured (ID configurable)
5. **SSH access to the target Proxmox node** for snippet uploads

   The `bpg/proxmox` provider uses SSH for certain operations (including uploading snippet files).
   This repo is configured to use `ssh-agent` authentication.

   - Ensure `ssh-add -L` shows a loaded key
   - Ensure the target node SSH user (configured in `provider.tf`) accepts that key
   - Note: SSH configuration in `~/.ssh/config` is not used by the provider
6. **GitHub CLI** (optional, for repo management)

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

Edit `terraform.tfvars` with your actual values:
```hcl
# Proxmox API configuration
proxmox_api_url          = "https://your-proxmox-host:8006/"
proxmox_api_token_id     = "your-token-id"
proxmox_api_token_secret = "your-token-secret"

# Deployment configuration
proxmox_host_node = "your-target-node"  # Target node
vm_id             = 100                 # New VM ID
template_vm_id    = 900                # Source template ID
vm_password       = "your-vm-password"
storage_volume    = "local-lvm"

# VM configuration
vm_name           = "prox-docker"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"

# Tailscale configuration
tailscale_auth_key = "your-tailscale-auth-key"
tailscale_hostname = "prox-docker"
tailscale_tags     = ["tag:homelab"]
```

> **💡 API Token Setup**: See the [Proxmox provider documentation](https://registry.terraform.io/providers/bpg/proxmox/latest/docs#api-token-authentication) for detailed instructions on creating and configuring your API token.

### 3. Initialize Terraform
```bash
terraform init
```

### 4. Review the Plan
```bash
terraform plan
```

### 5. Deploy
```bash
terraform apply
```

### 6. Verify Services (Tailscale, Docker, Portainer)
Run these on the VM:
```bash
tailscale status
docker ps
curl -kI https://localhost:9443 || curl -I http://localhost:8000
tail -n 200 /var/log/bootstrap.log
```

### 7. Cloud-Init Bootstrap (Tailscale + Portainer)
On first boot, the VM automatically:

- **Installs Docker CE** from the official Docker repository
- **Installs and joins Tailscale** using the provided auth key
- **Deploys Portainer** as a Docker container on ports 8000 and 9443

The bootstrap process is handled by a cloud-init snippet that is:
1. Rendered using Terraform's `templatefile()` function
2. Uploaded to the Proxmox node's snippets directory via SCP
3. Referenced in the VM's cloud-init configuration

**Accessing Portainer:**
- Once the VM boots and Portainer starts, access it at:
  - `https://<vm-ip-or-hostname>:9443` (HTTPS, recommended)
  - `http://<vm-ip-or-hostname>:8000` (HTTP, legacy)

**Accessing Portainer over Tailscale (MagicDNS):**
- If you have Tailscale MagicDNS enabled, you can typically use the node's MagicDNS name:
  - `https://<magicdns-hostname>.<tailnet>.ts.net:9443`
  - `http://<magicdns-hostname>.<tailnet>.ts.net:8000`

**Tailscale Configuration:**
- The VM automatically joins your Tailscale network with the specified hostname and tags
- Use Tailscale ACLs to control access to the node and Portainer

## 📁 File Structure

```
proxmox-terraform/
├── README.md                    # This file
├── .gitignore                   # Excludes secrets and state
├── .terraform.lock.hcl          # Provider version lock
├── main.tf                      # VM resource definition
├── provider.tf                  # Provider configuration
├── variables.tf                 # Variable definitions
├── outputs.tf                   # Output values
├── terraform.tfvars.example     # Template for user configuration
└── templates/
    └── cloud-init-bootstrap.yaml.tftpl  # Cloud-init bootstrap template
```

### File Descriptions

#### `provider.tf`
- Configures the `bpg/proxmox` provider (~> 0.88.0)
- Sets up API endpoint, authentication, and TLS settings
- Includes `insecure = true` for self-signed certificates

#### `main.tf`
- Defines the `proxmox_virtual_environment_vm` resource
- Clones from the configured `template_vm_id` on the configured `proxmox_host_node`
- Configures Cloud-Init for Debian user and DHCP networking
- Renders cloud-init bootstrap template using `templatefile()`
- Uploads cloud-init snippet to Proxmox node via SCP
- Automatically installs Docker CE, Tailscale, and Portainer on first boot

#### `variables.tf`
- Declares all input variables with types and descriptions
- Sets sensible defaults where appropriate
- Marks sensitive values (`api_token_secret`, `vm_password`, `tailscale_auth_key`)
- Includes new variables for VM naming and Tailscale configuration

#### `outputs.tf`
- Exports VM ID and name for reference
- Useful for automation and integration

#### `templates/cloud-init-bootstrap.yaml.tftpl`
- Cloud-init template for first-boot bootstrap
- Installs Docker CE from official repository
- Installs Tailscale and joins the specified tailnet
- Deploys Portainer as a Docker container
- Uses Terraform variables for dynamic configuration

#### `.gitignore`
- Protects sensitive files:
  - `*.tfvars` (contains secrets)
  - `*.tfstate*` (infrastructure state)
  - `.terraform/` (working directory)
- Allows `.terraform.lock.hcl` for reproducible builds

## 🔧 Configuration Details

### VM Specifications
- **CPU**: 2 cores, qemu64 type, 100 units per core
- **Memory**: 4GB dedicated, no floating or shared memory
- **Disk**: 60GB, scsi0 interface, raw format, io_uring AIO
- **Network**: virtio model on vmbr0 bridge, firewall disabled
- **Agent**: QEMU Guest Agent enabled (15m timeout)

### Cloud-Init Configuration
- **User**: debian (with specified password)
- **Network**: IPv4 DHCP
- **Datastore**: local-lvm for cloud-init files

### Clone Settings
- **Full clone**: Creates independent VM copy
- **Source**: `template_vm_id`
- **Target**: `proxmox_host_node`
- **Retries**: 1 (configurable via timeout_clone)

## 🔒 Security Considerations

### ⚠️ CRITICAL: Never Commit terraform.tfvars
- `terraform.tfvars` contains sensitive secrets (API token, VM password, Tailscale auth key)
- **Never commit this file to version control**
- Use `terraform.tfvars.example` as the template and keep real values local-only
- If you have accidentally committed secrets, **rotate them immediately**

### API Token
- Create a dedicated API token for Terraform
- Grant minimum required permissions
- Store token in `terraform.tfvars` (never commit)
- Rotate tokens regularly

### Network Security
- VM connects to `vmbr0` bridge (adjust for your network)
- Firewall disabled on VM network interface
- Consider enabling firewall rules for production

### Secrets Management
- All sensitive values marked with `sensitive = true` in variables
- `.gitignore` prevents accidental commits of secrets
- Use environment variables or secret management tools for CI/CD

## 🚨 Troubleshooting

### Common Issues

**DNS Resolution Error**
```
lookup bpg-proxmox.crocodile-morray.ts.net: no such host
```
- Check `proxmox_api_url` in `terraform.tfvars`
- Ensure hostname resolves from your machine

**Template Not Found**
```
unable to find configuration file for VM 9000 on node 'proxmox-02'
```
- Verify template VM exists and is on proxmox-02
- Check template VM ID matches `template_vm_id`

**Permission Denied**
```
Permission check failed (/vms/100, VM.GuestAgent.Audit)
```
- Ensure API token has required permissions
- Check VM Guest Agent permissions in Proxmox

**TLS Certificate Error**
```
certificate is not trusted
```
- Provider configured with `insecure = true` for self-signed certs
- For production, configure proper TLS certificates

### State Management
- Terraform state stored locally in `.terraform.tfstate`
- For team use, configure remote state backend
- Never commit state files to version control

## 🔄 Updates and Modifications

### Changing VM Resources
Edit `main.tf` and adjust:
- `cpu { cores = ... }`
- `memory { dedicated = ... }`
- `disk { size = ... }`

### Different Template or Node
Update `terraform.tfvars`:
- `template_vm_id = ...`
- `proxmox_host_node = "..."`

### Network Configuration
Modify `main.tf` network_device block:
```hcl
network_device {
  bridge   = "your-bridge"
  model    = "virtio"  # or "e1000", "rtl8139"
  firewall = true/false
}
```

## 📚 References

- [bpg/proxmox Provider Documentation](https://registry.terraform.io/providers/bpg/proxmox/latest)
- [Proxmox VE API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `terraform plan`
5. Submit a pull request

## 📄 License

This configuration is provided as-is for educational and operational purposes.
