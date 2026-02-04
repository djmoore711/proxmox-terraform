output "vm_ids" {
  description = "The IDs of the created VMs"
  value = merge(
    { for k, v in proxmox_virtual_environment_vm.vm-instance : k => v.vm_id },
    { "ai-devbox" = proxmox_virtual_environment_vm.devbox.vm_id }
  )
}

output "vm_names" {
  description = "The names of the created VMs"
  value = merge(
    { for k, v in proxmox_virtual_environment_vm.vm-instance : k => v.name },
    { "ai-devbox" = proxmox_virtual_environment_vm.devbox.name }
  )
}
