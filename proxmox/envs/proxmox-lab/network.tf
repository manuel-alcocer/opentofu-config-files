# SDN resources are only created when network_mode = "subnet".
#
# Proxmox SDN "simple" zone:
#   - Creates an internal Linux bridge on each node
#   - snat_enabled = true  → iptables MASQUERADE (VMs share the host's public IP)
#   - snat_enabled = false → plain IP forwarding (upstream router needs a static
#                            route to var.subnet.cidr via the Proxmox host)

resource "proxmox_virtual_environment_sdn_zone" "internal" {
  count = var.network_mode == "subnet" ? 1 : 0

  zone = local.sdn_zone_id
  type = "simple"
}

resource "proxmox_virtual_environment_sdn_vnet" "internal" {
  count = var.network_mode == "subnet" ? 1 : 0

  vnet = local.sdn_vnet_id
  zone = proxmox_virtual_environment_sdn_zone.internal[0].zone
}

resource "proxmox_virtual_environment_sdn_subnet" "internal" {
  count = var.network_mode == "subnet" ? 1 : 0

  vnet    = proxmox_virtual_environment_sdn_vnet.internal[0].vnet
  subnet  = var.subnet.cidr
  gateway = cidrhost(var.subnet.cidr, 1)
  snat    = var.subnet.snat_enabled
}
