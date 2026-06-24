resource "proxmox_virtual_environment_vm" "vm" {
  for_each = local.vms

  name      = each.key
  node_name = var.proxmox_node
  vm_id     = each.value.vm_id

  clone {
    vm_id = each.value.template_id
    full  = true
  }

  cpu {
    cores = each.value.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.memory_mb
  }

  disk {
    datastore_id = each.value.datastore
    size         = each.value.disk_size
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
  }

  # Referencing the SDN VNet output here creates an implicit dependency so that
  # the SDN subnet (and its SNAT rule) is fully applied before any VM starts.
  network_device {
    bridge = var.network_mode == "subnet" ? (
      length(proxmox_virtual_environment_sdn_vnet.internal) > 0
      ? proxmox_virtual_environment_sdn_vnet.internal[0].vnet
      : local.sdn_vnet_id
    ) : var.bridge_name
    model = "virtio"
  }

  operating_system {
    type = each.value.os_type == "windows" ? "win10" : "l26"
  }

  agent {
    enabled = true
  }

  # Cloud-init: Linux VMs only.
  # Windows VMs must be configured via the template (cloudbase-init / sysprep).
  dynamic "initialization" {
    for_each = each.value.os_type == "linux" ? [1] : []
    content {
      user_account {
        username = var.default_linux_user
        keys     = [var.ssh_public_key]
      }

      ip_config {
        ipv4 {
          address = each.value.ip_cidr
          gateway = each.value.gateway
        }
      }
    }
  }
}
