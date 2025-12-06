output "vm_id" {
  description = "The ID of the created VM"
  value       = proxmox_virtual_environment_vm.vm-instance.vm_id
}

output "vm_name" {
  description = "The name of the created VM"
  value       = proxmox_virtual_environment_vm.vm-instance.name
}
