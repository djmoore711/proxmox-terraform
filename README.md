# Proxmox Terraform Configuration

This Terraform configuration deploys a Docker-ready virtual machine on Proxmox VE using the modern `bpg/proxmox` provider.

## 🚀 What This Deploys

A single VM configured for running 5-10 Docker containers with the following specifications:

- **VM ID**: 100 (configurable)
- **Name**: vm-instance (configurable)
- **Target Node**: Your chosen Proxmox node
- **Source Template**: Your template VM ID (configurable)
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
5. **GitHub CLI** (optional, for repo management)

## 🛠️ Setup

### 1. Clone the Repository
```bash
git clone <your-repo-url>
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
```

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
└── terraform.tfvars.example     # Template for user configuration
```

### File Descriptions

#### `provider.tf`
- Configures the `bpg/proxmox` provider (~> 0.88.0)
- Sets up API endpoint, authentication, and TLS settings
- Includes `insecure = true` for self-signed certificates

#### `main.tf`
- Defines the `proxmox_virtual_environment_vm` resource
- Clones from template VM 9000 on proxmox-01
- Deploys to proxmox-02 with specified resources
- Configures Cloud-Init for Debian user and DHCP networking

#### `variables.tf`
- Declares all input variables with types and descriptions
- Sets sensible defaults where appropriate
- Marks sensitive values (`api_token_secret`, `vm_password`)

#### `outputs.tf`
- Exports VM ID and name for reference
- Useful for automation and integration

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
- **Source**: VM 9000 on proxmox-01
- **Target**: proxmox-02
- **Retries**: 1 (configurable via timeout_clone)

## 🔒 Security Considerations

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
- Verify template VM exists and is on proxmox-01
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
