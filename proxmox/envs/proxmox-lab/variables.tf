# ---------------------------------------------------------------------------
# Proxmox connection
# ---------------------------------------------------------------------------

variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, e.g. https://pve.example.com:8006"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the form 'user@realm!tokenid=secret' (vault secret in opensoja)"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS certificate verification (use for self-signed certs)"
  type        = bool
  default     = false
}

variable "proxmox_node" {
  description = "Proxmox node where all VMs will be created"
  type        = string
}

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------

variable "env_name" {
  description = "Short identifier for this environment (max 6 chars, lowercase alphanumeric). Used as prefix for VM names and SDN resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,5}$", var.env_name))
    error_message = "env_name must be 1–6 lowercase alphanumeric characters starting with a letter."
  }
}

variable "vm_id_base" {
  description = "Starting Proxmox VM ID. VMs are assigned IDs sequentially from this value."
  type        = number
  default     = 200

  validation {
    condition     = var.vm_id_base >= 100 && var.vm_id_base <= 999999900
    error_message = "vm_id_base must be between 100 and 999999900."
  }
}

# ---------------------------------------------------------------------------
# OS templates
# ---------------------------------------------------------------------------

variable "os_templates" {
  description = <<-EOT
    Map of OS identifier -> Proxmox template VM ID.
    Keys must match the keys used in vm_groups.
    Example:
      {
        windows2022   = 9001
        windows2012r2 = 9002
        debian13      = 9003
      }
  EOT
  type        = map(number)
}

# ---------------------------------------------------------------------------
# VM groups
# ---------------------------------------------------------------------------

variable "vm_groups" {
  description = <<-EOT
    Groups of VMs to deploy. Each key must exist in os_templates.
    Example:
      {
        windows2022   = { count = 1, os_type = "windows", cores = 4, memory_mb = 4096, disk_size = "60G" }
        windows2012r2 = { count = 2, os_type = "windows", cores = 2, memory_mb = 2048, disk_size = "40G" }
        debian13      = { count = 3, os_type = "linux",   cores = 2, memory_mb = 2048, disk_size = "20G" }
      }
  EOT
  type = map(object({
    count     = number
    os_type   = optional(string, "linux") # "linux" or "windows"
    cores     = optional(number, 2)
    memory_mb = optional(number, 2048)
    disk_size = optional(string, "40G")
    datastore = optional(string, "local-lvm")
  }))

  validation {
    condition     = alltrue([for v in values(var.vm_groups) : contains(["linux", "windows"], v.os_type)])
    error_message = "os_type must be 'linux' or 'windows'."
  }
}

variable "ssh_public_key" {
  description = "SSH public key injected via cloud-init into Linux VMs"
  type        = string
  sensitive   = true
}

variable "default_linux_user" {
  description = "Default cloud-init user for Linux VMs"
  type        = string
  default     = "ubuntu"
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

variable "network_mode" {
  description = "Network topology: 'bridge' (VMs directly on an existing bridge) or 'subnet' (VMs behind a Proxmox SDN internal network)"
  type        = string
  default     = "bridge"

  validation {
    condition     = contains(["bridge", "subnet"], var.network_mode)
    error_message = "network_mode must be 'bridge' or 'subnet'."
  }
}

variable "bridge_name" {
  description = "Bridge name to use when network_mode = 'bridge' (e.g. vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "subnet" {
  description = <<-EOT
    Subnet configuration for network_mode = 'subnet'.
    - cidr:         IP range for the internal network, e.g. "192.168.100.0/24"
    - snat_enabled: true → Proxmox MASQUERADE (VMs share host's outbound IP)
                    false → pure IP forwarding (requires static route on upstream router)
    - first_ip_offset: host offset for the first VM (default 10 → .10, .11, …)
  EOT
  type = object({
    cidr             = string
    snat_enabled     = bool
    first_ip_offset  = optional(number, 10)
  })
  default = null
}
