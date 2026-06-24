# opentofu-config-files

Central repository for OpenTofu infrastructure configurations, consumed by [opensoja](https://github.com/manuel-alcocer/opensoja).

## Structure

```
proxmox/
└── envs/
    └── proxmox-lab/    # VM environment on Proxmox
        ├── versions.tf  — OpenTofu ≥1.8, bpg/proxmox ~0.73
        ├── providers.tf — API token auth
        ├── variables.tf — all inputs
        ├── locals.tf    — vm_groups expansion + SDN identifiers
        ├── network.tf   — SDN zone/vnet/subnet (subnet mode only)
        ├── main.tf      — proxmox_virtual_environment_vm
        └── outputs.tf
```

## Usage with opensoja

1. Create a workspace in opensoja pointing to this repo with working directory `proxmox/envs/proxmox-lab`.
2. Set the variables below as workspace variables (mark sensitive ones as vault-backed or encrypted).

### Required variables

| Variable | Type | Sensitive | Description |
|---|---|---|---|
| `proxmox_endpoint` | string | No | Proxmox API URL, e.g. `https://pve:8006` |
| `proxmox_api_token` | string | **Yes (vault)** | `user@realm!tokenid=secret` |
| `proxmox_node` | string | No | Target Proxmox node name |
| `env_name` | string | No | Short env prefix, e.g. `lab` (max 6 chars) |
| `os_templates` | map(number) | No | OS name → Proxmox template VM ID |
| `vm_groups` | map(object) | No | VM groups to deploy (see below) |
| `ssh_public_key` | string | **Yes** | SSH public key for Linux VMs |

### Optional variables

| Variable | Default | Description |
|---|---|---|
| `proxmox_insecure` | `false` | Skip TLS verification |
| `vm_id_base` | `200` | First Proxmox VM ID |
| `default_linux_user` | `"ubuntu"` | Cloud-init user for Linux VMs |
| `network_mode` | `"bridge"` | `"bridge"` or `"subnet"` |
| `bridge_name` | `"vmbr0"` | Bridge for `network_mode = "bridge"` |
| `subnet` | `null` | Subnet config for `network_mode = "subnet"` (see below) |

### vm_groups example

```hcl
{
  windows2022   = { count = 1, os_type = "windows", cores = 4, memory_mb = 4096, disk_size = "60G" }
  windows2012r2 = { count = 2, os_type = "windows", cores = 2, memory_mb = 2048, disk_size = "40G" }
  debian13      = { count = 3, os_type = "linux",   cores = 2, memory_mb = 2048, disk_size = "20G" }
}
```

### subnet example (network_mode = "subnet")

```hcl
{
  cidr            = "192.168.100.0/24"
  snat_enabled    = true   # false → pure routing (needs static route on upstream router)
  first_ip_offset = 10     # first VM gets .10, second .11, …
}
```

### os_templates example

```hcl
{
  windows2022   = 9001
  windows2012r2 = 9002
  debian13      = 9003
}
```

## Network modes

| Mode | Resources created | Outbound connectivity |
|---|---|---|
| `bridge` | None (uses existing bridge) | Depends on bridge config |
| `subnet` + `snat_enabled = true` | SDN zone + vnet + subnet | MASQUERADE via Proxmox host IP |
| `subnet` + `snat_enabled = false` | SDN zone + vnet + subnet | IP forwarding only (needs upstream static route) |

## Windows VMs

Windows VMs are cloned from their template without cloud-init. Initial configuration (IP, user, etc.) must be handled by the template via `cloudbase-init` or `sysprep`. The QEMU guest agent must be installed in the template for opensoja to report the VM's IP.
