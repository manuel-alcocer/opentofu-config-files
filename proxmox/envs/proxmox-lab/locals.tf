locals {
  # ---------------------------------------------------------------------------
  # Expand vm_groups into a flat ordered list, then into a keyed map.
  # VM names follow the pattern: <env>-<group>-<N>
  # VM IDs are assigned sequentially from vm_id_base.
  # ---------------------------------------------------------------------------
  _vm_list = flatten([
    for group_name, group in var.vm_groups : [
      for i in range(group.count) : {
        key        = "${var.env_name}-${group_name}-${i + 1}"
        group_name = group_name
        group      = group
      }
    ]
  ])

  vms = {
    for idx, vm in local._vm_list :
    vm.key => {
      vm_id       = var.vm_id_base + idx
      template_id = var.os_templates[vm.group_name]
      os_type     = vm.group.os_type
      cores       = vm.group.cores
      memory_mb   = vm.group.memory_mb
      disk_size   = vm.group.disk_size
      datastore   = vm.group.datastore
      # IPs assigned statically in subnet mode; DHCP in bridge mode
      ip_cidr = var.network_mode == "subnet" ? (
        "${cidrhost(var.subnet.cidr, var.subnet.first_ip_offset + idx)}/${split("/", var.subnet.cidr)[1]}"
      ) : "dhcp"
      gateway = var.network_mode == "subnet" ? cidrhost(var.subnet.cidr, 1) : null
    }
  }

  # ---------------------------------------------------------------------------
  # SDN identifiers (deterministic, no resource refs — safe to use in for_each)
  # ---------------------------------------------------------------------------
  sdn_zone_id = "${var.env_name}z"
  sdn_vnet_id = "${var.env_name}vn"
}
