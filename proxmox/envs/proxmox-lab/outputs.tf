output "vm_ids" {
  description = "Proxmox VM IDs keyed by VM name"
  value       = { for k, v in proxmox_virtual_environment_vm.vm : k => v.vm_id }
}

output "vm_ip_addresses" {
  description = "Assigned IP addresses (static for subnet mode, null for DHCP bridge mode)"
  value = {
    for k, v in local.vms : k => (
      v.ip_cidr != "dhcp" ? split("/", v.ip_cidr)[0] : "dhcp"
    )
  }
}

output "network_mode" {
  description = "Active network topology"
  value       = var.network_mode
}

output "sdn_vnet" {
  description = "SDN VNet ID (only set when network_mode = 'subnet')"
  value       = var.network_mode == "subnet" ? local.sdn_vnet_id : null
}

output "subnet_cidr" {
  description = "Internal subnet CIDR (only set when network_mode = 'subnet')"
  value       = var.network_mode == "subnet" ? var.subnet.cidr : null
}
